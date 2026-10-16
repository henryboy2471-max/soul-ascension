extends SceneTree
# Real-window playtest of Episode 3 M3 (needs a display):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --resolution 1280x720 --script res://tests/playtest_relay_puzzles.gd -- OUTDIR LABEL
# Resumes in the tower with the M2 evidence in the save, then plays the three resonator puzzles with injected key events (the keyboard path): walks to each
# resonator, presses Enter, solves the puzzle with arrows/Enter (including a hint and a leave-and-return), climbs the unlocked stairs, takes the sealed fragment
# and examines the archive. Screenshots land in OUTDIR; the report lists every check.
var out := "/tmp"
var label := "desktop"
var main
var ep
var events: Array = []
var fails := 0
var t0 := 0
func _initialize() -> void:
 var a := OS.get_cmdline_user_args()
 if a.size() > 0: out = a[0]
 if a.size() > 1: label = a[1]
 call_deferred("run")
func note(s: String) -> void:
 var line := "[%6.1fs] %s" % [float(Time.get_ticks_msec() - t0) / 1000.0, s]
 events.append(line)
 print(line)
func expect(ok: bool, what: String) -> void:
 if not ok: fails += 1
 note(("OK   " if ok else "FAIL ") + what)
func key(code: int, pressed: bool) -> void:
 var e := InputEventKey.new()
 e.physical_keycode = code
 e.keycode = code
 e.pressed = pressed
 Input.parse_input_event(e)
func tap(code: int, hold := 0.07) -> void:
 key(code, true)
 await create_timer(hold).timeout
 key(code, false)
 await create_timer(0.07).timeout
func shot(name: String, wait := 0.25) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("%s/%s_p_%s.png" % [out, label, name])
func screen():
 for c in ep.get_children():
  if c.has_method("request_hint") and c.has_method("paint"): return c
 return null
func dialogue_open() -> bool:
 for c in ep.get_children():
  if c.has_method("finish_all"): return true
 return false
func flush(max_s := 40.0) -> void:
 var s := Time.get_ticks_msec()
 while float(Time.get_ticks_msec() - s) / 1000.0 < max_s and screen() == null and (dialogue_open() or ep.busy or ep.traveling or ep.explore == null or ep.explore.locked):
  await tap(KEY_ENTER)
func walk_to(target: float, timeout := 30.0) -> void:
 var x = ep.explore
 var code := KEY_D if target > x.px else KEY_A
 var s := Time.get_ticks_msec()
 key(code, true)
 while float(Time.get_ticks_msec() - s) / 1000.0 < timeout and ((code == KEY_D and x.px < target) or (code == KEY_A and x.px > target)):
  await process_frame
 key(code, false)
 await create_timer(0.3).timeout
func use(id: String) -> void:
 var sp: Dictionary = ep.spot_of(id)
 await walk_to(float(sp.x))
 await tap(KEY_ENTER)
 await create_timer(0.5).timeout
 await flush()
func go(exit_id: String, zone: String) -> void:
 await use(exit_id)
 var s := Time.get_ticks_msec()
 while ep.zone_id != zone and float(Time.get_ticks_msec() - s) / 1000.0 < 8.0:
  await process_frame
 await create_timer(0.8).timeout
 await flush(5.0)
func presses(code: int, n: int) -> void:
 for i in range(n): await tap(code, 0.05)
func run() -> void:
 t0 = Time.get_ticks_msec()
 var profile = root.get_node("Profile")
 profile.data = profile.defaults()
 profile.data.onboarded = true
 profile.data.completed = ["1-1", "1-2"]
 profile.data.settings.sound = false
 profile.data.settings.dev_unlock = true
 var clues := ["tx_1","tx_2","tx_3","terminal","anselm_met","anselm_admits","records","scraped_entry","teo_met","decoded","theory"]
 profile.data.mission_progress = {"1-3":{"intro":true,"zone":"workshop","visited":["market","station","alleys","workshop"],"unlocks":["shortcut","tower"],"discoveries":[],"clues":clues}}
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.8).timeout
 main.show_home()
 await create_timer(0.5).timeout
 main.start_episode("1-3")
 await create_timer(1.0).timeout
 ep = main.screen.get_child(0)
 while ep.explore == null: await process_frame
 await create_timer(1.0).timeout
 await go("exit_tower", "tower_1")
 expect(ep.zone_id == "tower_1" and ep.explore.objective_text == "Restore the signal resonator on the first floor", "entered the tower; objective is the first resonator")
 await shot("01_tower_floor1_objective", 0.4)
 # --- floor 1: signal
 await use("exit_up_1")
 expect(ep.zone_id == "tower_1", "stairs are locked before the signal resonator is restored")
 await shot("02_stairs_locked", 0.3)
 await use("resonator_1")
 var sc = screen()
 expect(sc != null and sc.kind == "signal", "signal puzzle opened by Enter at the resonator")
 await shot("03_signal_start", 0.4)
 await tap(KEY_H)
 await shot("04_signal_hint", 0.3)
 await tap(KEY_ESCAPE)
 await create_timer(0.4).timeout
 await flush(5.0)
 expect(screen() == null and not ep.progress.clues.has("puzzle_signal"), "Esc leaves the puzzle unsolved")
 await use("resonator_1")
 sc = screen()
 expect(sc != null and int(sc.state.hints) == 1, "returning resumes the saved puzzle (hint count kept)")
 for r in range(3):
  var t = PuzzleLogic.signal_target(sc.state)
  var df: int = int(t.freq) - int(sc.state.freq)
  var da: int = int(t.amp) - int(sc.state.amp)
  await presses(KEY_RIGHT if df > 0 else KEY_LEFT, absi(df))
  await presses(KEY_UP if da > 0 else KEY_DOWN, absi(da))
  if r == 0: await shot("05_signal_tuned_round1", 0.3)
  if r == 2: await shot("06_signal_tuned_round3", 0.3)
  await tap(KEY_ENTER)
  await create_timer(0.2).timeout
 await create_timer(2.0).timeout
 await flush(8.0)
 expect(ep.progress.clues.has("puzzle_signal") and ep.progress.unlocks.has("floor2"), "all three transmissions locked: resonator restored, stairs open")
 await shot("07_signal_restored", 0.5)
 # --- floor 2: power
 await go("exit_up_1", "tower_2")
 expect(ep.zone_id == "tower_2", "climbed to floor 2")
 await use("resonator_2")
 sc = screen()
 expect(sc != null and sc.kind == "power", "power puzzle opened")
 await shot("08_power_start", 0.4)
 await tap(KEY_H)
 await tap(KEY_H)
 await shot("09_power_hint_marked_tile", 0.3)
 for cell in PuzzleLogic.ROUTE_PATH:
  if not PuzzleLogic.ROUTE_SOLUTION.has(cell): continue
  # move the keyboard cursor to the tile, then turn it until it matches
  var cx: int = cell % PuzzleLogic.COLS
  var cy: int = cell / PuzzleLogic.COLS
  var sx: int = sc.cursor % PuzzleLogic.COLS
  var sy: int = sc.cursor / PuzzleLogic.COLS
  await presses(KEY_RIGHT if cx > sx else KEY_LEFT, absi(cx - sx))
  await presses(KEY_DOWN if cy > sy else KEY_UP, absi(cy - sy))
  var turns: int = posmod(int(PuzzleLogic.ROUTE_SOLUTION[cell]) - int(sc.state.rots[cell]), 4)
  await presses(KEY_ENTER, turns)
  if cell == 8: await shot("10_power_half_connected", 0.3)
 await create_timer(2.0).timeout
 await flush(8.0)
 expect(ep.progress.clues.has("puzzle_power") and ep.progress.unlocks.has("floor3"), "relay lamp lit: power restored, stairs to floor 3 open")
 await shot("11_power_restored", 0.5)
 await use("sealed_chamber")
 expect(ep.progress.clues.has("first_memory_fragment"), "sealed chamber (optional) gave its fragment")
 await shot("12_sealed_chamber", 0.4)
 # --- floor 3: memory
 await go("exit_up_2", "tower_3")
 expect(ep.zone_id == "tower_3", "climbed to floor 3")
 await use("resonator_3")
 sc = screen()
 expect(sc != null and sc.kind == "memory", "memory puzzle opened")
 await shot("13_memory_start", 0.4)
 # deliberately wrong first, then check
 var wrong := ["bulletin","tone","terminal","records"]
 for i in range(4):
  var tray: Array = PuzzleLogic.memory_tray(sc.state, sc.clues)
  var col: int = tray.find(wrong[i])
  sc.cursor = col
  await tap(KEY_ENTER)
  await tap(KEY_DOWN)
  sc.cursor = 4 + i
  await tap(KEY_ENTER)
  await tap(KEY_UP)
 await tap(KEY_C)
 await shot("14_memory_wrong_order", 0.3)
 expect(sc.feedback.text.contains("OF 4 IN PLACE") and not sc.done, "wrong order: feedback says how many are in place")
 for i in range(4):
  var want: String = PuzzleLogic.MEMORY_ORDER[i]
  if sc.state.slots[i] != want:
   # take back the occupant, then place the right card
   sc.cursor = 4 + i
   if sc.state.slots[i] != "": await tap(KEY_ENTER)
   var tray2: Array = PuzzleLogic.memory_tray(sc.state, sc.clues)
   var holder: int = sc.state.slots.find(want)
   if holder >= 0:
    sc.cursor = 4 + holder
    await tap(KEY_ENTER)
    tray2 = PuzzleLogic.memory_tray(sc.state, sc.clues)
   sc.cursor = tray2.find(want)
   await tap(KEY_ENTER)
   sc.cursor = 4 + i
   await tap(KEY_ENTER)
 await shot("15_memory_ordered", 0.3)
 await tap(KEY_C)
 await create_timer(2.0).timeout
 await flush(8.0)
 expect(ep.progress.clues.has("puzzle_memory"), "fragments in clue order: memory restored")
 await shot("16_memory_restored", 0.5)
 await use("archive_gate")
 expect(ep.progress.clues.has("archive_examined") and Episode3Data.next_step(ep.progress.clues).is_empty(), "archive stirs; the M3 quest line is complete")
 await shot("17_archive_stirs", 0.6)
 expect(profile.data.completed == ["1-1", "1-2"], "Episode 1-2 completion untouched")
 note("RESULT: %d failures" % fails)
 var f := FileAccess.open("%s/relay_puzzles_%s.txt" % [out, label], FileAccess.WRITE)
 f.store_string("\n".join(events) + "\n")
 f.close()
 quit(1 if fails > 0 else 0)
