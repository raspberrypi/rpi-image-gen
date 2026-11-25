#!/usr/bin/env python3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SITE_DIR = REPO_ROOT / "site"
if str(SITE_DIR) not in sys.path:
    sys.path.insert(0, str(SITE_DIR))

from validators import NameListValidator, parse_validator


VALID = (
    "system",
    "system,user",
    "wlan.ssid",
    "system,wlan.ssid,locale.lc_time",
    "Name-1,name_2,3.name",
)
INVALID = (
    "",
    " ",
    ",",
    "system,",
    ",system",
    "system,,user",
    "system, user",
    " system",
    "system ",
    "system,\tuser",
    "sys/tem",
    "sys:tem",
    "system,system",
)


def main() -> None:
    validator = parse_validator("namelist")
    if not isinstance(validator, NameListValidator):
        raise SystemExit(f"expected 'namelist' to give a NameListValidator, got {validator!r}")

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
