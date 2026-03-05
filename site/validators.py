from __future__ import annotations

import re
from abc import ABC, abstractmethod
from typing import Optional, Union


# Reusable validation helpers for X-Env metadata

# === VALIDATORS ===

class BaseValidator(ABC):
    @abstractmethod
    def validate(self, value: Optional[str]) -> list[str]:
        """Validate a value and return a list of error messages (empty if valid)"""
        pass

    @abstractmethod
    def describe(self) -> str:
        """Return a human-readable description of this validator"""
        pass


class BooleanValidator(BaseValidator):
    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            return ["Value cannot be None"]
        if value.lower() not in ("true", "false", "1", "0", "yes", "no", "y", "n"):
            return [f"Value '{value}' is not a valid boolean."]
        return []

    def describe(self) -> str:
        return "Boolean value - accepts: true/false, 1/0, yes/no, y/n (case insensitive)"

    @classmethod
    def get_help_text(cls) -> str:
        return "bool                   - Must be: true/false, 1/0, yes/no, y/n (case insensitive)"


class IntegerValidator(BaseValidator):
    def __init__(self, min_val: Optional[int] = None, max_val: Optional[int] = None):
        self.min_val = min_val
        self.max_val = max_val

    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            return ["Value cannot be None"]
        try:
            val = int(value)
            if self.min_val is not None and val < self.min_val:
                return [f"Value '{val}' is below minimum {self.min_val}."]
            if self.max_val is not None and val > self.max_val:
                return [f"Value '{val}' is above maximum {self.max_val}."]
        except (ValueError, TypeError):
            return [f"Value '{value}' is not a valid integer."]
        return []

    def describe(self) -> str:
        desc = "Integer value"
        if self.min_val is not None or self.max_val is not None:
            desc += f" in range {self.min_val or '-∞'} to {self.max_val or '∞'}"
        return desc

    @classmethod
    def get_help_text(cls) -> str:
        return """int                    - Must be a valid integer
  int:MIN-MAX           - Integer within range (inclusive)
  Examples:
    int:1-100           - Integer from 1 to 100
    int:1024-65535      - Port numbers
    int:0-255           - Byte values"""


class StringValidator(BaseValidator):
    def __init__(self, allow_empty: bool = False, allow_unset: bool = False):
        self.allow_empty = allow_empty
        self.allow_unset = allow_unset

    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            if self.allow_unset:
                return []
            return ["String value cannot be None/unset"]
        if value == "" and not self.allow_empty:
            return ["String value cannot be empty"]
        return []

    def describe(self) -> str:
        if self.allow_unset and self.allow_empty:
            return "String value (may be empty or unset)"
        elif self.allow_unset:
            return "String value (may be unset but not empty)"
        elif self.allow_empty:
            return "String value (may be empty)"
        else:
            return "Non-empty string value"

    @classmethod
    def get_help_text(cls) -> str:
        return """string                 - Must be a non-empty string (required)
  string-or-unset        - Must be non-empty string or unset (null)
  string-or-empty        - Must be any string (may be empty) but not unset"""


class EnumValidator(BaseValidator):
    def __init__(self, options: list[str]):
        self.options = options

    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            return ["Value cannot be None"]
        if value not in self.options:
            return [f"Value '{value}' is not one of: {', '.join(self.options)}"]
        return []

    def describe(self) -> str:
        return f"Must be one of: {', '.join(self.options)}"

    @classmethod
    def get_help_text(cls) -> str:
        return """value1,value2,value3  - Must be one of the listed values
  (Tip: For a single allowed value, either add a trailing comma
        e.g. "syft," or use the keywords: prefix as shown below.)
  Examples:
    development,staging,production    - Environment names
    small,medium,large               - Size options
    debug,info,warn,error            - Log levels

KEYWORDS:
  keywords:word1,word2,word3  - Must be one of the listed alphanumeric keywords
  Keywords can contain: letters (a-z, A-Z), numbers (0-9), underscore (_), hyphen (-)
  Examples:
    keywords:frontend,backend,database     - Application components
    keywords:cpu-intensive,io-bound        - Workload types
    keywords:dev,test,staging,prod         - Environment shortcuts"""


class RegexValidator(BaseValidator):
    def __init__(self, pattern: str):
        self.pattern = pattern
        try:
            self.compiled = re.compile(pattern)
        except re.error as e:
            raise ValueError(f"Invalid regex pattern '{pattern}': {e}")

    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            return ["Value cannot be None"]
        if not self.compiled.fullmatch(value):
            return [f"Value '{value}' does not match pattern: {self.pattern}"]
        return []

    def describe(self) -> str:
        return f"Must match regex pattern: {self.pattern}"

    @classmethod
    def get_help_text(cls) -> str:
        return """regex:PATTERN         - Must match regular expression
  Examples:
    regex:^[a-zA-Z0-9.-]+$     - Hostname format
    regex:^[0-9]{3}-[0-9]{2}$  - Format like 123-45
    regex:^(http|https)://     - URLs starting with http/https"""


class SizeValidator(BaseValidator):
    def __init__(self):
        self.size_re = re.compile(r"(?:[0-9]+(?:[kKmMgGsS])?|[1-9][0-9]*%)$")

    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            return ["Value cannot be None"]
        if not self.size_re.fullmatch(value):
            return [f"Value '{value}' is not a valid size format"]
        return []

    def describe(self) -> str:
        return "Size value with optional unit (bytes, k/m/g/s) or percentage"

    @classmethod
    def get_help_text(cls) -> str:
        return """size                   - Size with optional unit (bytes, k/m/g/s) or percentage

SIZES:
  size can be specified in one of the following formats
    12345        (bytes)
    20k / 20K    (kilobytes, multiples of 1024)
    128M / 128m  (megabytes)
    1G / 4g      (gigabytes)
    512s         (sectors, multiples of 512)
    50%          (percentage; any positive integer)"""


class CapacityValidator(BaseValidator):
    def __init__(self):
        # Accept: K, M, G, T, (1024-based) and KiB, MiB, GiB, TiB
        # Reject: KB, MB, GB, TB (1000-based decimal units)
        # Pattern matches: numbers + optional binary unit suffix
        self.capacity_re = re.compile(r"^[0-9]+(?:[KMGT]|[KMGT]iB)?$")

    def validate(self, value: Optional[str]) -> list[str]:
        if value is None:
            return ["Value cannot be None"]

        if not isinstance(value, str):
            return ["Capacity must be a string with optional binary unit suffix"]

        # Reject percentage values
        if '%' in value:
            return ["Capacity doesn't support percentage values - use 'size' validator for percentages"]

        # Reject decimal units (KB, MB, GB, TB)
        if re.search(r'[KMGTPEZY]B$', value):
            return [f"Value '{value}' uses decimal units (KB/MB/GB/TB) - capacity requires binary units (K/M/G/T or KiB/MiB/GiB/TiB)"]

        if not self.capacity_re.fullmatch(value):
            return [f"Value '{value}' is not a valid capacity format - use integer with optional binary unit (K, M, G, T or KiB, MiB, etc.)"]

        # Check plain numbers (no suffix)
        if value.isdigit():
            num = int(value)

            # Must be at least 512 (bytes)
            if num < 512:
                return [f"Value '{num}' is too small for storage capacity - minimum is 512 (bytes)"]

            # Check binary alignment
            if num <= 1024:
                if 1024 % num != 0:
                    return [f"Value '{num}' is not binary-aligned - should divide evenly into 1024, or use binary units"]
            else:
                if num % 1024 != 0:
                    return [f"Value '{num}' is not binary-aligned - should be a multiple of 1024, or use binary units"]

        return []

    def describe(self) -> str:
        return "Storage capacity: bytes (512+) or binary units (K, M, G, T, KiB, MiB, etc.)"

    @classmethod
    def get_help_text(cls) -> str:
        return """capacity               - Storage capacity in binary units (1024-based)

BINARY CAPACITY UNITS:
  capacity must be specified with binary (1024-based) units for storage devices
    8K / 8KiB    (8 × 1024 bytes = 8,192 bytes)
    128M / 128MiB (128 × 1024² bytes = 134,217,728 bytes)
    4G / 4GiB    (4 × 1024³ bytes = 4,294,967,296 bytes)
    2T / 2TiB    (2 × 1024⁴ bytes)

  Supported units: K, M, G, T (short form)
                   KiB, MiB, GiB, TiB (explicit binary)

  Rejected units:  KB, MB, GB, TB (decimal 1000-based)

PLAIN NUMBERS (no suffix):
  Accepted with requirements:
    Minimum: 512 (typical sector size in bytes)
    Binary alignment: must be 512, 1024, 2048, 4096, etc.

  Examples:
    512
    4MiB
    8G

  This validator is designed for storage device capacity where binary
  units align with filesystem blocks, sectors, and hardware reality."""


# === VALIDATOR FACTORY ===

def parse_validator(rule_str: str) -> BaseValidator:
    """Parse a rule string into a validator instance"""
    if not rule_str:
        raise ValueError("Empty rule string")

    rule_str = rule_str.strip()

    if rule_str == "string":
        return StringValidator()
    elif rule_str == "string-or-empty":
        return StringValidator(allow_empty=True)
    elif rule_str == "string-or-unset":
        return StringValidator(allow_unset=True)
    elif rule_str == "bool":
        return BooleanValidator()
    elif rule_str == "int":
        return IntegerValidator()
    elif rule_str.startswith("int:"):
        try:
            range_str = rule_str.split(":", 1)[1]
            min_val, max_val = map(int, range_str.split("-"))
            return IntegerValidator(min_val, max_val)
        except Exception as e:
            raise ValueError(f"Invalid int range format '{rule_str}': {e}")
    elif rule_str.startswith("regex:"):
        pattern = rule_str.split(":", 1)[1]
        return RegexValidator(pattern)
    elif rule_str.startswith("keywords:"):
        options = [x.strip() for x in rule_str.split(":", 1)[1].split(",")]
        return EnumValidator(options)
    elif rule_str == "size":
        return SizeValidator()
    elif rule_str == "capacity":
        return CapacityValidator()
    elif "," in rule_str:
        # Comma-separated enum
        options = [x.strip() for x in rule_str.split(",") if x.strip()]
        return EnumValidator(options)
    else:
        # Single value without comma - reject unless it's a known type
        if rule_str in ["string", "string-or-empty", "string-or-unset", "bool", "int", "size", "capacity"]:
            raise ValueError(f"Unknown validation rule: {rule_str}")
        else:
            raise ValueError(f"Single value '{rule_str}' must use trailing comma ('{rule_str},') or keywords: prefix ('keywords:{rule_str}')")


def get_validator_documentation_data() -> dict:
    """Extract structured validator data for documentation generation"""
    import inspect

    validator_classes = []
    for name, obj in globals().items():
        if (inspect.isclass(obj) and
            issubclass(obj, BaseValidator) and
            obj != BaseValidator and
            hasattr(obj, 'get_help_text')):
            validator_classes.append(obj)

    # Sort by class name for consistent output
    validator_classes.sort(key=lambda cls: cls.__name__)

    # Extract structured data
    basic_types = []
    advanced_types = []

    for validator_class in validator_classes:
        if hasattr(validator_class, 'get_help_text'):
            help_text = validator_class.get_help_text()

            if '\n' in help_text:
                # Multi-line = advanced type
                lines = help_text.split('\n')
                advanced_types.append({
                    'name': validator_class.__name__.replace('Validator', '').lower(),
                    'title': lines[0],
                    'details': lines[1:] if len(lines) > 1 else []
                })
            else:
                # Single line = basic type
                basic_types.append({
                    'name': validator_class.__name__.replace('Validator', '').lower(),
                    'description': help_text
                })

    return {
        'basic_types': basic_types,
        'advanced_types': advanced_types,
        'set_policies': [
            {'name': 'force', 'class': 'force', 'description': 'Always overwrite existing environment value, regardless of what was set before.'},
            {'name': 'immediate', 'class': 'immediate', 'description': 'Set the variable if it is currently unset (first-wins strategy). This is the default behavior.'},
            {'name': 'lazy', 'class': 'lazy', 'description': 'Applied after all layers are processed (last-wins strategy). Useful for defaults that can be overridden.'},
            {'name': 'skip', 'class': 'skip', 'description': 'Never set the variable. Useful for optional variables or when you want to disable a variable.'}
        ],
        'placeholders': [
            {'name': '${FILENAME}', 'description': 'layer metadata file name'},
            {'name': '${DIRECTORY}', 'description': 'directory containing the file'},
            {'name': '${FILEPATH}', 'description': 'absolute path to the file'}
        ]
    }


def get_validation_help() -> str:
    """Generate comprehensive validation help by discovering all validator classes"""
    import inspect

    help_sections = []

    # Header
    help_sections.append("Validation Schemes for X-Env-Var-*-Valid Fields:\n")

    # Discover all validator classes
    validator_classes = []
    for name, obj in globals().items():
        if (inspect.isclass(obj) and
            issubclass(obj, BaseValidator) and
            obj != BaseValidator and
            hasattr(obj, 'get_help_text')):
            validator_classes.append(obj)

    # Sort by class name for consistent output
    validator_classes.sort(key=lambda cls: cls.__name__)

    # Basic types section
    help_sections.append("BASIC TYPES:")
    for validator_class in validator_classes:
        if hasattr(validator_class, 'get_help_text'):
            help_text = validator_class.get_help_text()
            # Only show basic types in this section (single line descriptions)
            if '\n' not in help_text:
                help_sections.append(f"  {help_text}")

    # Advanced types section
    help_sections.append("\nADVANCED TYPES:")
    for validator_class in validator_classes:
        if hasattr(validator_class, 'get_help_text'):
            help_text = validator_class.get_help_text()
            # Show multi-line descriptions here
            if '\n' in help_text:
                lines = help_text.split('\n')
                help_sections.append(f"  {lines[0]}")  # First line
                for line in lines[1:]:
                    help_sections.append(f"  {line}")
                help_sections.append("")  # Add blank line after each advanced type

    # Additional sections from original help
    help_sections.extend([
        "TIP: Use `ig metadata --lint <file>` to quickly check syntax and field names without validating environment variables.\n",

        "PLACEHOLDERS (auto-substituted in values):",
        "  ${FILENAME}   - layer metadata file name",
        "  ${DIRECTORY}  - directory containing the file",
        "  ${FILEPATH}   - absolute path to the file",
        "  Escape with \\${NAME} to keep the literal text.\n",

        "SET POLICY (X-Env-Var-*-Set):",
        "  force       - always overwrite existing environment value",
        "  immediate   - set if the variable is unset (default)",
        "  lazy        - applied after all layers are processed (last-wins)",
        "  false/no/0  - skip; never set the variable\n",

        "  Aliases:",
        "    true/yes/1/y -> immediate",
        "    false/no/0/n -> skip\n",

        "EXAMPLES:",
        "  X-Env-Var-port-Valid: int:1024-65535",
        "  X-Env-Var-env-Valid: development,staging,production",
        "  X-Env-Var-hostname-Valid: regex:^[a-zA-Z0-9.-]+$",
        "  X-Env-Var-debug-Valid: bool",
        "  X-Env-Var-count-Valid: int:1-1000",
        "  X-Env-Var-component-Valid: keywords:frontend,backend,database\n",

        "VARIABLE REQUIREMENTS:",
        "  X-Env-VarRequires: var1,var2,var3         - Comma-separated environment variables (required)",
        "  X-Env-VarRequires-Valid: rule1,rule2,rule3 - Validation rules (same order)\n",

        "  X-Env-VarOptional: var1,var2,var3         - Comma-separated environment variables (optional)",
        "  X-Env-VarOptional-Valid: rule1,rule2,rule3 - Validation rules (same order)\n",

        "  Variables are checked as-is (no IGconf_ prefix or VarPrefix applied)."
    ])

    return '\n'.join(help_sections)
