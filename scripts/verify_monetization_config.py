#!/usr/bin/env python3
from __future__ import annotations

import os
import re
import sys
from urllib.parse import urlparse


TEST_PUBLISHER = "ca-app-pub-3940256099942544"


def require(errors: list[str], condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)


def https_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme == "https" and bool(parsed.netloc)


def admob_app_id(value: str) -> bool:
    return bool(re.fullmatch(r"ca-app-pub-\d{16}~\d{10}", value))


def admob_unit_id(value: str) -> bool:
    return bool(re.fullmatch(r"ca-app-pub-\d{16}/\d{10}", value))


def main() -> int:
    errors: list[str] = []
    monetization_enabled = os.environ.get(
        "ENABLE_MONETIZATION", "false"
    ).lower() in {"1", "true", "yes"}
    android_app = os.environ.get("VYCETKA_ADMOB_ANDROID_APP_ID", "")
    ios_app = os.environ.get("VYCETKA_ADMOB_IOS_APP_ID", "")
    android_banner = os.environ.get("ADMOB_ANDROID_BANNER_ID", "")
    ios_banner = os.environ.get("ADMOB_IOS_BANNER_ID", "")
    privacy = os.environ.get("PRIVACY_POLICY_URL", "")
    terms = os.environ.get("TERMS_URL", "")

    if monetization_enabled:
        require(errors, admob_app_id(android_app), "Android AdMob app ID is missing or invalid")
        require(errors, admob_app_id(ios_app), "iOS AdMob app ID is missing or invalid")
        require(errors, admob_unit_id(android_banner), "Android banner ad unit ID is missing or invalid")
        require(errors, admob_unit_id(ios_banner), "iOS banner ad unit ID is missing or invalid")
        for label, value in [
            ("Android AdMob app ID", android_app),
            ("iOS AdMob app ID", ios_app),
            ("Android banner ad unit ID", android_banner),
            ("iOS banner ad unit ID", ios_banner),
        ]:
            require(errors, TEST_PUBLISHER not in value, f"{label} still uses Google's test publisher")

    require(errors, https_url(privacy), "Public HTTPS privacy policy URL is required")
    require(errors, https_url(terms), "Public HTTPS terms URL is required")
    require(
        errors,
        os.environ.get("FORCE_AD_FREE", "").lower() not in {"1", "true", "yes"},
        "FORCE_AD_FREE must not be enabled for a public build",
    )
    require(
        errors,
        os.environ.get("FORCE_FULL", "").lower() not in {"1", "true", "yes"},
        "Legacy FORCE_FULL must not be enabled for a public build",
    )
    if monetization_enabled:
        require(
            errors,
            os.environ.get("ENABLE_ADS", "true").lower() not in {"0", "false", "no"},
            "Ads must be enabled when monetization is enabled",
        )
    else:
        require(
            errors,
            os.environ.get("ENABLE_ADS", "false").lower() in {"0", "false", "no"},
            "ENABLE_ADS must stay disabled for the free launch build",
        )

    if errors:
        print("MONETIZATION CONFIG NOT READY")
        for error in errors:
            print(f"- {error}")
        return 1

    print("PUBLIC CONFIG READY")
    if monetization_enabled:
        print("- Monetization enabled; live purchase and ad checks are still required.")
    else:
        print("- Free launch mode: no ad requests and no purchase UI.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
