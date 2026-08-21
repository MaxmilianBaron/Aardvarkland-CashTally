#!/usr/bin/env python3
"""Run an offline LanguageTool audit over directly translated app strings.

The script deliberately excludes English fallback strings. It produces
machine-readable candidates, not a claim of native-speaker proofreading:
LanguageTool can report false positives and does not support every app locale.
"""

from __future__ import annotations

import argparse
import concurrent.futures
import json
import urllib.parse
import urllib.request
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("audit", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--server", default="http://127.0.0.1:8081")
    return parser.parse_args()


def get_json(url: str) -> object:
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.load(response)


def post_json(url: str, values: dict[str, str]) -> dict:
    body = urllib.parse.urlencode(values).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
    )
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.load(response)


def pick_language(language_code: str, supported: list[dict]) -> str | None:
    exact = [item["longCode"] for item in supported if item["longCode"] == language_code]
    if exact:
        return exact[0]
    base = [
        item["longCode"]
        for item in supported
        if item["longCode"].split("-", 1)[0] == language_code
    ]
    return base[0] if base else None


def main() -> int:
    args = parse_args()
    audit = json.loads(args.audit.read_text(encoding="utf-8"))
    supported = get_json(f"{args.server}/v2/languages")
    rows: list[dict] = []
    for language in audit["languages"]:
        code = language["language"]
        tool_code = pick_language(code, supported)
        strings = language["translatedStrings"]
        if tool_code is None:
            rows.append(
                {
                    "language": code,
                    "status": "unsupported",
                    "checkedStrings": 0,
                    "candidateCount": 0,
                    "candidates": [],
                }
            )
            continue

        candidates: list[dict] = []
        # Check each UI string as an independent text. Concatenating labels
        # makes the grammar engine invent cross-label sentences, repeated words
        # and capitalisation errors which do not exist in the application.
        def check_string(item: tuple[str, str]) -> list[dict]:
            key, source = item
            result = post_json(
                f"{args.server}/v2/check",
                {"language": tool_code, "text": source},
            )
            findings: list[dict] = []
            for match in result.get("matches", []):
                findings.append(
                    {
                        "key": key,
                        "source": source,
                        "offsetInString": match["offset"],
                        "length": match["length"],
                        "message": match["message"],
                        "shortMessage": match.get("shortMessage", ""),
                        "ruleId": match["rule"]["id"],
                        "category": match["rule"]["category"]["name"],
                        "replacements": [
                            item["value"]
                            for item in match.get("replacements", [])[:5]
                        ],
                    }
                )
            return findings

        with concurrent.futures.ThreadPoolExecutor(max_workers=12) as executor:
            for findings in executor.map(check_string, strings.items()):
                candidates.extend(findings)
        rows.append(
            {
                "language": code,
                "languageToolCode": tool_code,
                "status": "checked",
                "checkedStrings": len(strings),
                "candidateCount": len(candidates),
                "candidates": candidates,
            }
        )
        print(f"{code}: {len(strings)} strings, {len(candidates)} candidates", flush=True)

    output = {
        "schemaVersion": 1,
        "engine": "LanguageTool local server",
        "languages": rows,
        "checkedLanguageCount": sum(item["status"] == "checked" for item in rows),
        "unsupportedLanguageCount": sum(
            item["status"] == "unsupported" for item in rows
        ),
        "candidateCount": sum(item["candidateCount"] for item in rows),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(output, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        f"checked={output['checkedLanguageCount']} "
        f"unsupported={output['unsupportedLanguageCount']} "
        f"candidates={output['candidateCount']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
