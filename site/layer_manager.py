import os
import glob
import shutil
import argparse
import shlex
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass
import yaml


from metadata_parser import Metadata
from metadata_parser import print_env_var_descriptions

from logger import log_warning, log_failure, log_error, log_info


@dataclass(frozen=True)
class LayerSearchRoot:
    tag: str
    path: Path


# Handles discovery, dependency resolution, and orchestration
class LayerManager:
    def __init__(
        self,
        search_paths: Optional[List[str]] = None,
        file_patterns: Optional[List[str]] = None,
        *,
        show_loaded: bool = False,
        doc_mode: bool = False,
        fail_on_lint: bool = False,
    ):
        if search_paths is None:
            search_paths = ['./layer']
        if file_patterns is None:
            file_patterns = ['*.yaml', '*.yml']

        self.search_roots = self._build_search_roots(search_paths)
        self.search_paths = [root.path for root in self.search_roots]
        self.file_patterns = file_patterns
        self.layers: Dict[str, Metadata] = {}  # layer_name -> Metadata object
        self.layer_files: Dict[str, str] = {}  # layer_name -> file_path
        self.layer_tags: Dict[str, str] = {}  # layer_name -> search path tag
        self.layer_relpaths: Dict[str, str] = {}  # layer_name -> relative path under tagged root
        self.tag_to_path: Dict[str, Path] = {root.tag: root.path for root in self.search_roots}
        self.show_loaded = show_loaded
        self.doc_mode = doc_mode  # Relaxed loader, eg does not run generators for dynamic layers
        self.fail_on_lint = fail_on_lint
        # provider index will be built after layers are loaded
        self.provider_index: Dict[str, str] = {}
        self.provider_conflicts: Dict[str, Set[str]] = {}
        self.generated_root: Optional[Path] = None
        self.load_errors: Dict[str, str] = {}

        for path in self.search_paths:
            if not path.exists():
                log_warning(f"Search path '{path}' does not exist")

        self.load_layers()

        # now that self.layers is populated, build provider index
        self._build_provider_index()


    def _handle_layer_load_error(self, rel_path: Path, message: str, exc: Optional[Exception] = None, layer_name: Optional[str] = None) -> None:
        """Record and report layer load failures."""
        key = layer_name or str(rel_path)
        self.load_errors[key] = message
        self.load_errors[str(rel_path)] = message
        log_warning(f"{rel_path}: {message}")

    @staticmethod
    def _is_env_resolution_error(exc: Exception) -> bool:
        """Return True if the exception is due to unresolved environment placeholders."""
        return isinstance(exc, ValueError) and "Unresolved environment variables" in str(exc)

    def _build_search_roots(self, raw_paths: List[str]) -> List[LayerSearchRoot]:
        roots: List[LayerSearchRoot] = []
        seen_tags: Set[str] = set()
        auto_index = 0

        for entry in raw_paths:
            entry = (entry or '').strip()
            if not entry:
                continue

            if '=' in entry:
                tag, path = entry.split('=', 1)
                tag = tag.strip()
                path = path.strip()
            else:
                tag = ''
                path = entry.strip()

            explicit_tag = bool(tag)

            if explicit_tag:
                if tag in seen_tags:
                    raise ValueError(f"Duplicate layer path tag '{tag}'")
            else:
                while True:
                    candidate = f"root{auto_index}"
                    auto_index += 1
                    if candidate not in seen_tags:
                        tag = candidate
                        break

            if not path:
                continue

            resolved = Path(path).expanduser().resolve()
            seen_tags.add(tag)
            roots.append(LayerSearchRoot(tag=tag, path=resolved))

        if not roots:
            roots.append(LayerSearchRoot(tag="root0", path=Path('./layer').resolve()))
        return roots


    def _build_provider_index(self):
        """Index providers to unique layer names"""
        for lname, layer in self.layers.items():
            info = layer.get_layer_info()
            if not info:
                continue
            for prov in info.get('provides', []):
                existing = self.provider_index.get(prov)
                if existing and existing != lname:
                    # record conflict but keep the first provider mapping (first-wins semantics)
                    self.provider_conflicts.setdefault(prov, set()).update({existing, lname})
                else:
                    self.provider_index[prov] = lname

    def load_layers(self):
        """Discover and load all layer files, creating Metadata objects for each"""
        loaded_layers = set()

        for root in self.search_roots:
            search_path = root.path
            if not search_path.exists():
                continue

            if root.tag == 'DYNlayer':
                # Reserved for generated output only
                continue

            # Find all matching files
            all_files = []
            for pattern in self.file_patterns:
                files = glob.glob(str(search_path / "**" / pattern), recursive=True)
                all_files.extend(files)

            for metadata_file in all_files:
                abs_file = Path(metadata_file).resolve()
                try:
                    relative_path = abs_file.relative_to(search_path)
                except ValueError:
                    relative_path = abs_file
                try:
                    meta = Metadata(metadata_file, doc_mode=self.doc_mode)
                except Exception as exc:
                    # If placeholders can’t resolve yet, record and skip. Other
                    # errors are hard failures for this file.
                    if self._is_env_resolution_error(exc):
                        self.load_errors[str(relative_path)] = str(exc)
                        log_warning(f"{relative_path}: {exc}")
                        continue
                    self._handle_layer_load_error(relative_path, f"Failed to load layer file: {exc}", exc)
                    continue

                try:
                    layer_info = meta.get_layer_info()
                except ValueError as exc:
                    # Layer fields present but invalid, so env resolution errors
                    # are downgraded to a warning/skip.
                    if self._is_env_resolution_error(exc):
                        self.load_errors[str(relative_path)] = str(exc)
                        log_warning(f"{relative_path}: {exc}")
                        continue
                    self._handle_layer_load_error(relative_path, f"Invalid X-Env-Layer metadata: {exc}", exc)
                    continue
                if not layer_info:
                    raw_meta = meta.get_metadata()
                    if any(k.startswith('X-Env-Layer-') for k in raw_meta.keys()):
                        # Layer metadata present but incomplete (eg, missing Name)
                        self._handle_layer_load_error(
                            relative_path,
                            "Incomplete X-Env-Layer metadata (missing required fields)",
                            layer_name=abs_file.stem,
                        )
                    continue

                layer_type = (layer_info.get('type') or 'static').lower()
                generator_cmd = (layer_info.get('generator') or '').strip()

                layer_name = layer_info['name']

                # lint on load
                lint_results = meta.lint_metadata_syntax()
                if lint_results:  # Any syntax errors found
                    details = "; ".join(
                        filter(
                            None,
                            (error.get("message", "") for error in lint_results.values()),
                        )
                    ) or "metadata syntax errors"
                    self._handle_layer_load_error(
                        relative_path,
                        f"Layer '{layer_name}' failed lint: {details}",
                        layer_name=layer_name,
                    )
                    continue

                # Duplicate detection
                if layer_name in self.layers:
                    prev_path = self.layer_files[layer_name]
                    raise ValueError(
                        f"Duplicate layer name '{layer_name}' found in:\n  {prev_path}\n  {abs_file}"
                    )

                if layer_type == 'dynamic':
                    if not generator_cmd:
                        raise ValueError(f"Layer '{layer_name}' marked dynamic but no generator defined")
                    try:
                        rel_path = abs_file.relative_to(search_path)
                    except ValueError:
                        rel_path = Path(layer_name).with_suffix('.yaml')

                    if self.doc_mode:
                        # Don't run generator - not needed in doc mode
                        tag = root.tag
                    else:
                        generated_root = self._ensure_generated_root()
                        output_file = generated_root / rel_path
                        output_file.parent.mkdir(parents=True, exist_ok=True)
                        self._run_layer_generator(layer_name, generator_cmd, abs_file, output_file)
                        abs_file = output_file.resolve()
                        tag = 'DYNlayer' # implicitly hard wired
                else:
                    tag = root.tag
                    try:
                        rel_path = abs_file.relative_to(search_path)
                    except ValueError:
                        rel_path = abs_file

                self.layers[layer_name] = meta
                self.layer_files[layer_name] = str(abs_file)
                self.layer_tags[layer_name] = tag
                self.layer_relpaths[layer_name] = str(rel_path)
                loaded_layers.add(layer_name)

                if self.show_loaded:
                    relative_path = rel_path
                    log_info(f"Loaded layer: {layer_name} from {relative_path}")

    def _ensure_generated_root(self) -> Path:
        if self.generated_root is not None:
            return self.generated_root

        tmp_path = self.tag_to_path.get('DYNlayer')
        if tmp_path is None:
            raise ValueError('Dynamic layer requested but DYNlayer tag not provided in path')

        tmp_path.mkdir(parents=True, exist_ok=True)
        self.generated_root = tmp_path
        return tmp_path

    def _run_layer_generator(self, layer_name: str, generator_cmd: str, input_path: Path, output_path: Path) -> None:
        cmd = shlex.split(generator_cmd) # supports positional args
        if not cmd:
            raise ValueError(f"Generator command for layer '{layer_name}' is empty")
        cmd = cmd + [str(input_path), str(output_path)]
        try:
            subprocess.run(cmd, check=True)
        except FileNotFoundError as exc:
            raise ValueError(f"Generator '{generator_cmd}' for layer '{layer_name}' not found") from exc
        except subprocess.CalledProcessError as exc:
            raise ValueError(f"Generator '{generator_cmd}' for layer '{layer_name}' failed with exit code {exc.returncode}") from exc

    def get_layer_info(self, layer_name: str) -> Optional[dict]:
        if layer_name not in self.layers:
            return None
        return self.layers[layer_name].get_layer_info()

    def get_layer_relative_spec(self, layer_name: str) -> Optional[str]:
        tag = self.layer_tags.get(layer_name)
        rel_path = self.layer_relpaths.get(layer_name)
        if tag and rel_path is not None:
            return f"{tag}:{rel_path}"
        return None

    def get_dependencies(self, layer_name: str) -> List[str]:
        """Get hard deps"""
        layer_info = self.get_layer_info(layer_name)
        if not layer_info:
            return []
        return list(layer_info['depends'])

    def get_reverse_dependencies(self, target_layer: str) -> List[str]:
        """Get hard reverse deps"""
        reverse_deps = []

        # Resolve the target layer name first
        resolved_target = self.resolve_layer_name(target_layer)
        if not resolved_target:
            return []

        # Search through all loaded layers
        for layer_name, layer_obj in self.layers.items():
            layer_info = layer_obj.get_layer_info()
            if layer_info and layer_info.get('depends'):
                # Check if target layer is in this layer's dependencies
                if resolved_target in layer_info['depends']:
                    reverse_deps.append(layer_name)

        return sorted(reverse_deps)

    def get_optional_dependencies(self, layer_name: str) -> List[str]:
        """Get optional deps"""
        layer_info = self.get_layer_info(layer_name)
        return layer_info['optional_depends'] if layer_info else []

    def get_all_dependencies(self, layer_name: str, visited: Optional[Set[str]] = None, include_optional: bool = True) -> List[str]:
        """Get all deps (including transitive) for a layer"""
        if visited is None:
            visited = set()

        if layer_name in visited or layer_name not in self.layers:
            return []

        visited.add(layer_name)
        all_deps = []

        # Add required dependencies
        for dep in self.get_dependencies(layer_name):
            if dep not in all_deps:
                all_deps.append(dep)
            # Add transitive dependencies
            for trans_dep in self.get_all_dependencies(dep, visited.copy(), include_optional):
                if trans_dep not in all_deps:
                    all_deps.append(trans_dep)

        # Add optional dependencies if requested and they exist
        if include_optional:
            for opt_dep in self.get_optional_dependencies(layer_name):
                if opt_dep in self.layers and opt_dep not in all_deps:
                    all_deps.append(opt_dep)
                    # Add transitive dependencies of optional dependencies
                    for trans_dep in self.get_all_dependencies(opt_dep, visited.copy(), include_optional):
                        if trans_dep not in all_deps:
                            all_deps.append(trans_dep)

        return all_deps

    def check_dependencies(self, layer_name: str) -> Tuple[bool, List[str]]:
        """Check if all dependencies for a layer are available"""
        if layer_name not in self.layers:
            return False, [f"Layer '{layer_name}' not found in search paths"]

        missing_deps = []
        warnings = []

        # Check required dependencies
        required_deps = self.get_all_dependencies(layer_name, include_optional=False)
        for dep in required_deps:
            if dep not in self.layers:
                missing_deps.append(f"Layer '{layer_name}' missing required dependency: {dep}")

        # Check optional dependencies separately - these generate warnings only
        optional_deps = self.get_optional_dependencies(layer_name)
        for opt_dep in optional_deps:
            if opt_dep not in self.layers:
                warnings.append(f"Optional dependency not available: {opt_dep}")

        # Check for circular dependencies
        circular = self._check_circular_dependencies(layer_name)
        if circular:
            missing_deps.append(f"Circular dependency detected: {' -> '.join(circular)}")

        # Check provider requirements (only if all required deps are present)
        if not missing_deps:
            try:
                # Get all layers that would be included in the dependency chain
                build_order = self.get_build_order([layer_name])
                # Provider validation happens inside get_build_order now
            except ValueError as e:
                missing_deps.append(str(e))

        if warnings:
            for warning in warnings:
                log_warning(f"{warning}")

        return len(missing_deps) == 0, missing_deps + warnings

    def _check_circular_dependencies(self, layer_name: str, path: Optional[List[str]] = None) -> List[str]:
        """Check for circular dependencies"""
        if path is None:
            path = []

        if layer_name in path:
            return path + [layer_name]  # Found cycle

        if layer_name not in self.layers:
            return []

        path = path + [layer_name]

        for dep in self.get_dependencies(layer_name):
            cycle = self._check_circular_dependencies(dep, path)
            if cycle:
                return cycle

        return []

    def get_build_order(self, target_layers: List[str]) -> List[str]:
        """Get the correct build order for target layers"""
        build_order = []
        processed = set()

        def check_missing_dependencies(layer_name: str, checked: set = None):
            """Recursively check for missing dependencies and raise ValueError if any are found"""
            if checked is None:
                checked = set()

            if layer_name in checked:  # Avoid infinite recursion
                return
            checked.add(layer_name)

            if layer_name not in self.layers:
                if layer_name in self.load_errors:
                    raise ValueError(f"Layer '{layer_name}' unavailable: {self.load_errors[layer_name]}")
                raise ValueError(f"Missing required dependency: {layer_name}")

            # Recurse
            for dep in self.get_dependencies(layer_name):
                check_missing_dependencies(dep, checked)

        def add_layer_and_deps(layer_name: str):
            if layer_name in processed:
                return

            # Add required dependencies first
            for dep in self.get_dependencies(layer_name):
                add_layer_and_deps(dep)

            # Add optional dependencies if they exist and are available
            for opt_dep in self.get_optional_dependencies(layer_name):
                if opt_dep in self.layers:
                    add_layer_and_deps(opt_dep)

            if layer_name not in processed:
                build_order.append(layer_name)
                processed.add(layer_name)

        # First, validate that all required dependencies exist
        for layer in target_layers:
            check_missing_dependencies(layer)

        # Then build the order
        for layer in target_layers:
            add_layer_and_deps(layer)

        # Validate that all required providers are satisfied by the build order
        self._validate_provider_requirements(build_order)

        return build_order

    def _validate_provider_requirements(self, build_order: List[str]) -> None:
        """Validate that all required providers are satisfied by layers in the build order"""
        # Check for provider conflicts within the build order scope
        self._check_provider_conflicts_in_scope(build_order)

        # Collect all providers available in the build order
        available_providers = set()
        for layer_name in build_order:
            layer_info = self.get_layer_info(layer_name)
            if layer_info:
                available_providers.update(layer_info.get('provides', []))

        # Check each layer's provider requirements
        for layer_name in build_order:
            layer_info = self.get_layer_info(layer_name)
            if layer_info:
                for required_provider in layer_info.get('provider_requires', []):
                    if required_provider not in available_providers:
                        raise ValueError(f"Layer '{layer_name}' requires provider '{required_provider}' but no layer in the dependency chain provides it")

    def _check_provider_conflicts_in_scope(self, layer_names: List[str]) -> None:
        """Validate that no provider conflicts exist within the given scope of layers."""
        # Build provider mapping only for the layers in scope
        scope_providers = {}
        for layer_name in layer_names:
            layer_info = self.get_layer_info(layer_name)
            if layer_info:
                for provider in layer_info.get('provides', []):
                    if provider in scope_providers:
                        # Found a conflict within scope
                        existing_layer = scope_providers[provider]
                        raise ValueError(f"Provider conflict: '{provider}' is provided by multiple layers: {existing_layer}, {layer_name}")
                    scope_providers[provider] = layer_name

    def _load_layer_yaml(self, filepath: str) -> Optional[dict]:
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except (FileNotFoundError, yaml.YAMLError, UnicodeDecodeError):
            return None

    def _get_mmdebstrap_config(self, layer_name: str) -> Optional[dict]:
        """Get mmdebstrap configuration if present """
        layer_path = self.layer_files.get(layer_name)
        if not layer_path:
            return None

        yaml_data = self._load_layer_yaml(layer_path)
        if not yaml_data:
            return None

        mmdebstrap = yaml_data.get('mmdebstrap')
        if isinstance(mmdebstrap, dict):
            return mmdebstrap

        return None

    def _get_env_config(self, layer_name: str) -> Optional[dict]:
        """Get env configuration if present """
        layer_path = self.layer_files.get(layer_name)
        if not layer_path:
            return None

        yaml_data = self._load_layer_yaml(layer_path)
        if not yaml_data:
            return None

        env = yaml_data.get('env')
        if isinstance(env, dict):
            return env

        return None

    def validate_layer(self, layer_name: str, silent: bool = False, *, ignore_missing_required: bool = False) -> bool:
        """Validate environment variables for a single layer (no dependency resolution)"""
        if layer_name not in self.layers:
            if not silent:
                log_error(f"Layer '{layer_name}' not found")
            return False

        layer = self.layers[layer_name]
        results = layer.validate_env_vars()

        layer_valid = True
        for var, result in results.items():
            if result["status"] == "missing_required":
                if ignore_missing_required:
                    continue
                if not silent:
                    log_error(f"[FAIL] {var} - REQUIRED but not set (layer: {layer_name})")
                layer_valid = False
            elif result["status"] == "missing_required_var":
                if ignore_missing_required:
                    continue
                if not silent:
                    log_error(f"[FAIL] {result['required_var']} - REQUIRED but not set (layer: {layer_name})")
                layer_valid = False
            elif result["status"] == "invalid_value":
                if not silent:
                    log_error(f"[FAIL] {var}={result['value']} (invalid value, layer: {layer_name})")
                layer_valid = False
            elif result["status"] == "validated" and not result["valid"]:
                if not silent:
                    log_error(f"[FAIL] {var}={result['value']} (invalid, layer: {layer_name})")
                layer_valid = False
            elif result["status"] == "required_validated" and not result["valid"]:
                if not silent:
                    log_error(f"[FAIL] {result['required_var']}={result['value']} (invalid, layer: {layer_name})")
                layer_valid = False
            # Handle other statuses for info output
            elif not silent:
                if result["status"] == "optional_var_unset":
                    log_info(f"[INFO] {result['optional_var']} - optional, not set (layer: {layer_name})")
                elif result["status"] == "optional_validated":
                    status = "OK" if result["valid"] else "WARN"
                    log_info(f"[{status}] {result['optional_var']}={result['value']} (optional, layer: {layer_name})")
                elif result["status"] == "optional_no_validation":
                    (f"[SKIP] {result['optional_var']}={result['value']} (optional, no validation rule, layer: {layer_name})")

        # Additional check: unsupported layer fields
        unsupported_layer = layer._check_unsupported_layer_fields()
        if unsupported_layer:
            for fld, msg in unsupported_layer.items():
                if not silent:
                    log_error(f"{msg} (layer: {layer_name})")
            layer_valid = False

        return layer_valid

    def list_layers(self):
        """List available layers grouped by category"""

        BOLD = "\033[1m"
        RESET = "\033[0m"
        MAX_DESC = 60

        # Build category -> [layer_names]
        categories: Dict[str, List[str]] = {}
        for lname in self.layers.keys():
            info = self.get_layer_info(lname)
            if not info:
                continue
            cat = info.get('category', 'general')
            categories.setdefault(cat, []).append(lname)

        # Compute widest layer name for column alignment
        all_layer_names = [n for lst in categories.values() for n in lst]
        name_width = max(len(n) for n in all_layer_names) if all_layer_names else 0

        print("Available layers:")

        for cat in sorted(categories.keys()):
            print(f"{BOLD}Category: {cat}{RESET}")

            for layer_name in sorted(categories[cat]):
                layer_info = self.get_layer_info(layer_name)
                if not layer_info:
                    continue

                # Description trimming
                raw_desc = (layer_info.get('description') or '')
                desc = ' '.join(raw_desc.split())
                if len(desc) > MAX_DESC:
                    desc = desc[: MAX_DESC - 3] + '...'

                # Bold layer name column
                print(f"  {BOLD}{layer_name:<{name_width}}{RESET}  {desc}")

                # Dependencies line
                deps = ', '.join(layer_info['depends']) if layer_info['depends'] else 'none'
                print(f"    deps: {deps}")

                # Capability info
                provides = ', '.join(layer_info.get('provides', [])) or 'none'
                reqprov = ', '.join(layer_info.get('provider_requires', [])) or 'none'
                print(f"    provides: {provides}")
                print(f"    requires-provider: {reqprov}")

    def show_search_paths(self):
        print("Layer search paths:")
        for i, root in enumerate(self.search_roots, 1):
            path = root.path
            exists = "✓" if path.exists() else "✗"
            print(f"  {i}. {exists} {root.tag}={path}")

    def resolve_layer_name(self, layer_identifier: str) -> Optional[str]:
        # Direct layer name lookup
        if layer_identifier in self.layers:
            return layer_identifier

        # Known load error for this identifier
        if layer_identifier in self.load_errors:
            raise ValueError(self.load_errors[layer_identifier])

        # File path lookup for already loaded layers
        for layer_name, file_path in self.layer_files.items():
            if Path(file_path).resolve() == Path(layer_identifier).resolve():
                return layer_name

        # Load error recorded by path
        rel_id = Path(layer_identifier).name
        if rel_id in self.load_errors:
            raise ValueError(self.load_errors[rel_id])

        return None

    def get_layer_documentation_data(self, layer_name: str):
        """Extract structured layer data for documentation generation"""
        if layer_name not in self.layers:
            return None

        layer = self.layers[layer_name]

        # Get detailed variable information from validators
        variables = {}

        # Read raw (unexpanded) metadata values from file
        raw_field_values = self._get_raw_metadata_fields(layer_name)

        anchors = []
        if hasattr(layer, '_container') and layer._container.variables:
            for var_name, var_obj in layer._container.variables.items():
                # Extract the original variable name from the IGconf_prefix_varname format
                # var_name is like "IGconf_test_directory", we need "DIRECTORY" for "X-Env-Var-DIRECTORY"
                parts = var_name.split('_')
                if len(parts) >= 3 and parts[0] == 'IGconf':
                    # Remove IGconf and prefix, keep original case to match the file
                    base_var_name = '_'.join(parts[2:])
                    var_key = f"X-Env-Var-{base_var_name}"
                    # Get original (unexpanded) value from raw metadata
                    original_value = raw_field_values.get(var_key, var_obj.value)
                else:
                    # Fallback for variables that don't follow the expected pattern
                    original_value = var_obj.value

                variables[var_name] = {
                    'name': var_obj.name,
                    'value': var_obj.value,  # Expanded/processed value
                    'original_value': original_value,  # Original value with placeholders
                    'description': var_obj.description,
                    'validation_rule': var_obj.validation_rule,
                    'required': var_obj.required,
                    'set_policy': var_obj.set_policy,
                    'validation_description': var_obj.get_validation_description()
                }
                if getattr(var_obj, "anchor_name", None):
                    anchors.append({
                        'name': var_obj.anchor_name,
                        'variable': var_obj.name,
                        'description': var_obj.description,
                    })

        # Get mmdebstrap configuration
        mmdebstrap_config = self._get_mmdebstrap_config(layer_name) or {}

        # Get env configuration
        env_config = self._get_env_config(layer_name) or {}

        # Make file path relative to search paths
        file_path = self.layer_files.get(layer_name)
        relative_path = file_path
        if file_path:
            for search_path in self.search_paths:
                try:
                    from pathlib import Path
                    abs_search = Path(search_path).resolve()
                    abs_file = Path(file_path).resolve()
                    if abs_file.is_relative_to(abs_search):
                        relative_path = str(abs_file.relative_to(abs_search))
                        break
                except (ValueError, AttributeError):
                    continue

        # Parse metadata for documentation using processed metadata
        raw_metadata = layer.get_metadata()
        required_variables = []
        if 'X-Env-VarRequires' in raw_metadata:
            var_requires = raw_metadata['X-Env-VarRequires'].split(',')
            required_variables = [var.strip() for var in var_requires if var.strip()]

        variable_prefix = raw_metadata.get('X-Env-VarPrefix', '')

        # Check for companion doc
        companion_doc = self._get_companion_doc(layer_name, format='asciidoc')

        # Process dependencies to categorise them as static or dynamic
        dependencies = self._categorise_dependencies(layer_name)

        # Reverse dependencies don't need categorisation - we can't determine them
        # if they use env vars, so we only report static rdeps.
        reverse_dependencies = self.get_reverse_dependencies(layer_name)

        return {
            'layer_info': layer.get_layer_info(),
            'variables': variables,
            'required_variables': required_variables,
            'variable_prefix': variable_prefix,
            'mmdebstrap': mmdebstrap_config,
            'env': env_config,
            'file_path': relative_path,
            'companion_doc': companion_doc,
            'dependencies': dependencies,
            'reverse_dependencies': reverse_dependencies,
            'anchors': anchors
        }

    def _get_companion_doc(self, layer_name: str, format: str = 'markdown') -> str:
        if layer_name not in self.layer_files:
            return ""

        yaml_file_path = self.layer_files[layer_name]

        # Convert .yaml/.yml extension to appropriate format extension
        from pathlib import Path
        yaml_path = Path(yaml_file_path)

        # Map format to file extension
        format_extensions = {
            'markdown': '.md',
            'rst': '.rst',
            'asciidoc': '.adoc'
        }

        extension = format_extensions.get(format, '.md')
        companion_path = yaml_path.with_suffix(extension)

        try:
            if companion_path.exists():
                with open(companion_path, 'r', encoding='utf-8') as f:
                    return f.read()

        except Exception as e:
            log_warning(f"[WARN] Could not read companion documentation file {companion_path}: {e}")

        return ""

    def _get_raw_metadata_fields(self, layer_name: str) -> dict:
        """Get all raw (unexpanded) metadata field values from the layer file."""
        if layer_name not in self.layer_files:
            return {}

        file_path = self.layer_files[layer_name]
        raw_fields = {}

        try:
            with open(file_path, 'r') as f:
                content = f.read()

            # Parse the commented metadata section
            in_meta_section = False

            for line in content.splitlines():
                line_stripped = line.strip()

                if line_stripped == '# METABEGIN':
                    in_meta_section = True
                    continue
                elif line_stripped == '# METAEND':
                    in_meta_section = False
                    break

                if in_meta_section and ':' in line_stripped and line_stripped.startswith('# '):
                    # Parse field: value pairs
                    line_content = line_stripped[2:]  # Remove '# '
                    if ':' in line_content:
                        field_name, field_value = line_content.split(':', 1)
                        raw_fields[field_name.strip()] = field_value.strip()

            return raw_fields
        except Exception:
            return {}

    def _categorise_dependencies(self, layer_name: str) -> dict:
        """Categorise dependencies as static or dynamic based on environment variable usage."""
        layer_info = self.get_layer_info(layer_name)
        if not layer_info:
            return {'static_dep': [], 'dyn_dep': []}

        static_deps = []
        dyn_deps = []

        for dep in layer_info.get('depends', []):
            if '${' in dep and '}' in dep:
                # Contains env variable substitution (dynamic)
                dyn_deps.append(dep)
            else:
                # static
                static_deps.append(dep)

        return {
            'static_dep': static_deps,
            'dyn_dep': dyn_deps
        }



def _generate_layer_boilerplate():
    """Generate boilerplate example layer with metadata"""
    boilerplate = """# METABEGIN
# X-Env-Layer-Name: my-example-layer
# X-Env-Layer-Desc: Example layer with options
# X-Env-Layer-Version: 1.0.0
# X-Env-Layer-Provides: debian-base
# X-Env-Layer-RequiresProvider:
# X-Env-Layer-Requires: base-layer,common-tools

# X-Env-VarRequires: SITE
# X-Env-VarRequires-Valid: regex:^/.*,string,string

# X-Env-VarPrefix: example

# X-Env-Var-service_port: 8080
# X-Env-Var-service_port-Desc: Port number for the service
# X-Env-Var-service_port-Required: false
# X-Env-Var-service_port-Valid: int:1024-65535
# X-Env-Var-service_port-Set: true
# METAEND
---
mmdebstrap:
  mirrors:
    - deb http://archive.example.com/debian suite main
  packages:
    - ca-certificates
  setup-hooks:
    - echo hello
  essential-hooks:
    - echo world
  customize-hooks:
    - echo ${SITE}:${IGconf_example_service_port} > ${1}/port.spec
  cleanup-hooks:
    - rm ${1}/port.spec

# Using:
# 1. Copy this template to your desired location.
# 2. Customise the X-Env-* fields for your layer
# 3. Customise the YAML for your use case
# 4. For validation, run: ig metadata --help-validation
#
# Notes:
# Depending on script needs, YAML scalar/block constructs may be required."""

    print(boilerplate)


# CLI integration
def LayerManager_register_parser(subparsers, root=None):
    if root:
        default_paths = f'layer={root}/layer:device={root}/device:image={root}/image'
        help_text = 'Colon-separated search paths for layers (use tag=/path to name each root)'
    else:
        default_paths = 'layer=./layer:device=./device:image=./image'
        help_text = 'Colon-separated search paths for layers (use tag=/path to name each root)'

    # Use terminal width for help formatting
    terminal_width = shutil.get_terminal_size().columns
    formatter_class = lambda prog: argparse.HelpFormatter(prog, width=terminal_width)

    parser = subparsers.add_parser("layer", help="Layer utilities", add_help=False,
                                   formatter_class=formatter_class)

    class HelpAction(argparse.Action):
        def __init__(self, option_strings, dest=argparse.SUPPRESS, default=argparse.SUPPRESS, help=None):
            super().__init__(option_strings=option_strings, dest=dest, default=default, nargs=0, help=help)

        def __call__(self, parser, namespace, values, option_string=None):
            # Get the current search paths from the --path argument
            current_paths = getattr(namespace, 'path', None) or default_paths
            search_paths = [p.strip() for p in current_paths.split(':') if p.strip()]

            parser.print_help()
            # Then print search path without wrapping
            print(f"\nSearch path: {':'.join(search_paths)}")
            parser.exit()

    parser.add_argument('-h', '--help', action=HelpAction,
                       help='show this help message and exit')

    parser.add_argument('--path', '-p', default=default_paths, help=help_text)
    parser.add_argument('--patterns', nargs='+', default=['*.yaml', '*.yml'],
                       help='File patterns to search (default: *.yaml *.yml)')
    parser.add_argument('--list', '-l', action='store_true',
                       help='List all available layers')
    parser.add_argument('--describe', metavar='LAYER',
                       help='Show detailed information for a layer (use layer name)')
    parser.add_argument('--rdep', '--reverse-deps', metavar='LAYER',
                       help='Show layers that depend on the specified layer')
    parser.add_argument('--show-paths', action='store_true',
                       help='Show search paths')
    parser.add_argument('--gen', action='store_true',
                       help='Generate boilerplate layer template with  metadata')
    parser.set_defaults(func=_layer_main)


def _layer_main(args):
    """Main function for layer management CLI"""

    if args.gen:
        _generate_layer_boilerplate()
        return

    # Check if any action argument was provided
    action_args = ['list', 'describe', 'rdep', 'show_paths']
    if not any(getattr(args, arg, None) for arg in action_args):
        print("Error: No action specified. Use -h or --help for available options.")
        exit(1)

    # Create default manager (non-doc-mode) for general operations
    search_paths = [p.strip() for p in args.path.split(':') if p.strip()]

    # For all layer CLI actions, use a single doc-mode manager to avoid running dynamic generators.
    try:
        manager = LayerManager(search_paths, args.patterns, doc_mode=True, show_loaded=args.list)
    except ValueError as exc:
        print(f'Error: {exc}')
        exit(1)
    print()

    if args.show_paths:
        manager.show_search_paths()
        print()

    if args.list:
        # Always show the search paths when listing layers
        manager.show_search_paths()
        print()
        manager.list_layers()

    if args.rdep:
        layer_name = manager.resolve_layer_name(args.rdep)
        if not layer_name:
            print(f"✗ Layer '{args.rdep}' not found")
            exit(1)

        reverse_deps = manager.get_reverse_dependencies(layer_name)

        if reverse_deps:
            print(f"Reverse dependencies for '{layer_name}':")
            print()
            for dep_layer in reverse_deps:
                dep_info = manager.get_layer_info(dep_layer)
                if dep_info:
                    print(f"Layer: {dep_info['name']}")
                    print(f"Category: {dep_info.get('category', 'unknown')}")
                    print(f"Description: {dep_info.get('description', 'No description')}")
                    print()

            print(f"{len(reverse_deps)} layer(s) depend on '{layer_name}'")

    if args.describe:
        layer_name = manager.resolve_layer_name(args.describe)
        if not layer_name:
            print(f"✗ Layer '{args.describe}' not found")
            exit(1)

        layer_info = manager.get_layer_info(layer_name)
        if layer_info:
            print(f"Layer: {layer_info['name']}")
            print(f"Version: {layer_info['version']}")
            print(f"Category: {layer_info['category']}")
            print(f"Description: {layer_info['description']}")
            print(f"Type: {layer_info['type']}")
            if layer_info.get('type') == 'dynamic' and layer_info.get('generator'):
                print(f"Generator: {layer_info['generator']}")

            if layer_info.get('provides'):
                provides_list = ', '.join(layer_info['provides'])
                print(f"Provides: {provides_list}")

            if layer_info.get('provider_requires'):
                requires_list = ', '.join(layer_info['provider_requires'])
                print(f"Requires Provider: {requires_list}")

            layer_path = manager.layer_files.get(layer_name, "<unknown>")
            rel_layer_path = manager.layer_relpaths.get(layer_name, layer_path)
            print(f"Path: {rel_layer_path}")

            if layer_info['depends']:
                print("Depends:")

                def _show_deps(dep_layer: str, seen: set[str], indent: int = 1):
                    pad = "  " * indent
                    for dep in manager.get_dependencies(dep_layer):
                        # guard against cycles / duplicates
                        if dep in seen:
                            print(f"{pad}- {dep} (already shown)")
                            continue
                        seen.add(dep)

                        dep_path = manager.layer_files.get(dep, "<unknown>")
                        rel_path = manager.layer_relpaths.get(dep, dep_path)
                        print(f"{pad}- {dep}: {rel_path}")

                        # recurse into dependencies of this dependency
                        _show_deps(dep, seen, indent + 1)

                _show_deps(layer_name, set())
            if layer_info['optional_depends']:
                print(f"Optional-Depends: {', '.join(layer_info['optional_depends'])}")
            if layer_info['conflicts']:
                print(f"Conflicts: {', '.join(layer_info['conflicts'])}")

            # Show mmdebstrap configuration if any
            # TODO can extend for other maps
            mmdebstrap_config = manager._get_mmdebstrap_config(layer_name)
            if mmdebstrap_config:
                print()

                architectures = mmdebstrap_config.get('architectures')
                if architectures and isinstance(architectures, list):
                    arch_list = ', '.join(architectures)
                    print(f"Architectures: {arch_list}")

                packages = mmdebstrap_config.get('packages')
                if packages and isinstance(packages, list):
                    print("Packages:")
                    for package in packages:
                        print(f"  - {package}")

            # Print environment variables for this layer
            meta_obj = manager.layers.get(layer_name)
            if meta_obj and meta_obj.get_all_env_vars():
                print()
                print_env_var_descriptions(meta_obj, indent=2)

    # build-order CLI removed; layer commands are read-only.
