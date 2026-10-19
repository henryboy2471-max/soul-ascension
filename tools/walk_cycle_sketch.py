#!/usr/bin/env python3
"""Pose sketches, contact sheets and old-vs-new motion comparisons for the proposed walk/run cycles.
These are GUIDES for the artist (stick figures over the approved idle silhouette), not game art, and nothing here is wired into the game.
usage: tools/walk_cycle_sketch.py [set ...]      sets: echo_walk echo_run mira_walk mira_run (default: all)
Writes <character>/frames_proposed/<walk|run>/{sketch_00..07.png, contact_sheet.png, params.json, compare_<speed>.gif}.
Final art dropped next to them as walk_00..07.png / run_00..07.png is checked with tools/measure_foot_travel.py (see docs/overnight/WALK_CYCLE_FRAME_SPEC.md)."""
import glob, json, math, os, sys
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters")
# screen_scale = world_height / canvas_height of the idle frame x the node scale 1.2 (scripts/combat/fighter.gd attach_frames, scripts/world/explore.gd).
# Echo's idle canvas stays 108 high, so a 216-high walk canvas needs a per-animation scale of 0.5 when it is wired in (not done yet).
# Echo V2 (owner-approved design authority, REVIEW-ONLY reference art): the ghost under Echo guides is its right-facing view fitted to the figure height. The in-game Echo sprites are the superseded old design.
V2_SIDE = ("../approved_anime/review/echo_v2_review/round2_consistency_pass/echo_v2_r2_right_facing_360x887_REVIEW_ONLY.png", 0)
SETS = {
    "echo_walk": dict(char="hero", anim="walk", canvas=(272, 216), fig=190, scale=170 / 108 * 1.2 * 0.5, fps=8, speed=90.0, kind="walk",
                      old=("hero/frames_aligned", "walk", 5.3, 170 / 108 * 1.2), idle=V2_SIDE),
    "echo_run": dict(char="hero", anim="run", canvas=(480, 216), fig=190, scale=170 / 108 * 1.2 * 0.5, fps=12, speed=300.0, kind="run",
                     old=("hero/frames_aligned", "walk", 10.0, 170 / 108 * 1.2), idle=V2_SIDE),
    "mira_walk": dict(char="mira", anim="walk", canvas=(258, 153), fig=139, scale=155 / 153 * 1.2, fps=8, speed=90.0, kind="walk",
                      old=("mira/frames_aligned", "run", 7.4, 155 / 153 * 1.2), idle=("mira/frames/idle_00.png", 1)),
    "mira_run": dict(char="mira", anim="run", canvas=(258, 153), fig=139, scale=155 / 153 * 1.2, fps=12, speed=300.0, kind="run",
                     old=("mira/frames_aligned", "run", 14.0, 155 / 153 * 1.2), idle=("mira/frames/idle_00.png", 1)),
}
WALK_NAMES = ["1 contact", "2 down", "3 passing", "4 up", "5 contact", "6 down", "7 passing", "8 up"]
RUN_NAMES = ["1 contact", "2 mid-stance", "3 AIR (toe-off)", "4 AIR (reach)", "5 contact", "6 mid-stance", "7 AIR (toe-off)", "8 AIR (reach)"]

def per_frame_travel(s):  # source px a planted foot must move back per frame
    return s["speed"] / (s["scale"] * s["fps"])

def leg_targets(s, k):
    """foot (x offset from the pelvis in source px, lift in source px) of the leg whose cycle phase is k (0..7)."""
    p = per_frame_travel(s); fig = s["fig"]
    if s["kind"] == "walk":
        c = 2 * p   # planted foot goes +c .. -c over 4 frames
        x = [c, c / 2, 0, -c / 2, -c, -c / 2, 0, c / 2][k % 8]; lift = [0, 0, 0, 0, 0, .35, 1.0, .45][k % 8] * 0.09 * fig
    else:
        c = p       # +c then 0 over the one ground step; the foot leaves the ground at -c
        x = [c, 0, -c, -2.3 * c, -1.4 * c, 0, 1.4 * c, 1.9 * c][k % 8]; lift = [0, 0, .12, .7, 1.0, .75, .3, .08][k % 8] * 0.28 * fig
    return x, lift

def pelvis_up(s, i):  # px the pelvis is above its mean height
    L = 0.50 * s["fig"]
    walk = [0, -.02, 0, .02]; run = [0, -.06, 0, .07]
    return (walk if s["kind"] == "walk" else run)[i % 4] * L

def two_bone(h, f, l1, l2):
    dx, dy = f[0] - h[0], f[1] - h[1]; d = max(1e-6, min(math.hypot(dx, dy), (l1 + l2) * 0.999))
    ux, uy = dx / math.hypot(dx, dy), dy / math.hypot(dx, dy); a = (l1 * l1 - l2 * l2 + d * d) / (2 * d); hh = math.sqrt(max(0.0, l1 * l1 - a * a))
    px, py = -uy, ux
    if px < 0: px, py = -px, -py   # knee bends forward
    return (h[0] + ux * a + px * hh, h[1] + uy * a + py * hh)

def pose(s, i):
    W, H = s["canvas"]; fig = s["fig"]; L = 0.50 * fig; gy = H - 1; cx = W / 2
    hip = (cx, gy - 0.97 * L - pelvis_up(s, i))
    run = s["kind"] == "run"; lean = math.radians(10 if run else 1)
    sh = (hip[0] + math.sin(lean) * 0.31 * fig, hip[1] - math.cos(lean) * 0.31 * fig)
    head = (sh[0] + math.sin(lean) * 0.115 * fig, sh[1] - 0.115 * fig)
    legs = []
    for ph in (i, i + 4):
        x, lift = leg_targets(s, ph); legs.append((cx + x, gy - lift, lift <= 0.01))
    arms = []
    for ph in (i + 4, i):   # an arm swings opposite its leg
        x, _ = leg_targets(s, ph); amp = (55 if run else 22); ref = leg_targets(s, 0)[0] or 1.0
        ang = math.radians(max(-1.0, min(1.0, x / (abs(ref) * (1.9 if run else 1)))) * amp); bend = math.radians(85 if run else 18)
        el = (sh[0] + math.sin(ang) * 0.16 * fig, sh[1] + math.cos(ang) * 0.16 * fig)
        ha = (el[0] + math.sin(ang + bend) * 0.15 * fig, el[1] + math.cos(ang + bend) * 0.15 * fig); arms.append((el, ha))
    return dict(hip=hip, shoulder=sh, head=head, legs=legs, arms=arms, l=L)

def draw_pose(d, s, i, k=1.0, ox=0, oy=0):
    P = pose(s, i); lw = max(2, int(round(3 * k * s["canvas"][0] / 272))) if False else max(2, int(3 * k))
    def t(p): return ((p[0]) * k + ox, (p[1]) * k + oy)
    for n, (fx, fy, planted) in enumerate(P["legs"]):
        col = (60, 140, 255, 255) if n == 0 else (255, 150, 40, 255); l1 = l2 = P["l"] * 0.5
        knee = two_bone(P["hip"], (fx, fy), l1, l2)
        d.line([t(P["hip"]), t(knee), t((fx, fy))], fill=col, width=lw)
        d.line([t((fx, fy)), t((fx + 0.14 * s["fig"], fy))], fill=col, width=lw)
        if planted: d.ellipse([t((fx - 3, fy - 3))[0], t((fx - 3, fy - 3))[1], t((fx + 3, fy + 3))[0], t((fx + 3, fy + 3))[1]], fill=(40, 200, 80, 255))
    d.line([t(P["hip"]), t(P["shoulder"])], fill=(90, 90, 90, 255), width=lw + 1)
    for (el, ha), col in zip(P["arms"], [(255, 150, 40, 200), (60, 140, 255, 200)]):
        d.line([t(P["shoulder"]), t(el), t(ha)], fill=col, width=max(1, lw - 1))
    r = 0.06 * s["fig"]; hx, hy = P["head"]
    d.ellipse([t((hx - r, hy - r))[0], t((hx - r, hy - r))[1], t((hx + r, hy + r))[0], t((hx + r, hy + r))[1]], outline=(90, 90, 90, 255), width=lw)
    return P

def idle_ghost(s):
    path, up = s["idle"]; im = Image.open(os.path.join(ROOT, path)).convert("RGBA"); W, H = s["canvas"]
    if up == 0:   # fit a reference figure to the guide's figure height
        im = im.crop(im.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()); k = s["fig"] / im.height; im = im.resize((max(1, round(im.width * k)), s["fig"]), Image.LANCZOS)
    elif up != 1: im = im.resize((im.width * up, im.height * up), Image.NEAREST)
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0)); g.alpha_composite(im, ((W - im.width) // 2, H - im.height))
    g.putalpha(g.getchannel("A").point(lambda v: int(v * 0.28))); return g

def sketch_frame(s, i, ghost, plain=True):
    W, H = s["canvas"]; im = Image.new("RGBA", (W, H), (250, 250, 246, 255) if plain else (0, 0, 0, 0)); d = ImageDraw.Draw(im)
    im.alpha_composite(ghost)
    if plain: d.line([(0, H - 1), (W, H - 1)], fill=(120, 120, 120, 255)); d.line([(W // 2, 0), (W // 2, H)], fill=(210, 80, 80, 255), width=1)
    draw_pose(d, s, i); return im

def contact_sheet(s, frames, names):
    W, H = s["canvas"]; cols = 4; sc = 1.0 if W <= 280 else 0.8; cw, ch = int(W * sc), int(H * sc) + 30
    sheet = Image.new("RGB", (cols * cw, 2 * ch + 24), (255, 255, 255)); d = ImageDraw.Draw(sheet)
    d.text((6, 4), f"{s['char']} {s['anim']}: {s['canvas'][0]}x{s['canvas'][1]}, 8 frames at {s['fps']} fps, {s['speed']:.0f} px/s, screen scale {s['scale']:.3f}, planted foot moves back {per_frame_travel(s):.2f} source px per frame (blue = leg A, orange = leg B, green = planted, red = pelvis axis)", fill=(0, 0, 0))
    for i, f in enumerate(frames):
        x, y = (i % cols) * cw, 24 + (i // cols) * ch; sheet.paste(f.convert("RGB").resize((cw, ch - 30)), (x, y + 28))
        xa = leg_targets(s, i)[0]; xb = leg_targets(s, i + 4)[0]
        d.text((x + 4, y + 2), f"{names[i]}", fill=(0, 0, 0)); d.text((x + 4, y + 14), f"A {xa:+.1f}  B {xb:+.1f} px from pelvis", fill=(60, 60, 60))
    return sheet

def old_frames(s):
    folder, anim, fps, sc = s["old"]; files = sorted(glob.glob(os.path.join(ROOT, folder, f"{anim}_*.png")))
    return [Image.open(f).convert("RGBA") for f in files], fps, sc

def panel(img_fn, sc, W, H, speed, t, label):
    """one panel at on-screen size: ground ticks scroll left at `speed`, the pelvis stays at the centre."""
    pw, ph = int(W * sc), int(H * sc) + 22; im = Image.new("RGB", (pw, ph), (250, 250, 246)); d = ImageDraw.Draw(im)
    gy = ph - 2 - 0; d.line([(0, gy), (pw, gy)], fill=(120, 120, 120)); off = (speed * t) % 60.0
    n = -1
    for x in range(int(pw / 60) + 3):
        px = x * 60 - off; d.line([(px, gy - 10), (px, gy)], fill=(200, 80, 80), width=2)
    spr = img_fn(); spr = spr.resize((max(1, int(spr.width * sc)), max(1, int(spr.height * sc))), Image.NEAREST)
    base = Image.new("RGBA", (pw, ph), (0, 0, 0, 0)); base.alpha_composite(spr, ((pw - spr.width) // 2, gy + 1 - spr.height)); im.paste(base, (0, 0), base)
    d.text((4, 3), label, fill=(0, 0, 0)); return im

def compare_gif(name, s, frames):
    old, ofps, osc = old_frames(s); W, H = s["canvas"]; ow, oh = old[0].size; dur = 3.0; step = 0.04; out = []
    for n in range(int(dur / step)):
        t = n * step; oi = int(t * ofps) % len(old); ni = int(t * s["fps"]) % 8
        a = panel(lambda: old[oi], osc, ow, oh, s["speed"], t, f"CURRENT art, {ofps:.1f} fps, ground {s['speed']:.0f} px/s")
        b = panel(lambda: frames[ni], s["scale"], W, H, s["speed"], t, f"PROPOSED pose guide, {s['fps']} fps")
        w = a.width + b.width + 10; h = max(a.height, b.height); im = Image.new("RGB", (w, h), (255, 255, 255)); im.paste(a, (0, h - a.height)); im.paste(b, (a.width + 10, h - b.height)); out.append(im)
    out[0].save(name, save_all=True, append_images=out[1:], duration=int(step * 1000), loop=0, optimize=True)

def validate(s):
    """planted foot ground speed in the guide: must equal the ground speed (it is built to; this catches edits to the tables)."""
    errs = []
    for i in range(8):
        for ph_off in (0, 4):
            (x0, l0), (x1, l1) = leg_targets(s, i + ph_off), leg_targets(s, i + ph_off + 1)
            if l0 <= 0.01 and l1 <= 0.01:
                v = -(x1 - x0) * s["scale"] * s["fps"]; errs.append(abs(v - s["speed"]) / s["speed"])
    return max(errs) if errs else None, len(errs)

def build(key):
    s = SETS[key]; out = os.path.join(ROOT, s["char"], "frames_proposed", s["anim"]); os.makedirs(out, exist_ok=True)
    open(os.path.join(ROOT, s["char"], "frames_proposed", ".gdignore"), "a").close()   # Godot must neither import nor export these
    ghost = idle_ghost(s); frames = [sketch_frame(s, i, ghost) for i in range(8)]
    for i, f in enumerate(frames): f.save(os.path.join(out, f"sketch_{i:02d}.png"))
    contact_sheet(s, frames, WALK_NAMES if s["kind"] == "walk" else RUN_NAMES).save(os.path.join(out, "contact_sheet.png"))
    compare_gif(os.path.join(out, f"compare_{int(s['speed'])}pxs.gif"), s, [sketch_frame(s, i, ghost, False) for i in range(8)])
    err, nseg = validate(s); p = per_frame_travel(s)
    params = dict(set=key, canvas=s["canvas"], figure_height_src_px=s["fig"], screen_scale=round(s["scale"], 4), fps=s["fps"], frames=8, ground_speed_px_s=s["speed"],
                  planted_foot_travel_src_px_per_frame=round(p, 2), step_length_src_px=round(p * 4, 2), cycle_seconds=8 / s["fps"],
                  max_planted_foot_speed_error=err, planted_segments_checked=nseg,
                  foot_x_from_pelvis_per_frame={"leg_A": [round(leg_targets(s, i)[0], 1) for i in range(8)], "leg_B": [round(leg_targets(s, i + 4)[0], 1) for i in range(8)]},
                  foot_lift_src_px_per_frame={"leg_A": [round(leg_targets(s, i)[1], 1) for i in range(8)]},
                  pelvis_up_src_px=[round(pelvis_up(s, i), 1) for i in range(8)])
    json.dump(params, open(os.path.join(out, "params.json"), "w"), indent=1)
    print(f"{key}: {s['canvas'][0]}x{s['canvas'][1]} planted travel {p:.2f} src px/frame, cycle {8 / s['fps']:.2f} s, guide planted-foot speed error {err:.2e} over {nseg} segments -> {out}")

if __name__ == "__main__":
    for k in (sys.argv[1:] or list(SETS)): build(k)
