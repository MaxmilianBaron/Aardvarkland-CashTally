#!/usr/bin/env python3
"""Download a reproducible, attributed banknote OCR corpus from Commons.

Only Wikimedia Commons thumbnails are used. Every selected file keeps its
source page, author, licence and SHA-256 in sources.json. Images are QA input
artifacts and are never bundled into the application.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import ssl
import time
import urllib.parse
import urllib.request
from urllib.error import HTTPError
from pathlib import Path

from PIL import Image
import certifi


API = "https://commons.wikimedia.org/w/api.php"
USER_AGENT = "VycetkaOCRAudit/0.1 (local application QA; attributed corpus)"
TLS_CONTEXT = ssl.create_default_context(cafile=certifi.where())
COUNTRY_TERMS = {
    "CZK": "Czech",
    "EUR": "euro",
    "USD": "United States",
    "GBP": "British",
    "CHF": "Swiss",
    "CAD": "Canadian",
    "AUD": "Australian",
    "JPY": "Japanese",
    "KRW": "South Korean",
    "SEK": "Swedish",
    "NOK": "Norwegian",
    "UAH": "Ukrainian",
    "RUB": "Russian",
    "DKK": "Danish",
    "HUF": "Hungarian",
    "PLN": "Polish",
    "BRL": "Brazilian",
    "ARS": "Argentine",
    "TRY": "Turkish",
    "MXN": "Mexican",
    "INR": "Indian",
    "IDR": "Indonesian",
    "PKR": "Pakistani",
    "MYR": "Malaysian",
    "THB": "Thai",
    "NGN": "Nigerian",
    "ZAR": "South African",
    "DZD": "Algerian",
    "EGP": "Egyptian",
    "ILS": "Israeli",
    "SAR": "Saudi",
    "AED": "United Arab Emirates",
}
CURRENCY_TITLE_PATTERNS = {
    "CZK": (r"\bczech (?:koruna|korun|crowns?)\b", r"\bczk\b"),
    "EUR": (r"\beuros?\b",),
    "USD": (
        r"\b(?:united states|u\.?s\.?|us) dollars?\b",
        r"\busd\b",
    ),
    "GBP": (
        r"\b(?:british|english) pounds?\b",
        r"\bpounds? sterling\b",
        r"\bbank of england\b",
        r"\bgbp\b",
    ),
    "CHF": (r"\bswiss francs?\b", r"\bchf\b"),
    "CAD": (r"\bcanadian dollars?\b", r"\bbank of canada\b", r"\bcad\b"),
    "AUD": (r"\baustralian dollars?\b", r"\baud\b"),
    "JPY": (r"\bjapan(?:ese)? yen\b", r"\bjpy\b"),
    "KRW": (r"\b(?:south )?korean? won\b", r"\bkrw\b"),
    "SEK": (r"\bswedish (?:krona|kronor)\b", r"\bsek\b"),
    "NOK": (r"\bnorwegian (?:krone|kroner)\b", r"\bnok\b"),
    "UAH": (r"\bukrainian hryvnia\b", r"\buah\b"),
    "RUB": (r"\brussian (?:rubles?|roubles?)\b", r"\brub\b"),
    "DKK": (r"\bdanish (?:krone|kroner)\b", r"\bdkk\b"),
    "HUF": (r"\bhungarian forints?\b", r"\bhuf\b"),
    "PLN": (r"\bpolish (?:zloty|złoty)\b", r"\bpln\b"),
    "BRL": (r"\bbraz(?:il|ilian) reals?\b", r"\bbrl\b"),
    "ARS": (r"\bargentin(?:a|e) pesos?\b", r"\bars\b"),
    "TRY": (r"\bturkish lira\b", r"\btry\b"),
    "MXN": (r"\bmexican pesos?\b", r"\bmxn\b"),
    "INR": (r"\bindian rupees?\b", r"\binr\b"),
    "IDR": (r"\bindonesian rupiah\b", r"\bidr\b"),
    "PKR": (r"\bpakistani rupees?\b", r"\bpkr\b"),
    "MYR": (r"\bmalaysian ringgit\b", r"\bmyr\b"),
    "THB": (r"\bthai baht\b", r"\bthb\b"),
    "NGN": (r"\bnigerian naira\b", r"\bngn\b"),
    "ZAR": (r"\bsouth african rand\b", r"\bzar\b"),
    "DZD": (r"\balgerian dinars?\b", r"\bdzd\b"),
    "EGP": (r"\begyptian pounds?\b", r"\begp\b"),
    "ILS": (r"\bisraeli (?:new )?shekels?\b", r"\bils\b"),
    "SAR": (r"\bsaudi riyals?\b", r"\bsar\b"),
    "AED": (
        r"\b(?:united arab emirates|uae) dirhams?\b",
        r"\baed\b",
    ),
}
REJECTED_TITLE_PATTERNS = (
    r"\bblanket\b",
    r"\bcoins?\b",
    r"\bcents?\b",
    r"\bcounterfeit\b",
    r"\bfantasy\b",
    r"\binfrared\b",
    r"\bultraviolet\b",
    r"\b(?:uv|x-ray)\b",
    r"\bmonopoly\b",
    r"\bplay money\b",
    r"\bsimple worksheet\b",
    r"\bsouvenir\b",
    r"\bspecimen\b",
    r"\bplan of\b",
    r"\bdesign for\b",
    r"\bconcept\b",
    r"\b(?:old|historic(?:al)?) banknotes?\b",
    r"\bold\b",
    r"\b(?:empire|imperial|occupation|notgeld)\b",
    r"\broyal bank of canada\b",
    r"\b(?:banknotes|banknoten)\b",
    r"\bbank\s+notes\b",
    r"\b(?:bundle|stack|strap)s?\b",
    r"\b(?:handshake|hands?)\b",
    r"\b(?:torn|damaged)\b",
    r"\b(?:hologram|security thread)\b",
    r"\b(?:detail|macro|close-up)\b",
    r"\bon (?:the )?ground\b",
    r"\b(?:queue|exchange)\b",
    r"\beuler\b",
    r"\b\d+\s*[-&/]\s*\d+\b",
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("catalog", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--delay", type=float, default=0.08)
    parser.add_argument(
        "--shared-only",
        action="store_true",
        help="use one broad Commons search per currency and skip per-note queries",
    )
    return parser.parse_args()


def api_search(query: str, *, limit: int = 24) -> list[dict]:
    params = {
        "action": "query",
        "generator": "search",
        "gsrsearch": query,
        "gsrnamespace": "6",
        "gsrlimit": str(limit),
        "prop": "imageinfo",
        "iiprop": "url|mime|extmetadata",
        # Wikimedia enforces standard thumbnail widths since 2026. Requesting
        # 500 also avoids the API returning a smaller, non-standard original
        # URL which upload.wikimedia.org now rejects for hotlinking.
        "iiurlwidth": "500",
        "format": "json",
        "formatversion": "2",
        "origin": "*",
    }
    request = urllib.request.Request(
        f"{API}?{urllib.parse.urlencode(params)}",
        headers={"User-Agent": USER_AGENT},
    )
    for attempt in range(2):
        try:
            with urllib.request.urlopen(
                request, timeout=30, context=TLS_CONTEXT
            ) as response:
                payload = json.load(response)
            return payload.get("query", {}).get("pages", [])
        except HTTPError as exc:
            if exc.code != 429 or attempt == 1:
                raise
            retry_after = float(exc.headers.get("Retry-After", 2 + attempt * 2))
            time.sleep(min(retry_after, 5))
    return []


def normalized_digits(value: str) -> str:
    return re.sub(r"[^0-9]", "", value)


def title_matches_record(title: str, record: dict) -> bool:
    lowered = title.lower()
    if any(re.search(pattern, lowered) for pattern in REJECTED_TITLE_PATTERNS):
        return False
    if not any(
        re.search(pattern, lowered)
        for pattern in CURRENCY_TITLE_PATTERNS[record["currency"]]
    ):
        return False
    numeric_tokens = {
        normalized_digits(match)
        for match in re.findall(r"[0-9][0-9,\.\s]*", lowered)
        if normalized_digits(match)
    }
    expected = {normalized_digits(str(record["value"]))}
    if str(record["value"]).startswith("0."):
        expected.add(normalized_digits(str(record["value"]).split(".", 1)[1]))
    expected.discard("")
    if numeric_tokens.isdisjoint(expected):
        return False
    # The catalog targets current circulation. A year before 1990 in a file
    # title is a strong signal for a historical issue, except when the same
    # four digits are the denomination being searched for.
    for raw_year in re.findall(r"(?<!\d)(?:18|19)\d{2}(?!\d)", lowered):
        if raw_year not in expected and int(raw_year) < 1993:
            return False
    return True


def score(page: dict, record: dict) -> int:
    title = page.get("title", "").lower()
    if not title_matches_record(title, record):
        return -1000
    points = 40
    country = COUNTRY_TERMS[record["currency"]].lower()
    if country.split()[0] in title:
        points += 16
    if record["currency"].lower() in title:
        points += 10
    for token in ("obverse", "front", "avers", "banknote", "note"):
        if token in title:
            points += 4
    for token in (
        "collection",
        "comparison",
        "all banknotes",
        "wallet",
        "monopoly",
    ):
        if token in title:
            points -= 18
    for token in ("provisional", "czechoslovak"):
        if token in title:
            points -= 20
    imageinfo = (page.get("imageinfo") or [{}])[0]
    if not str(imageinfo.get("mime", "")).startswith("image/"):
        return -1000
    return points


def metadata_value(imageinfo: dict, key: str) -> str:
    value = imageinfo.get("extmetadata", {}).get(key, {}).get("value", "")
    return re.sub(r"<[^>]+>", "", value).strip()


def download_image(url: str, destination: Path) -> str:
    data = b""
    for attempt in range(2):
        request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
        try:
            with urllib.request.urlopen(
                request, timeout=60, context=TLS_CONTEXT
            ) as response:
                data = response.read()
            break
        except urllib.error.HTTPError as exc:
            if exc.code != 429 or attempt == 1:
                raise
            retry_after = float(exc.headers.get("Retry-After", 3 + attempt * 3))
            time.sleep(min(retry_after, 5))
    digest = hashlib.sha256(data).hexdigest()
    temporary = destination.with_suffix(".download")
    temporary.write_bytes(data)
    with Image.open(temporary) as image:
        image = image.convert("RGB")
        image.thumbnail((1400, 1400), Image.Resampling.LANCZOS)
        image.save(destination, format="JPEG", quality=90, optimize=True)
    temporary.unlink(missing_ok=True)
    return digest


def main() -> int:
    args = parse_args()
    catalog = json.loads(args.catalog.read_text(encoding="utf-8"))
    records = catalog["banknotes"]
    if args.limit > 0:
        records = records[: args.limit]
    images_dir = args.output / "sources"
    images_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = args.output / "sources.json"
    existing = {}
    if manifest_path.exists():
        for item in json.loads(manifest_path.read_text(encoding="utf-8")).get(
            "sources", []
        ):
            existing[item["id"]] = item

    results: list[dict] = []
    currency_candidates: dict[str, list[dict]] = {}
    for index, record in enumerate(records, start=1):
        item_id = f'{record["currency"]}_{record["minorUnits"]}'
        destination = images_dir / f"{item_id}.jpg"
        if item_id in existing:
            previous = existing[item_id]
            if previous["status"] == "unresolved" or (
                previous["status"] == "downloaded"
                and destination.exists()
                and title_matches_record(previous.get("commonsTitle", ""), record)
            ):
                results.append(previous)
                continue

        country = COUNTRY_TERMS[record["currency"]]
        queries = [
            f'{record["value"]} {country} banknote obverse',
            f'{record["label"]} {country} banknote',
            f'{record["value"]} {record["currencyName"]} note',
        ]
        candidates: dict[str, dict] = {
            page.get("title", ""): page
            for page in currency_candidates.get(record["currency"], [])
        }
        error = ""
        if record["currency"] not in currency_candidates:
            try:
                shared = api_search(f"{country} banknote", limit=50)
                currency_candidates[record["currency"]] = shared
                candidates.update(
                    {page.get("title", ""): page for page in shared}
                )
            except Exception as exc:
                error = str(exc)
            time.sleep(args.delay)
        for query in ([] if args.shared_only else queries):
            current = sorted(
                candidates.values(),
                key=lambda page: score(page, record),
                reverse=True,
            )
            if current and score(current[0], record) >= 55:
                break
            try:
                for page in api_search(query):
                    candidates[page.get("title", "")] = page
            except Exception as exc:  # network failures stay explicit in manifest
                error = str(exc)
            time.sleep(args.delay)
        ranked = sorted(
            candidates.values(), key=lambda page: score(page, record), reverse=True
        )
        selected = ranked[0] if ranked and score(ranked[0], record) >= 35 else None
        if selected is None:
            results.append(
                {
                    "id": item_id,
                    **record,
                    "status": "unresolved",
                    "queries": queries,
                    "error": error or "no sufficiently specific Commons result",
                }
            )
        else:
            imageinfo = selected["imageinfo"][0]
            thumbnail_url = imageinfo.get("thumburl")
            original_url = imageinfo["url"]
            image_url = thumbnail_url or original_url
            try:
                source_sha256 = download_image(image_url, destination)
                results.append(
                    {
                        "id": item_id,
                        **record,
                        "status": "downloaded",
                        "file": destination.relative_to(args.output).as_posix(),
                        "commonsTitle": selected["title"],
                        "descriptionUrl": imageinfo.get("descriptionurl", ""),
                        "imageUrl": image_url,
                        "license": metadata_value(imageinfo, "LicenseShortName"),
                        "artist": metadata_value(imageinfo, "Artist"),
                        "sourceSha256": source_sha256,
                        "queries": queries,
                        "selectionScore": score(selected, record),
                    }
                )
            except Exception as exc:
                results.append(
                    {
                        "id": item_id,
                        **record,
                        "status": "download_failed",
                        "commonsTitle": selected["title"],
                        "descriptionUrl": imageinfo.get("descriptionurl", ""),
                        "error": str(exc),
                        "queries": queries,
                    }
                )
        manifest = {
            "schemaVersion": 1,
            "source": "Wikimedia Commons API",
            "requested": len(records),
            "downloaded": sum(item["status"] == "downloaded" for item in results),
            "sources": results,
        }
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(
            f"[{index}/{len(records)}] {item_id}: {results[-1]['status']}",
            flush=True,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
