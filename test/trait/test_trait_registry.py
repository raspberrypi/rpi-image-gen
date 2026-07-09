#!/usr/bin/env python3
"""Tests for the trait registry (site/trait_registry.py).

Single-file validation and load-time errors are covered static fixtures.
Only resolve() behaviour lives here.
"""
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SITE_DIR = REPO_ROOT / "site"
TRAIT_DIR = REPO_ROOT / "trait"
FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"
if str(SITE_DIR) not in sys.path:
    sys.path.insert(0, str(SITE_DIR))

from trait_registry import TraitRegistry


def case_by_prefix_colon_boundary() -> None:
    # 'hw:soc' must not match 'hw:soccer'
    r = TraitRegistry(str(FIXTURES_DIR / "by-prefix-boundary"))
    matches = set(r.by_prefix("hw:soc"))
    if matches != {"hw:soc"}:
        raise SystemExit(f"by_prefix('hw:soc') matched {matches}")


def case_conditional_triggers_self_targeting() -> None:
    # derived should only fire once both a and b are active
    r = TraitRegistry(str(FIXTURES_DIR / "conditional-triggers"))

    if "hw:derived" in r.resolve({"hw:a"}):
        raise SystemExit("hw:derived fired with only one condition met")

    if "hw:derived" not in r.resolve({"hw:a", "hw:b"}):
        raise SystemExit("hw:derived did not fire with both conditions met")


def case_external_srcroot_extends_real_tree() -> None:
    # OEM srcroot loaded alongside the built-in tree: a new namespace, plus
    # extending the built-in hw namespace with a child of its own
    r = TraitRegistry([str(TRAIT_DIR), str(FIXTURES_DIR / "oem-srcroot")])

    if "carrier:v1" not in r.all_tokens:
        raise SystemExit("carrier:v1 not loaded from external srcroot")
    if "hw:customboard" not in r.all_tokens:
        raise SystemExit("hw:customboard not loaded from external srcroot")
    if "hw:device:rpi:cm5" not in r.all_tokens:
        raise SystemExit("built-in tokens missing alongside external srcroot")

    try:
        r.resolve({"carrier:v1"})
    except ValueError as exc:
        if "hw:bluetooth" not in str(exc):
            raise SystemExit(f"wrong Requires error: {exc}")
    else:
        raise SystemExit("carrier:v1 without hw:bluetooth should fail")

    active = r.resolve({"carrier:v1", "hw:bluetooth"})
    if "carrier:v1" not in active or "hw:bluetooth" not in active:
        raise SystemExit("carrier:v1 + hw:bluetooth should resolve cleanly")


def main() -> None:
    case_by_prefix_colon_boundary()
    case_conditional_triggers_self_targeting()
    case_external_srcroot_extends_real_tree()


if __name__ == "__main__":
    main()
