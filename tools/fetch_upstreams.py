#!/usr/bin/env python3
"""Fetch and verify Zenith's pinned source inputs."""

from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "upstreams.lock.json"


def run(*args: str, cwd: Path | None = None) -> str:
    result = subprocess.run(
        args,
        cwd=cwd,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    return result.stdout.strip()


def fetch(name: str, entry: dict[str, str], destination: Path) -> None:
    checkout = destination / name
    revision = entry["revision"]
    if not checkout.exists():
        run("git", "clone", "--filter=blob:none", "--no-checkout", entry["url"], str(checkout))
    elif not (checkout / ".git").is_dir():
        raise SystemExit(f"refusing non-Git destination: {checkout}")
    elif run("git", "remote", "get-url", "origin", cwd=checkout) != entry["url"]:
        run("git", "remote", "set-url", "origin", entry["url"], cwd=checkout)

    run("git", "fetch", "--depth=1", "origin", revision, cwd=checkout)
    run("git", "checkout", "--detach", revision, cwd=checkout)
    actual = run("git", "rev-parse", "HEAD", cwd=checkout)
    if actual != revision:
        raise SystemExit(f"revision mismatch for {name}: expected {revision}, got {actual}")
    print(f"{name}: {actual} ({entry['license']}, {entry['language']})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "destination",
        nargs="?",
        type=Path,
        default=ROOT / "work" / "upstreams",
        help="checkout directory (default: work/upstreams)",
    )
    parser.add_argument("--only", choices=("imperium-engine", "kage-shell", "pydos"))
    args = parser.parse_args()

    data = json.loads(LOCK.read_text(encoding="utf-8"))
    entries = data["upstreams"]
    args.destination.mkdir(parents=True, exist_ok=True)
    selected = {args.only: entries[args.only]} if args.only else entries
    for name, entry in selected.items():
        fetch(name, entry, args.destination)


if __name__ == "__main__":
    main()
