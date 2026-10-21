#!/usr/bin/env python3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SITE_DIR = REPO_ROOT / "site"
if str(SITE_DIR) not in sys.path:
    sys.path.insert(0, str(SITE_DIR))

from validators import PathListValidator, parse_validator


VALID = (
    "usr/lib/modules",
    "/usr/lib/modules",
    "usr/lib/modules,usr/share/doc",
    "usr/lib/modules, /usr/share/doc",
    "usr/lib/modules,usr/lib/modules-load.d",
    "opt/libstdc++,var/lib/app@1",
)
INVALID = (
    "",
    " ",
    "usr/lib/modules,",
    "usr/lib/modules/",
    "//usr/lib",
    "usr/lib//modules",
    "usr/lib/../modules",
    "./usr/lib",
    "/",
    "usr/lib modules",
    "usr/lib\tmodules",
    "usr/lib/mod'x",
    "usr/$HOME",
    "usr|lib",
    "usr\\lib",
    "usr/lib/*",
    "usr/lib/modules,/usr/lib/modules",
    "usr/lib,usr/lib/modules",
    "usr/lib/modules,usr/lib",
)


def main() -> None:
    validator = parse_validator("pathlist")
    if not isinstance(validator, PathListValidator):
        raise SystemExit(f"expected 'pathlist' to give a PathListValidator, got {validator!r}")

    if not validator.validate(None):
        raise SystemExit("expected an unset value to be rejected")

    for value in VALID:
        errors = validator.validate(value)
        if errors:
            raise SystemExit(f"expected {value!r} to be valid, got: {errors}")

    for value in INVALID:
        if not validator.validate(value):
            raise SystemExit(f"expected {value!r} to be rejected")


if __name__ == "__main__":
    main()
