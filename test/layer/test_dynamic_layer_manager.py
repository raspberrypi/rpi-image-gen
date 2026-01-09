#!/usr/bin/env python3
import os
import tempfile
from pathlib import Path

import sys
REPO_ROOT = Path(__file__).resolve().parents[2]
SITE_DIR = REPO_ROOT / "site"
if str(SITE_DIR) not in sys.path:
    sys.path.insert(0, str(SITE_DIR))

from layer_manager import LayerManager


def main() -> None:
    layers_dir = Path(__file__).resolve().parent
    tools_dir = layers_dir / "tools"
    with tempfile.TemporaryDirectory(prefix="dynamic-layer-") as tmpdir:
        os.environ["PATH"] = f"{tools_dir}:{os.environ['PATH']}"
        manager = LayerManager([f"DYNlayer={tmpdir}", str(layers_dir)])
        order = manager.get_build_order(["dynamic-test"])
        if "dynamic-test" not in order:
            raise SystemExit("dynamic-test not in build order")
        generated = Path(manager.layer_files["dynamic-test"])
        if tmpdir not in str(generated):
            raise SystemExit("generated file not in dynamic layer directory")
        data = generated.read_text().strip()
        if "# generated" not in data:
            raise SystemExit("generated marker not found in output")


if __name__ == "__main__":
    main()
