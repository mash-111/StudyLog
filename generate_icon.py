"""
StudyLog App Icon Generator
Design: 時計 × 本 (Clock + Book)
"""

from PIL import Image, ImageDraw
import math
import os

SIZE = 1024
OUT_DIR = "StudyLog/Assets.xcassets/AppIcon.appiconset"


def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.ellipse([x0, y0, x0 + radius * 2, y0 + radius * 2], fill=fill)
    draw.ellipse([x1 - radius * 2, y0, x1, y0 + radius * 2], fill=fill)
    draw.ellipse([x0, y1 - radius * 2, x0 + radius * 2, y1], fill=fill)
    draw.ellipse([x1 - radius * 2, y1 - radius * 2, x1, y1], fill=fill)


def draw_book(draw, cx, cy, w, h, cover_color, spine_color, page_color, line_color):
    """Open book viewed slightly from front"""
    half = w // 2
    # Left page
    lx0, ly0 = cx - half, cy - h // 2
    lx1, ly1 = cx, cy + h // 2
    draw.polygon([(lx0, ly0 + 20), (lx1, ly0), (lx1, ly1), (lx0, ly1 + 20)], fill=cover_color)
    # Right page
    rx0, ry0 = cx, cy - h // 2
    rx1, ry1 = cx + half, cy + h // 2
    draw.polygon([(rx0, ry0), (rx1, ry0 + 20), (rx1, ry1 + 20), (rx0, ry1)], fill=page_color)
    # Spine (center line)
    draw.line([(cx, cy - h // 2), (cx, cy + h // 2)], fill=spine_color, width=8)
    # Lines on left page (text lines)
    for i in range(1, 5):
        y = ly0 + 30 + i * (h // 6)
        indent = 20 + i * 4
        draw.line([(lx0 + indent, y), (lx1 - 20, y)], fill=line_color, width=6)
    # Lines on right page
    for i in range(1, 5):
        y = ry0 + 30 + i * (h // 6)
        draw.line([(rx0 + 20, y), (rx1 - 30 - i * 3, y)], fill=line_color, width=6)


def draw_clock(draw, cx, cy, r, face_color, rim_color, hand_color, mark_color):
    """Analog clock face"""
    # Outer ring (shadow/depth)
    draw.ellipse([cx - r - 8, cy - r - 8, cx + r + 8, cy + r + 8], fill=rim_color)
    # Clock face
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=face_color)
    # Hour marks
    for i in range(12):
        angle = math.radians(i * 30 - 90)
        if i % 3 == 0:
            r_in, r_out, lw = r - 22, r - 6, 8
        else:
            r_in, r_out, lw = r - 14, r - 6, 5
        x1 = cx + math.cos(angle) * r_in
        y1 = cy + math.sin(angle) * r_in
        x2 = cx + math.cos(angle) * r_out
        y2 = cy + math.sin(angle) * r_out
        draw.line([(x1, y1), (x2, y2)], fill=mark_color, width=lw)
    # Hour hand (pointing to ~10)
    h_angle = math.radians(10 * 30 - 90)
    hx = cx + math.cos(h_angle) * (r * 0.5)
    hy = cy + math.sin(h_angle) * (r * 0.5)
    draw.line([(cx, cy), (hx, hy)], fill=hand_color, width=14)
    # Minute hand (pointing to ~2)
    m_angle = math.radians(2 * 30 - 90)
    mx = cx + math.cos(m_angle) * (r * 0.72)
    my = cy + math.sin(m_angle) * (r * 0.72)
    draw.line([(cx, cy), (mx, my)], fill=hand_color, width=9)
    # Center dot
    draw.ellipse([cx - 10, cy - 10, cx + 10, cy + 10], fill=hand_color)


def make_icon(bg_color, book_cover, book_spine, book_page, book_line,
              clock_face, clock_rim, clock_hand, clock_mark):
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background (iOS clips to rounded rect, but include slight rounding for preview)
    draw.rectangle([0, 0, SIZE, SIZE], fill=bg_color)

    # Book: lower-center area
    bk_cx, bk_cy = SIZE // 2, int(SIZE * 0.62)
    bk_w, bk_h = 520, 320
    draw_book(draw, bk_cx, bk_cy, bk_w, bk_h,
              book_cover, book_spine, book_page, book_line)

    # Clock: upper-center, slightly overlapping book top
    cl_cx, cl_cy = SIZE // 2, int(SIZE * 0.40)
    cl_r = 175
    draw_clock(draw, cl_cx, cl_cy, cl_r,
               clock_face, clock_rim, clock_hand, clock_mark)

    return img


os.makedirs(OUT_DIR, exist_ok=True)

# ── Light (Universal) ──────────────────────────────────────────
# Deep navy background, warm white clock, cream book
light = make_icon(
    bg_color=(22, 42, 90),          # deep navy
    book_cover=(255, 210, 100),     # warm amber cover
    book_spine=(180, 130, 40),      # dark amber spine
    book_page=(255, 245, 220),      # cream pages
    book_line=(180, 160, 120),      # muted tan lines
    clock_face=(245, 248, 255),     # near-white face
    clock_rim=(100, 130, 200),      # blue rim
    clock_hand=(22, 42, 90),        # navy hands
    clock_mark=(80, 110, 180),      # blue marks
)
light.save(f"{OUT_DIR}/AppIcon.png")
print("Saved AppIcon.png (light)")

# ── Dark ───────────────────────────────────────────────────────
# Very dark navy, softer glow colors
dark = make_icon(
    bg_color=(10, 18, 42),          # darker navy
    book_cover=(200, 160, 60),      # muted amber
    book_spine=(130, 95, 25),
    book_page=(220, 210, 180),
    book_line=(150, 135, 100),
    clock_face=(30, 40, 70),        # dark face
    clock_rim=(50, 70, 130),
    clock_hand=(180, 210, 255),     # light blue hands
    clock_mark=(120, 160, 230),
)
dark.save(f"{OUT_DIR}/AppIcon-dark.png")
print("Saved AppIcon-dark.png (dark)")

# ── Tinted (monochrome) ────────────────────────────────────────
tinted = make_icon(
    bg_color=(60, 60, 60),
    book_cover=(200, 200, 200),
    book_spine=(120, 120, 120),
    book_page=(240, 240, 240),
    book_line=(160, 160, 160),
    clock_face=(235, 235, 235),
    clock_rim=(140, 140, 140),
    clock_hand=(50, 50, 50),
    clock_mark=(100, 100, 100),
)
tinted.save(f"{OUT_DIR}/AppIcon-tinted.png")
print("Saved AppIcon-tinted.png (tinted)")

print("Done!")
