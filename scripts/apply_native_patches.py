#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import os
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TEST_ANDROID_ADMOB_APP_ID = "ca-app-pub-3940256099942544~3347511713"
TEST_IOS_ADMOB_APP_ID = "ca-app-pub-3940256099942544~1458002511"


def patch_android() -> None:
    source = ROOT / "native/android/MainActivity.kt"
    target = (
        ROOT
        / "android/app/src/main/kotlin/cz/vycetka/vycetka/MainActivity.kt"
    )
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, target)

    gradle_kts = ROOT / "android/app/build.gradle.kts"
    gradle_groovy = ROOT / "android/app/build.gradle"
    if gradle_kts.exists():
        text = gradle_kts.read_text(encoding="utf-8")
        text = re.sub(
            r"minSdk\s*=\s*flutter\.minSdkVersion",
            "minSdk = 24",
            text,
        )
        gradle_kts.write_text(text, encoding="utf-8")
    elif gradle_groovy.exists():
        text = gradle_groovy.read_text(encoding="utf-8")
        text = re.sub(
            r"minSdkVersion\s+flutter\.minSdkVersion",
            "minSdkVersion 24",
            text,
        )
        gradle_groovy.write_text(text, encoding="utf-8")
    else:
        raise FileNotFoundError("Android app Gradle file was not generated.")

    manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
    text = manifest.read_text(encoding="utf-8")
    # The current app has no camera or microphone workflow. Remove both old
    # declarations, including the tools namespace that was only needed for
    # the former RECORD_AUDIO merger marker.
    text = re.sub(
        r'\s*<uses-permission\s+android:name="android.permission\.(?:CAMERA|RECORD_AUDIO)"[^>]*/>',
        '',
        text,
    )
    text = re.sub(
        r'\s+xmlns:tools="http://schemas.android.com/tools"',
        '',
        text,
    )
    text = re.sub(
        r'android:label="[^"]*"',
        'android:label="Výčetka"',
        text,
        count=1,
    )
    if 'android:allowBackup=' in text:
        text = re.sub(
            r'android:allowBackup="[^"]*"',
            'android:allowBackup="false"',
            text,
            count=1,
        )
    else:
        text = text.replace(
            '<application',
            '<application\n        android:allowBackup="false"',
            1,
        )
    impeller_name = "io.flutter.embedding.android.EnableImpeller"
    if impeller_name not in text:
        application_start = text.index("<application")
        application_open_end = text.index(">", application_start) + 1
        impeller_metadata = (
            '\n        <meta-data\n'
            f'            android:name="{impeller_name}"\n'
            '            android:value="false" />'
        )
        text = (
            text[:application_open_end]
            + impeller_metadata
            + text[application_open_end:]
        )
    admob_name = "com.google.android.gms.ads.APPLICATION_ID"
    admob_app_id = os.environ.get(
        "VYCETKA_ADMOB_ANDROID_APP_ID",
        TEST_ANDROID_ADMOB_APP_ID,
    )
    if admob_name in text:
        text = re.sub(
            rf'(android:name="{re.escape(admob_name)}"\s*\n\s*android:value=")[^"]+("\s*/>)',
            rf"\g<1>{admob_app_id}\g<2>",
            text,
            count=1,
        )
    else:
        application_start = text.index("<application")
        application_open_end = text.index(">", application_start) + 1
        admob_metadata = (
            '\n        <meta-data\n'
            f'            android:name="{admob_name}"\n'
            f'            android:value="{admob_app_id}" />'
        )
        text = (
            text[:application_open_end]
            + admob_metadata
            + text[application_open_end:]
        )
    manifest.write_text(text, encoding="utf-8")


def patch_ios() -> None:
    shutil.copy2(
        ROOT / "native/ios/AppDelegate.swift",
        ROOT / "ios/Runner/AppDelegate.swift",
    )

    info_path = ROOT / "ios/Runner/Info.plist"
    with info_path.open("rb") as handle:
        info = plistlib.load(handle)
    info["CFBundleDisplayName"] = "Výčetka"
    info.pop("NSCameraUsageDescription", None)
    info.pop("NSMicrophoneUsageDescription", None)
    info["GADApplicationIdentifier"] = os.environ.get(
        "VYCETKA_ADMOB_IOS_APP_ID",
        TEST_IOS_ADMOB_APP_ID,
    )
    with info_path.open("wb") as handle:
        plistlib.dump(info, handle, sort_keys=False)

    podfile = ROOT / "ios/Podfile"
    if podfile.exists():
        text = podfile.read_text(encoding="utf-8")
        if re.search(r"^#?\s*platform :ios", text, flags=re.MULTILINE):
            text = re.sub(
                r"^#?\s*platform :ios,\s*'[^']+'",
                "platform :ios, '13.0'",
                text,
                count=1,
                flags=re.MULTILINE,
            )
        else:
            text = "platform :ios, '13.0'\n" + text
        if not re.search(r"^\s*use_frameworks!\s*$", text, flags=re.MULTILINE):
            platform_line = "platform :ios, '13.0'\n"
            text = text.replace(
                platform_line,
                platform_line + "\nuse_frameworks!\n",
                1,
            )
        podfile.write_text(text, encoding="utf-8")

    entitlement_payload = {
        "keychain-access-groups": [],
    }
    # A shared entitlement is applied to all Xcode configurations. The two
    # conventional files are also emitted so future Flutter/plugin templates
    # can switch to per-configuration paths without losing Keychain access.
    for name in [
        "Runner.entitlements",
        "DebugProfile.entitlements",
        "Release.entitlements",
    ]:
        entitlements = ROOT / "ios/Runner" / name
        with entitlements.open("wb") as handle:
            plistlib.dump(entitlement_payload, handle, sort_keys=False)

    framework_info = ROOT / "ios/Flutter/AppFrameworkInfo.plist"
    if framework_info.exists():
        with framework_info.open("rb") as handle:
            framework = plistlib.load(handle)
        framework["MinimumOSVersion"] = "13.0"
        with framework_info.open("wb") as handle:
            plistlib.dump(framework, handle, sort_keys=False)

    project = ROOT / "ios/Runner.xcodeproj/project.pbxproj"
    text = project.read_text(encoding="utf-8")
    text = re.sub(
        r"IPHONEOS_DEPLOYMENT_TARGET = [^;]+;",
        "IPHONEOS_DEPLOYMENT_TARGET = 13.0;",
        text,
    )
    if "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" not in text:
        text = re.sub(
            r"(\n\s*)(PRODUCT_BUNDLE_IDENTIFIER = cz\.vycetka\.vycetka;)",
            r"\1CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\1\2",
            text,
        )
    project.write_text(text, encoding="utf-8")


def main() -> None:
    patch_android()
    patch_ios()
    print("Native platform requirements applied.")


if __name__ == "__main__":
    main()
