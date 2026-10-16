extends SceneTree
# Real-window playtest of Episode 3 M2 (needs a display):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --resolution 1280x720 --script res://tests/playtest_relay_window.gd -- OUTDIR LABEL
# Starts mission 1-3 (dev_unlock) and plays the investigation with injected key events (the game polls Input.is_physical_key_pressed, i.e. the keyboard path):
# walks to each spot, presses Enter (talk) or holds E (channel), skips dialogue, travels through exits, and screenshots the objective HUD, dialogue, toasts,
# the hidden panel, the tower unlock and the Codex. Reports the objective text and clue count after every step and fails on any divergence.
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
func tap(code: int, hold := 0.08) -> void:
 key(code, true)
 await create_timer(hold).timeout
 key(code, false)
 await create_timer(0.08).timeout
func shot(name: String, wait := 0.25) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("%s/%s_r_%s.png" % [out, label, name])
func dialogue_open() -> bool:
 for c in ep.get_children():
  if c.has_method("finish_all"): return true
 return false
func flush(max_s := 40.0) -> void:
 var s := Time.get_ticks_msec()
 while float(Time.get_ticks_msec() - s) / 1000.0 < max_s and (dialogue_open() or ep.busy or ep.traveling or ep.explore == null or ep.explore.locked):
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
func spot(id: String) -> Dictionary:
 return ep.spot_of(id)
# walk to the spot, then use it the way a player does: Enter for talk spots, hold E for channel spots
func use(id: String, shot_name := "", mid_shot := "") -> void:
 var sp := spot(id)
 if sp.is_empty():
  expect(false, "spot %s exists in %s" % [id, ep.zone_id])
  return
 await walk_to(float(sp.x))
 if sp.kind == "channel":
  key(KEY_E, true)
  await create_timer(2.7).timeout
  key(KEY_E, false)
 else:
  await tap(KEY_ENTER)
 await create_timer(0.5).timeout
 if mid_shot != "":
  await shot(mid_shot, 0.2)
 await flush()
 if shot_name != "": await shot(shot_name, 0.5)
func state() -> String:
 return "zone=%s obj='%s' counter=%d/%d clues=%d" % [ep.zone_id, ep.explore.objective_text, ep.explore.counter_done, ep.explore.counter_total, ep.progress.clues.size()]
func go(exit_id: String, zone: String) -> void:
 await use(exit_id)
 var s := Time.get_ticks_msec()
 while ep.zone_id != zone and float(Time.get_ticks_msec() - s) / 1000.0 < 8.0:
  await process_frame
 await create_timer(0.8).timeout
 await flush(5.0)
 expect(ep.zone_id == zone, "travelled through %s to %s" % [exit_id, zone])
func run() -> void:
 t0 = Time.get_ticks_msec()
 var profile = root.get_node("Profile")
 profile.data = profile.defaults()
 profile.data.onboarded = true
 profile.data.completed = ["1-1", "1-2"]
 profile.data.settings.sound = false
 profile.data.settings.dev_unlock = true
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.8).timeout
 main.show_home()
 await create_timer(0.5).timeout
 main.start_episode("1-3")
 await create_timer(0.8).timeout
 ep = main.screen.get_child(0)
 await shot("00_title_card", 1.0)
 await flush()
 while ep.explore == null: await process_frame
 await create_timer(1.0).timeout
 await shot("01_market_start")
 expect(ep.explore.objective_text == "Investigate the three unusual transmissions" and ep.explore.counter_total == 3, "opening objective is the 0/3 transmissions counter")
 # --- Lantern Market
 await use("notice")
 await use("signal_1", "02_signal_scanned", "02a_signal_dialogue")
 expect(ep.explore.counter_done == 1, "scanning a transmission advances the counter to 1/3")
 await use("witness_a")
 await use("signal_2")
 await use("witness_b")
 await use("signal_3", "03_third_signal_objective_moves")
 expect(ep.explore.objective_text == "Check the access terminal at the Transit Station", "after 3/3 the objective moves to the station terminal")
 await use("witness_c")
 await use("journal", "04_hidden_journal")
 expect(profile.data.codex.has("relay_journal"), "the hidden journal enters the Codex")
 await go("exit_station", "station")
 # --- Transit Station: out-of-order first, then the intended way
 await use("records", "05_records_too_early")
 expect(not ep.progress.clues.has("records"), "records give nothing before Anselm admits")
 await use("anselm", "06_anselm_stonewalls")
 expect(not ep.progress.clues.has("anselm_admits"), "Anselm stonewalls without the terminal log")
 await use("terminal_a", "07_terminal_log")
 await use("anselm", "08_anselm_admits", "08a_anselm_dialogue")
 expect(ep.progress.clues.has("anselm_admits"), "Anselm admits after the terminal log")
 await use("records", "09_old_records")
 expect(ep.progress.clues.has("records") and ep.explore.enabled.get("registry_hidden", false), "records found; the hidden panel is now available")
 await use("registry_hidden", "10_hidden_registry")
 # (the archive door opens its sealed-door puzzle since M4: that puzzle and its cinematic are played in playtest_relay_puzzles.gd / playtest_relay_finale.gd)
 # --- back through the market to the alleys (the shortcut is not open yet)
 await go("exit_market", "market")
 await go("exit_alleys", "alleys")
 await use("pip", "11_pip_asks")
 await use("fragment_1", "12_fragment")
 await use("fragment_2")
 await use("pip")
 expect(not ep.progress.clues.has("pip_done"), "Pip's quest stays open at 2 of 3 marks")
 await use("fragment_3")
 await use("pip", "13_pip_done")
 expect(ep.progress.clues.has("pip_done"), "Pip's optional quest completes")
 await use("lever", "14_shortcut_opened")
 await go("exit_workshop", "workshop")
 # --- Teo's workshop
 await use("decoder", "15_decoder_refused")
 expect(not ep.progress.clues.has("decoded"), "decoder refuses before Teo has been spoken to")
 await use("teo", "16_teo_cautious", "16a_teo_dialogue")
 await use("board", "17_board_gaps")
 expect(not ep.progress.clues.has("theory"), "board has gaps before the signals are decoded")
 await use("decoder", "18_decoded")
 await use("exit_tower")
 expect(ep.zone_id == "workshop", "the tower stays sealed before the theory")
 await shot("19_tower_sealed", 0.4)
 await use("board", "20_theory_assembled", "20a_board_dialogue")
 # since M4 the quest line continues after the theory (door puzzle, relay map) before the tower: the objective is whatever the saved clues say is next
 expect(ep.progress.unlocks.has("tower") and ep.explore.objective_text == Episode3Data.next_step(ep.progress.clues).text, "theory assembled: tower unlocked, objective follows the saved clues")
 await go("exit_tower", "tower_1")
 expect(ep.explore.objective_text == Episode3Data.next_step(ep.progress.clues).text, "inside the tower the objective still follows the saved clues")
 await shot("21_tower_floor_1", 0.5)
 # --- Codex
 main.show_hero()
 await create_timer(0.5).timeout
 main.show_codex()
 await shot("22_codex", 0.6)
 var c = profile.data.codex
 expect(c.has("relay_voices") and c.has("teo") and c.has("anselm") and c.has("false_register") and c.has("earlier_candidates") and c.has("relay_journal") and c.has("pips_trail"), "all seven Episode 3 Codex entries found")
 expect(profile.data.completed == ["1-1", "1-2"], "Episode 1-2 completion untouched")
 note("final: " + state())
 note("RESULT: %d failures" % fails)
 var f := FileAccess.open("%s/relay_report_%s.txt" % [out, label], FileAccess.WRITE)
 f.store_string("\n".join(events) + "\n")
 f.close()
 quit(1 if fails > 0 else 0)
