extends SceneTree
# Real-window playtest of Episode 1's Neon District (not a unit test; it needs a display):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --resolution 1280x720 --script res://tests/playtest_neon_window.gd -- OUTDIR LABEL
# Plays the real main scene with injected key events (the game polls Input.is_physical_key_pressed, so this is the same path as a keyboard): opens the episode, walks the whole street, talks to Mira,
# channels the relay, scans the mural and walks to the far end. Per frame it logs the camera and every parallax layer, then reports layer gaps, parallax mismatches, camera jumps and frame hitches.
# Screenshots (the viewport) land in OUTDIR; the report is printed and written to OUTDIR/report_LABEL.txt.
var out := "/tmp"
var label := "desktop"
var main
var ep
var rows: Array = []
var sampling := false
var last_ms := 0
var notes: Array = []
var shot_marks: Array = []   # frame indexes where a screenshot stalled the frame (PNG encoding); the analysis ignores those frames and the next two
func _initialize() -> void:
 var a := OS.get_cmdline_user_args()
 if a.size() > 0: out = a[0]
 if a.size() > 1: label = a[1]
 call_deferred("run")
func key(code: int, pressed: bool) -> void:
 var e := InputEventKey.new()
 e.physical_keycode = code
 e.keycode = code
 e.pressed = pressed
 Input.parse_input_event(e)
func tap(code: int, hold := 0.09) -> void:
 key(code, true)
 await create_timer(hold).timeout
 key(code, false)
 await create_timer(0.1).timeout
func shot(name: String, wait := 0.25) -> void:
 await create_timer(wait).timeout
 shot_marks.append(rows.size())
 get_root().get_viewport().get_texture().get_image().save_png("%s/%s_%s.png" % [out, label, name])
 print("shot ", name, "  px=", snappedf(ep.explore.px if ep != null and ep.explore != null else -1.0, 1.0), " cam=", snappedf(ep.explore.cam if ep != null and ep.explore != null else -1.0, 1.0))
func sample() -> void:
 if not sampling or ep == null or ep.explore == null: return
 var x = ep.explore
 var now := Time.get_ticks_msec()
 var r := {"ms": now - last_ms, "px": x.px, "cam": x.cam, "lift": x.lift, "layers": [], "fg": x.foreground_plate.position.x if x.foreground_plate != null else 0.0, "props": x.props.position.x}
 last_ms = now
 for l in x.layers: r.layers.append([l.position.x, float(l.get_meta("factor")), float(l.width)])
 rows.append(r)
func walk_to(target: float, timeout := 25.0) -> void:
 var x = ep.explore
 var code := KEY_D if target > x.px else KEY_A
 var t0 := Time.get_ticks_msec()
 key(code, true)
 while float(Time.get_ticks_msec() - t0) / 1000.0 < timeout and ((code == KEY_D and x.px < target) or (code == KEY_A and x.px > target)):
  await process_frame
 key(code, false)
 await create_timer(0.25).timeout
func dialogue_open() -> bool:
 for c in ep.get_children():
  if c.has_method("finish_all"): return true
 return false
func flush_dialogue(max_s := 25.0) -> void:
 var t := 0.0
 while t < max_s and (dialogue_open() or ep.explore == null or ep.explore.locked):
  await tap(KEY_ENTER)
  t += 0.2
func run() -> void:
 var profile = root.get_node("Profile")
 profile.data = profile.defaults()
 profile.data.onboarded = true
 profile.data.settings.sound = false
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.8).timeout
 main.show_home()
 await shot("00_home", 0.8)
 main.start_episode("1-1")
 await create_timer(0.8).timeout
 ep = main.screen.get_child(0)
 await shot("01_title", 1.0)
 await flush_dialogue()
 while ep.explore == null: await process_frame
 await create_timer(1.2).timeout
 process_frame.connect(sample)
 last_ms = Time.get_ticks_msec()
 sampling = true
 await shot("02_start", 0.3)
 # --- walk to Mira, talk
 await walk_to(500.0)
 await shot("03_near_mira", 0.3)
 await tap(KEY_ENTER)
 await create_timer(1.0).timeout
 await shot("04_dialogue_mira_open", 0.4)
 await flush_dialogue()
 notes.append("after Mira: step=%s" % str(ep.step))
 # --- mid-travel, walking
 key(KEY_D, true)
 while ep.explore.px < 1000.0: await process_frame
 await shot("05_mid_travel_walking_a", 0.0)
 while ep.explore.px < 1250.0: await process_frame
 await shot("06_mid_travel_walking_b", 0.0)
 key(KEY_D, false)
 await create_timer(0.3).timeout
 # --- tram stop: walk under it
 await walk_to(900.0)
 await shot("07_tram_wheels_stopped", 0.3)
 await walk_to(1500.0)
 await shot("08_relay_prompt", 0.3)
 # --- relay: hold E (channel)
 key(KEY_E, true)
 await create_timer(0.6).timeout
 await shot("09_relay_channel_hold", 0.0)
 await create_timer(2.4).timeout
 key(KEY_E, false)
 await flush_dialogue(10.0)
 notes.append("after relay: step=%s" % str(ep.step))
 await walk_to(1830.0)
 await shot("10_mural_prompt", 0.3)
 key(KEY_E, true)
 await create_timer(2.8).timeout
 key(KEY_E, false)
 await flush_dialogue(10.0)
 notes.append("after mural: step=%s" % str(ep.step))
 # --- far end
 await walk_to(2380.0)
 await shot("11_far_end", 0.4)
 await walk_to(1300.0)
 await shot("12_walk_back_mid", 0.3)
 sampling = false
 report()
 quit(0)
func report() -> void:
 var lines: Array = []
 lines.append("PLAYTEST %s  window=%s  frames=%d" % [label, str(get_root().size), rows.size()])
 for n in notes: lines.append("  " + n)
 var gap_min := 1e9
 var gaps := 0
 var mism := 0
 var jumps := 0
 var hitches := 0
 var worst_step := 0.0
 var flagged: Array = []
 var speeds: Array = []
 for i in range(1, rows.size()):
  var dpx := absf(rows[i].px - rows[i - 1].px)
  if dpx > 0.5 and rows[i].ms > 0 and rows[i].ms < 120: speeds.append(absf(rows[i].cam - rows[i - 1].cam) / float(rows[i].ms) * 1000.0)
 speeds.sort()
 var med_speed := 0.0
 if speeds.size() > 0: med_speed = speeds[speeds.size() / 2]
 for i in range(rows.size()):
  var r = rows[i]
  var view := roundf(r.cam)
  for L in r.layers:
   var pos: float = L[0]
   var w: float = L[2]
   if absf(pos - roundf(-view * L[1])) > 0.01: mism += 1
   var left := -pos
   var right := pos + w - 1280.0
   gap_min = minf(gap_min, minf(left, right))
   if left < -0.01 or right < -0.01: gaps += 1
  var skip := false
  for m in shot_marks:
   if i >= m and i <= m + 2: skip = true
  if i > 0 and not skip:
   var d := absf(r.cam - rows[i - 1].cam)
   worst_step = maxf(worst_step, d)
   # a camera pop: the camera moves far more in one frame than its usual speed allows for that frame's duration (frame hitches are counted separately)
   if med_speed > 0.0 and d > 2.5 * med_speed * float(r.ms) / 1000.0 + 6.0 and absf(r.px - rows[i - 1].px) < 40.0:
    jumps += 1
    if flagged.size() < 8: flagged.append("frame %d: cam %.1f -> %.1f (step %.1f px in %d ms) px %.0f -> %.0f lift %.0f" % [i, rows[i - 1].cam, r.cam, d, r.ms, rows[i - 1].px, r.px, r.lift])
   if r.ms > 120: hitches += 1
 lines.append("  parallax layer positions vs round(-view*factor): %d mismatches in %d layer-samples" % [mism, rows.size() * 5])
 lines.append("  layer coverage of the 1280 px screen (min margin over all layers/frames): %.1f px, frames with a gap: %d" % [gap_min, gaps])
 lines.append("  camera: median moving speed %.0f px/s, worst single-frame step %.1f px, pops (step beyond 2.5x the usual speed for that frame time): %d" % [med_speed, worst_step, jumps])
 for f in flagged: lines.append("    pop: " + f)
 var lift_max := 0.0
 for r in rows: lift_max = maxf(lift_max, absf(r.lift))
 lines.append("  street lift (dialogue) max %.1f px; frames over 120 ms (excluding screenshot stalls): %d of %d" % [lift_max, hitches, rows.size()])
 for l in lines: print(l)
 var f := FileAccess.open("%s/report_%s.txt" % [out, label], FileAccess.WRITE)
 f.store_string("\n".join(lines) + "\n")
 f.close()
