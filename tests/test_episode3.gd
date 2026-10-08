extends SceneTree
# M3: Episode 2 breach entry (6 energy only on entry, saved run state), Soul Realm battle, Resonance Shade pacing, Hollow Cantor,
# Phase 2 "THE CHORUS RISES", Mira's one-shot lantern support, Codex unlock, and the temporary battle-complete hand-off.
var passed=0
var failed=0
var main
var profile
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(280.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip(ep:Node, until_call:Callable, max_frames:int=600) -> void:
 var frames=0
 while frames<max_frames:
  if until_call.call():
   return
  if is_instance_valid(ep):
   for c in ep.get_children():
    if c.has_method("finish_all"): c.finish_all()
    elif c.has_method("finish"): c.finish()
  await process_frame
  frames+=1
func texts(node:Node, out:Array) -> void:
 if node is Label or node is Button:
  if node.visible and str(node.text)!="": out.append(str(node.text))
 for c in node.get_children(): texts(c,out)
func key(code:int, pressed:bool) -> void:
 var e=InputEventKey.new()
 e.physical_keycode=code
 e.keycode=code
 e.pressed=pressed
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func touch(index:int, pressed:bool, pos:Vector2) -> void:
 var e=InputEventScreenTouch.new()
 e.index=index
 e.pressed=pressed
 e.position=pos
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func drag(index:int, pos:Vector2) -> void:
 var e=InputEventScreenDrag.new()
 e.index=index
 e.position=pos
 Input.parse_input_event(e)
 Input.flush_buffered_events()
const READY={"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true}
func fresh(progress:Dictionary=READY) -> void:
 if main!=null and is_instance_valid(main):
  main.queue_free()
  await process_frame
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.data.completed=["1-1"]
 profile.active_run=""
 if not progress.is_empty():
  profile.data.mission_progress={"1-2":progress.duplicate(true)}
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
func start():
 main.start_episode("1-2")
 await process_frame
 var ep=main.screen.get_child(0)
 await skip(ep,func(): return ep.explore!=null)
 return ep
func spot_label(ep:Node, id:String) -> String:
 for sp in ep.explore.spots:
  if sp.id==id: return str(sp.label)
 return ""
func prompt_of(ep:Node):
 for c in ep.get_children():
  if c.has_method("decide") and "paid" in c: return c
 return null
# Walks to the breach, opens the confirmation and returns it (not decided yet).
func open_prompt(ep):
 ep.explore.px=2600.0
 await process_frame
 ep.on_interact("breach")
 var guard=0
 while prompt_of(ep)==null and guard<60:
  await process_frame
  guard+=1
 var prompt=prompt_of(ep)
 if prompt!=null:
  prompt.armed=0.0
 return prompt
# Full entry: breach-ready save, enough energy, confirm. Returns the Battle.
func enter_battle(energy:int=60):
 await fresh()
 profile.data.energy=energy
 profile.data.energy_at=int(Time.get_unix_time_from_system())
 var ep=await start()
 var prompt=await open_prompt(ep)
 prompt.decide(true)
 await process_frame
 await process_frame
 var battle=main.screen.get_child(0)
 return battle
func skip_intro(battle) -> void:
 battle.skip_whispers()
 battle.intro=0.0
 battle.tip.text=""
func kill_foe(battle) -> void:
 battle.foe.receive(1000000.0)
 await create_timer(0.8).timeout
func run() -> void:
 root.size=Vector2i(1280,720)
 profile=root.get_node("Profile")
 var BattleScript=load("res://scripts/combat/battle.gd")
 var shade_frames=load("res://assets/enemies/resonance_shade/frames.tres")
 # ---------------- breach entry and energy ----------------
 await fresh()
 profile.data.energy=5
 profile.data.energy_at=int(Time.get_unix_time_from_system())
 var ep=await start()
 check(ep.step==4 and ep.explore.props.breach_open,"Resuming a saved Episode 2 with the breach open lands on the free-exploration breach step")
 check(profile.data.energy==5 and profile.active_run=="" ,"Exploration alone charges no energy")
 var prompt=await open_prompt(ep)
 check(prompt!=null and prompt.cost==6,"Interacting with the open breach shows the entry confirmation (6 energy)")
 prompt.decide(true)
 await process_frame
 await process_frame
 var t=[]
 texts(main,t)
 check(main.scene_name=="episode" and profile.active_run=="" and profile.data.energy==5,"Without 6 energy the breach does not open combat and nothing is charged")
 check(t.has("ENERGY RECHARGING"),"The normal energy-recharging screen is shown")
 check(profile.mission_progress("1-2").get("resonators",[]).size()==3 and profile.mission_progress("1-2").get("array",false) and not profile.mission_progress("1-2").has("combat_run"),"Resonator and mission progress survive a failed combat entry")
 main.close_modal()
 await process_frame
 check(is_instance_valid(ep) and ep.explore.props.breach_open and ep.synced.size()==3,"The Lantern Quarter is still intact and can be revisited")
 # declining costs nothing
 profile.data.energy=60
 prompt=await open_prompt(ep)
 prompt.decide(false)
 await skip(ep,func(): return not ep.busy,200)
 check(profile.data.energy==60 and main.scene_name=="episode" and profile.active_run=="","Choosing NOT YET leaves energy and the scene untouched")
 # keyboard: Enter confirms
 prompt=await open_prompt(ep)
 key(KEY_ENTER,true)
 key(KEY_ENTER,false)
 await process_frame
 await process_frame
 check(main.scene_name=="battle" and profile.data.energy==54,"Keyboard: Enter on the confirmation enters the breach and charges exactly 6 energy (60 to 54)")
 check(profile.active_run=="1-2" and profile.mission_progress("1-2").get("combat_run",false),"Combat entry is saved in the mission progress")
 check(profile.backend.read_data().mission_progress["1-2"].get("combat_run",false) and int(profile.backend.read_data().energy)==54,"The saved file holds the combat-entry state and the paid energy")
 # ---------------- reload / resume does not double charge ----------------
 var battle=main.screen.get_child(0)
 battle.queue_free()
 main.queue_free()
 await process_frame
 profile.active_run=""
 profile._ready()
 check(int(profile.data.energy)==54 and profile.mission_progress("1-2").get("combat_run",false),"After a reload the paid run is still recorded (54 energy)")
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 ep=await start()
 check(ep.step==4 and spot_label(ep,"breach").contains("ENERGY PAID"),"The breach offers RESUME with energy paid after a reload")
 prompt=await open_prompt(ep)
 check(prompt.paid,"The confirmation says the energy is already paid")
 prompt.decide(true)
 await process_frame
 await process_frame
 check(main.scene_name=="battle" and int(profile.data.energy)==54 and profile.active_run=="1-2","Resuming the active run does not charge energy a second time")
 # ---------------- Wave 1: Episode 2 Resonance Shade ----------------
 battle=main.screen.get_child(0)
 check(battle.waves.size()==2 and battle.waves[0].look=="shade" and battle.waves[1].look=="cantor","Two waves only: Resonance Shade then Hollow Cantor")
 check(battle.foe.max_health==300.0 and battle.foe.attack==23.0 and battle.foe_speed>170.0 and battle.telegraph_len<0.8 and battle.recovery<1.0,"Episode 2 Shade uses its mission-data stats and is faster than Episode 1's")
 check(battle.foe.sprite_frames==shade_frames,"Wave 1 uses the approved Shade art")
 check(battle.realm_art!=null and battle.realm_art.theme_id=="rain","The Soul Realm arena uses the violet-rain treatment")
 check(battle.intro>3.0 and is_instance_valid(battle.whisper_label),"The three resonator whispers play before combat (controls locked)")
 await create_timer(1.0).timeout
 check(battle.whisper_label.text.contains("A SLEEPER") and MissionDefs.get_def("1-2").whispers.size()==3,"Whisper beats are the three sleeper memories")
 skip_intro(battle)
 check(battle.intro==0.0,"The whispers can be skipped and combat starts")
 # Episode 1 Shade is unchanged by this
 var e1=BattleScript.new()
 e1.mission_id="1-1"
 e1.boss_mode=true
 main.screen.add_child(e1)
 await process_frame
 check(e1.foe.max_health==240.0 and e1.foe.attack==20.0 and e1.foe_speed==170.0 and e1.telegraph_len==0.8 and e1.recovery==1.0 and e1.telegraph_radius==100.0 and e1.telegraph_style=="","Episode 1's Shade keeps its original stats and pacing")
 e1.queue_free()
 await process_frame
 # ---------------- telegraph honesty on wave 1 (radius 100) ----------------
 var h0=battle.hero.health
 battle.target=battle.hero.position+Vector2(130,0)
 battle.telegraph=0.001
 battle.foe.stun=0.0
 battle.hero.invincible=0.0
 await process_frame
 await process_frame
 check(battle.hero.health==h0,"Wave 1 telegraph radius is 100: a hero 130 away is safe")
 # ---------------- Shade -> Cantor handoff ----------------
 var shade=battle.foe
 var shade_scale=shade.scale.x
 await kill_foe(battle)
 check(battle.wave==1 and battle.foe!=shade and battle.foe.look=="cantor" and battle.waves.size()==2,"Shade defeat hands off to the Hollow Cantor (wave 2 of 2)")
 check(battle.foe_name_label.text=="HOLLOW CANTOR" and battle.foe_sub_label.text=="THE VOICE IN THE RAIN","Unique HOLLOW CANTOR boss nameplate")
 check(battle.intro_card.text=="HOLLOW CANTOR","Boss intro card shows the Hollow Cantor")
 skip_intro(battle)
 battle.intro=0.0
 var cantor=battle.foe
 var cantor_frames=load("res://assets/enemies/hollow_cantor/frames.tres")
 check(cantor.cantor and not cantor.temp_art and cantor.sprite_frames==cantor_frames and cantor.sprite_frames!=shade_frames,"Cantor uses its dedicated Hollow Cantor frames.tres (not the Shade sprite)")
 check(cantor.scale.x>=1.4 and cantor.scale.x>shade_scale and cantor.sprite.modulate==Color.WHITE,"Cantor is larger and carries no tint workaround")
 check(cantor.max_health==960.0 and battle.foe_accent(battle.waves[1])==Color("cdbfff"),"Cantor stats and nameplate accent come from mission data")
 # future sprite hook
 check(ResourceLoader.exists("res://assets/enemies/hollow_cantor/frames.tres") and battle.waves[1].frames=="res://assets/enemies/hollow_cantor/frames.tres","The hook path assets/enemies/hollow_cantor/frames.tres is wired and the art exists")
 # the Shade fallback still works when the resource is missing: same wave data pointing at a missing path
 var missing=battle.waves[1].duplicate()
 missing.frames="res://assets/enemies/hollow_cantor/_missing.tres"
 battle.spawn_foe(missing)
 check(battle.foe.temp_art and battle.foe.sprite_frames==shade_frames and battle.foe.sprite.modulate!=Color.WHITE,"If the dedicated resource is missing the Cantor falls back to the tinted Shade sprite")
 battle.foe.queue_free()
 var hook=BattleScript.resolve_enemy_frames(battle.waves[1],func(p): return true)
 check(hook.path=="res://assets/enemies/hollow_cantor/frames.tres" and not hook.temporary,"If hollow_cantor/frames.tres exists the boss resolves to it (not temporary)")
 var fb=BattleScript.resolve_enemy_frames(battle.waves[1],func(p): return p.contains("resonance_shade"))
 check(fb.temporary and fb.path.contains("resonance_shade"),"Without it the boss resolves to the interim Shade frames")
 var fake=shade_frames.duplicate()
 ResourceSaver.save(fake,"user://fake_cantor_frames.tres")
 var def2=battle.waves[1].duplicate()
 def2.frames="user://fake_cantor_frames.tres"
 var hp_before=cantor.max_health
 battle.spawn_foe(def2)
 check(battle.foe.sprite_frames!=shade_frames and not battle.foe.temp_art and battle.foe.sprite.modulate==Color.WHITE and battle.foe.max_health==hp_before and battle.telegraph_radius==150.0,"Dropping in dedicated frames swaps the art without changing combat values")
 battle.foe.queue_free()
 battle.spawn_foe(battle.waves[1])
 cantor=battle.foe
 battle.intro=0.0
 # larger bell-toll telegraph
 check(battle.telegraph_radius==150.0 and battle.telegraph_style=="bell" and battle.telegraph_radius>100.0 and battle.telegraph_len>0.8,"Cantor's bell-toll telegraph is larger (150 vs 100) and slower to read")
 h0=battle.hero.health
 battle.target=battle.hero.position+Vector2(130,0)
 battle.telegraph=0.001
 cantor.stun=0.0
 battle.hero.invincible=0.0
 await process_frame
 await process_frame
 check(battle.hero.health<h0,"A hero 130 away is inside the Cantor's 150 radius (the telegraph is the real hit area)")
 # ---------------- Phase 2 ----------------
 battle.hero.health=battle.hero.max_health*0.5
 battle.hero.invincible=0.0
 var wave_count=battle.waves.size()
 var phase_foe=battle.foe
 var rain0=battle.realm_art.live.rain_k
 phase_foe.health=phase_foe.max_health*0.52
 await process_frame
 check(battle.phase==1 and battle.transform_count==0,"Above 50% there is no Phase 2")
 phase_foe.health=phase_foe.max_health*0.49
 var health_at_trigger=phase_foe.health
 await process_frame
 await process_frame
 check(battle.phase==2 and battle.transform_count==1,"Phase 2 triggers at 50% health")
 check(battle.intro_card.text=="THE CHORUS RISES" and battle.wave_chip.text=="PHASE 2","Banner reads THE CHORUS RISES")
 check(battle.foe==phase_foe and battle.foe.health>=health_at_trigger-1.0 and battle.foe.health<battle.foe.max_health*0.5 and battle.wave==1 and battle.waves.size()==wave_count,"Phase 2 does not reset boss health and spawns no third wave")
 check(battle.telegraph_len==0.7 and battle.recovery==0.62 and battle.telegraph_radius==175.0 and battle.foe.attack==35.0,"Phase 2 telegraphs are faster and the bell reaches farther")
 check(battle.realm_art.live.rain_k>rain0 and battle.realm_art.rain_k==2.2,"Violet/white rain intensifies in Phase 2")
 await create_timer(1.3).timeout
 check(phase_foe.boss_form and phase_foe.form_color!=Color("ff4f72") and phase_foe.aura and phase_foe.sprite_frames==load("res://assets/enemies/hollow_cantor/phase2/frames.tres") and phase_foe.sprite.modulate==Color.WHITE,"Phase 2: the same Cantor swaps to its intensified Phase 2 frames (violet aura, not the Episode 1 red)")
 # Mira's support
 var healed_to=battle.hero.health
 check(battle.support_fired.has("mira_lantern") and battle.support_cues.size()==1 and abs(healed_to-(battle.hero.max_health*0.75))<1.0,"Mira's lantern signal healed 25% of max health once")
 check(battle.hero.get_child_count()>0 and battle.hero.get_children().any(func(c): return c.get_script()!=null and str(c.get_script().resource_path).ends_with("support_fx.gd")),"Lantern-signal visual cue is on the Hero")
 check(is_instance_valid(battle.radio_label) and battle.radio_label.text.begins_with("MIRA VEY"),"Mira's radio line is queued with her name")
 await create_timer(0.8).timeout
 check(battle.radio_label.modulate.a>0.0,"Mira's radio line appears once the banner has faded")
 # no retrigger when the threshold is crossed again
 battle.phase=1
 phase_foe.health=phase_foe.max_health*0.30
 battle.hero.health=battle.hero.max_health*0.4
 await process_frame
 await process_frame
 check(battle.transform_count==1 and battle.support_cues.size()==1 and abs(battle.hero.health-battle.hero.max_health*0.4)<1.0,"Re-crossing 50% cannot retrigger the transformation or Mira's heal")
 # ---------------- Mira support rules (pure) ----------------
 var Support=load("res://scripts/combat/battle_support.gd")
 var FighterScript=load("res://scripts/combat/fighter.gd")
 var ev={"heal_pct":0.25}
 var near=FighterScript.new()
 near.max_health=200.0
 near.health=190.0
 var amount=Support.apply_heal(near,ev)
 check(amount==10 and near.health==200.0,"Mira's heal caps at max health")
 var full=FighterScript.new()
 check(Support.apply_heal(full,ev)==0 and full.health==full.max_health,"A full-health Hero is not raised above max")
 var down=FighterScript.new()
 down.health=0.0
 down.dead=true
 check(Support.apply_heal(down,ev)==0 and down.health==0.0 and down.dead,"Mira cannot revive a dead Hero")
 # battle-level: a dead hero gets nothing and the event is still consumed
 var b2=BattleScript.new()
 b2.mission_id="1-2"
 b2.boss_mode=true
 main.screen.add_child(b2)
 await process_frame
 b2.hero.health=0.0
 b2.hero.dead=true
 var r=b2.run_support("phase2")
 check(r.size()==1 and r[0].healed==0 and b2.hero.health==0.0 and b2.run_support("phase2").is_empty(),"Support on a dead Hero heals nothing and cannot fire again")
 b2.ended=true
 b2.queue_free()
 await process_frame
 # ---------------- Cantor defeat ----------------
 check(not profile.data.codex.has("hollow_cantor"),"hollow_cantor stays locked while the Cantor lives")
 var gold0=int(profile.data.gold)
 var xp0=int(profile.data.xp)
 battle.foe.receive(1000000.0)
 var guard=0
 while main.scene_name!="ending" and guard<400:
  await create_timer(0.1).timeout
  guard+=1
 check(main.scene_name=="ending","Cantor defeat hands off to the Episode 2 ending sequence")
 check(profile.data.codex.has("hollow_cantor"),"Defeating the Hollow Cantor unlocks Codex entry hollow_cantor")
 check(int(profile.data.gold)==gold0 and int(profile.data.xp)==xp0 and not profile.data.completed.has("1-2"),"No rewards or completion yet (those belong to M4)")
 check(not profile.mission_progress("1-2").has("combat_run") and profile.mission_progress("1-2").get("battle_won",false) and profile.mission_progress("1-2").resonators.size()==3,"Paid run is closed (combat_run cleared), battle_won saved, Lantern Quarter progress kept")
 main.show_codex()
 await process_frame
 t=[]
 texts(main,t)
 check(t.has("HOLLOW CANTOR") and t.has("STORY AND WORLD ENTRIES  /  "+str(profile.data.codex.size())+" OF "+str(profile.data.codex.size())+" FOUND") or t.has("HOLLOW CANTOR"),"The Codex lists the Hollow Cantor once found")
 main.close_modal()
 # ---------------- retreat / loss: run closed, re-entry charges again ----------------
 battle=await enter_battle(60)
 check(battle.has_method("run_support") and profile.data.energy==54,"Fresh entry charges 6")
 battle.retreat.emit()
 await process_frame
 await process_frame
 t=[]
 texts(main,t)
 check(profile.active_run=="" and not profile.mission_progress("1-2").has("combat_run") and t.any(func(s): return s.begins_with("RETURN TO THE BREACH")),"A lost/retreated run is closed; the result screen returns to the breach")
 check(profile.mission_progress("1-2").resonators.size()==3 and profile.mission_progress("1-2").get("array",false),"Resonator progress survives a lost run")
 main.start_episode("1-2")
 await process_frame
 ep=main.screen.get_child(0)
 await skip(ep,func(): return ep.explore!=null)
 prompt=await open_prompt(ep)
 prompt.decide(true)
 await process_frame
 await process_frame
 check(main.scene_name=="battle" and profile.data.energy==48,"Re-entering after a loss charges again (54 to 48)")
 # ---------------- touch: joystick + battle buttons in the Soul Realm ----------------
 battle=main.screen.get_child(0)
 skip_intro(battle)
 var x0=battle.hero.position.x
 touch(1,true,Vector2(120,610))
 drag(1,Vector2(220,610))
 await create_timer(0.5).timeout
 check(battle.stick.direction.x>0.7 and battle.hero.position.x-x0>40.0,"Touch: dragging the joystick moves the Hero in the Soul Realm")
 touch(1,false,Vector2(220,610))
 await process_frame
 var hits0=battle.tutorial_hits
 battle.hero.position=battle.foe.position-Vector2(90,0)
 var strike=battle.controls.attack
 touch(2,true,strike.global_position+strike.size/2.0)
 await create_timer(0.35).timeout
 touch(2,false,strike.global_position+strike.size/2.0)
 check(battle.tutorial_hits>hits0 or battle.foe.health<battle.foe.max_health,"Touch: the STRIKE button lands a hit")
 # keyboard in battle
 x0=battle.hero.position.x
 key(KEY_A,true)
 await create_timer(0.4).timeout
 key(KEY_A,false)
 check(battle.hero.position.x<x0-20.0,"Keyboard: A moves the Hero in the Soul Realm")
 # phase 2 (Cantor) HUD and nameplate colors differ from Episode 1's
 check(BattleScript.new().foe_accent({"look":"shade"})==Color("b46bff") and BattleScript.new().foe_accent({"look":"warped"})==Color("ff8a2a"),"Episode 1 nameplate colors are unchanged")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
