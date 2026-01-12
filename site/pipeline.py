from __future__ import annotations

import argparse
import os
from collections import OrderedDict
from typing import List, Optional, Dict

from layer_manager import LayerManager
from env_types import EnvVariable, VariableResolver
from env_resolver import (
    load_env_file,
    write_env_file,
    LazyEnvResolver,
    AnchorRegistry,
)
from logger import LogConfig, log_info


def Pipeline_register_parser(subparsers, root=None):
    if root:
        default_paths = f'layer={root}/layer:device={root}/device:image={root}/image'
    else:
        default_paths = 'layer=./layer:device=./device:image=./image'
    help_text = 'Colon-separated search paths for layers (use tag=/path to name each root)'

    parser = subparsers.add_parser(
        "pipeline",
        help="Apply layers then resolve env/anchors in one step",
    )
    parser.add_argument("--env-in", help="Env file produced by 'ig config --write-to'")
    parser.add_argument("--layers", nargs="+", help="Layers to apply (names)")
    parser.add_argument("--path", "-p", default=default_paths, help=help_text)
    parser.add_argument("--env-out", required=True, help="Write fully resolved env (anchors expanded)")
    parser.add_argument("--order-out", help="Write layer order (tag:relative) to this file (host mode only)")
    parser.set_defaults(func=_pipeline_main)


def _pipeline_main(args):
    search_paths = [p.strip() for p in args.path.split(':') if p.strip()]

    if not args.env_in or not args.layers:
        print("Error: --env-in and --layers are required")
        raise SystemExit(1)

    LogConfig.set_verbose(True)

    assignments: OrderedDict[str, str] = load_env_file(args.env_in)
    for key, value in assignments.items():
        os.environ[key] = value

    try:
        manager = LayerManager(search_paths, ['*.yaml'], fail_on_lint=True)
    except ValueError as exc:
        print(f"Error: {exc}")
        raise SystemExit(1)

    resolved_layers: List[str] = []
    for layer_id in args.layers:
        layer_name = manager.resolve_layer_name(layer_id)
        if not layer_name:
            print(f"Error: Layer '{layer_id}' not found")
            raise SystemExit(1)
        resolved_layers.append(layer_name)

    try:
        build_order = manager.get_build_order(resolved_layers)
    except ValueError as exc:
        print(f"Error: {exc}")
        raise SystemExit(1)

    if not _validate_layers(manager, build_order, ignore_missing_required=True):
        raise SystemExit(1)

    applied_values = _apply_layers(manager, build_order)
    for var_name, value in applied_values.items():
        assignments[var_name] = value

    if not _validate_layers(manager, resolved_layers, ignore_missing_required=False):
        print("Error: Validation failed for target layers")
        raise SystemExit(1)

    if args.order_out:
        _write_layer_order(args.order_out, build_order, manager)

    layer_anchor_map = _build_anchor_map_from_layers(manager, build_order)
    source_anchors = layer_anchor_map or {}

    # Always inject IGROOT/SRCROOT so downstream tooling can remap paths
    _inject_root_anchors(source_anchors, assignments)

    # Load all anchors
    registry_final = AnchorRegistry(source_anchors)

    # Resolve now
    from env_resolver import (
            AssignmentError,
            CircularReferenceError,
            UndefinedVariableError,
            )
    resolver_final = LazyEnvResolver(assignments, anchor_registry=registry_final, preserve_anchors=False)
    try:
        final_values = resolver_final.resolve_all()
    except AssignmentError as e:
        raise SystemExit(f"Variable resolution failed: {e}")
    except UndefinedVariableError as e:
        raise SystemExit(f"Undefined variable: {e}")
    except CircularReferenceError as e:
        raise SystemExit(f"Circular reference: {e}")

    # Write out
    write_env_file(args.env_out, assignments, final_values)


def _inject_root_anchors(anchor_map: Dict[str, Dict[str, Optional[str]]], env_assignments: Dict[str, str]) -> None:
    for root_var in ("IGROOT", "SRCROOT"):
        value = env_assignments.get(root_var)
        if value:
            anchor_map.setdefault(f"@{root_var}", {"var": root_var, "value": value})


def _write_layer_order(path: str, build_order: List[str], manager: LayerManager) -> None:
    try:
        with open(path, "w", encoding="utf-8") as handle:
            for layer in build_order:
                rel_spec = manager.get_layer_relative_spec(layer)
                if rel_spec:
                    handle.write(f'{layer}="{rel_spec}"\n')
                else:
                    handle.write(f"{layer}\n")
        print(f"Layer order written to: {path}")
    except Exception as exc:
        print(f"Error writing layer order to {path}: {exc}")
        raise SystemExit(1)


def _build_anchor_map_from_layers(manager: LayerManager, layers: List[str]) -> Dict[str, Dict[str, Optional[str]]]:
    anchor_bindings: Dict[str, str] = {}
    for layer in layers:
        meta = manager.layers.get(layer)
        if not meta:
            continue
        for env_var in meta._container.variables.values():
            if getattr(env_var, "anchor_name", None):
                anchor_bindings.setdefault(env_var.anchor_name, env_var.name)
    return {anchor: {"var": var_name} for anchor, var_name in anchor_bindings.items()}


def _collect_variable_definitions(manager: LayerManager, build_order: List[str]) -> Dict[str, List[EnvVariable]]:
    variable_definitions: Dict[str, List[EnvVariable]] = {}
    for position, layer_name in enumerate(build_order):
        meta = manager.layers.get(layer_name)
        if not meta:
            continue
        for var_name, env_var in meta._container.variables.items():
            var_with_position = EnvVariable(
                name=env_var.name,
                value=env_var.value,
                description=env_var.description,
                required=env_var.required,
                validator=env_var.validator,
                validation_rule=getattr(env_var, "validation_rule", ""),
                set_policy=env_var.set_policy,
                source_layer=layer_name,
                position=position,
                anchor_name=env_var.anchor_name,
            )
            variable_definitions.setdefault(var_name, []).append(var_with_position)
    return variable_definitions


def _apply_layers(
    manager: LayerManager,
    build_order: List[str],
) -> OrderedDict[str, str]:
    variable_definitions = _collect_variable_definitions(manager, build_order)
    resolver = VariableResolver()
    resolved_variables = resolver.resolve(variable_definitions)

    applied: "OrderedDict[str, str]" = OrderedDict()
    ordered_vars = sorted(resolved_variables.values(), key=lambda env_var: env_var.position)

    for env_var in ordered_vars:
        var_name = env_var.name
        value = env_var.value
        policy = env_var.set_policy
        layer_name = env_var.source_layer

        if policy == "force":
            os.environ[var_name] = value
            applied[var_name] = value
            _log_env_action("FORCE", var_name, value, layer_name)
        elif policy == "immediate":
            if var_name not in os.environ:
                os.environ[var_name] = value
                applied[var_name] = value
                _log_env_action("SET", var_name, value, layer_name)
            else:
                _log_env_action("SKIP", var_name, None, layer_name, reason=" (already set)")
        elif policy == "lazy":
            if var_name not in os.environ:
                os.environ[var_name] = value
                applied[var_name] = value
                _log_env_action("LAZY", var_name, value, layer_name)
            else:
                _log_env_action("SKIP", var_name, None, layer_name, reason=" (already set)")
        elif policy == "already_set":
            _log_env_action("SKIP", var_name, None, layer_name, reason=" (already set)")
        elif policy == "skip":
            _log_env_action("SKIP", var_name, None, layer_name, reason=" (Set: false/skip)")

    if applied:
        print("Environment variables applied successfully")
    return applied


def _validate_layers(manager: LayerManager, layer_names: List[str], *, ignore_missing_required: bool) -> bool:
    for layer_name in layer_names:
        if layer_name not in manager.layers:
            print(f"Layer '{layer_name}' not found")
            return False
        if not hasattr(manager, "validate_layer"):
            raise AttributeError("LayerManager.validate_layer is required for pipeline validation")
        if not manager.validate_layer(layer_name, silent=False, ignore_missing_required=ignore_missing_required):
            return False
    return True


def _log_env_action(
    tag: str,
    var_name: str,
    value: Optional[str],
    layer_name: str,
    *,
    reason: str = "",
) -> None:
    if not LogConfig.verbose:
        return
    if value is None:
        log_info(f"  [{tag}]  {var_name}{reason} (layer: {layer_name})")
    else:
        log_info(f"  [{tag}]  {var_name}={value}{reason} (layer: {layer_name})")

