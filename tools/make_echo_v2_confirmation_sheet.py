#!/usr/bin/env python3
"""Confirmation sheet for the two Echo V2 questions the references cannot settle (brow scar position, loc bead count): unmodified crops of the REVIEW-ONLY round-2 views at the brow and at the locs, magnified (6x brow, 3x hair)
with nearest-neighbour (no new detail is invented), so the owner can point at what is and is not there. Output: assets/characters/hero/frames_proposed/echo_v2_native/confirmation_sheet.png.
usage: tools/make_echo_v2_confirmation_sheet.py"""
import os
from PIL import Image, ImageDraw
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
R = os.path.join(REPO, "assets/approved_anime/review/echo_v2_review/round2_consistency_pass")
V = {"front": "echo_v2_r2_front_530x887_REVIEW_ONLY.webp", "left-facing": "echo_v2_r2_left_facing_434x887_REVIEW_ONLY.png", "right-facing": "echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png", "back": "echo_v2_r2_back_450x887_REVIEW_ONLY.png"}
# crops in source pixels (x0, y0, x1, y1), chosen by inspection of the 887 px sources: brow/forehead for the scar, the whole hair mass for the bead count
BROW = {"front": (240, 45, 345, 105), "left-facing": (110, 55, 215, 125), "right-facing": (225, 45, 305, 115)}
HAIR = {"front": (190, 0, 360, 130), "left-facing": (120, 0, 360, 135), "right-facing": (90, 0, 360, 135), "back": (130, 0, 330, 130)}
def tile(view, box, z):
    im = Image.open(os.path.join(R, V[view])).convert("RGBA"); bg = Image.new("RGBA", im.size, (240, 240, 235, 255)); bg.alpha_composite(im)
    c = bg.convert("RGB").crop(box); return c.resize((c.width * z, c.height * z), Image.NEAREST)
def row(title, boxes, z, d, board, y):
    d.text((8, y), title, fill=(0, 0, 0)); y += 16; x = 8; h = 0
    for v, b in boxes.items():
        t = tile(v, b, z); board.paste(t, (x, y + 14)); d.text((x, y), f"{v} (source px {b})", fill=(60, 60, 60)); x += t.width + 8; h = max(h, t.height)
    return y + h + 30
def main():
    W, H = 2700, 1500; board = Image.new("RGB", (W, H), (255, 255, 255)); d = ImageDraw.Draw(board)
    d.text((8, 4), "ECHO V2 CONFIRMATION SHEET: unmodified crops of the REVIEW-ONLY round-2 views, nearest-neighbour magnified. Nothing here is new art; it shows exactly what the reference does and does not contain.", fill=(0, 0, 0))
    y = row("1. BROW / FOREHEAD (scar position): is there a scar? If yes, which side, where relative to the brow, how long, what angle? Faint specks in the front crop are the only mark found.", BROW, 6, d, board, 24)
    y = row("2. LOC BEADS (count and placement): the hair mass in each view, 3x. Counts differ by view in the reference; the owner confirms the canonical count and which locs carry beads.", HAIR, 3, d, board, y)
    board.crop((0, 0, W, min(H, y))).save(os.path.join(REPO, "assets/characters/hero/frames_proposed/echo_v2_native/confirmation_sheet.png")); print("ok", y)
if __name__ == "__main__": main()
