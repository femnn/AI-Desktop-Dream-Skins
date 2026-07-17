#!/usr/bin/env python3
"""Build a lightweight animated README GIF from a verified Codex home screenshot."""

from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--width", type=int, default=1367)
    args = parser.parse_args()

    with Image.open(args.source) as opened:
        source = opened.convert("RGB")
    height = round(source.height * args.width / source.width)
    base = source.resize((args.width, height), Image.Resampling.LANCZOS)

    # These points stay inside the themed hero, away from native controls and text.
    points = [
        (0.30, 0.13, 0.8),
        (0.43, 0.21, 1.0),
        (0.57, 0.10, 0.7),
        (0.71, 0.17, 1.1),
        (0.84, 0.11, 0.8),
        (0.92, 0.28, 1.0),
        (0.48, 0.33, 0.7),
        (0.62, 0.29, 0.9),
    ]
    rgba_base = base.convert("RGBA")
    frames: list[Image.Image] = []
    frame_count = 12
    for index in range(frame_count):
        glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(glow)
        for point_index, (nx, ny, weight) in enumerate(points):
            phase = 2 * math.pi * (index / frame_count + point_index / len(points))
            strength = max(0.0, math.sin(phase)) ** 2
            radius = 2.0 + 4.5 * strength * weight
            alpha = round(30 + 150 * strength)
            x, y = nx * base.width, ny * base.height
            draw.ellipse(
                (x - radius, y - radius, x + radius, y + radius),
                fill=(105, 226, 255, alpha),
            )
        glow = glow.filter(ImageFilter.GaussianBlur(radius=2.2))
        frames.append(Image.alpha_composite(rgba_base, glow).convert("RGB"))

    palette = frames[0].convert("P", palette=Image.Palette.ADAPTIVE, colors=255)
    indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    indexed[0].save(
        args.output,
        save_all=True,
        append_images=indexed[1:],
        duration=140,
        loop=0,
        disposal=2,
        optimize=True,
    )
    print(f"created={args.output} frames={frame_count} size={args.output.stat().st_size}")


if __name__ == "__main__":
    main()
