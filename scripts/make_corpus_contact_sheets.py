#!/usr/bin/env python3
"""Create labelled contact sheets for human review of corpus sources."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


CELL_WIDTH = 420
CELL_HEIGHT = 280
COLUMNS = 4
ROWS = 4


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path)
    parser.add_argument("output", type=Path)
    return parser.parse_args()


def fit(image: Image.Image, width: int, height: int) -> Image.Image:
    image = image.convert("RGB")
    image.thumbnail((width, height), Image.Resampling.LANCZOS)
    return image


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    sources = [
        source for source in manifest["sources"] if source["status"] == "downloaded"
    ]
    root = args.manifest.parent
    args.output.mkdir(parents=True, exist_ok=True)
    font = ImageFont.load_default(size=16)
    sheet_size = COLUMNS * ROWS
    index = []

    for page_start in range(0, len(sources), sheet_size):
        page = sources[page_start : page_start + sheet_size]
        canvas = Image.new(
            "RGB",
            (CELL_WIDTH * COLUMNS, CELL_HEIGHT * ROWS),
            (235, 235, 235),
        )
        draw = ImageDraw.Draw(canvas)
        for offset, source in enumerate(page):
            column = offset % COLUMNS
            row = offset // COLUMNS
            x = column * CELL_WIDTH
            y = row * CELL_HEIGHT
            with Image.open(root / source["file"]) as raw:
                image = fit(raw, CELL_WIDTH - 20, CELL_HEIGHT - 70)
            image_x = x + (CELL_WIDTH - image.width) // 2
            image_y = y + 42 + (CELL_HEIGHT - 62 - image.height) // 2
            canvas.paste(image, (image_x, image_y))
            draw.rectangle(
                (x, y, x + CELL_WIDTH - 1, y + CELL_HEIGHT - 1),
                outline=(130, 130, 130),
                width=1,
            )
            draw.text((x + 8, y + 7), source["id"], fill=(0, 0, 0), font=font)
            title = source.get("commonsTitle", "").removeprefix("File:")
            draw.text((x + 8, y + 24), title[:48], fill=(60, 60, 60), font=font)

        page_number = page_start // sheet_size + 1
        destination = args.output / f"contact-sheet-{page_number:02d}.jpg"
        canvas.save(destination, "JPEG", quality=88, optimize=True)
        index.append(
            {
                "file": destination.name,
                "sources": [source["id"] for source in page],
            }
        )

    (args.output / "index.json").write_text(
        json.dumps(
            {"sourceCount": len(sources), "sheets": index},
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(f"Created {len(index)} sheets for {len(sources)} sources")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
