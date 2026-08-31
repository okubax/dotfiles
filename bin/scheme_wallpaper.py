#!/usr/bin/env python3
"""
Scheme Wallpaper — a small, from-scratch wallpaper generator built around the
same role-based palette every theme family already uses (bg, bg_alt, fg,
accent, ...) instead of a separate 26-key Catppuccin-shaped schema. A new
family only has to define its palette once (palette.md already documents
it) — those same hex values are copy-pasted straight in here.

Not a rewrite of palette_wallpaper.py, which stays as-is for the five
existing families (Zephyr/Harmattan/Solarized/Nord/Catppuccin). This is a
second, independent tool, used for the Litho/Vellum/Daguerre monochrome
schemes.

Patterns are deliberately few and each tied to one scheme's visual idea:

  dots    — a brick-offset grid of circles, radius modulated by a soft sine
            field, drawn in a handful of flat tones. Litho's poster/ink-plate
            feel: bold shapes, few plates, no gradients.
  bands   — a diagonal gradient across the *whole* bg->fg range, warped by a
            gentle sine ripple so the tonal steps read as soft bands rather
            than one flat ramp. Daguerre's full-tonal-range idea.
  grain   — blurred random noise remapped into a narrow slice of the palette.
            Vellum's soft, no-pure-extremes paper/graphite feel.
  glow    — a radial vignette, accent at the center fading to bg at the
            edges. Used for every family's lockscreen background.

Usage:
  scheme_wallpaper.py --palette litho_dark --pattern dots --output out.png
  scheme_wallpaper.py --list
"""

import argparse
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

WIDTH_DEFAULT = 2560
HEIGHT_DEFAULT = 1600

# Role-based palettes — the exact same hex values as each family's
# palette.md / waybar.css tokens, not a separate schema.
PALETTES = {
    "litho_dark": dict(
        bg="000000", bg_alt="0D0D0D", bg_panel="1A1A1A", bg_panel_alt="262626",
        bg_header="333333", fg="FFFFFF", fg_muted="8C8C8C", border="595959",
        accent="FFFFFF", link="BFBFBF", red="F2F2F2", green="A6A6A6",
        yellow="D9D9D9", purple="737373",
    ),
    "litho_light": dict(
        bg="FFFFFF", bg_alt="F2F2F2", bg_panel="E6E6E6", bg_panel_alt="D9D9D9",
        bg_header="CCCCCC", fg="000000", fg_muted="737373", border="A6A6A6",
        accent="000000", link="404040", red="0D0D0D", green="595959",
        yellow="262626", purple="8C8C8C",
    ),
    "vellum_dark": dict(
        bg="2E2E2E", bg_alt="363636", bg_panel="3E3E3E", bg_panel_alt="464646",
        bg_header="4E4E4E", fg="DCDCDC", fg_muted="8C8C8C", border="5E5E5E",
        accent="E6E6E6", link="C6C6C6", red="D2D2D2", green="B4B4B4",
        yellow="A2A2A2", purple="9E9E9E",
    ),
    "vellum_light": dict(
        bg="E9E9E9", bg_alt="E0E0E0", bg_panel="D6D6D6", bg_panel_alt="CCCCCC",
        bg_header="C2C2C2", fg="333333", fg_muted="7A7A7A", border="AEAEAE",
        accent="262626", link="4E4E4E", red="404040", green="626262",
        yellow="6E6E6E", purple="6A6A6A",
    ),
    "daguerre_dark": dict(
        bg="000000", bg_alt="1A1A1A", bg_panel="333333", bg_panel_alt="4D4D4D",
        bg_header="666666", fg="F5F5F5", fg_muted="8C8C8C", border="7A7A7A",
        accent="FFFFFF", link="E6E6E6", red="D4D4D4", green="B0B0B0",
        yellow="9E9E9E", purple="C2C2C2",
    ),
    "daguerre_light": dict(
        bg="FFFFFF", bg_alt="E5E5E5", bg_panel="CCCCCC", bg_panel_alt="B2B2B2",
        bg_header="999999", fg="0A0A0A", fg_muted="737373", border="858585",
        accent="000000", link="191919", red="2B2B2B", green="4F4F4F",
        yellow="616161", purple="3D3D3D",
    ),
}


def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a: np.ndarray, b: np.ndarray, t: np.ndarray) -> np.ndarray:
    return a + (b - a) * t


def array_to_image(arr: np.ndarray) -> Image.Image:
    return Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), mode="RGB")


# --------------------------------------------------------------------------
# Patterns
# --------------------------------------------------------------------------

def pattern_dots(w: int, h: int, pal: dict, seed: int) -> Image.Image:
    bg = hex_to_rgb(pal["bg"])
    img = Image.new("RGB", (w, h), bg)
    draw = ImageDraw.Draw(img)

    plates = [pal["bg_panel"], pal["bg_panel_alt"], pal["fg_muted"], pal["accent"]]
    plates = [hex_to_rgb(p) for p in plates]

    spacing = max(w, h) // 26
    max_r = spacing * 0.42
    rng = np.random.default_rng(seed)
    # A few low-frequency sine terms decide dot size per cell, so large and
    # small dots cluster instead of a uniform halftone screen.
    fx = rng.uniform(2.0, 4.0, size=3)
    fy = rng.uniform(2.0, 4.0, size=3)
    phase = rng.uniform(0, math.tau, size=3)

    row = 0
    for cy in range(-spacing, h + spacing, spacing):
        offset = (spacing // 2) if row % 2 else 0
        for cx in range(-spacing, w + spacing, spacing * 2):
            x = cx + offset
            nx, ny = x / w, cy / h
            field = sum(
                math.sin(fx[i] * math.tau * nx + fy[i] * math.tau * ny + phase[i])
                for i in range(3)
            ) / 3.0
            size_t = (field + 1) / 2  # 0..1
            r = max_r * (0.15 + 0.85 * size_t)
            if r < 1:
                continue
            plate = plates[int(size_t * (len(plates) - 1e-6))]
            draw.ellipse((x - r, cy - r, x + r, cy + r), fill=plate)
        row += 1

    return img


def pattern_bands(w: int, h: int, pal: dict) -> Image.Image:
    bg = np.array(hex_to_rgb(pal["bg"]), dtype=np.float64)
    fg = np.array(hex_to_rgb(pal["fg"]), dtype=np.float64)

    xs = np.linspace(0.0, 1.0, w)
    ys = np.linspace(0.0, 1.0, h)
    gx, gy = np.meshgrid(xs, ys)

    diagonal = (gx + gy) / 2.0
    ripple = 0.06 * np.sin(diagonal * math.pi * 6)
    t = np.clip(diagonal + ripple, 0.0, 1.0)

    arr = lerp(bg, fg, t[..., None])
    return array_to_image(arr)


def pattern_grain(w: int, h: int, pal: dict, seed: int) -> Image.Image:
    bg = np.array(hex_to_rgb(pal["bg"]), dtype=np.float64)
    top = np.array(hex_to_rgb(pal["bg_header"]), dtype=np.float64)

    rng = np.random.default_rng(seed)
    noise = rng.random((h, w)).astype(np.float32)
    noise_img = Image.fromarray((noise * 255).astype(np.uint8), mode="L")
    noise_img = noise_img.filter(ImageFilter.GaussianBlur(radius=max(w, h) / 60))
    field = np.asarray(noise_img, dtype=np.float64) / 255.0
    field = (field - field.min()) / (field.max() - field.min() + 1e-9)

    arr = lerp(bg, top, field[..., None])
    return array_to_image(arr)


def pattern_grid(w: int, h: int, pal: dict) -> Image.Image:
    bg = hex_to_rgb(pal["bg"])
    line = hex_to_rgb(pal["bg_panel_alt"])
    img = Image.new("RGB", (w, h), bg)
    draw = ImageDraw.Draw(img)
    step = max(w, h) // 40
    for x in range(0, w, step):
        draw.line((x, 0, x, h), fill=line, width=1)
    for y in range(0, h, step):
        draw.line((0, y, w, y), fill=line, width=1)
    return img


def pattern_glow(w: int, h: int, pal: dict) -> Image.Image:
    bg = np.array(hex_to_rgb(pal["bg"]), dtype=np.float64)
    center = np.array(hex_to_rgb(pal["accent"]), dtype=np.float64)

    xs = np.linspace(-1.0, 1.0, w)
    ys = np.linspace(-1.0, 1.0, h) * (h / w)
    gx, gy = np.meshgrid(xs, ys)
    dist = np.sqrt(gx ** 2 + gy ** 2)
    t = np.clip(1.0 - dist / 1.1, 0.0, 1.0) ** 2.2

    arr = lerp(bg, center, t[..., None])
    return array_to_image(arr)


PATTERNS = {
    "dots": lambda w, h, pal, seed: pattern_dots(w, h, pal, seed),
    "bands": lambda w, h, pal, seed: pattern_bands(w, h, pal),
    "grain": lambda w, h, pal, seed: pattern_grain(w, h, pal, seed),
    "grid": lambda w, h, pal, seed: pattern_grid(w, h, pal),
    "glow": lambda w, h, pal, seed: pattern_glow(w, h, pal),
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--palette", choices=sorted(PALETTES), help="Palette to render")
    parser.add_argument("--pattern", choices=sorted(PATTERNS), help="Pattern to render")
    parser.add_argument("--width", type=int, default=WIDTH_DEFAULT)
    parser.add_argument("--height", type=int, default=HEIGHT_DEFAULT)
    parser.add_argument("--seed", type=int, default=0, help="Seed for dots/grain (default: 0)")
    parser.add_argument("--output", help="Output PNG path")
    parser.add_argument("--list", action="store_true", help="List available palettes and patterns")
    args = parser.parse_args()

    if args.list:
        print("Palettes:", ", ".join(sorted(PALETTES)))
        print("Patterns:", ", ".join(sorted(PATTERNS)))
        return 0

    if not args.palette or not args.pattern or not args.output:
        parser.error("--palette, --pattern and --output are required (or use --list)")

    pal = PALETTES[args.palette]
    img = PATTERNS[args.pattern](args.width, args.height, pal, args.seed)

    out = Path(args.output).expanduser()
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out, format="PNG")
    print(f"Wrote {out} ({args.width}x{args.height}, {args.palette}/{args.pattern})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
