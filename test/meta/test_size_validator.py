#!/usr/bin/env python3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SITE_DIR = REPO_ROOT / "site"
if str(SITE_DIR) not in sys.path:
    sys.path.insert(0, str(SITE_DIR))

from validators import SizeValidator


VALID_SIZES = ("12345", "20k", "20K", "128M", "1G", "512s", "50%")
INVALID_SIZES = ("128m", "1g", "512S")


def main() -> None:
    validator = SizeValidator()

    for value in VALID_SIZES:
        errors = validator.validate(value)
        if errors:
            raise SystemExit(f"expected {value!r} to be valid, got: {errors}")

    for value in INVALID_SIZES:
        if not validator.validate(value):
            raise SystemExit(f"expected {value!r} to be rejected")


if __name__ == "__main__":
    main()
