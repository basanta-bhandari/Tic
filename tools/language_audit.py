#!/usr/bin/env python3
"""Audit Zenith-owned source languages during the no-shell migration."""

from __future__ import annotations

import argparse
from pathlib import Path


ALLOWED = {".go", ".rs", ".zig", ".py", ".s", ".S", ".asm"}
CONFIG = {".json", ".toml", ".tsv", ".conf", ".desktop", ".service"}
RUNTIME_ROOTS = (Path("overlay/usr/local/bin"), Path("overlay/usr/local/lib"))


def violations(root: Path) -> list[Path]:
    found: list[Path] = []
    for relative in RUNTIME_ROOTS:
        directory = root / relative
        if not directory.exists():
            continue
        for path in directory.rglob("*"):
            if path.is_symlink() or not path.is_file():
                continue
            suffix = path.suffix
            if suffix in ALLOWED or suffix in CONFIG:
                continue
            first_line = path.open("rb").readline(256)
            if suffix == ".sh" or b"/bin/bash" in first_line or b"/bin/sh" in first_line:
                found.append(path.relative_to(root))
    return sorted(found)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true", help="fail while migration files remain")
    args = parser.parse_args()
    found = violations(args.root.resolve())
    for path in found:
        print(f"migration-required: {path}")
    print(f"{len(found)} runtime shell file(s) remain")
    return int(args.strict and bool(found))


if __name__ == "__main__":
    raise SystemExit(main())
