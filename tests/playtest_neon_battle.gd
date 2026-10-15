extends SceneTree
# Real-window playtest of Episode 1 from the street to the ending (needs a display). Companion to playtest_neon_window.gd:
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --resolution 1280x720 --script res://tests/playtest_neon_battle.gd -- OUTDIR LABEL
# Walks Mira -> relay -> breach with injected key events, then fights the Soul Realm battle with a simple key-driven bot (WASD / J / K / Space / R / F, the game's own controls),
# screenshots the Shade wave, the Enforcer intro, the Phase 2 change, the finisher, the ending, the teaser and the reward screen, and reports progression (XP, gold, energy, completion flag).
var out := "/tmp"
var label := "desktop"
var main
var ep
var events: Array = []
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
 await create_timer(0.06).timeout
func shot(name: String, wait := 0.2) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("%s/%s_b_%s.png" % [out, label, name])
 note("shot " + name)
func scene() -> String:
 return str(main.scene_name)
func walk_to(target: float, timeout := 25.0) -> void:
 var x = ep.explore
 var code := KEY_D if target > x.px else KEY_A
 var s := Time.get_ticks_msec()
 key(code, true)
 while float(Time.get_ticks_msec() - s) / 1000.0 < timeout and ((code == KEY_D and x.px < target) or (code == KEY_A and x.px > target)):
  await process_frame
 key(code, false)
 await create_timer(0.25).timeout
func dialogue_open() -> bool:
 for c in ep.get_children():
  if c.has_method("finish_all"): return true
 return false
func flush_dialogue(max_s := 25.0) -> void:
 var s := Time.get_ticks_msec()
 while float(Time.get_ticks_msec() - s) / 1000.0 < max_s and (dialogue_open() or ep.explore == null or ep.explore.locked):
  await tap(KEY_ENTER)
func battle_node():
 for c in main.screen.get_children():
  if c.has_method("enter_phase_two"): return c
 return null
func fight() -> void:
 var seen := {}
 var last_j := 0
 var last_k := 0
 var last_dodge := 0
 var start := Time.get_ticks_msec()
 var shot_flags := {}
 while scene() == "battle":
  var b = battle_node()
  if b == null or not is_instance_valid(b): break
  await process_frame
  if not is_instance_valid(b): break
  var now := Time.get_ticks_msec()
  var secs := float(now - start) / 1000.0
  if b.ended:
   if not shot_flags.has("ended"):
    shot_flags["ended"] = true
    note("battle ended flag set (finisher/result transition); hero hp %.0f/%.0f, foe hp %.0f, combo %d, phase %d" % [b.hero.health, b.hero.max_health, b.foe.health, b.combo, b.phase])
    await shot("09b_finisher_cinematic", 0.12)
    await shot("09c_finisher_aftermath", 0.5)
   continue
  var tag := "wave%d_phase%d" % [b.wave, b.phase]
  if not seen.has(tag):
   seen[tag] = true
   note("battle state " + tag + "  foe=" + str(b.foe_name_label.text) + "  hero hp %.0f/%.0f" % [b.hero.health, b.hero.max_health])
   if b.phase == 2:
    await shot("08_boss_phase2_banner", 0.35)
   elif b.wave == 0:
    await shot("04_wave1_shade_start", 0.5)
   elif b.wave >= 1:
    await shot("06_boss_intro_enforcer", 0.5)
  if b.intro > 0:
   key(KEY_D, false); key(KEY_A, false)
   continue
  if b.foe.health > 0 and not b.foe.dead and not seen.has("mid%d" % b.wave) and b.foe.health < b.foe.max_health * 0.7:
   seen["mid%d" % b.wave] = true
   await shot(("05_wave1_mid" if b.wave == 0 else "07_boss_mid"), 0.0)
  if b.foe.health > 0 and b.foe.health < b.foe.max_health * 0.12 and not seen.has("low%d" % b.wave):
   seen["low%d" % b.wave] = true
   await shot(("09_boss_nearly_dead" if b.wave >= 1 else "05b_shade_nearly_dead"), 0.0)
  # key-driven bot: close the distance, align the lane, strike, dodge, mend, ultimate
  var dx: float = b.foe.position.x - b.hero.position.x
  var dy: float = b.foe.position.y - b.hero.position.y
  key(KEY_D, dx > 120.0)
  key(KEY_A, dx < -120.0)
  key(KEY_S, dy > 26.0)
  key(KEY_W, dy < -26.0)
  if absf(dx) < 190.0 and absf(dy) < 60.0:
   if now - last_j > 380:
    last_j = now
    key(KEY_J, true)
    await create_timer(0.05).timeout
    key(KEY_J, false)
   if now - last_k > 1900:
    last_k = now
    key(KEY_K, true)
    await create_timer(0.05).timeout
    key(KEY_K, false)
  if now - last_dodge > 2600 and absf(dx) < 220.0:
   last_dodge = now
   key(KEY_SPACE, true)
   await create_timer(0.05).timeout
   key(KEY_SPACE, false)
  if b.hero.health < b.hero.max_health * 0.45 and b.cooldowns.mend <= 0.0 and b.energy >= 20.0:
   key(KEY_R, true)
   await create_timer(0.05).timeout
   key(KEY_R, false)
  if b.ultimate >= 100.0:
   key(KEY_F, true)
   await create_timer(0.05).timeout
   key(KEY_F, false)
  if secs > 420.0:
   note("battle timeout")
   break
 for c in [KEY_D, KEY_A, KEY_S, KEY_W]: key(c, false)
func run() -> void:
 t0 = Time.get_ticks_msec()
 var profile = root.get_node("Profile")
 profile.data = profile.defaults()
 profile.data.onboarded = true
 profile.data.settings.sound = false
 var xp0 = int(profile.data.get("xp", 0))
 var gold0 = int(profile.data.get("gold", 0))
 main = load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.8).timeout
 main.show_home()
 await shot("00_home", 0.6)
 main.start_episode("1-1")
 await create_timer(0.8).timeout
 ep = main.screen.get_child(0)
 await flush_dialogue()
 while ep.explore == null: await process_frame
 await create_timer(1.0).timeout
 await walk_to(500.0)
 await tap(KEY_ENTER)
 await create_timer(0.8).timeout
 await flush_dialogue()
 note("after Mira step=" + str(ep.step))
 await walk_to(1500.0)
 key(KEY_E, true)
 await create_timer(2.6).timeout
 key(KEY_E, false)
 await flush_dialogue(10.0)
 note("after relay step=" + str(ep.step))
 await walk_to(2150.0)
 await shot("01_breach_open_prompt", 0.4)
 var energy0 = float(profile.data.get("energy", -1))
 await tap(KEY_ENTER)
 await create_timer(0.8).timeout
 for i in 30:
  if scene() == "battle": break
  await shot("02_mission_zone_or_transition", 0.3) if i == 1 else await create_timer(0.3).timeout
  await tap(KEY_ENTER)
 note("scene now: " + scene())
 if scene() != "battle":
  note("FAIL: battle did not start")
  finish(xp0, gold0, energy0)
  return
 await shot("03_battle_first_frame", 0.3)
 await fight()
 # --- result / ending / teaser / reward screens
 var seen_scenes := {}
 var s := Time.get_ticks_msec()
 while float(Time.get_ticks_msec() - s) / 1000.0 < 120.0 and scene() != "home":
  var sc := scene()
  if not seen_scenes.has(sc):
   seen_scenes[sc] = true
   note("scene -> " + sc)
   await shot("10_" + sc, 1.2)
  # advance with the game's own input (Enter / E advances dialogue); the rewards screen's NEXT EPISODE button is pressed where the game expects it (rewards -> teaser -> home)
  var pressed_button := false
  for n in main.screen.find_children("*", "Button", true, false):
   var t := str(n.text).to_upper()
   if sc == "result" and t.begins_with("NEXT EPISODE") and n.visible and not n.disabled:
    note("pressing the result screen button: " + str(n.text))
    await shot("11_result_before_next_episode", 0.2)
    n.pressed.emit()
    pressed_button = true
    break
  if not pressed_button: await tap(KEY_ENTER)
  await create_timer(0.35).timeout
 note("final scene: " + scene() + "  level " + str(profile.data.get("level")) + "  completed " + str(profile.data.get("completed")))
 await shot("12_final", 0.8)
 finish(xp0, gold0, energy0)
func finish(xp0: int, gold0: int, energy0: float) -> void:
 var profile = root.get_node("Profile")
 note("progression: xp %d -> %d, gold %d -> %d, energy %.1f -> %.1f, completed=%s" % [xp0, int(profile.data.get("xp", 0)), gold0, int(profile.data.get("gold", 0)), energy0, float(profile.data.get("energy", -1)), str(profile.data.get("completed", []))])
 var f := FileAccess.open("%s/battle_report_%s.txt" % [out, label], FileAccess.WRITE)
 f.store_string("\n".join(events) + "\n")
 f.close()
 quit(0)
