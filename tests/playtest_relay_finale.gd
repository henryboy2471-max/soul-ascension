extends SceneTree
# Real-window playtest of Episode 3 M4 (needs a display):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --resolution 1280x720 --script res://tests/playtest_relay_finale.gd -- OUTDIR LABEL
# Starts at the Transit Station with the M2 evidence and the three resonators already restored (the M3 playthrough covers those), then plays with injected key
# events: the sealed rail door and Anselm's exposure, the walk back through the market and alleys to Teo's workshop, the relay map and Teo's reveal, the tower
# climb, the archive gate, the Warden chamber (a wrong mechanism first, then VALVE, BELL, SEAL, with a bot that walks out of every telegraph the way a player
# would), the recognition scene, the First Echo recording, the rewards screen, NEXT EPISODE and the teaser.
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
 get_root().get_viewport().get_texture().get_image().save_png("%s/%s_f_%s.png" % [out, label, name])
func screen():
 for c in ep.get_children():
  if c.has_method("request_hint") and c.has_method("paint"): return c
 return null
func dialogue_open() -> bool:
 for c in ep.get_children():
  if c.has_method("finish_all"): return true
 return false
func flush(max_s := 90.0) -> void:
 var s := Time.get_ticks_msec()
 while float(Time.get_ticks_msec() - s) / 1000.0 < max_s and screen() == null and (dialogue_open() or ep.busy or ep.traveling or ep.explore == null or ep.explore.locked):
  await tap(KEY_ENTER)
func walk_to(target: float, timeout := 40.0) -> void:
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
 while ep.zone_id != zone and float(Time.get_ticks_msec() - s) / 1000.0 < 10.0:
  await process_frame
 await create_timer(0.8).timeout
 await flush(30.0)
func presses(code: int, n: int) -> void:
 for i in range(n): await tap(code, 0.05)
# ---- the arena bot: a player who reads the floor telegraphs
func dodge_dir() -> int:
 if ep.arena == null or not is_instance_valid(ep.arena): return 0
 var st = ep.arena.state
 var px: float = ep.explore.px
 if str(st.phase) == "telegraph" and WardenLogic.in_zones(st.zones, px):
  var best := px
  var bd := INF
  for z in st.zones:
   for edge in [float(z[0]) - 40.0, float(z[1]) + 40.0]:
    if edge >= WardenLogic.PLAYER_MIN and edge <= WardenLogic.PLAYER_MAX and not WardenLogic.in_zones(st.zones, edge) and absf(edge - px) < bd:
     bd = absf(edge - px)
     best = edge
  return 1 if best > px else -1
 return 0
func arena_walk(target: float, timeout := 60.0) -> void:
 var s := Time.get_ticks_msec()
 while float(Time.get_ticks_msec() - s) / 1000.0 < timeout:
  var d := dodge_dir()
  var px: float = ep.explore.px
  var want := 0
  if d != 0: want = d
  elif absf(px - target) > 18.0: want = 1 if target > px else -1
  key(KEY_D, want > 0)
  key(KEY_A, want < 0)
  if want == 0: break
  await process_frame
 key(KEY_D, false)
 key(KEY_A, false)
 await create_timer(0.15).timeout
# hold E at a mechanism; if a telegraph threatens the spot, let go, step clear and try again
func arena_channel(id: String) -> void:
 var sp: Dictionary = ep.spot_of(id)
 await arena_walk(float(sp.x))
 var tries := 0
 while not ep.progress.clues.has("restored_" + id) and tries < 12:
  tries += 1
  var s := Time.get_ticks_msec()
  key(KEY_E, true)
  while float(Time.get_ticks_msec() - s) / 1000.0 < 2.2 and not ep.progress.clues.has("restored_" + id):
   if dodge_dir() != 0: break
   await process_frame
  key(KEY_E, false)
  if dodge_dir() != 0:
   await arena_walk(float(sp.x))   # walks out of the zone first (dodge has priority), then back to the mechanism
  await create_timer(0.3).timeout
 await flush(40.0)
func run() -> void:
 t0 = Time.get_ticks_msec()
 var profile = root.get_node("Profile")
 profile.data = profile.defaults()
 profile.data.onboarded = true
 profile.data.completed = ["1-1", "1-2"]
 profile.data.settings.sound = false
 profile.data.settings.dev_unlock = true
 var clues := ["tx_1","tx_2","tx_3","terminal","anselm_met","anselm_admits","records","scraped_entry","teo_met","decoded","theory","puzzle_signal","puzzle_power","puzzle_memory","w_a","w_b","w_c","journal","pip_done","hidden_registry","first_memory_fragment","tower_reached"]
 profile.data.mission_progress = {"1-3":{"intro":true,"zone":"station","visited":["market","station","alleys","workshop","tower_1","tower_2","tower_3"],"unlocks":["shortcut","tower","floor2","floor3"],"discoveries":["resonator_1","resonator_2","resonator_3"],"clues":clues,"puzzles":{}}}
 var gold0 := int(profile.data.gold)
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
 expect(ep.zone_id == "station" and ep.explore.objective_text == "Open the sealed archive door at the station", "resumed at the station; objective is the sealed door")
 await shot("01_station_objective", 0.4)
 # --- the sealed rail door
 var sp: Dictionary = ep.spot_of("archive_door")
 await walk_to(float(sp.x))
 await tap(KEY_ENTER)
 var n := 0
 while screen() == null and n < 400:
  await tap(KEY_ENTER)
  n += 1
 var sc = screen()
 expect(sc != null and sc.kind == "rail", "the door opens the rail puzzle")
 await shot("02_rail_start", 0.4)
 await tap(KEY_H)
 await tap(KEY_H)
 var sol = PuzzleLogic.rail_solve(sc.state)
 var made := 0
 for mv in sol:
  var guard := 0
  while sc.sel != int(mv[0]) and guard < 10:
   await tap(KEY_ENTER, 0.05)
   guard += 1
  var blk = sc.state.blocks[int(mv[0])]
  var code: int = (KEY_RIGHT if int(mv[1]) > 0 else KEY_LEFT) if blk[3] == "h" else (KEY_DOWN if int(mv[1]) > 0 else KEY_UP)
  await tap(code, 0.05)
  made += 1
  if made == 5: await shot("03_rail_midway", 0.2)
 await create_timer(2.0).timeout
 await shot("04_exposure_start", 0.3)
 await flush(60.0)
 expect(ep.progress.clues.has("puzzle_rail") and ep.progress.clues.has("seen_exposure") and profile.data.codex.has("echo_entry"), "rail door solved by keyboard; Anselm's exposure played; registry entry in the Codex")
 # --- back through the market and alleys to Teo
 await go("exit_market", "market")
 await go("exit_alleys", "alleys")
 await go("exit_workshop", "workshop")
 expect(ep.zone_id == "workshop" and ep.explore.objective_text == "Repair Teo's relay map", "walked to the workshop; objective is the relay map")
 # --- the relay map (seven lamps), keyboard cursor
 sp = ep.spot_of("relay_map")
 await walk_to(float(sp.x))
 await tap(KEY_ENTER)
 n = 0
 while screen() == null and n < 400:
  await tap(KEY_ENTER)
  n += 1
 sc = screen()
 expect(sc != null and sc.kind == "map", "the relay map opens its puzzle")
 await shot("05_map_start", 0.4)
 var cells: Array = PuzzleLogic.MAP_SOLUTION.keys()
 cells.sort()
 var turned := 0
 for cell in cells:
  var cols: int = 7
  var cx: int = int(cell) % cols
  var cy: int = int(cell) / cols
  var sx: int = sc.cursor % cols
  var sy: int = sc.cursor / cols
  await presses(KEY_RIGHT if cx > sx else KEY_LEFT, absi(cx - sx))
  await presses(KEY_DOWN if cy > sy else KEY_UP, absi(cy - sy))
  var want: int = PuzzleLogic.rotate_mask(PuzzleLogic.base_mask(PuzzleLogic.cell_kind(int(cell), "map")), int(PuzzleLogic.MAP_SOLUTION[cell]))
  var guard2 := 0
  while PuzzleLogic.cell_mask(int(cell), sc.state.rots, "map") != want and guard2 < 4:
   await tap(KEY_ENTER, 0.05)
   guard2 += 1
  turned += 1
  if turned == 12: await shot("06_map_half", 0.2)
 await create_timer(2.0).timeout
 await shot("07_teo_reveal", 0.4)
 await flush(60.0)
 expect(ep.progress.clues.has("puzzle_map") and ep.progress.clues.has("seen_teo_reveal") and profile.data.codex.has("seven_arrays"), "relay map lit all seven lamps; Teo's reveal played; Seven Arrays in the Codex")
 # --- up the tower
 await go("exit_tower", "tower_1")
 await go("exit_up_1", "tower_2")
 await go("exit_up_2", "tower_3")
 expect(ep.zone_id == "tower_3", "climbed to the top floor through the unlocked stairs")
 await shot("08_archive_gate_objective", 0.4)
 await use("archive_gate")
 expect(ep.progress.clues.has("archive_examined") and ep.explore.enabled.get("exit_arena", false), "all keys restored: the archive stirs and the gate to the Central Relay appears")
 await go("exit_arena", "arena")
 expect(ep.zone_id == "arena" and is_instance_valid(ep.arena), "entered the Warden's chamber; the arrival scene played")
 await shot("09_arena_start", 0.5)
 # --- the Warden: the inscription, a wrong mechanism, then VALVE, BELL, SEAL
 await arena_walk(330.0)
 await tap(KEY_ENTER)
 await create_timer(0.5).timeout
 await flush(30.0)
 expect(ep.progress.clues.has("inscription_read"), "read the brass plaque (VALVE, BELL, SEAL)")
 await shot("10_arena_waypoint_valve", 0.3)
 var hp0: int = int(ep.arena.state.hp)
 await arena_channel("mech_1")   # out of order on purpose
 expect(not ep.progress.clues.has("restored_mech_1") or int(ep.arena.state.hp) < hp0, "a mechanism out of order shocks Echo")
 await shot("11_wrong_order_shock", 0.1)
 # wait for a telegraph to capture it, while standing clear
 var waited := 0.0
 while str(ep.arena.state.phase) != "telegraph" and waited < 12.0:
  await arena_walk(float(ep.explore.px))
  await create_timer(0.1).timeout
  waited += 0.1
 await shot("12_telegraph", 0.2)
 await arena_channel("mech_2")
 expect(ep.progress.clues.has("restored_mech_2"), "VALVE restored while dodging telegraphs")
 await shot("13_valve_restored_stun", 0.3)
 await arena_channel("mech_3")
 expect(ep.progress.clues.has("restored_mech_3"), "BELL restored")
 await arena_channel("mech_1")
 await shot("14_before_recognition", 0.2)
 await flush(90.0)
 expect(ep.progress.clues.has("warden_restored") and profile.data.codex.has("relay_warden"), "SEAL restored: the recognition scene played; the Warden is restored, not destroyed")
 await shot("15_archive_core_open", 0.5)
 # --- the recording and the rewards
 note("walking to the archive core")
 var core: Dictionary = ep.spot_of("archive_core")
 await walk_to(float(core.x))
 note("at the archive core; pressing Enter")
 await tap(KEY_ENTER)
 note("finale started")
 var s0 := Time.get_ticks_msec()
 var ticks := 0
 while main.scene_name != "result" and float(Time.get_ticks_msec() - s0) / 1000.0 < 120.0:
  await tap(KEY_ENTER)
  ticks += 1
  if ticks % 25 == 0: note("finale tick %d scene=%s busy=%s" % [ticks, main.scene_name, str(ep.busy) if is_instance_valid(ep) else "freed"])
 await create_timer(1.2).timeout
 expect(main.scene_name == "result" and profile.data.completed.has("1-3"), "the finale played and the rewards screen is up; mission 1-3 completed")
 expect(int(profile.data.gold) == gold0 + 340, "first clear paid the placeholder 340 gold")
 await shot("16_rewards", 0.4)
 for b in main.screen.find_children("*", "Button", true, false):
  if str(b.text) == "NEXT EPISODE": b.pressed.emit()
 await create_timer(1.6).timeout
 expect(main.scene_name == "teaser", "NEXT EPISODE shows the EPISODE 4 / THE FIRST ECHO teaser")
 await shot("17_teaser", 0.2)
 main.screen.get_child(0).finish()
 await create_timer(1.2).timeout
 expect(main.scene_name == "home", "the teaser returns home")
 note("RESULT: %d failures" % fails)
 var f := FileAccess.open("%s/relay_finale_%s.txt" % [out, label], FileAccess.WRITE)
 f.store_string("\n".join(events) + "\n")
 f.close()
 quit(1 if fails > 0 else 0)
