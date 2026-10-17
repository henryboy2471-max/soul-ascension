#!/usr/bin/env python3
"""Summarise a motion_browser.cjs capture: frame pacing, on-screen step regularity, idle stability, animation flicker.
usage: motion_report.py motion.json [motion2.json ...]        per-segment detail
       motion_report.py --table before.json after.json         the headline numbers side by side"""
import json, statistics as st, sys

def pct(a, p):
 a = sorted(a); return a[min(len(a) - 1, int(len(a) * p))] if a else 0.0

def seg_stats(seg):
 tr, raf = seg["tr"], seg["raf"]
 dt = [r[0] for r in tr]; out = {"seg": seg["seg"], "frames": len(tr)}
 if len(tr) < 5: return out
 out["raf_ms"] = (round(st.mean(raf[2:]), 1), round(pct(raf[2:], .95), 1), round(max(raf[2:]), 1)) if len(raf) > 4 else None
 out["dt_ms"] = (round(st.mean(dt), 1), round(pct(dt, .95), 1), round(max(dt), 1))
 out["slow>25ms"] = sum(1 for d in dt if d > 25)
 # world px/s vs on-screen px/s: irregularity of the per-frame on-screen step relative to the step the world motion calls for
 sx = [r[3] for r in tr]; wx = [r[2] for r in tr]; cam = [r[1] for r in tr]
 ex = []   # screen step minus (hero world step - camera step): 0 when the sprite lands exactly where the simulation says
 for i in range(1, len(tr)):
  ex.append((sx[i] - sx[i - 1]) - ((wx[i] - wx[i - 1]) - (cam[i] - cam[i - 1])))
 out["place_err_px"] = (round(st.mean(abs(e) for e in ex), 3), round(max(abs(e) for e in ex), 3))
 # jitter: change of the on-screen step between consecutive frames, ignoring the genuine speed ramp (use a 5-frame median of the step as reference)
 steps = [sx[i] - sx[i - 1] for i in range(1, len(sx))]
 j = []
 for i in range(2, len(steps) - 2):
  ref = st.median(steps[i - 2:i + 3]); j.append(abs(steps[i] - ref))
 out["step_jitter_px"] = (round(st.mean(j), 3), round(pct(j, .95), 3), round(max(j), 3)) if j else None
 out["reverse_steps"] = sum(1 for i in range(len(steps)) if abs(steps[i]) > 0.01 and abs(wx[i + 1] - wx[i]) > 0.05 and (steps[i] > 0) != (wx[i + 1] - wx[i] > 0) and abs(cam[i + 1] - cam[i]) < 0.05)
 # idle stability: hero + NPC screen positions when nothing should be moving
 if seg["seg"].startswith("idle"):
  tail = tr[len(tr) // 3:]
  out["idle_hero_range_px"] = round(max(r[3] for r in tail) - min(r[3] for r in tail), 3)
  out["idle_hero_y_range_px"] = round(max(r[4] for r in tail) - min(r[4] for r in tail), 3)
  out["idle_npc_range_px"] = round(max(r[5] for r in tail) - min(r[5] for r in tail), 3)
 rows=[r for r in tr if len(r)>14]
 if rows: out["engine_process_ms"]=(round(st.mean(r[11] for r in rows),2),round(max(r[11] for r in rows),2)); out["draw_calls"]=int(st.mean(r[12] for r in rows)); out["primitives"]=int(st.mean(r[13] for r in rows)); out["nodes"]=rows[-1][14]
 # animation transitions
 sw = [(i, tr[i - 1][7], tr[i][7]) for i in range(1, len(tr)) if tr[i][7] != tr[i - 1][7]]
 out["anim_switches"] = len(sw)
 out["anim_flicker"] = sum(1 for k in range(1, len(sw)) if sw[k][0] - sw[k - 1][0] < 8 and sw[k][2] == sw[k - 1][1])
 # sprite frame advance regularity while moving
 fr = [(r[8], r[0]) for r in tr if r[7] in ("walk", "run")]
 if len(fr) > 10:
  ch = [i for i in range(1, len(fr)) if fr[i][0] != fr[i - 1][0]]
  gaps = [sum(f[1] for f in fr[ch[k - 1]:ch[k]]) for k in range(1, len(ch))]
  out["walk_frame_hold_ms"] = (round(st.mean(gaps), 0), round(min(gaps), 0), round(max(gaps), 0)) if gaps else None
 return out

def headline(path):
 d = json.load(open(path)); out = {}
 raf = [r for seg in d["out"] for r in seg["raf"][2:]]; dt = [r[0] for seg in d["out"] for r in seg["tr"]]
 med = st.median(raf) if raf else 0
 out["frame interval median / p95 / worst (ms, browser rAF)"] = f"{med:.1f} / {pct(raf, .95):.1f} / {max(raf):.1f}"
 out["frames > 1.5x median interval (dropped-frame proxy)"] = f"{sum(1 for r in raf if r > 1.5 * med)} of {len(raf)}"
 out["engine delta median / worst (ms)"] = f"{st.median(dt):.1f} / {max(dt):.1f}"
 # slow walker (ambient pedestrian) with the camera still: per-frame step size regularity (idle segments, walker 0 on screen)
 steps = []
 for seg in d["out"]:
  if not seg["seg"].startswith("idle"): continue
  tr = seg["tr"]
  for i in range(len(tr) // 3 + 1, len(tr)):
   if tr[i][1] == tr[i - 1][1] and abs(tr[i][6]) > 0:   # camera not moving
    steps.append(tr[i][6] - tr[i - 1][6])
 if len(steps) > 10:
  zero = sum(1 for x in steps if abs(x) < 0.01) / len(steps); mean = st.mean(steps)
  out["slow walker: frames where it did not move on screen"] = f"{100 * zero:.0f}%"
  out["slow walker: step size spread (std / mean, lower = smoother)"] = f"{st.pstdev(steps) / abs(mean):.2f}" if mean else "n/a"
 # hero settle: time from key release (last frame at full speed) until the hero stops moving on screen; idle stability afterwards
 settle = []; wobble = []
 byname = {seg["seg"]: seg for seg in d["out"]}
 for walk, idle in (("right", "idle_after_right"), ("left", "idle_after_left")):
  if walk not in byname or idle not in byname: continue
  tr = byname[walk]["tr"] + byname[idle]["tr"]
  if len(tr) < 20: continue
  t = [0.0]
  for r in tr[1:]: t.append(t[-1] + r[0] / 1000.0)
  vmax = max(abs(r[10]) for r in tr)
  if vmax < 20: continue
  rel = max(i for i in range(len(tr)) if abs(tr[i][10]) >= 0.9 * vmax)   # last frame at (near) top speed = key release
  last = rel
  for i in range(rel + 1, len(tr)):
   if abs(tr[i][3] - tr[i - 1][3]) > 0.01: last = i
  settle.append(t[last] - t[rel])
  tail = byname[idle]["tr"][len(byname[idle]["tr"]) * 2 // 3:]; wobble.append(max(r[3] for r in tail) - min(r[3] for r in tail))
 if settle: out["hero keeps sliding on screen after release (s), right / left"] = " / ".join(f"{x:.2f}" for x in settle)
 if wobble: out["idle hero on-screen range, last third of idle (px)"] = " / ".join(f"{x:.2f}" for x in wobble)
 # companion (Episode 3): fastest world speed in the whole run (hero top speed is 300 px/s)
 best = 0.0
 for seg in d["out"]:
  tr = seg["tr"]
  for i in range(3, len(tr)):
   dtt = sum(tr[k][0] for k in range(i - 2, i + 1)) / 1000.0
   if dtt <= 0: continue
   wx = (tr[i][5] + tr[i][1]) - (tr[i - 3][5] + tr[i - 3][1])
   best = max(best, abs(wx) / dtt)
 out["fastest on-screen+camera speed of the NPC/companion (px/s)"] = f"{best:.0f}"
 # hero walk/idle switching: number of animation switches in the stop_and_go segment (4 short taps => ideal 8)
 for seg in d["out"]:
  if seg["seg"] == "stop_and_go":
   tr = seg["tr"]; out["stop_and_go: animation switches (4 taps, ideal 8)"] = sum(1 for i in range(1, len(tr)) if tr[i][7] != tr[i - 1][7])
 for seg in d["out"]:
  if seg["seg"] == "travel" and len(seg["tr"]) > 10:
   tr = seg["tr"]; t = 0.0; x0 = tr[0][2]; t400 = None; top = 0.0
   for i in range(1, len(tr)):
    t += tr[i][0] / 1000.0
    if t400 is None and tr[i][2] - x0 >= 200: t400 = t
    top = max(top, abs(tr[i][10]))
   out["browser: world distance walked in 5 s of holding the key (px)"] = f"{tr[-1][2] - x0:.0f}"
   out["browser: time to walk 200 px from rest (s)"] = f"{t400:.2f}" if t400 else "not reached"
   out["browser: top velocity reported by the game (px/s)"] = f"{top:.0f}"
 out["console errors"] = len(d["msgs"])
 return out

if sys.argv[1] == "--table":
 a, b = headline(sys.argv[2]), headline(sys.argv[3])
 print(f"| metric | before | after |\n|---|---|---|")
 for k in a: print(f"| {k} | {a[k]} | {b.get(k, '')} |")
 sys.exit(0)
for path in sys.argv[1:]:
 d = json.load(open(path)); print(f"== {path}  viewport {d['W']}x{d['H']}  cpu-throttle x{d['thr']}  console errors {len(d['msgs'])}")
 for seg in d["out"]:
  s = seg_stats(seg); print(f"-- {seg['scene']} / {s.pop('seg')}")
  for k, v in s.items(): print(f"   {k}: {v}")
