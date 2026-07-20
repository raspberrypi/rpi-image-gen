import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Union

from metadata_parser import Metadata
from env_types import EnvTrait, TRAIT_TOKEN_PATTERN
import conditions as _cond

TOKEN_RE = re.compile(rf'^{TRAIT_TOKEN_PATTERN}$')
NAMESPACE_NODE_RE = re.compile(r'^[a-z][a-z0-9]*$')


def provider_token_type(token: str) -> str:
    """Return 'trait' for namespaced tokens (containing ':'), 'label' otherwise."""
    return 'trait' if ':' in token else 'label'


class TraitRegistry:
    """
    Loads trait token definitions from one or more trait/ directories.

    Each file is one deb822 stanza that can define several sibling local names
    (X-Env-Trait-<local>-Desc etc), all sharing whichever prefix the Include:
    that pulled the file in established. Hierarchy comes purely from
    position in the Include: chain - a local name is always a single,
    colon-free segment.

    Directories are scanned in order - put the built-in root first so OEM
    extensions can reference its tokens. Within a directory the top-level
    *.deb822 scan is single-level, not recursive: a file only meant to be
    reached via Include must live in a subdirectory, or it loads twice -
    once correctly via Include and once directly by the scan with the wrong
    (empty) prefix, and whichever wins the race silently shadows the other.
    Include: also defines load order (parent before child), which is what
    makes forward-reference checking possible.

    A token is never legitimately defined twice - the only supported
    override is a build config file's `trait:` section (see resolve()), not a
    second definition - so any duplicate is a hard error.
    """

    def __init__(self, trait_dirs: Union[str, Path, List[Union[str, Path]]]):
        if not isinstance(trait_dirs, list):
            trait_dirs = [trait_dirs]
        trait_dirs = [Path(d) for d in trait_dirs]

        self._definitions: Dict[str, EnvTrait] = {}
        # Namespace nodes only: which root(s) have defined this name, so the
        # duplicate check can tell a cross-root extension (fine) from a
        # same-root copy/paste (error).
        self._namespace_roots: Dict[str, Set[int]] = {}
        self._position = 0
        visited: Set[Path] = set()
        for root_index, trait_dir in enumerate(trait_dirs):
            if not trait_dir.is_dir():
                continue
            for deb822_file in sorted(trait_dir.glob('*.deb822')):
                self._load_file(deb822_file.resolve(), visited, prefix=None, root_index=root_index)

        # Namespace nodes (bare identifiers, e.g. 'hw') are load-time
        # scaffolding - they only carry Include: and hand their name down as
        # a prefix, so they're excluded here and can never satisfy a
        # Requires:/Triggers: reference. No orphaned children are possible:
        # a node is always added before its own.
        # Include: is followed, so every ancestor of a resolved token is always
        # loaded first.
        self._resolved: Dict[str, EnvTrait] = {
            token: trait for token, trait in self._definitions.items() if ':' in token
        }

    def _load_file(self, path: Path, visited: Set[Path], prefix: Optional[str], root_index: int) -> None:
        """Load one file's local names. 'prefix' is the full name of whichever
        node's Include: pulled this file in - None for a top-level scanned
        file. Each local name is resolved to prefix:local_name or used as-is.
        'root_index' is which trait_dirs entry this file traces back to, and 
        is inherited unchanged through Include: recursion.
        """
        if path in visited:
            return
        visited.add(path)

        meta = Metadata(str(path))
        for local_name, trait in meta.get_traits().items():
            full_name = f"{prefix}:{local_name}" if prefix is not None else local_name
            if ':' in full_name:
                if not TOKEN_RE.match(full_name):
                    raise ValueError(f"{path}: invalid trait token name '{full_name}'")
            elif not NAMESPACE_NODE_RE.match(full_name):
                raise ValueError(f"{path}: invalid namespace node name '{full_name}'")
            trait.name = full_name
            trait.position = self._position
            self._position += 1

            for dep in trait.requires:
                self._check_reference(dep, path, trait.name, "Requires")
            for rule in trait.triggers:
                if rule.target != trait.name:
                    self._check_reference(rule.target, path, trait.name, "Triggers")

            # A namespace node can be (re)defined once per root - a different
            # root extending it (eg, an OEM adding children under 'hw') is
            # expected/possible, but two top-level files in the same root both
            # defining it is a mistake. Real tokens always need exactly one
            # definition, regardless of root.
            if ':' in trait.name:
                existing = self._definitions.get(trait.name)
                if existing is not None:
                    raise ValueError(
                        f"Duplicate trait definition: '{trait.name}' is defined in both "
                        f"{existing.source} and {path}"
                    )
            else:
                seen_roots = self._namespace_roots.setdefault(trait.name, set())
                if root_index in seen_roots:
                    existing = self._definitions[trait.name]
                    raise ValueError(
                        f"Duplicate trait definition: namespace node '{trait.name}' is defined "
                        f"twice within the same source root, in both {existing.source} and {path}"
                    )
                seen_roots.add(root_index)
            self._definitions[trait.name] = trait

            for inc in trait.include:
                inc_path = (path.parent / inc).resolve()
                if not inc_path.exists():
                    raise FileNotFoundError(
                        f"Include '{inc}' not found (from {path}, node '{trait.name}')"
                    )
                self._load_file(inc_path, visited, prefix=trait.name, root_index=root_index)

    def _check_reference(self, target: str, path: Path, name: str, field: str) -> None:
        """A Requires:/Triggers: target is always a full name (never
        relative) and must resolve to an already-defined real trait, not a
        namespace node."""
        if target not in self._definitions:
            raise ValueError(
                f"{path}: '{name}' {field} forward reference to '{target}' before it's defined"
            )
        if ':' not in target:
            raise ValueError(
                f"{path}: '{name}' {field} references '{target}', a namespace node, not a trait"
            )

    def expand(self, token: str) -> Dict[str, str]:
        """Closure of one token: hierarchy ancestors plus unconditional
        (when=y) Triggers, recursively. Conditional Triggers need a build's
        accumulated token set, see resolve()."""
        if token not in self._resolved:
            raise ValueError(f"'{token}' is not defined in the registry")
        result: Dict[str, str] = {}
        self._expand(token, result, set())
        return result

    def _expand(self, token: str, result: Dict[str, str], seen: Set[str]) -> None:
        if token in seen:
            return
        seen.add(token)
        parts = token.split(':')
        for i in range(2, len(parts)):
            self._expand(':'.join(parts[:i]), result, seen)
        result[token] = self._resolved[token].source
        for rule in self._resolved[token].triggers:
            if rule.condition == 'y':
                self._expand(rule.target, result, seen)

    def __contains__(self, token: str) -> bool:
        return token in self._resolved

    def get_desc(self, token: str) -> Optional[str]:
        d = self._resolved.get(token)
        return d.desc if d else None

    def get_valid(self, token: str) -> Optional[str]:
        d = self._resolved.get(token)
        return d.valid if d else None

    def get_requires(self, token: str) -> List[str]:
        d = self._resolved.get(token)
        return d.requires if d else []

    @property
    def all_tokens(self) -> Dict[str, str]:
        return {t: d.source for t, d in self._resolved.items()}

    def by_prefix(self, prefix: str) -> Dict[str, str]:
        """Every real token equal to 'prefix' or nested under it at a colon
        boundary (e.g. 'hw:soc' matches 'hw:soc:bcm2712', not 'hw:soccer').
        A trailing colon is stripped, so 'hw:' and 'hw' are the same """
        prefix = prefix.rstrip(':')
        return {
            t: d.source for t, d in self._resolved.items()
            if t == prefix or t.startswith(prefix + ':')
        }

    def resolve(self, declared: Set[str]) -> Set[str]:
        """Simulate a build's accumulated trait set from a set of directly
        declared tokens (TODO layer manager injection point).

        1. Expand each declared token (hierarchy + unconditional Triggers).
        2. Fixed point: fire any Trigger whose condition now holds, until
           nothing changes. A self-targeting rule fires on its condition
           alone - a cross-targeting rule also requires its source token to
           be active.
        3. Validate Requires for every active token, however it got there -
           direct declaration, hierarchy ancestor, or a Trigger. If a token
           is active, its own preconditions must hold too.
        """
        active: Set[str] = set()
        for token in declared:
            if token not in self._resolved:
                raise ValueError(f"Unknown trait token: '{token}'")
            active.update(self.expand(token).keys())

        changed = True
        while changed:
            changed = False
            for token, trait in self._resolved.items():
                for rule in trait.triggers:
                    if rule.target in active:
                        continue
                    if rule.target == token:
                        fires = rule.condition == 'y' or _cond.evaluate(rule.condition, {}, active)
                    else:
                        fires = token in active and (
                            rule.condition == 'y' or _cond.evaluate(rule.condition, {}, active)
                        )
                    if fires:
                        for t in self.expand(rule.target):
                            if t not in active:
                                active.add(t)
                                changed = True

        unmet: Dict[str, List[str]] = {}
        for token in active:
            missing = [r for r in self._resolved[token].requires if r not in active]
            if missing:
                unmet[token] = missing
        if unmet:
            msgs = [f"{t}: Requires not satisfied, missing: {', '.join(m)}"
                    for t, m in sorted(unmet.items())]
            raise ValueError('\n'.join(msgs))

        return active
