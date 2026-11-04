"""Генератор иконки 1024x1024 для TapClicker.

Запуск: python scripts/make_icon.py
Результат: Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png

Рисуем в 2048x2048 и уменьшаем в 2 раза — так края получаются гладкими.
"""

import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"

SIZE = 1024
SS = 2
N = SIZE * SS

BG_TOP = np.array([18, 9, 40], dtype=np.float32) / 255.0
BG_BOTTOM = np.array([66, 18, 126], dtype=np.float32) / 255.0
DISC_A = np.array([255, 183, 74], dtype=np.float32) / 255.0
DISC_B = np.array([238, 22, 92], dtype=np.float32) / 255.0


def smoothstep(edge0, edge1, x):
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def main() -> None:
    grid = np.mgrid[0:N, 0:N].astype(np.float32) / (N - 1)
    y, x = grid

    # --- Фон: диагональный градиент -------------------------------------
    t = np.clip((x * 0.55 + y * 0.65) * 1.1, 0.0, 1.0)[..., None]
    rgb = BG_TOP * (1 - t) + BG_BOTTOM * t

    # Мягкие цветные блики
    g_purple = np.exp(-(((x - 0.16) ** 2 + (y - 0.10) ** 2) / 0.055))
    g_amber = np.exp(-(((x - 0.88) ** 2 + (y - 0.92) ** 2) / 0.09))
    rgb += (g_purple * 0.30)[..., None] * np.array([0.55, 0.28, 1.0], dtype=np.float32)
    rgb += (g_amber * 0.18)[..., None] * np.array([1.0, 0.42, 0.55], dtype=np.float32)

    cx, cy = 0.5, 0.5
    dist = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)

    # --- Кольца «риппл» --------------------------------------------------
    for radius, width, alpha in ((0.441, 0.011, 0.30), (0.353, 0.013, 0.55), (0.279, 0.010, 0.28)):
        ring = alpha * np.exp(-(((dist - radius) / width) ** 2))
        rgb = rgb * (1 - ring[..., None]) + ring[..., None] * 1.0

    # --- Тень под диском -------------------------------------------------
    shadow = smoothstep(0.235, 0.185, np.sqrt((x - cx) ** 2 + (y - (cy + 0.028)) ** 2))
    rgb *= (1 - (shadow * 0.55))[..., None]

    # --- Главный диск ----------------------------------------------------
    disc_r = 0.209
    disc_mask = smoothstep(disc_r + 0.0015, disc_r - 0.0015, dist)

    dt = np.clip(((x - cx + disc_r) / (2 * disc_r) * 0.45 + (y - cy + disc_r) / (2 * disc_r) * 0.55), 0.0, 1.0)
    disc = DISC_A * (1 - dt[..., None]) + DISC_B * dt[..., None]

    # Блик сверху слева
    spec = np.exp(-(((x - (cx - 0.055)) ** 2 + (y - (cy - 0.065)) ** 2) / 0.008))
    disc = disc + (spec * 0.42)[..., None] * (1 - disc)

    # Тёмный низ — объём
    shade = np.exp(-(((x - cx) ** 2 + (y - (cy + 0.115)) ** 2) / 0.02))
    disc = disc * (1 - (shade * 0.30)[..., None])

    # Тонкая светлая кромка
    rim = np.exp(-(((dist - (disc_r - 0.004)) / 0.0035) ** 2))
    disc = disc * (1 - (rim * 0.35)[..., None]) + (rim * 0.35)[..., None] * 1.0

    rgb = rgb * (1 - disc_mask[..., None]) + disc * disc_mask[..., None]

    # --- Белая точка «палец» --------------------------------------------
    dot_r = 0.082
    dot_mask = smoothstep(dot_r + 0.0015, dot_r - 0.0015, dist)
    dot_glow = np.exp(-(((dist - dot_r) / 0.035) ** 2)) * 0.25
    rgb = rgb + dot_glow[..., None] * 1.0
    rgb = rgb * (1 - dot_mask[..., None]) + dot_mask[..., None] * 1.0

    image = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB")

    # --- Искра в правом верхнем углу ------------------------------------
    overlay = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    sx, sy = N * 0.785, N * 0.235
    r_outer, r_inner = N * 0.047, N * 0.012
    vertices = []
    for i in range(8):
        radius = r_outer if i % 2 == 0 else r_inner
        angle = math.radians(i * 45 - 90)
        vertices.append((sx + radius * math.cos(angle), sy + radius * math.sin(angle)))
    draw.polygon(vertices, fill=(255, 255, 255, 250))
    # мягкое свечение вокруг искры
    glow_layer = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    ImageDraw.Draw(glow_layer).ellipse(
        [sx - r_outer * 2.2, sy - r_outer * 2.2, sx + r_outer * 2.2, sy + r_outer * 2.2],
        fill=(255, 240, 255, 70),
    )
    glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(N * 0.018))
    overlay = Image.alpha_composite(glow_layer, overlay)
    overlay = overlay.filter(ImageFilter.GaussianBlur(N * 0.0012))

    image = Image.alpha_composite(image.convert("RGBA"), overlay)

    # --- Уменьшение и сохранение ----------------------------------------
    image = image.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT, "PNG")
    print(f"OK: {OUT}")


if __name__ == "__main__":
    main()
