import json
import platform
import socket
from pathlib import Path


def EnvInit_register_parser(subparsers, *, root: str) -> None:
    parser = subparsers.add_parser("env", help="Invocation snapshot as JSON")
    parser.add_argument("-c", "--config", dest="config_file", help="Primary config file")
    parser.add_argument("-B", "--build-dir", dest="build_dir", help="Build directory (IGconf_sys_workroot)")
    parser.add_argument("-S", "--srcroot", dest="srcroot", help="Custom source tree override")
    parser.add_argument("-I", "--interactive", action="store_true", help="Interactive mode")
    parser.add_argument("-f", "--fs-only", dest="fs_only", action="store_true",
                        help="Build only filesystem, skip image generation")
    parser.add_argument("-i", "--image-only", dest="image_only", action="store_true",
                        help="Skip filesystem generation, build image only")
    parser.add_argument("overrides", nargs="*", help="Overrides (key=value, supply after --)")
    parser.set_defaults(func=_env_init_command, igroot=root)


def _env_init_command(args) -> None:
    igroot = Path(args.igroot).resolve()
    srcroot = _resolve_optional_path(args.srcroot)
    if srcroot and not srcroot.exists():
        raise SystemExit(f"Source directory not found: {srcroot}")
    if srcroot and srcroot.samefile(igroot):
        srcroot = None

    build_dir = _resolve_optional_path(args.build_dir)
    if build_dir and not build_dir.exists():
        raise SystemExit(f"Build directory not found: {build_dir}")

    config_dirs = _collect_config_paths(igroot, srcroot)
    config_file = None
    if args.config_file:
        try:
            config_file = _resolve_config_file(args.config_file, config_dirs)
        except FileNotFoundError as exc:
            raise SystemExit(str(exc))

    payload = {
        "igroot": str(igroot),
        "srcroot": str(srcroot) if srcroot else None,
        "config_file": str(config_file) if config_file else None,
        "build_dir": str(build_dir) if build_dir else None,
        "interactive": bool(args.interactive),
        "only_fs": bool(getattr(args, "fs_only", False)),
        "only_image": bool(getattr(args, "image_only", False)),
        "paths": {
            "config": ":".join(config_dirs),
            "layer": _collect_layer_paths(igroot, srcroot),
            "exec": _collect_exec_paths(igroot, srcroot),
        },
        "overrides": _normalise_overrides(args.overrides),
        "argv": getattr(args, "_unknown", []),
        "system": {
            "hostname": socket.gethostname(),
            "os": platform.platform(),
            "python": platform.python_version(),
            "machine": platform.machine(),
        },
    }

    print(json.dumps(payload, indent=2, sort_keys=True))


def _collect_config_paths(igroot: Path, srcroot: Path | None) -> list[str]:
    dirs: list[str] = []
    if srcroot:
        cfg = (srcroot / "config").resolve()
        if cfg.is_dir():
            dirs.append(str(cfg))
    cfg = (igroot / "config").resolve()
    if cfg.is_dir():
        dirs.append(str(cfg))
    return dirs


def _collect_layer_paths(igroot: Path, srcroot: Path | None) -> list[dict]:
    paths: list[dict] = []
    if srcroot:
        for tag, rel in (("SRCdevice", "device"), ("SRCimage", "image"), ("SRClayer", "layer")):
            candidate = (srcroot / rel).resolve()
            if candidate.is_dir():
                paths.append({"tag": tag, "path": str(candidate)})
    for tag, rel in (("IGdevice", "device"), ("IGimage", "image"), ("IGlayer", "layer")):
        candidate = (igroot / rel).resolve()
        if candidate.is_dir():
            paths.append({"tag": tag, "path": str(candidate)})
    return paths


def _collect_exec_paths(igroot: Path, srcroot: Path | None) -> list[str]:
    paths: list[str] = []
    if srcroot:
        for rel in ("bin", "bin/generators"):
            candidate = (srcroot / rel).resolve()
            if candidate.is_dir():
                paths.append(str(candidate))
    for rel in ("bin", "bin/generators"):
        candidate = (igroot / rel).resolve()
        if candidate.is_dir():
            paths.append(str(candidate))
    return paths


def _resolve_optional_path(raw: str | None) -> Path | None:
    if not raw:
        return None
    return Path(raw).expanduser().resolve()


def _resolve_config_file(raw: str | None, search_roots: list[str]) -> Path:
    candidate = Path(raw).expanduser()
    if candidate.is_absolute() or raw.startswith(("./", "../")) or "/" in raw:
        if candidate.exists():
            return candidate.resolve()
        raise FileNotFoundError(f"Config file not found: {candidate}")
    for root in search_roots:
        target = (Path(root) / raw).resolve()
        if target.exists():
            return target
    raise FileNotFoundError(f"Config file '{raw}' not found in {search_roots}")


def _normalise_overrides(values: list[str] | None) -> list[str]:
    if not values:
        return []
    cleaned = values[1:] if values and values[0] == "--" else values
    return [item.strip() for item in cleaned if item.strip()]
