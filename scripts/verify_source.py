#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []
NOTES: list[str] = []


def require(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def run(command: list[str], *, stdin: str | None = None) -> None:
    result = subprocess.run(
        command,
        input=stdin,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        ERRORS.append(
            f"Command failed ({' '.join(command)}):\n"
            f"{result.stdout}{result.stderr}"
        )


def check_yaml() -> None:
    for path in [
        ROOT / "pubspec.yaml",
        ROOT / "analysis_options.yaml",
        ROOT / ".github/workflows/ci.yml",
        ROOT / ".github/dependabot.yml",
    ]:
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except Exception as error:  # noqa: BLE001 - QA tool reports all errors.
            ERRORS.append(f"Invalid YAML {path.relative_to(ROOT)}: {error}")


def check_requested_features() -> None:
    catalog = (ROOT / "lib/data/currency_catalog.dart").read_text(encoding="utf-8")
    for code in ["CZK", "EUR", "USD", "GBP", "CHF", "CAD", "AUD"]:
        require(f"code: '{code}'" in catalog, f"Missing currency {code}")

    config = (ROOT / "lib/core/app_config.dart").read_text(encoding="utf-8")
    require("trialOcrScanLimit" not in config, "A Free OCR limit unexpectedly remains")
    require(
        "trialSavedSessionLimit" not in config,
        "A Free saved-session limit unexpectedly remains",
    )
    require(
        "vycetka_full_unlock" in config,
        "One-time ad-free product ID is missing",
    )
    require(
        "retiredMonthlyProductId" in config and "vycetka_ad_free_monthly" in config,
        "Retired monthly entitlement migration ID is missing",
    )
    require(
        "purchaseVerificationUrl" not in config,
        "The client-only lifetime model still requires a receipt backend",
    )
    require("forceAdFree" in config, "Ad-free QA override is missing")

    purchase_service = (ROOT / "lib/services/purchase_service.dart").read_text(
        encoding="utf-8"
    )
    require(
        "adFreeLifetimeProductId" in purchase_service,
        "Purchase service does not offer the lifetime product",
    )
    require(
        "ServerPurchaseVerifier" not in purchase_service,
        "Obsolete project-owned receipt verifier remains active",
    )

    controller = (ROOT / "lib/state/app_controller.dart").read_text(encoding="utf-8")
    require("canUseOcr" not in controller, "Removed OCR capability remains in the controller")
    require(
        "bool canCreateSavedSession() => true" in controller,
        "Free history is not unlimited",
    )
    report = (ROOT / "lib/screens/report_preview_screen.dart").read_text(
        encoding="utf-8"
    )
    require("trialWatermark" not in report, "Free report export remains watermarked")
    require("PaywallScreen" not in report, "Free report export still has a paywall")
    closing_report = (ROOT / "lib/services/closing_report_service.dart").read_text(
        encoding="utf-8"
    )
    require("QrImage" not in closing_report, "QR rendering remains in the closing report")
    require("qrPayload" not in closing_report, "QR payload remains in the closing report")

    gitignore = (ROOT / ".gitignore").read_text(encoding="utf-8")
    require("pubspec.lock" not in gitignore, "App lockfile must not be ignored")

    patcher = (ROOT / "scripts/apply_native_patches.py").read_text(encoding="utf-8")
    require("MinimumOSVersion" in patcher, "iOS framework minimum version patch is missing")
    require("DebugProfile.entitlements" in patcher, "iOS Keychain entitlements are incomplete")
    require("GADApplicationIdentifier" in patcher, "iOS AdMob app ID patch is missing")
    require(
        "com.google.android.gms.ads.APPLICATION_ID" in patcher,
        "Android AdMob app ID patch is missing",
    )
    require(
        "android.permission.RECORD_AUDIO" not in patcher,
        "Unused Android microphone permission remains in the native patcher",
    )
    require(
        'tools:node="remove"' not in patcher,
        "Legacy permission-removal marker remains in the native patcher",
    )

    android = (ROOT / "native/android/MainActivity.kt").read_text(encoding="utf-8")
    ios = (ROOT / "native/ios/AppDelegate.swift").read_text(encoding="utf-8")
    require("cz.vycetka/ocr" not in android and "cz.vycetka/ocr" not in ios, "Removed OCR channel remains")
    require("TextRecognition" not in android, "Android ML Kit bridge remains")
    require("VNRecognizeTextRequest" not in ios, "iOS Vision bridge remains")
    manifest = (ROOT / "android/app/src/main/AndroidManifest.xml").read_text(encoding="utf-8")
    require("android.permission.CAMERA" not in manifest, "Camera permission remains")
    info = (ROOT / "ios/Runner/Info.plist").read_text(encoding="utf-8")
    require("NSCameraUsageDescription" not in info, "iOS camera usage declaration remains")
    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    require(re.search(r"^\s+camera\s*:", pubspec, flags=re.MULTILINE) is None, "Camera dependency remains")


def check_relative_dart_imports() -> None:
    for path in ROOT.glob("lib/**/*.dart"):
        source = path.read_text(encoding="utf-8")
        for match in re.finditer(r"^import\s+'([^']+)';", source, flags=re.MULTILINE):
            target = match.group(1)
            if target.startswith(("package:", "dart:")):
                continue
            resolved = (path.parent / target).resolve()
            require(resolved.exists(), f"Missing import {target} in {path.relative_to(ROOT)}")


def check_delimiters() -> None:
    pairs = {')': '(', ']': '[', '}': '{'}
    openings = set(pairs.values())
    for path in [*ROOT.glob("lib/**/*.dart"), *ROOT.glob("test/**/*.dart")]:
        source = path.read_text(encoding="utf-8")
        stack: list[tuple[str, int]] = []
        quote: str | None = None
        escaped = False
        in_line_comment = False
        in_block_comment = False
        index = 0
        while index < len(source):
            char = source[index]
            next_char = source[index + 1] if index + 1 < len(source) else ""
            if in_line_comment:
                if char == "\n":
                    in_line_comment = False
                index += 1
                continue
            if in_block_comment:
                if char == "*" and next_char == "/":
                    in_block_comment = False
                    index += 2
                else:
                    index += 1
                continue
            if quote is not None:
                if escaped:
                    escaped = False
                elif char == "\\":
                    escaped = True
                elif char == quote:
                    quote = None
                index += 1
                continue
            if char == "/" and next_char == "/":
                in_line_comment = True
                index += 2
                continue
            if char == "/" and next_char == "*":
                in_block_comment = True
                index += 2
                continue
            if char in {"'", '"'}:
                quote = char
            elif char in openings:
                stack.append((char, index))
            elif char in pairs:
                if not stack or stack[-1][0] != pairs[char]:
                    ERRORS.append(f"Unbalanced {char} in {path.relative_to(ROOT)} at {index}")
                    break
                stack.pop()
            index += 1
        if stack:
            ERRORS.append(f"Unclosed delimiter in {path.relative_to(ROOT)} at {stack[-1][1]}")


def check_native_syntax() -> None:
    swiftc = shutil.which("swiftc")
    if swiftc:
        run([swiftc, "-frontend", "-parse", str(ROOT / "native/ios/AppDelegate.swift")])
    else:
        NOTES.append("swiftc unavailable; Swift parse skipped")

    kotlinc = shutil.which("kotlinc")
    if kotlinc:
        result = subprocess.run(
            [kotlinc, str(ROOT / "native/android/MainActivity.kt"), "-d", "/tmp/vycetka-kotlin.jar"],
            text=True,
            capture_output=True,
            check=False,
        )
        # No Android/Flutter classpath exists in this source-only environment.
        # Accept dependency resolution errors, but surface parser-level failures.
        parser_markers = ["expecting", "unexpected tokens", "syntax error"]
        combined = (result.stdout + result.stderr).lower()
        if any(marker in combined for marker in parser_markers):
            ERRORS.append(f"Kotlin parser failure:\n{result.stdout}{result.stderr}")
        else:
            NOTES.append("Kotlin parsed; unresolved Android/Flutter symbols are expected without SDK classpath")
    else:
        NOTES.append("kotlinc unavailable; Kotlin parse skipped")


def check_native_patcher() -> None:
    run([sys.executable, str(ROOT / "scripts/test_native_patcher.py")])


def main() -> int:
    check_yaml()
    check_requested_features()
    check_relative_dart_imports()
    check_delimiters()
    check_native_syntax()
    check_native_patcher()
    if ERRORS:
        print("SOURCE VERIFICATION FAILED")
        for error in ERRORS:
            print(f"- {error}")
        return 1

    print("SOURCE VERIFICATION PASSED")
    for note in NOTES:
        print(f"- {note}")
    print("- Flutter analyze/test/build still require the Flutter SDK and generated platform projects.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
