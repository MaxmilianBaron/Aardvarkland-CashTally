#!/usr/bin/env python3
"""Generate deterministic camera-like OCR variants from source banknotes."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


ROTATIONS = (-20, -12, -6, 6, 12, 20)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("sources", type=Path)
    parser.add_argument("output", type=Path)
    return parser.parse_args()


def canvas(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    # A banknote photographed inside the app guide occupies most of the
    # camera frame. Scale both small web references and large originals to
    # the same deterministic working size before applying camera stresses.
    scale = min(1100 / image.width, 800 / image.height)
    image = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    background = Image.new("RGB", (1280, 960), (205, 205, 205))
    x = (background.width - image.width) // 2
    y = (background.height - image.height) // 2
    background.paste(image, (x, y))
    return background


def perspective(image: Image.Image, direction: str) -> Image.Image:
    width, height = image.size
    amount = 0.00042
    coefficients = {
        "left": (1, amount, -70, 0, 1, 0, 0.00025, 0),
        "right": (1, -amount, 70, 0, 1, 0, -0.00025, 0),
        "top": (1, 0, 0, amount, 1, -70, 0, 0.00025),
        "bottom": (1, 0, 0, -amount, 1, 70, 0, -0.00025),
    }[direction]
    return image.transform(
        (width, height),
        Image.Transform.PERSPECTIVE,
        coefficients,
        resample=Image.Resampling.BICUBIC,
        fillcolor=(205, 205, 205),
    )


def variants(image: Image.Image) -> list[tuple[str, Image.Image]]:
    base = canvas(image)
    output = [("original", base)]
    output.extend(
        (
            f"rotate_{angle:+d}",
            base.rotate(
                angle,
                resample=Image.Resampling.BICUBIC,
                expand=False,
                fillcolor=(205, 205, 205),
            ),
        )
        for angle in ROTATIONS
    )
    output.extend((f"perspective_{name}", perspective(base, name)) for name in (
        "left",
        "right",
        "top",
        "bottom",
    ))
    output.extend(
        [
            ("dark", ImageEnhance.Brightness(base).enhance(0.55)),
            ("bright", ImageEnhance.Brightness(base).enhance(1.45)),
            ("low_contrast", ImageEnhance.Contrast(base).enhance(0.55)),
            ("blur", base.filter(ImageFilter.GaussianBlur(radius=1.8))),
        ]
    )
    return output


def main() -> int:
    args = parse_args()
    source_manifest = json.loads(args.sources.read_text(encoding="utf-8"))
    root = args.sources.parent
    images_dir = args.output / "images"
    images_dir.mkdir(parents=True, exist_ok=True)
    records = []
    downloaded = [
        item for item in source_manifest["sources"] if item["status"] == "downloaded"
    ]
    for index, item in enumerate(downloaded, start=1):
        with Image.open(root / item["file"]) as source:
            for variant_name, image in variants(source):
                filename = f'{item["id"]}__{variant_name}.jpg'
                destination = images_dir / filename
                image.save(destination, "JPEG", quality=82, optimize=True)
                records.append(
                    {
                        "id": f'{item["id"]}__{variant_name}',
                        "sourceId": item["id"],
                        "currency": item["currency"],
                        "minorUnits": item["minorUnits"],
                        "value": item["value"],
                        "recognizer": item["preferredRecognizer"],
                        "variant": variant_name,
                        "file": f"images/{filename}",
                    }
                )
        print(f"[{index}/{len(downloaded)}] {item['id']}: 15 variants")
    manifest = {
        "schemaVersion": 1,
        "sourceCount": len(downloaded),
        "variantCount": len(records),
        "variantsPerSource": 15,
        "variants": records,
    }
    (args.output / "variants.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
