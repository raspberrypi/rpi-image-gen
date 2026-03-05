from __future__ import annotations

import json
import os
import re
from collections import OrderedDict
from pathlib import Path
from typing import Dict, Mapping, Optional, Any

__all__ = [
    "AssignmentError",
    "CircularReferenceError",
    "UndefinedVariableError",
    "load_env_file",
    "write_env_file",
    "LazyEnvResolver",
    "AnchorRegistry",
    "write_anchor_manifest",
    "resolve_env_file",
    "EnvResolver_register_parser",
]

_VAR_PATTERN = re.compile(r"\$\{([^}]+)\}")
_VALID_VAR = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


class AssignmentError(Exception):
    """Raised when a shell-style assignment cannot be parsed or evaluated."""


class CircularReferenceError(AssignmentError):
    """Raised when a variable depends on itself via nested references."""


class UndefinedVariableError(AssignmentError):
    """Raised when a referenced variable is missing."""


def load_env_file(path: str | os.PathLike[str]) -> "OrderedDict[str, str]":
    """Load simple key=value pairs (no inline comments/quotes)."""
    ordered: "OrderedDict[str, str]" = OrderedDict()
    resolved = str(Path(path).resolve())
    with open(resolved, "r", encoding="utf-8") as handle:
        for lineno, line in enumerate(handle, 1):
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if "=" not in stripped:
                raise AssignmentError(f"Expected key=value syntax in {resolved}:{lineno}")
            name, value = stripped.split("=", 1)
            name = name.strip()
            value = value.strip()
            if not _VALID_VAR.match(name):
                raise AssignmentError(f"Invalid variable name '{name}' ({resolved}:{lineno})")
            if len(value) >= 2 and value[0] == value[-1] == '"':
                value = value[1:-1]
            ordered[name] = value
    return ordered


def write_env_file(
    path: str | os.PathLike[str],
    assignments: Mapping[str, str],
    resolved_values: Mapping[str, str],
) -> None:
    """Write resolved values back to disk using simple key=value syntax."""
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    with open(target, "w", encoding="utf-8") as handle:
        for name in assignments:
            handle.write(f"{name}={resolved_values.get(name, '')}\n")


class AnchorRegistry:
    """Tracks anchor metadata and resolved values."""

    def __init__(self, initial: Optional[Mapping[str, Any]] = None):
        self._anchors: Dict[str, Dict[str, Any]] = {}
        if initial:
            for name, entry in initial.items():
                norm = self.normalize(name)
                if isinstance(entry, dict):
                    var_name = entry.get("var")
                    value = entry.get("value")
                else:
                    var_name = None
                    value = entry
                self._anchors[norm] = {"var": var_name, "value": value, "referenced_by": set()}

    @staticmethod
    def normalize(name: str) -> str:
        if not name:
            raise AssignmentError("Anchor name cannot be empty")
        name = name.strip()
        if not name.startswith("@"):
            name = f"@{name}"
        return name.upper()

    def register(self, anchor_name: str, *, var_name: Optional[str] = None) -> None:
        norm = self.normalize(anchor_name)
        entry = self._anchors.setdefault(norm, {"var": None, "value": None, "referenced_by": set()})
        if var_name:
            if entry["var"] and entry["var"] != var_name:
                raise AssignmentError(f"Anchor {norm} already bound to {entry['var']}")
            entry["var"] = var_name

    def get_var(self, anchor_name: str) -> Optional[str]:
        norm = self.normalize(anchor_name)
        entry = self._anchors.get(norm)
        if entry:
            return entry.get("var")
        return None

    def mark_usage(self, anchor_name: str, owner: str) -> None:
        norm = self.normalize(anchor_name)
        entry = self._anchors.setdefault(norm, {"var": None, "value": None, "referenced_by": set()})
        entry["referenced_by"].add(owner)

    def set_value(self, anchor_name: str, value: str) -> None:
        norm = self.normalize(anchor_name)
        entry = self._anchors.setdefault(norm, {"var": None, "value": None, "referenced_by": set()})
        entry["value"] = value

    def capture_values(self, env_values: Mapping[str, str]) -> None:
        for norm, entry in self._anchors.items():
            target = entry.get("var")
            if target and target in env_values:
                entry["value"] = env_values[target]

    def resolve(self, anchor_name: str) -> str:
        norm = self.normalize(anchor_name)
        entry = self._anchors.get(norm)
        if not entry or entry.get("value") is None:
            raise AssignmentError(f"Anchor {norm} has no assigned value")
        return entry["value"]

    def to_payload(self) -> Dict[str, Any]:
        payload: Dict[str, Any] = {}
        for name, entry in self._anchors.items():
            payload[name] = {
                "var": entry.get("var"),
                "value": entry.get("value"),
            }
        return dict(sorted(payload.items()))


def write_anchor_manifest(
    path: str | os.PathLike[str],
    registry: AnchorRegistry,
    resolved_values: Optional[Mapping[str, str]] = None,
) -> None:
    """Emit anchor metadata + resolved values as JSON."""
    if resolved_values:
        registry.capture_values(resolved_values)
    payload = {"anchors": registry.to_payload()}
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    with open(target, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, sort_keys=True)
        handle.write("\n")


class LazyEnvResolver:
    """Evaluates ${VAR} references lazily, preserving ${@ANCHOR} placeholders."""

    def __init__(
        self,
        assignments: Mapping[str, str],
        *,
        external_context: Optional[Mapping[str, str]] = None,
        anchor_registry: Optional[AnchorRegistry] = None,
        preserve_anchors: bool = True,
    ):
        self.assignments = OrderedDict(assignments)
        self.external_context = dict(external_context or os.environ)
        self.anchor_registry = anchor_registry or AnchorRegistry()
        self.preserve_anchors = preserve_anchors
        self._cache: Dict[str, str] = {}
        self._stack: list[str] = []

    def set(self, name: str, value: str) -> None:
        self.assignments[name] = value
        self._cache.pop(name, None)

    def resolve_all(self) -> "OrderedDict[str, str]":
        resolved: "OrderedDict[str, str]" = OrderedDict()
        for name in self.assignments:
            resolved[name] = self.resolve(name)
        return resolved

    def resolve(self, name: str) -> str:
        if name in self._cache:
            return self._cache[name]
        if name in self._stack:
            chain = " -> ".join(self._stack + [name])
            raise CircularReferenceError(f"Circular reference detected: {chain}")
        if name in self.assignments:
            raw_value = self.assignments[name]
        elif name in self.external_context:
            return self.external_context[name]
        else:
            raise UndefinedVariableError(f"Undefined variable '{name}'")

        self._stack.append(name)
        try:
            expanded = self._expand_text(raw_value, current_var=name)
            self._cache[name] = expanded
            return expanded
        finally:
            self._stack.pop()

    def _expand_text(self, text: str, *, current_var: str) -> str:
        def repl(match: re.Match[str]) -> str:
            token = match.group(1).strip()
            if not token:
                return ""
            if token.startswith("@"):
                self.anchor_registry.mark_usage(token, current_var)
                if self.preserve_anchors:
                    return match.group(0)
                try:
                    return self.anchor_registry.resolve(token)
                except AssignmentError:
                    bound_var = self.anchor_registry.get_var(token)
                    if bound_var:
                        return self.resolve(bound_var)
                    raise
            if not _VALID_VAR.match(token):
                raise AssignmentError(f"Invalid reference '${{{token}}}' in {current_var}")
            return self.resolve(token)

        return _VAR_PATTERN.sub(repl, text)


def resolve_env_file(
    env_in: str,
    env_out: str,
    anchors_out: Optional[str],
    *,
    preserve_anchors: bool,
    anchor_in: Optional[str] = None,
    external_context: Optional[Mapping[str, str]] = None,
) -> AnchorRegistry:
    """High-level helper to resolve an env file and emit outputs."""
    assignments = load_env_file(env_in)
    preload = None
    if anchor_in:
        with open(anchor_in, "r", encoding="utf-8") as handle:
            data = json.load(handle)
        preload = data.get("anchors") if isinstance(data, dict) else data
    registry = AnchorRegistry(preload)
    resolver = LazyEnvResolver(
        assignments,
        external_context=external_context,
        anchor_registry=registry,
        preserve_anchors=preserve_anchors,
    )
    resolved = resolver.resolve_all()
    write_env_file(env_out, assignments, resolved)
    if anchors_out:
        write_anchor_manifest(anchors_out, registry, resolved)
    return registry


def EnvResolver_register_parser(subparsers):
    parser = subparsers.add_parser("resolve", help="Resolve env files and emit anchor manifests")
    parser.add_argument("--env-in", required=True, help="Input env file produced by config/layer stages")
    parser.add_argument("--env-out", required=True, help="Output env file")
    parser.add_argument("--anchors-out", required=True, help="JSON file capturing anchors and their values")
    parser.add_argument("--anchor-in", help="Existing anchor manifest to preload values (expands anchors)")
    parser.add_argument(
        "--preserve-anchors",
        action="store_true",
        help="Preserve ${@ANCHOR} placeholders (default is to expand when --anchor-in is supplied)",
    )
    parser.set_defaults(func=_resolve_main)


def _resolve_main(args):
    try:
        preserve = args.preserve_anchors or not bool(args.anchor_in)
        resolve_env_file(
            args.env_in,
            args.env_out,
            args.anchors_out,
            preserve_anchors=preserve,
            anchor_in=args.anchor_in,
        )
    except AssignmentError as exc:
        print(f"Error: {exc}")
        raise SystemExit(1)

