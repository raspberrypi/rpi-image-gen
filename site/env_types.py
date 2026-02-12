import re
from dataclasses import dataclass
from typing import List, Optional, Dict, Any, Tuple
from validators import BaseValidator, parse_validator


# X-Env field helpers
class XEnv:
    """Helper for constructing X-Env field names consistently."""

    VAR_PREFIX = "X-Env-Var-"
    LAYER_PREFIX = "X-Env-Layer-"

    # === VARIABLE FIELD METHODS ===

    @classmethod
    def var_base(cls, name: str) -> str:
        """Build base variable field name: X-Env-Var-{name}"""
        return f"{cls.VAR_PREFIX}{name.upper()}"

    @classmethod
    def var_desc(cls, name: str) -> str:
        """Build description field name: X-Env-Var-{name}-Desc"""
        return f"{cls.VAR_PREFIX}{name.upper()}-Desc"

    @classmethod
    def var_required(cls, name: str) -> str:
        """Build required field name: X-Env-Var-{name}-Required"""
        return f"{cls.VAR_PREFIX}{name.upper()}-Required"

    @classmethod
    def var_valid(cls, name: str) -> str:
        """Build validation field name: X-Env-Var-{name}-Valid"""
        return f"{cls.VAR_PREFIX}{name.upper()}-Valid"

    @classmethod
    def var_set(cls, name: str) -> str:
        """Build set policy field name: X-Env-Var-{name}-Set"""
        return f"{cls.VAR_PREFIX}{name.upper()}-Set"

    @classmethod
    def var_anchor(cls, name: str) -> str:
        """Build anchor field name: X-Env-Var-{name}-Anchor"""
        return f"{cls.VAR_PREFIX}{name.upper()}-Anchor"

    @classmethod
    def var_conflicts(cls, name: str) -> str:
        """Build conflicts field name: X-Env-Var-{name}-Conflicts"""
        return f"{cls.VAR_PREFIX}{name.upper()}-Conflicts"

    # === PATTERN METHODS FOR SUPPORTED_FIELD_PATTERNS ===

    @classmethod
    def var_desc_pattern(cls) -> str:
        """Build description pattern: X-Env-Var-*-Desc"""
        return f"{cls.VAR_PREFIX}*-Desc"

    @classmethod
    def var_required_pattern(cls) -> str:
        """Build required pattern: X-Env-Var-*-Required"""
        return f"{cls.VAR_PREFIX}*-Required"

    @classmethod
    def var_valid_pattern(cls) -> str:
        """Build validation pattern: X-Env-Var-*-Valid"""
        return f"{cls.VAR_PREFIX}*-Valid"

    @classmethod
    def var_set_pattern(cls) -> str:
        """Build set policy pattern: X-Env-Var-*-Set"""
        return f"{cls.VAR_PREFIX}*-Set"

    @classmethod
    def var_anchor_pattern(cls) -> str:
        """Build anchor field pattern: X-Env-Var-*-Anchor"""
        return f"{cls.VAR_PREFIX}*-Anchor"

    @classmethod
    def var_conflicts_pattern(cls) -> str:
        """Build conflicts field pattern: X-Env-Var-*-Conflicts"""
        return f"{cls.VAR_PREFIX}*-Conflicts"

    @classmethod
    def var_prefix(cls) -> str:
        """Build variable prefix field: X-Env-VarPrefix"""
        return "X-Env-VarPrefix"

    @classmethod
    def var_requires(cls) -> str:
        """Build variable requirements field: X-Env-VarRequires"""
        return "X-Env-VarRequires"

    @classmethod
    def var_optional(cls) -> str:
        """Build variable optional field: X-Env-VarOptional"""
        return "X-Env-VarOptional"

    @classmethod
    def var_requires_valid(cls) -> str:
        """Build variable requirements validation field: X-Env-VarRequires-Valid"""
        return "X-Env-VarRequires-Valid"

    @classmethod
    def var_optional_valid(cls) -> str:
        """Build variable optional validation field: X-Env-VarOptional-Valid"""
        return "X-Env-VarOptional-Valid"

    @classmethod
    def is_var_field(cls, field_name: str) -> bool:
        """Check if field name is an X-Env-Var field."""
        return field_name.startswith(cls.VAR_PREFIX)

    @classmethod
    def is_base_var_field(cls, field_name: str) -> bool:
        """Check if field name is a base variable definition (no attribute suffix)."""
        if not cls.is_var_field(field_name):
            return False
        var_part = field_name[len(cls.VAR_PREFIX):]
        return '-' not in var_part

    @classmethod
    def extract_var_name(cls, field_name: str) -> Optional[str]:
        """Extract variable name from field name. Returns None if not a var field."""
        if not cls.is_var_field(field_name):
            return None
        return field_name[len(cls.VAR_PREFIX):]

    @classmethod
    def extract_base_var_name(cls, field_name: str) -> Optional[str]:
        """Extract base variable name from any X-Env-Var field (base or attribute)."""
        if not cls.is_var_field(field_name):
            return None
        var_part = field_name[len(cls.VAR_PREFIX):]

        # If it's a base field, return as-is
        if '-' not in var_part:
            return var_part

        # If it's an attribute field, extract the base part
        return var_part.split('-')[0]

    @classmethod
    def parse_var_field(cls, field_name: str) -> Optional[Tuple[str, Optional[str]]]:
        """
        Parse a var field into (base_name, attribute_suffix).

        Returns:
            - For base fields: (var_name, None)
            - For attribute fields: (var_name, suffix)
            - For non-var fields: None
        """
        if not cls.is_var_field(field_name):
            return None

        var_part = field_name[len(cls.VAR_PREFIX):]

        if '-' not in var_part:
            # Base variable field
            return (var_part, None)

        # Attribute field - split on first dash
        parts = var_part.split('-', 1)
        if len(parts) == 2:
            return (parts[0], f"-{parts[1]}")

        return (var_part, None)

    # === LAYER FIELD METHODS ===

    @classmethod
    def layer_name(cls) -> str:
        """Build layer name field: X-Env-Layer-Name"""
        return f"{cls.LAYER_PREFIX}Name"

    @classmethod
    def layer_description(cls) -> str:
        """Build layer description field: X-Env-Layer-Desc"""
        return f"{cls.LAYER_PREFIX}Desc"

    @classmethod
    def layer_version(cls) -> str:
        """Build layer version field: X-Env-Layer-Version"""
        return f"{cls.LAYER_PREFIX}Version"

    @classmethod
    def layer_category(cls) -> str:
        """Build layer category field: X-Env-Layer-Category"""
        return f"{cls.LAYER_PREFIX}Category"

    @classmethod
    def layer_requires(cls) -> str:
        """Build layer requires field: X-Env-Layer-Requires"""
        return f"{cls.LAYER_PREFIX}Requires"

    @classmethod
    def layer_provides(cls) -> str:
        """Build layer provides field: X-Env-Layer-Provides"""
        return f"{cls.LAYER_PREFIX}Provides"

    @classmethod
    def layer_type(cls) -> str:
        """Build layer type field: X-Env-Layer-Type"""
        return f"{cls.LAYER_PREFIX}Type"

    @classmethod
    def layer_generator(cls) -> str:
        """Build layer generator field: X-Env-Layer-Generator"""
        return f"{cls.LAYER_PREFIX}Generator"

    @classmethod
    def layer_requires_provider(cls) -> str:
        """Build layer requires provider field: X-Env-Layer-RequiresProvider"""
        return f"{cls.LAYER_PREFIX}RequiresProvider"

    @classmethod
    def layer_conflicts(cls) -> str:
        """Build layer conflicts field: X-Env-Layer-Conflicts"""
        return f"{cls.LAYER_PREFIX}Conflicts"

    @classmethod
    def is_layer_field(cls, field_name: str) -> bool:
        """Check if field name is an X-Env-Layer field."""
        return field_name.startswith(cls.LAYER_PREFIX)


TRIGGER_DEFAULT_POLICY = "immediate"
ACTION_PARSERS: Dict[str, Any] = {}


def _parse_set_action(args: List[str], var_name: str, line: str) -> Tuple[str, str, str]:
    """
    Parse a 'set' action: TARGET=VALUE [policy=...]
    Returns (target, value, policy)
    """
    if not args:
        raise ValueError(f"Trigger action '{line}' for {var_name} is missing a target")

    target_token = args[0]
    if "=" not in target_token:
        raise ValueError(f"Trigger action '{line}' for {var_name} must start with TARGET=VALUE")

    target, value = target_token.split("=", 1)
    target = target.strip()
    value = value.strip()
    if not target:
        raise ValueError(f"Trigger action for {var_name} is missing target variable name")
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", target):
        raise ValueError(f"Trigger action for {var_name} has invalid target '{target}' (must be POSIX var name)")

    policy = TRIGGER_DEFAULT_POLICY
    for token in args[1:]:
        if token.startswith("policy="):
            policy = EnvVariable._parse_set_policy(token.split("=", 1)[1])
    return target, value, policy


# Register built-in actions
ACTION_PARSERS["set"] = _parse_set_action


@dataclass(frozen=True)
class TriggerRule:
    """Represents a conditional trigger to perform an action."""
    condition: Optional[str]  # None means unconditional
    action: str
    target: str
    value: str
    policy: str = TRIGGER_DEFAULT_POLICY


class EnvVariable:
    """Represents an environment variable with its metadata and validation rules."""

    def __init__(self, name: str, value: str = "", description: str = "",
                 required: bool = False, validator: Optional[BaseValidator] = None,
                 validation_rule: str = "", set_policy: str = "immediate",
                 source_layer: str = "", position: int = 0,
                 anchor_name: Optional[str] = None,
                 triggers: Optional[List[TriggerRule]] = None,
                 conflicts: Optional[List[str]] = None):
        self.name = name
        self.value = value
        self.description = description
        self.required = required
        self.validator = validator
        self.validation_rule = validation_rule  # Original validation rule string
        self.set_policy = set_policy  # immediate, lazy, force, skip
        self.source_layer = source_layer  # Layer that defined this variable
        self.position = position  # Order within dependency processing
        self.anchor_name = anchor_name
        self.triggers: List[TriggerRule] = triggers or []
        self.conflicts: List[str] = conflicts or []

    @classmethod
    def from_metadata_fields(cls, var_name: str, metadata_dict: Dict[str, str],
                           prefix: str = "", source_layer: str = "", position: int = 0) -> 'EnvVariable':
        """Create an EnvVariable from metadata fields."""

        def _get_metadata_value(key: str, default: str = "") -> str:
            if key in metadata_dict:
                return metadata_dict[key]
            key_lower = key.lower()
            for actual_key, actual_value in metadata_dict.items():
                if actual_key.lower() == key_lower:
                    return actual_value
            return default
        # Extract the base variable name (without X-Env-Var- prefix)
        base_name = var_name.upper()

        # Get the basic variable definition
        var_key = XEnv.var_base(base_name)
        value = _get_metadata_value(var_key, "")

        # Get additional attributes
        desc_key = XEnv.var_desc(base_name)
        description = _get_metadata_value(desc_key, "")

        required_key = XEnv.var_required(base_name)
        required_str = _get_metadata_value(required_key, "false")
        required = required_str.lower() in ("true", "1", "yes", "y")

        valid_key = XEnv.var_valid(base_name)
        valid_rule = _get_metadata_value(valid_key, "")
        validator = None
        if valid_rule:
            try:
                validator = parse_validator(valid_rule)
            except ValueError as e:
                raise ValueError(f"Invalid validation rule '{valid_rule}' for variable {var_name}: {e}")

        set_key = XEnv.var_set(base_name)
        set_raw = _get_metadata_value(set_key, "immediate")
        set_policy = cls._parse_set_policy(set_raw)

        anchor_key = XEnv.var_anchor(base_name)
        anchor_name = _get_metadata_value(anchor_key, "").strip()
        if anchor_name and not anchor_name.startswith("@"):
            raise ValueError(
                f"Invalid anchor '{anchor_name}' for variable {var_name}: anchors must start with '@'"
            )
        anchor_name = anchor_name or None

        triggers_key = f"{XEnv.var_base(base_name)}-Triggers"
        triggers_raw = _get_metadata_value(triggers_key, "")
        triggers: List[TriggerRule] = []
        if triggers_raw and isinstance(triggers_raw, str):
            triggers = cls._parse_trigger_rules(triggers_raw, var_name)

        # Calculate full variable name
        full_name = f"IGconf_{prefix}_{var_name.lower()}" if prefix else var_name

        conflicts_key = XEnv.var_conflicts(base_name)
        conflicts_raw = _get_metadata_value(conflicts_key, "")
        conflicts: List[str] = []
        if conflicts_raw and isinstance(conflicts_raw, str):
            # Parse conflict expressions - only support "=" or "!=" as conditional operators
            conflicts_raw_list: List[str] = []
            for line in str(conflicts_raw).splitlines():
                conflicts_raw_list.extend([c.strip() for c in line.split(",") if c.strip()])
            for c in conflicts_raw_list:
                precursor_value = None
                if c.startswith("when="):
                    parts = c.split(None, 1)
                    if len(parts) < 2:
                        raise ValueError(f"Invalid conflict expr '{c}' (missing condition after precursor)")
                    precursor_value = parts[0][len("when="):].strip()
                    if not precursor_value:
                        raise ValueError(f"Invalid conflict expr '{c}' (missing precursor value)")
                    c = parts[1].strip()
                    if not c:
                        raise ValueError(f"Invalid conflict expr '{c}' (invalid condition after precursor)")

                operator = None
                name_part = ""
                value_part = ""
                if "!=" in c:
                    operator = "!="
                    name_part, value_part = c.split("!=", 1)
                elif "=" in c:
                    operator = "="
                    name_part, value_part = c.split("=", 1)
                # Add other operators as needed

                if operator:
                    # Conditional conflict: "var=value" or "var!=value"
                    name_part = name_part.strip()
                    value_part = value_part.strip()
                    if "=" in value_part or "!" in value_part:
                        raise ValueError(f"Invalid conflict expr '{c}' (unsupported operator)")
                    if not name_part or not value_part:
                        raise ValueError(f"Invalid conflict expr '{c}' (missing name or value)")
                    if name_part.startswith("IGconf_"):
                        conflict_name = name_part
                    else:
                        conflict_name = f"IGconf_{prefix}_{name_part.lower()}" if prefix else name_part
                    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", conflict_name):
                        raise ValueError(f"Invalid conflict expr '{c}' (invalid variable name)")
                    conflict_spec = f"{conflict_name}{operator}{value_part}"
                else:
                    # Unconditional conflict: just a variable name
                    if "!" in c or "=" in c:
                        raise ValueError(f"Invalid conflict expr '{c}' (unsupported operator)")
                    if c.startswith("IGconf_"):
                        conflict_spec = c
                    else:
                        conflict_name = f"IGconf_{prefix}_{c.lower()}" if prefix else c
                        if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", conflict_name):
                            raise ValueError(f"Invalid conflict expr '{c}' (invalid variable name)")
                        conflict_spec = conflict_name

                if precursor_value is not None:
                    conflicts.append(f"when={precursor_value} {conflict_spec}")
                else:
                    conflicts.append(conflict_spec)

        return cls(
            name=full_name,
            value=value,
            description=description,
            required=required,
            validator=validator,
            validation_rule=valid_rule,
            set_policy=set_policy,
            source_layer=source_layer,
            position=position,
            anchor_name=anchor_name,
            triggers=triggers,
            conflicts=conflicts,
        )

    @staticmethod
    def _parse_set_policy(value: Optional[str]) -> str:
        """Parse Set policy value into canonical form."""
        if value is None:
            return "immediate"
        val = str(value).strip().lower()

        if val in ["false", "0", "no", "n"]:
            return "skip"
        elif val == "lazy":
            return "lazy"
        elif val == "force":
            return "force"
        else:  # true, 1, yes, y, immediate, or anything else
            return "immediate"

    @staticmethod
    def _parse_trigger_rules(raw: str, var_name: str) -> List[TriggerRule]:
        """
        Parse trigger rules.
        Syntax (one rule per line):
          - "when=VALUE set TARGET=VAL [policy=...]"  # conditional
          - "set TARGET=VAL [policy=...]"             # unconditional
        """
        rules: List[TriggerRule] = []
        lines = [line.strip() for line in str(raw).splitlines() if line.strip()]

        for line in lines:
            tokens = line.split()
            if not tokens:
                continue

            condition: Optional[str] = None
            if tokens[0].startswith("when="):
                condition = tokens[0][len("when="):].strip()
                if not condition:
                    raise ValueError(f"Trigger rule '{line}' for {var_name} is missing value in when=")
                if len(tokens) < 2:
                    raise ValueError(f"Trigger rule '{line}' for {var_name} is missing an action keyword")
                action = tokens[1]
                action_args = tokens[2:]
            else:
                action = tokens[0]
                action_args = tokens[1:]

            parser = ACTION_PARSERS.get(action)
            if not parser:
                raise ValueError(f"Invalid trigger action '{action}' for {var_name}")

            if not action_args:
                raise ValueError(f"Trigger rule '{line}' for {var_name} is missing args for '{action}'")

            target, value, policy = parser(action_args, var_name, line)
            rules.append(TriggerRule(condition=condition, action=action, target=target, value=value, policy=policy))
        return rules

    def validate_value(self, value: Optional[str] = None) -> List[str]:
        """Validate a value against this variable's validation rule."""
        if self.validator is None:
            return []  # No validation rule, so it's valid

        test_value = value if value is not None else self.value
        return self.validator.validate(test_value)

    def get_validation_description(self) -> str:
        """Get a human-readable description of the validation rule."""
        if self.validator is None:
            return "No validation rule"
        return self.validator.describe()

    def should_set_in_environment(self) -> bool:
        """Check if this variable should be set in the environment."""
        return self.set_policy != "skip"

    def __repr__(self) -> str:
        return (
            f"EnvVariable(name='{self.name}', value='{self.value}', policy='{self.set_policy}', "
            f"layer='{self.source_layer}', pos={self.position}, anchor={self.anchor_name}, "
            f"triggers={len(self.triggers)}, conflicts={len(self.conflicts)})"
        )


class EnvLayer:
    """Represents a layer with its dependencies and metadata."""

    def __init__(self, name: str, description: str = "", version: str = "1.0.0",
                 category: str = "general", deps: List[str] = None,
                 provides: List[str] = None, requires_provider: List[str] = None,
                 conflicts: List[str] = None, layer_type: str = "static",
                 generator: str = "", config_file: str = ""):
        self.name = name
        self.description = description
        self.version = version
        self.category = category
        self.deps = deps or []
        self.provides = provides or []
        self.requires_provider = requires_provider or []
        self.conflicts = conflicts or []
        self.layer_type = layer_type
        self.generator = generator
        self.config_file = config_file

    @classmethod
    def from_metadata_fields(cls, metadata_dict: Dict[str, str],
                           filepath: str = "", doc_mode: bool = False) -> Optional['EnvLayer']:
        """Create an EnvLayer from metadata fields."""
        # Check if this has layer information
        layer_name = metadata_dict.get(XEnv.layer_name(), "")
        if not layer_name:
            return None

        # Validate all X-Env-Layer fields against supported schema
        cls._validate_layer_fields(metadata_dict, filepath)

        description = metadata_dict.get(XEnv.layer_description(), "")
        version = metadata_dict.get(XEnv.layer_version(), "1.0.0")
        category = metadata_dict.get(XEnv.layer_category(), "general")
        layer_type = metadata_dict.get(XEnv.layer_type(), "static").strip().lower() or "static"
        generator = metadata_dict.get(XEnv.layer_generator(), "").strip()
        if layer_type not in ("static", "dynamic"):
            raise ValueError(f"Invalid layer type '{layer_type}' in {filepath}")
        if layer_type == "dynamic" and not generator:
            raise ValueError(f"Layer '{layer_name}' marked dynamic but no X-Env-Layer-Generator specified")

        # Parse dependency lists
        requires_str = metadata_dict.get(XEnv.layer_requires(), "")
        requires = cls._parse_dependency_list(requires_str, doc_mode)

        provides_str = metadata_dict.get(XEnv.layer_provides(), "")
        provides = cls._parse_dependency_list(provides_str, doc_mode)

        requires_provider_str = metadata_dict.get(XEnv.layer_requires_provider(), "")
        requires_provider = cls._parse_dependency_list(requires_provider_str, doc_mode)

        conflicts_str = metadata_dict.get(XEnv.layer_conflicts(), "")
        conflicts = cls._parse_dependency_list(conflicts_str, doc_mode)

        # Infer config file from filepath if not provided
        import os
        config_file = os.path.basename(filepath) if filepath else f"{layer_name}.yaml"

        return cls(
            name=layer_name,
            description=description,
            version=version,
            category=category,
            deps=requires,
            provides=provides,
            requires_provider=requires_provider,
            conflicts=conflicts,
            layer_type=layer_type,
            generator=generator,
            config_file=config_file
        )

    @staticmethod
    def _parse_dependency_list(depends_str: str, doc_mode: bool = False) -> List[str]:
        """Parse dependency string into list of layer names/IDs with environment variable evaluation."""
        if not depends_str.strip():
            return []

        import re
        deps = []
        for dep in depends_str.split(','):
            dep_name = dep.strip()
            if dep_name:
                # Find and evaluate environment variables in dependency names
                if '${' in dep_name:
                    dep_name = EnvLayer._evaluate_env_variables(dep_name, doc_mode)

                # Validate dependency name format
                if re.search(r"\s", dep_name):
                    raise ValueError(
                        f"Invalid dependency token '{dep_name}' - dependencies must be comma-separated without spaces/newlines inside a token")
                # In doc_mode, allow environment variable placeholders like ${VAR}-suffix
                if doc_mode and not re.match(r'^[A-Za-z0-9_${}-]+$', dep_name):
                    raise ValueError(f"Invalid dependency name '{dep_name}' - only alphanum, dash, underscore, and environment variable placeholders allowed")
                elif not doc_mode and not re.match(r'^[A-Za-z0-9_-]+$', dep_name):
                    raise ValueError(f"Invalid dependency name '{dep_name}' - only alphanum, dash, underscore allowed")
                deps.append(dep_name)
        return deps

    @staticmethod
    def _evaluate_env_variables(text: str, doc_mode: bool = False) -> str:
        """Expand ${VAR} placeholders using environment variables.
        Raises on missing variables unless doc_mode=True (in which case placeholders are kept).
        - Iteratively expands (with cap) to support nested placeholders.
        """
        import os
        # Vatiables much conform to this regex
        pattern = re.compile(r'\$\{([A-Za-z_][A-Za-z0-9_]*)\}')

        previous = text
        max_iterations = 10

        for _ in range(max_iterations):
            current = pattern.sub(lambda m: os.environ.get(m.group(1), m.group(0)), previous)
            if current == previous:
                break
            previous = current

        # If any ${...} remain:
        if pattern.search(previous):
            if doc_mode:
                return previous
            remaining = sorted({m.group(1) for m in pattern.finditer(previous)})
            raise ValueError(f"Unresolved environment variables: {', '.join(remaining)}")

        return previous

    @classmethod
    def _validate_layer_fields(cls, metadata_dict: Dict[str, str], filepath: str = "") -> None:
        """Validate that all X-Env-Layer fields are supported according to the schema"""
        # Import here to avoid circular imports
        try:
            from metadata_parser import SUPPORTED_FIELD_PATTERNS
        except ImportError:
            # If we can't import the schema, skip validation
            return

        # Get all X-Env-Layer fields from metadata
        layer_fields = {key: value for key, value in metadata_dict.items()
                       if key.startswith(XEnv.LAYER_PREFIX)}

        # Check each field against supported patterns
        for field_name in layer_fields.keys():
            if field_name not in SUPPORTED_FIELD_PATTERNS:
                # Check if it matches any pattern-based fields (shouldn't for layers, but be thorough)
                supported = False
                for pattern_key in SUPPORTED_FIELD_PATTERNS.keys():
                    if '*' in pattern_key and field_name.startswith(pattern_key.split('*')[0]):
                        supported = True
                        break

                if not supported:
                    filename = filepath.split('/')[-1] if filepath else "unknown"
                    raise ValueError(f"Unsupported layer field '{field_name}' in {filename}")

    def get_all_dependencies(self) -> List[str]:
        """Get all dependencies (only actual requires, not provider requirements)."""
        return self.deps

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary format for API compatibility."""
        return {
            "name": self.name,
            "description": self.description,
            "version": self.version,
            "category": self.category,
            "type": self.layer_type,
            "generator": self.generator,
            "depends": self.deps,
            "optional_depends": [],  # Not currently supported
            "conflicts": self.conflicts,
            "config_file": self.config_file,
            "provides": self.provides,
            "provider_requires": self.requires_provider,
        }

    def __repr__(self) -> str:
        return f"EnvLayer(name='{self.name}', deps={self.deps}, provides={self.provides})"


class MetadataContainer:
    """Container for parsed metadata with variables and layer information."""

    def __init__(self, filepath: str = ""):
        self.filepath = filepath
        self.variables: Dict[str, EnvVariable] = {}
        self.layer: Optional[EnvLayer] = None
        self.var_prefix: str = ""
        self.required_vars: List[str] = []
        self.optional_vars: List[str] = []
        self.raw_metadata: Dict[str, str] = {}

    @classmethod
    def from_metadata_dict(cls, metadata_dict: Dict[str, str],
                          filepath: str = "", doc_mode: bool = False) -> 'MetadataContainer':
        """Create a MetadataContainer from a metadata dictionary."""
        container = cls(filepath)
        container.raw_metadata = metadata_dict.copy()

        # Apply placeholder substitution to the metadata
        container.apply_placeholders()

        # Extract prefix
        container.var_prefix = container.raw_metadata.get(XEnv.var_prefix(), "").lower()

        # Extract layer information
        container.layer = EnvLayer.from_metadata_fields(container.raw_metadata, filepath, doc_mode)

        # Extract variables
        for key in container.raw_metadata.keys():
            if XEnv.is_base_var_field(key):
                # This is a base variable definition
                var_name = XEnv.extract_base_var_name(key)
                try:
                    # Note: source_layer and position will be set later by LayerManager
                    env_var = EnvVariable.from_metadata_fields(
                        var_name, container.raw_metadata, container.var_prefix,
                        source_layer="", position=0
                    )
                    container.variables[env_var.name] = env_var
                except ValueError as e:
                    # Re-raise to fail layer loading
                    raise ValueError(f"Invalid specifier for variable {var_name}: {e}")
                except Exception as e:
                    # Skip other types of errors - they'll be caught during validation
                    pass

        # Extract required/optional environment variable lists
        required_vars_str = container.raw_metadata.get(XEnv.var_requires(), "")
        if required_vars_str.strip():
            container.required_vars = [v.strip() for v in required_vars_str.split(',') if v.strip()]

        optional_vars_str = container.raw_metadata.get(XEnv.var_optional(), "")
        if optional_vars_str.strip():
            container.optional_vars = [v.strip() for v in optional_vars_str.split(',') if v.strip()]

        return container

    def get_settable_variables(self) -> Dict[str, EnvVariable]:
        """Get variables that should be set according to their Set directive."""
        return {name: var for name, var in self.variables.items()
                if var.should_set_in_environment()}

    def has_layer_info(self) -> bool:
        """Check if this container has layer information."""
        return self.layer is not None

    def _build_placeholders(self) -> Dict[str, str]:
        """Return dict with placeholder values for this file."""
        import os
        abs_path = os.path.abspath(self.filepath)
        return {
            "FILENAME": os.path.basename(abs_path),
            "DIRECTORY": os.path.dirname(abs_path),
            "FILEPATH": abs_path,
        }

    def _substitute_placeholders(self, text: str, placeholders: Dict[str, str]) -> str:
        """Replace ${NAME} in text with corresponding placeholder."""
        if "${" not in text:
            return text

        # Handle escaped \${...}
        ESCAPE_TOKEN = "<<LITERAL_DOLLAR_BRACE>>"
        text_escaped = text.replace("\\${", ESCAPE_TOKEN)

        def _repl(match):
            key = match.group(1)
            return placeholders.get(key, match.group(0))

        substituted = re.sub(r"\$\{([A-Z][A-Z0-9_]*)\}", _repl, text_escaped)
        return substituted.replace(ESCAPE_TOKEN, "${")

    def apply_placeholders(self):
        """Walk metadata and substitute placeholders in all string fields."""
        placeholders = self._build_placeholders()

        if not self.raw_metadata:
            return

        for key in list(self.raw_metadata.keys()):
            val = self.raw_metadata[key]
            if isinstance(val, str):
                self.raw_metadata[key] = self._substitute_placeholders(val, placeholders)

    def __repr__(self) -> str:
        return f"MetadataContainer(vars={len(self.variables)}, layer={self.layer is not None})"


class VariableResolver:
    """Resolves final variable values from multiple definitions using policy rules."""

    def __init__(self):
        pass

    def resolve(self, variable_definitions: Dict[str, List[EnvVariable]]) -> Dict[str, EnvVariable]:
        """
        Resolve variables, then apply trigger rules once and re-resolve with
        any injected variables.
        """
        resolved = self._resolve_pass(variable_definitions)

        trigger_defs = self._collect_trigger_definitions(resolved)
        if not trigger_defs:
            return resolved

        merged_defs: Dict[str, List[EnvVariable]] = {k: list(v) for k, v in variable_definitions.items()}
        for name, defs in trigger_defs.items():
            merged_defs.setdefault(name, []).extend(defs)

        # Re-run resolution so triggers participate in normal policy handling
        return self._resolve_pass(merged_defs)

    def _resolve_pass(self, variable_definitions: Dict[str, List[EnvVariable]]) -> Dict[str, EnvVariable]:
        """
        Resolve final variable values using policy rules:
        a) If any variable is defined as force, use the last force definition.
        b) Else if any immediate, use the first one provided the variable is not set in the env.
        c) If lazy, use the last one provided the variable is not set in the env.

        Args:
            variable_definitions: Dict mapping variable names to lists of EnvVariable definitions

        Returns:
            Dict mapping variable names to the resolved EnvVariable instance in layer dependency order
        """
        import os
        resolved = {}

        # Get all variables and sort by their earliest position to maintain layer dependency order
        all_vars = []
        for var_name, definitions in variable_definitions.items():
            if definitions:
                earliest_position = min(d.position for d in definitions)
                all_vars.append((var_name, definitions, earliest_position))

        # Sort by earliest position to maintain layer dependency order
        all_vars.sort(key=lambda x: x[2])

        for var_name, definitions, _ in all_vars:
            resolved_var = self._resolve_single_variable(var_name, definitions)
            if resolved_var:
                # Merge triggers from all definitions so upstream triggers are preserved
                seen = set()
                merged_triggers: List[TriggerRule] = []
                for d in definitions:
                    for trig in getattr(d, "triggers", []) or []:
                        key = (
                            trig.condition,
                            trig.action,
                            trig.target,
                            trig.value,
                            trig.policy,
                        )
                        if key in seen:
                            continue
                        seen.add(key)
                        merged_triggers.append(trig)
                if merged_triggers:
                    resolved_var.triggers = merged_triggers
                resolved[var_name] = resolved_var
            elif var_name in os.environ:
                # Variable is in environment - keep triggers so they can still fire
                first_def = definitions[0]
                seen = set()
                merged_triggers: List[TriggerRule] = []
                for d in definitions:
                    for trig in getattr(d, "triggers", []) or []:
                        key = (
                            trig.condition,
                            trig.action,
                            trig.target,
                            trig.value,
                            trig.policy,
                        )
                        if key in seen:
                            continue
                        seen.add(key)
                        merged_triggers.append(trig)
                # Merge conflicts from definitions so env/CLI overrides carry conflict metadata
                merged_conflicts: List[str] = []
                seen_conf = set()
                for d in definitions:
                    for c in getattr(d, "conflicts", []) or []:
                        if c in seen_conf:
                            continue
                        seen_conf.add(c)
                        merged_conflicts.append(c)
                max_position = max(d.position for d in definitions)
                env_var = EnvVariable(
                    name=var_name,
                    value=os.environ[var_name],
                    description=first_def.description,
                    required=first_def.required,
                    validator=first_def.validator,
                    validation_rule=getattr(first_def, "validation_rule", ""),
                    set_policy="already_set",
                    source_layer=first_def.source_layer,
                    position=max_position,
                    anchor_name=first_def.anchor_name,
                    triggers=merged_triggers,
                    conflicts=merged_conflicts,
                )
                resolved[var_name] = env_var

        return resolved

    def _collect_trigger_definitions(self, resolved: Dict[str, EnvVariable]) -> Dict[str, List[EnvVariable]]:
        """Build trigger-sourced definitions based on resolved values."""
        import os

        trigger_defs: Dict[str, List[EnvVariable]] = {}
        for env_var in resolved.values():
            # Trigger conditions evaluate against the effective runtime value.
            effective_value = os.environ.get(env_var.name, env_var.value)
            for rule in getattr(env_var, "triggers", []) or []:
                if rule.condition is not None and effective_value != rule.condition:
                    continue
                if rule.action != "set":
                    raise ValueError(f"Unsupported trigger action '{rule.action}' for variable '{env_var.name}'")

                # If the target variable already exists, inherit its validation metadata
                target_template: Optional[EnvVariable] = resolved.get(rule.target)
                target_validator = getattr(target_template, "validator", None) if target_template else None
                target_validation_rule = getattr(target_template, "validation_rule", "") if target_template else ""
                target_required = getattr(target_template, "required", False) if target_template else False
                target_anchor = getattr(target_template, "anchor_name", None) if target_template else None
                target_description = getattr(target_template, "description", "") if target_template else ""
                description = target_description or f"Triggered by {env_var.name}"

                injected = EnvVariable(
                    name=rule.target,
                    value=rule.value,
                    description=description,
                    required=target_required,
                    validator=target_validator,
                    validation_rule=target_validation_rule,
                    set_policy=rule.policy or TRIGGER_DEFAULT_POLICY,
                    source_layer=env_var.source_layer or "trigger",
                    # Place injected definition just after the source variable’s position
                    # so triggers fire after the source but can still be overridden by
                    # later layer definitions in normal force ordering.
                    position=env_var.position + 0.01,
                    anchor_name=target_anchor,
                    triggers=[],
                )
                trigger_defs.setdefault(rule.target, []).append(injected)
        return trigger_defs

    def _resolve_single_variable(self, var_name: str, definitions: List[EnvVariable]) -> Optional[EnvVariable]:
        """Resolve a single variable using policy rules."""
        import os

        # Separate definitions by policy
        force_defs = [d for d in definitions if d.set_policy == "force"]
        immediate_defs = [d for d in definitions if d.set_policy == "immediate"]
        lazy_defs = [d for d in definitions if d.set_policy == "lazy"]
        skip_defs = [d for d in definitions if d.set_policy == "skip"]

        # Rule a: If any variable is defined as force, use the last force definition
        if force_defs:
            return self._get_last_by_position(force_defs)

        # Rule b: Else if any immediate, use the first one provided the variable is not set in the env
        elif immediate_defs and var_name not in os.environ:
            return self._get_first_by_position(immediate_defs)

        # Rule c: If lazy, use the last one provided the variable is not set in the env
        elif lazy_defs and var_name not in os.environ:
            return self._get_last_by_position(lazy_defs)

        # Rule d: If only skip, still return one so validation can check required
        elif skip_defs:
            return self._get_last_by_position(skip_defs)

        # Variable is set in environment or no applicable definitions
        return None

    def _get_first_by_position(self, definitions: List[EnvVariable]) -> EnvVariable:
        """Get the definition with the earliest position (first in dependency order)."""
        return min(definitions, key=lambda d: d.position)

    def _get_last_by_position(self, definitions: List[EnvVariable]) -> EnvVariable:
        """Get the definition with the latest position (last in dependency order)."""
        return max(definitions, key=lambda d: d.position)

