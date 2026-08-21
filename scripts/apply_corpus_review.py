#!/usr/bin/env python3
"""Apply explicit human-review decisions to a downloaded corpus manifest."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("review", type=Path)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    review = json.loads(args.review.read_text(encoding="utf-8"))
    rejected = review.get("rejected", {})
    changed = 0
    for source in manifest["sources"]:
        reason = rejected.get(source["id"])
        if reason is None:
            continue
        if source["status"] == "downloaded":
            source["status"] = "rejected_manual"
            changed += 1
        source["reviewReason"] = reason
    manifest["downloaded"] = sum(
        source["status"] == "downloaded" for source in manifest["sources"]
    )
    manifest["manualReview"] = {
        "reviewedOn": review["reviewedOn"],
        "rejected": sum(
            source["status"] == "rejected_manual" for source in manifest["sources"]
        ),
    }
    args.manifest.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Applied {changed} new rejection decisions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
