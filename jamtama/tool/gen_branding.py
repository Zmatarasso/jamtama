"""Generates placeholder app icon + splash for Royal Ruckus.

Design:  two R's facing each other (red left, blue right, mirrored)
inside a stylised wrestling ring. Run once; commits the outputs
under assets/branding/.

    python tool/gen_branding.py
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# ---- Palette ---------------------------------------------------------------
BG_DARK     = (24, 14, 10)         # near-black brown
BG_MID      = (43, 24, 16)         # game background
GOLD        = (212, 175, 55)
GOLD_DIM    = (139, 105, 20)
RED         = (220, 20, 60)        # crimson
RED_DEEP    = (140, 10, 35)
BLUE        = (65, 105, 225)       # royal blue
BLUE_DEEP   = (30, 50, 140)
MAT         = (180, 60, 60)        # ring mat (red canvas)
MAT_DARK    = (110, 30, 30)
ROPE_RED    = (210, 70, 70)
ROPE_WHITE  = (235, 235, 225)
ROPE_BLUE   = (80, 110, 210)
POST_CHROME = (230, 225, 210)

BOLD_FONT   = "C:/Windows/Fonts/arialbd.ttf"
IMPACT_FONT = "C:/Windows/Fonts/impact.ttf"


def _ring(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int):
    """Draws a simple front-view wrestling ring centred at (cx, cy)."""
    half = size // 2

    # Apron (skirt under the ring) — trapezoid
    apron_top_y    = cy + int(half * 0.15)
    apron_bot_y    = cy + int(half * 0.85)
    apron_top_lx   = cx - int(half * 0.95)
    apron_top_rx   = cx + int(half * 0.95)
    apron_bot_lx   = cx - int(half * 1.05)
    apron_bot_rx   = cx + int(half * 1.05)
    draw.polygon([
        (apron_top_lx, apron_top_y),
        (apron_top_rx, apron_top_y),
        (apron_bot_rx, apron_bot_y),
        (apron_bot_lx, apron_bot_y),
    ], fill=MAT_DARK, outline=GOLD_DIM)

    # Ring mat (top surface) — parallelogram for slight perspective
    mat_top_y = cy - int(half * 0.15)
    mat_bot_y = apron_top_y
    mat_top_lx = cx - int(half * 0.85)
    mat_top_rx = cx + int(half * 0.85)
    mat_bot_lx = apron_top_lx
    mat_bot_rx = apron_top_rx
    draw.polygon([
        (mat_top_lx, mat_top_y),
        (mat_top_rx, mat_top_y),
        (mat_bot_rx, mat_bot_y),
        (mat_bot_lx, mat_bot_y),
    ], fill=MAT, outline=GOLD)

    # Corner posts — four vertical chrome bars at the corners of the mat
    post_w = max(6, size // 40)
    post_h = int(half * 0.55)
    post_top = mat_top_y - post_h
    for (px, py_bottom) in [
        (mat_top_lx, mat_top_y),
        (mat_top_rx, mat_top_y),
        (mat_bot_lx, mat_bot_y),
        (mat_bot_rx, mat_bot_y),
    ]:
        draw.rectangle(
            [px - post_w // 2, py_bottom - post_h,
             px + post_w // 2, py_bottom],
            fill=POST_CHROME, outline=GOLD_DIM,
        )
        # Post cap
        cap_r = post_w
        draw.ellipse(
            [px - cap_r, py_bottom - post_h - cap_r,
             px + cap_r, py_bottom - post_h + cap_r],
            fill=GOLD, outline=GOLD_DIM,
        )

    # Ropes — three horizontal bands across the front face of the ring
    rope_colors = [ROPE_RED, ROPE_WHITE, ROPE_BLUE]
    rope_thickness = max(3, size // 100)
    # Ropes span between the front two posts (top-left & top-right of mat)
    for i, colour in enumerate(rope_colors):
        y = mat_top_y - post_h + int(post_h * (0.3 + i * 0.22))
        draw.line(
            [(mat_top_lx, y), (mat_top_rx, y)],
            fill=colour, width=rope_thickness,
        )
        # Side ropes (left + right) for depth
        draw.line(
            [(mat_top_lx, y), (mat_bot_lx, y + int(post_h * 0.08))],
            fill=colour, width=rope_thickness,
        )
        draw.line(
            [(mat_top_rx, y), (mat_bot_rx, y + int(post_h * 0.08))],
            fill=colour, width=rope_thickness,
        )

    return {
        "mat_top_y": mat_top_y,
        "mat_bot_y": mat_bot_y,
        "mat_top_lx": mat_top_lx,
        "mat_top_rx": mat_top_rx,
    }


def _letter_r(img: Image.Image, font_path: str, font_size: int,
              colour, outline, cx: int, cy: int, mirror: bool):
    """Draws a big, outlined R centred at (cx, cy), optionally mirrored."""
    # Render R on a transparent canvas large enough to hold the glyph,
    # then composite it (mirrored or not) onto the main image.
    font = ImageFont.truetype(font_path, font_size)
    pad = font_size // 4
    canvas = Image.new("RGBA", (font_size + pad * 2, font_size + pad * 2),
                       (0, 0, 0, 0))
    d = ImageDraw.Draw(canvas)
    # Outline — draw the text multiple times offset to fake a stroke
    stroke_w = max(3, font_size // 28)
    d.text((pad, pad // 2), "R", font=font, fill=colour,
           stroke_width=stroke_w, stroke_fill=outline)

    if mirror:
        canvas = canvas.transpose(Image.FLIP_LEFT_RIGHT)

    # Drop shadow for punch
    shadow = canvas.split()[-1].filter(ImageFilter.GaussianBlur(font_size // 40))
    shadow_img = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_img.putalpha(shadow)
    bbox = canvas.getbbox()
    if bbox is None:
        return
    w, h = canvas.size
    top_left = (cx - w // 2, cy - h // 2)
    img.alpha_composite(shadow_img, (top_left[0] + stroke_w,
                                     top_left[1] + stroke_w))
    img.alpha_composite(canvas, top_left)


def _gold_ring(draw: ImageDraw.ImageDraw, size: int):
    """Gold border ring around the whole image."""
    b = size // 28
    draw.rectangle([b, b, size - b, size - b],
                   outline=GOLD, width=max(3, size // 180))
    draw.rectangle([b * 2, b * 2, size - b * 2, size - b * 2],
                   outline=GOLD_DIM, width=max(2, size // 340))


def _banner(draw: ImageDraw.ImageDraw, text: str, size: int, y: int,
            font_path: str, font_size: int):
    font = ImageFont.truetype(font_path, font_size)
    tb = draw.textbbox((0, 0), text, font=font)
    w = tb[2] - tb[0]
    h = tb[3] - tb[1]
    x = (size - w) // 2 - tb[0]
    # Banner background
    pad_x = size // 20
    pad_y = size // 80
    draw.rounded_rectangle(
        [x - pad_x, y - pad_y, x + w + pad_x, y + h + pad_y],
        radius=size // 60, fill=BG_DARK, outline=GOLD, width=max(2, size // 400),
    )
    draw.text((x, y - tb[1]), text, font=font, fill=GOLD,
              stroke_width=max(2, size // 600), stroke_fill=BG_DARK)


def render(size: int, *, splash: bool) -> Image.Image:
    img = Image.new("RGBA", (size, size), BG_MID + (255,))
    draw = ImageDraw.Draw(img)

    # Subtle radial-ish vignette
    vignette = Image.new("L", (size, size), 0)
    vd = ImageDraw.Draw(vignette)
    vd.ellipse([-size // 4, -size // 4, size + size // 4, size + size // 4],
               fill=255)
    vignette = vignette.filter(ImageFilter.GaussianBlur(size // 8))
    bg_dark = Image.new("RGBA", (size, size), BG_DARK + (255,))
    img = Image.composite(img, bg_dark, vignette)
    draw = ImageDraw.Draw(img)

    if splash:
        # Splash: ring smaller, centred, leaves room for banner.
        ring_size = int(size * 0.70)
        cx, cy = size // 2, int(size * 0.52)
    else:
        # Icon: ring fills more of the canvas.
        ring_size = int(size * 0.88)
        cx, cy = size // 2, int(size * 0.54)

    _ring(draw, cx, cy, ring_size)

    # Letters — positioned on top of the mat, side-by-side facing each other.
    letter_size = int(ring_size * 0.42)
    offset_x = int(ring_size * 0.19)
    letter_y = cy + int(ring_size * 0.14)

    # Red R on left, facing right (mirrored so opening faces inward)
    _letter_r(img, IMPACT_FONT, letter_size, RED, RED_DEEP,
              cx - offset_x, letter_y, mirror=True)
    # Blue R on right, normal orientation (opening faces inward / left)
    _letter_r(img, IMPACT_FONT, letter_size, BLUE, BLUE_DEEP,
              cx + offset_x, letter_y, mirror=False)

    # Gold border
    draw = ImageDraw.Draw(img)
    _gold_ring(draw, size)

    # Title banner (splash only — icon stays uncluttered)
    if splash:
        _banner(draw, "ROYAL RUCKUS", size,
                y=int(size * 0.09),
                font_path=IMPACT_FONT,
                font_size=size // 14)

    return img


def main():
    out_dir = Path(__file__).resolve().parent.parent / "assets" / "branding"
    out_dir.mkdir(parents=True, exist_ok=True)

    icon = render(1024, splash=False)
    icon.save(out_dir / "icon.png", "PNG")
    print(f"wrote {out_dir / 'icon.png'}")

    # Foreground-only variant for Android adaptive icon (same art, padded)
    icon_fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    small = render(700, splash=False).resize((700, 700), Image.LANCZOS)
    icon_fg.paste(small, (162, 162), small)
    icon_fg.save(out_dir / "icon_foreground.png", "PNG")
    print(f"wrote {out_dir / 'icon_foreground.png'}")

    splash = render(2048, splash=True)
    splash.save(out_dir / "splash.png", "PNG")
    print(f"wrote {out_dir / 'splash.png'}")


if __name__ == "__main__":
    main()
