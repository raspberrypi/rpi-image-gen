#!/usr/bin/env python3

# Load JSON produced by env_init and emit a shell compatible variables

import json
import sys

if len(sys.argv) != 2:
    sys.exit(f"usage: {sys.argv[0]} <in.json>")

with open(sys.argv[1], encoding="utf-8") as fh:
    snapshot = json.load(fh)

def emit(name, value):
    if value is None:
        return
    if isinstance(value, str):
        if not value:
            return
        print(f'{name}="{value}"')
    else:
        print(f'{name}={value}')

def emit_array_literal(name, items):
    if not items:
        print(f'{name}=()')
        return
    def squote(s):
        return "'" + s.replace("'", "'\"'\"'") + "'"
    print(f"{name}=(" + " ".join(squote(i) for i in items) + ")")

def yn(flag: bool) -> str:
    return "y" if flag else "n"

paths = snapshot.get("paths", {})
config_spec = paths.get("config", "")
layer_entries = paths.get("layer", [])
exec_entries = paths.get("exec", [])
override_entries = snapshot.get("overrides", [])

layer_tagged = [f"{entry.get('tag','LAYER')}={entry.get('path')}" for entry in layer_entries if entry.get('path')]
exec_paths = [entry for entry in exec_entries if entry]

config_file = snapshot.get("config_file") or ""
build_dir = snapshot.get("build_dir") or ""
srcroot = snapshot.get("srcroot") or ""

only_fs = yn(bool(snapshot.get("only_fs", False)))
only_image = yn(bool(snapshot.get("only_image", False)))
interactive = yn(bool(snapshot.get("interactive", False)))

emit("HOST_CONFIG_PATH", config_spec)
emit("HOST_CONFIG_FILE", config_file)
emit("HOST_LAYER_PATH", ":".join(layer_tagged))
emit("HOST_EXEC_PATH", ":".join(exec_paths))
emit("HOST_BUILD_DIR", build_dir)
emit("SRCROOT", srcroot)
emit("INTERACTIVE", interactive)
emit("ONLY_FS", only_fs)
emit("ONLY_IMAGE", only_image)
emit_array_literal("OVERRIDES", override_entries)
