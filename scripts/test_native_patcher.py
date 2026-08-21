#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import shutil
import tempfile
from pathlib import Path

import apply_native_patches as patcher

SOURCE_ROOT = Path(__file__).resolve().parents[1]


def write_plist(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("wb") as handle:
        plistlib.dump(payload, handle, sort_keys=False)


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="vycetka-patcher-") as raw_temp:
        root = Path(raw_temp)
        shutil.copytree(SOURCE_ROOT / "native", root / "native")

        gradle = root / "android/app/build.gradle.kts"
        gradle.parent.mkdir(parents=True, exist_ok=True)
        gradle.write_text(
            "android {\n"
            "    defaultConfig {\n"
            "        minSdk = flutter.minSdkVersion\n"
            "    }\n"
            "}\n",
            encoding="utf-8",
        )
        manifest = root / "android/app/src/main/AndroidManifest.xml"
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text(
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
            '    <uses-permission android:name="android.permission.CAMERA" />\n'
            '    <uses-permission android:name="android.permission.RECORD_AUDIO" '\
            'tools:node="remove" />\n'
            '    <application android:label="Runner">\n'
            '        <activity android:name=".MainActivity" />\n'
            "    </application>\n"
            "</manifest>\n",
            encoding="utf-8",
        )

        write_plist(
            root / "ios/Runner/Info.plist",
            {
                "CFBundleDisplayName": "Runner",
                "NSCameraUsageDescription": "legacy",
            },
        )
        write_plist(
            root / "ios/Flutter/AppFrameworkInfo.plist",
            {"MinimumOSVersion": "12.0"},
        )
        (root / "ios/Podfile").write_text(
            "# platform :ios, '12.0'\n",
            encoding="utf-8",
        )
        project = root / "ios/Runner.xcodeproj/project.pbxproj"
        project.parent.mkdir(parents=True, exist_ok=True)
        project.write_text(
            "/* fixture */\n"
            "    IPHONEOS_DEPLOYMENT_TARGET = 12.0;\n"
            "    PRODUCT_BUNDLE_IDENTIFIER = cz.vycetka.vycetka;\n",
            encoding="utf-8",
        )

        original_root = patcher.ROOT
        patcher.ROOT = root
        try:
            patcher.patch_android()
            patcher.patch_ios()
            # Platform patches must remain safe when Flutter regeneration or
            # release automation applies them more than once.
            patcher.patch_android()
            patcher.patch_ios()
        finally:
            patcher.ROOT = original_root

        gradle_text = gradle.read_text(encoding="utf-8")
        assert "minSdk = 24" in gradle_text
        assert "com.google.mlkit" not in gradle_text

        manifest_text = manifest.read_text(encoding="utf-8")
        assert "android.permission.CAMERA" not in manifest_text
        assert "http://schemas.android.com/tools" not in manifest_text
        assert "android.permission.RECORD_AUDIO" not in manifest_text
        assert 'android:label="Výčetka"' in manifest_text
        assert 'android:allowBackup="false"' in manifest_text
        assert patcher.TEST_ANDROID_ADMOB_APP_ID in manifest_text
        assert manifest_text.count("com.google.android.gms.ads.APPLICATION_ID") == 1

        assert (root / "android/app/src/main/kotlin/cz/vycetka/vycetka/MainActivity.kt").exists()
        app_delegate = (root / "ios/Runner/AppDelegate.swift").read_text(
            encoding="utf-8"
        )
        assert "recognitionLanguages" not in app_delegate
        assert "VNRecognizeTextRequest" not in app_delegate
        podfile_text = (root / "ios/Podfile").read_text(encoding="utf-8")
        assert "platform :ios, '13.0'" in podfile_text
        assert podfile_text.count("use_frameworks!") == 1

        project_text = project.read_text(encoding="utf-8")
        assert "IPHONEOS_DEPLOYMENT_TARGET = 13.0;" in project_text
        assert "CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;" in project_text

        framework = plistlib.load(
            (root / "ios/Flutter/AppFrameworkInfo.plist").open("rb"),
        )
        assert framework["MinimumOSVersion"] == "13.0"

        for name in [
            "Runner.entitlements",
            "DebugProfile.entitlements",
            "Release.entitlements",
        ]:
            entitlement = plistlib.load((root / "ios/Runner" / name).open("rb"))
            assert entitlement["keychain-access-groups"] == []

        info = plistlib.load((root / "ios/Runner/Info.plist").open("rb"))
        assert info["CFBundleDisplayName"] == "Výčetka"
        assert "NSCameraUsageDescription" not in info
        assert info["GADApplicationIdentifier"] == patcher.TEST_IOS_ADMOB_APP_ID

    print("NATIVE PATCHER TEST PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
