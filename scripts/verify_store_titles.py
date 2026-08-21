from __future__ import annotations

import csv
from pathlib import Path
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "store_metadata" / "google_play_titles.tsv"
METADATA = ROOT / "fastlane" / "metadata" / "android"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"
IOS_RUNNER = ROOT / "ios" / "Runner"
APP_LOCALES = {
    "ar", "bg", "cs", "da", "de", "el", "en", "es", "et", "fi",
    "fr", "he", "hi", "hr", "hu", "id", "it", "ja", "ko", "lb",
    "lt", "lv", "ms", "mt", "nb", "nl", "pl", "pt", "ru", "sk",
    "sl", "sv", "th", "tr", "uk", "ur",
}


def main() -> int:
    errors: list[str] = []
    with CATALOG.open(encoding="utf-8", newline="") as source:
        rows = list(csv.DictReader(source, delimiter="\t"))

    locales = {row["app_locale"] for row in rows}
    if locales != APP_LOCALES:
        errors.append(
            f"App locale coverage mismatch: missing={sorted(APP_LOCALES - locales)}, "
            f"extra={sorted(locales - APP_LOCALES)}"
        )
    if len(rows) != len(locales):
        errors.append("Duplicate app locale in title catalog")

    expected_play_locales: set[str] = set()
    fallback_locales: set[str] = set()
    for row in rows:
        title = row["title"].strip()
        play_locale = row["play_locale"].strip()
        status = row["status"].strip()
        if not title:
            errors.append(f"{row['app_locale']}: empty title")
        if len(title) > 30:
            errors.append(
                f"{row['app_locale']}: title has {len(title)} characters (max 30)"
            )
        if status == "english_fallback":
            fallback_locales.add(row["app_locale"])
            if play_locale != "-" or title != "Cash Closing & Till Counter":
                errors.append(f"{row['app_locale']}: invalid English fallback")
        else:
            if not play_locale or play_locale == "-":
                errors.append(f"{row['app_locale']}: missing Google Play locale")
            else:
                expected_play_locales.add(play_locale)
                title_file = METADATA / play_locale / "title.txt"
                if not title_file.is_file():
                    errors.append(f"{play_locale}: title.txt is missing")
                elif title_file.read_text(encoding="utf-8").strip() != title:
                    errors.append(f"{play_locale}: title.txt differs from catalog")

        language = row["app_locale"]
        android_dir = "values" if language == "en" else f"values-{language}"
        android_file = ANDROID_RES / android_dir / "strings.xml"
        try:
            android_title = ElementTree.parse(android_file).findtext("string")
        except (OSError, ElementTree.ParseError):
            android_title = None
        if android_title != title:
            errors.append(f"{language}: Android launcher title differs from catalog")

        ios_file = IOS_RUNNER / f"{language}.lproj" / "InfoPlist.strings"
        expected_ios = f'"CFBundleDisplayName" = "{title}";'
        if not ios_file.is_file() or expected_ios not in ios_file.read_text(encoding="utf-8"):
            errors.append(f"{language}: iOS home-screen title differs from catalog")

    actual_play_locales = {
        path.parent.name for path in METADATA.glob("*/title.txt")
    }
    if actual_play_locales != expected_play_locales:
        errors.append(
            "Metadata locale mismatch: "
            f"missing={sorted(expected_play_locales - actual_play_locales)}, "
            f"extra={sorted(actual_play_locales - expected_play_locales)}"
        )
    if fallback_locales != {"lb", "mt"}:
        errors.append(f"Unexpected fallback locales: {sorted(fallback_locales)}")

    if errors:
        print("GOOGLE PLAY TITLE VERIFICATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1
    print(
        "GOOGLE PLAY TITLE VERIFICATION PASSED: "
        f"{len(rows)} app locales, {len(expected_play_locales)} Play listings, "
        "2 English fallbacks, all titles <= 30 characters"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
