extends SceneTree
# Episode 1 save/resume: reload after Mira, after the relay, with the energy paid mid-fight, with the ending pending; reward and Codex integrity;
# corrupted / outdated / hostile save data. A "reload" frees the game, re-reads the save file through Profile and builds a fresh Main.
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
 create_timer(240.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node, until_call:Callable, max_frames:int=900) -> bool:
 var frames=0
 while frames<max_frames:
  if until_call.call():
   return true
  if is_instance_valid(ep):
   for c in ep.get_children():
    if c.has_method("finish_all"):
     c.finish_all()
    elif c.has_method("finish"):
     c.finish()
  await process_frame
  frames+=1
 return until_call.call()
func wipe_saves() -> void:
 for suffix in ["",".bak",".tmp"]:
  var path=LocalSave.PATH+suffix
  if FileAccess.file_exists(path):
   DirAccess.remove_absolute(path)
func fresh() -> void:
 wipe_saves()
 profile.active_run=""
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.energy=60
 profile.data.energy_at=int(Time.get_unix_time_from_system())
 profile.persist()
# Simulates closing and reopening the game: the in-memory profile is dropped and re-read from the save file, and a new Main is built.
func reload() -> void:
 if is_instance_valid(main):
  main.queue_free()
 await process_frame
 profile.active_run=""
 profile._ready()
 profile.data.settings.sound=false
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
func has_card(ep:Node) -> bool:
 for c in ep.get_children():
  if c.get_script()!=null and c.get_script().get_global_name()=="TitleCard":
   return true
 return false
func write_raw(path:String, text:String) -> void:
 var f=FileAccess.open(path,FileAccess.WRITE)
 f.store_string(text)
 f.close()
func run() -> void:
 profile=root.get_node("Profile")
 fresh()
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 # ---- A. play to Mira, reload, resume --------------------------------------------------------------------------------------------------
 main.start_episode()
 await process_frame
 var ep=main.screen.get_child(0)
 await skip_scenes(ep,func(): return ep.explore!=null)
 var saved=profile.backend.read_data().get("mission_progress",{}).get("1-1",{})
 check(saved.get("intro",false)==true and int(saved.get("step",-1))==0,"Seeing the intro and reaching exploration is saved")
 var ex=ep.explore
 await create_timer(0.55).timeout
 ex.px=540.0
 await process_frame
 ex.act_edge=true
 await process_frame
 await process_frame
 await skip_scenes(ep,func(): return not ep.busy)
 saved=profile.backend.read_data().get("mission_progress",{}).get("1-1",{})
 check(ep.step==1 and int(saved.get("step",-1))==1 and absf(float(saved.get("px",0))-ex.px)<2.0,"Talking to Mira advances to the relay objective and saves step and position")
 var codex_before=profile.data.codex.duplicate()
 var gold=int(profile.data.gold)
 var xp=int(profile.data.xp)
 var energy=int(profile.data.energy)
 await reload()
 check(profile.data.codex==codex_before and int(profile.data.energy)==energy,"Reload keeps Codex entries and energy untouched")
 main.start_episode()
 await process_frame
 ep=main.screen.get_child(0)
 await process_frame
 check(not has_card(ep) and ep.explore!=null,"Resuming skips the title card and opening scene and returns to the district")
 ex=ep.explore
 check(ep.step==1 and ex.enabled.terminal and ex.enabled.mira and ex.objective_text=="Reboot the relay terminal","Resume restores the relay objective and interactions")
 check(absf(ex.px-540.0)<60.0 and not ex.blocked(ex.px,ex.py),"Resume puts the Hero back near where they stood, not inside Mira")
 check(profile.active_run=="" and int(profile.data.energy)==energy,"Resuming exploration spends no energy")
 # talking to Mira again after the reload does not duplicate Codex entries or story progress
 await create_timer(0.55).timeout
 ex.px=540.0
 await process_frame
 ex.act_edge=true
 await process_frame
 await process_frame
 await skip_scenes(ep,func(): return not ep.busy)
 check(ep.step==1 and profile.data.codex.count("mira")==1 and int(profile.data.gold)==gold and int(profile.data.xp)==xp,"Re-talking to Mira after a reload does not duplicate Codex entries or rewards")
 # ---- B. relay done, reload, resume at the breach ----------------------------------------------------------------------------------------
 ex.px=1560.0
 await process_frame
 ex.act_button.held=true
 var started=Time.get_ticks_msec()
 while not ep.busy and Time.get_ticks_msec()-started<4000:
  await process_frame
 ex.act_button.held=false
 await skip_scenes(ep,func(): return not ep.busy)
 check(ep.step==2 and int(profile.backend.read_data().get("mission_progress",{}).get("1-1",{}).get("step",-1))==2,"Completing the relay is saved")
 await reload()
 main.start_episode()
 await process_frame
 ep=main.screen.get_child(0)
 await process_frame
 ex=ep.explore
 check(not has_card(ep) and ep.step==2 and ex.props.breach_open and ex.props.terminal_done and ex.enabled.breach and not ex.enabled.terminal,"Resume after the relay: relay stays rebooted and the breach is open")
 check(profile.data.codex.count("terminal")==1,"Relay Codex entry is not duplicated")
 # ---- C. pay for the fight, reload mid-battle, resume without a second charge ------------------------------------------------------------
 await create_timer(0.55).timeout
 ex.px=2200.0
 await process_frame
 ex.act_edge=true
 await skip_scenes(ep,func(): return main.scene_name=="battle",900)
 check(main.scene_name=="battle" and profile.active_run=="1-1" and int(profile.data.energy)==energy-6,"Entering the breach pays the 6 energy once")
 check(profile.backend.read_data().get("mission_progress",{}).get("1-1",{}).get("combat_run",false)==true,"The paid attempt is saved")
 await reload()
 check(int(profile.data.energy)==energy-6 and profile.mission_progress("1-1").get("combat_run",false)==true,"After a reload mid-battle the energy stays paid (no refund, no extra charge)")
 main.start_episode()
 await process_frame
 ep=main.screen.get_child(0)
 await process_frame
 ex=ep.explore
 var breach_label=""
 for spot in ex.spots:
  if spot.id=="breach":
   breach_label=spot.label
 check(ep.step==2 and "ENERGY PAID" in breach_label,"The resumed breach says the energy is already paid")
 await create_timer(0.55).timeout
 ex.px=2200.0
 await process_frame
 ex.act_edge=true
 await skip_scenes(ep,func(): return main.scene_name=="battle",900)
 check(main.scene_name=="battle" and int(profile.data.energy)==energy-6,"Re-entering after a reload does not charge energy again")
 var battle=main.screen.get_child(0)
 battle.intro=0
 # paid attempt with no energy left still resumes
 profile.data.energy=0
 profile.active_run=""
 check(profile.begin_run("1-1") and int(profile.data.energy)==0,"A paid attempt resumes even at 0 energy")
 profile.data.energy=energy-6
 # ---- D. boss beaten, reload before the ending ends -> ending resumes, rewards exactly once ------------------------------------------------
 battle.foe.receive(100000)
 await create_timer(0.3).timeout
 battle.intro=0
 battle.foe.receive(100000)
 await create_timer(2.0).timeout
 check(main.scene_name=="ending" and profile.mission_progress("1-1").get("battle_won",false)==true and not profile.data.completed.has("1-1"),"Winning marks the ending pending; rewards are not paid yet")
 var gold_pre=int(profile.data.gold)
 var energy_pre=int(profile.data.energy)
 await reload()
 check(int(profile.data.gold)==gold_pre and not profile.data.completed.has("1-1"),"Reloading during the ending pays nothing")
 main.start_episode()
 await process_frame
 check(main.scene_name=="ending" and profile.active_run=="1-1" and int(profile.data.energy)==energy_pre,"Resuming plays the ending (no fight, no energy)")
 var ending=main.screen.get_child(0)
 await skip_scenes(ending,func(): return main.scene_name=="result",900)
 check(main.scene_name=="result" and profile.data.completed.count("1-1")==1 and int(profile.data.gold)==gold_pre+250 and int(profile.data.xp)>=xp,"First-clear rewards are paid exactly once after the resumed ending (+250 gold)")
 var after=profile.mission_progress("1-1")
 check(not after.has("battle_won") and not after.has("combat_run") and not after.has("step") and not after.has("intro") and not after.has("px"),"Finishing clears the resume state")
 check(profile.finish_run(true).is_empty() and int(profile.data.gold)==gold_pre+250,"A second finish pays nothing")
 await reload()
 main.start_episode()
 await process_frame
 check(main.scene_name=="episode" and profile.active_run=="","After completion, starting Episode 1 again replays it from the beginning (no stale resume, no ending)")
 ep=main.screen.get_child(0)
 await process_frame
 check(has_card(ep) and ep.explore==null,"A completed mission starts with the title card again")
 # replay reward rule is unchanged
 var gold_c=int(profile.data.gold)
 profile.active_run=""
 profile.data.energy=60
 check(profile.begin_run("1-1"),"Replay run starts")
 var r=profile.finish_run(true)
 check(not r.first and int(profile.data.gold)==gold_c+100 and profile.data.completed.count("1-1")==1,"Replay rewards (55 XP / 100 gold) and no duplicate completion are unchanged")
 # ---- E. EXIT keeps the spot -------------------------------------------------------------------------------------------------------------
 fresh()
 await reload()
 main.start_episode()
 await process_frame
 ep=main.screen.get_child(0)
 await skip_scenes(ep,func(): return ep.explore!=null)
 ep.explore.px=900.0
 ep.explore.request_exit()
 ep.explore.request_exit()
 await process_frame
 check(main.scene_name=="home" and absf(float(profile.mission_progress("1-1").get("px",0))-900.0)<2.0,"EXIT saves the Hero's position")
 main.show_mission("1-1")
 await process_frame
 var resume_btn=false
 for n in main.modal.get_children() if is_instance_valid(main.modal) else []:
  if n is Button and str(n.text).begins_with("RESUME"):
   resume_btn=true
 check(resume_btn,"The mission card offers RESUME once progress exists")
 main.close_modal()
 # ---- F. corrupted, outdated and hostile data --------------------------------------------------------------------------------------------
 var bad_sets=[
  {"step":"banana","px":"x","intro":"yes"},
  {"step":99,"px":-500.0,"intro":true},
  {"step":1.5,"px":1.0e30,"intro":true},
  {"step":-3,"px":null,"intro":null},
  {"step":[1,2],"px":{"a":1},"intro":[true]},
  {}
 ]
 var all_ok=true
 for bad in bad_sets:
  fresh()
  profile.data.mission_progress={"1-1":bad}
  profile.persist()
  await reload()
  main.start_episode()
  await process_frame
  var e2=main.screen.get_child(0)
  await process_frame
  var okay=main.scene_name=="episode" and e2.step==0 and profile.active_run=="" and int(profile.data.gold)==500 and profile.data.completed.is_empty()
  if e2.explore!=null:
   okay=okay and e2.explore.px>=80.0 and e2.explore.px<=e2.explore.world_w-80.0
  all_ok=all_ok and okay
  if not okay:
   print("  bad progress case failed: ",bad)
 check(all_ok,"Missing, wrong-typed, out-of-range, NaN-like and non-finite progress values are ignored safely (Episode 1 starts normally)")
 fresh()
 profile.data.mission_progress={"1-1":{"intro":true,"step":9,"px":300.0,"combat_run":"yes","battle_won":"maybe"}}
 profile.persist()
 await reload()
 check(not profile.begin_ending("1-1") and profile.active_run=="","A non-boolean battle_won flag does not trigger the ending")
 check(profile.begin_run("1-1") and int(profile.data.energy)==54,"A non-boolean combat_run flag is not treated as paid: the run is charged normally")
 profile.active_run=""
 # unreadable file / bad checksum / truncated file: falls back to defaults, never crashes
 fresh()
 write_raw(LocalSave.PATH,"{not json")
 write_raw(LocalSave.PATH+".bak","also broken")
 await reload()
 check(profile.data.onboarded==false and int(profile.data.gold)==500 and profile.data.completed.is_empty(),"A corrupted save and backup fall back to a fresh profile without crashing")
 fresh()
 profile.data.gold=777
 profile.persist()
 var good=FileAccess.get_file_as_string(LocalSave.PATH)
 var tampered=good.replace("777","999")
 write_raw(LocalSave.PATH,tampered)
 await reload()
 check(int(profile.data.gold)!=999,"A tampered save (checksum mismatch) is rejected")
 # corrupt current file but valid backup is used
 fresh()
 profile.data.gold=640
 profile.persist()
 profile.data.gold=641
 profile.persist()   # now .bak holds 640
 write_raw(LocalSave.PATH,"garbage")
 await reload()
 check(int(profile.data.gold)==640,"A corrupted save recovers from the backup copy")
 # outdated save: no mission_progress / codex keys at all, Episode 1 already completed
 fresh()
 var legacy=profile.defaults()
 legacy.onboarded=true
 legacy.erase("mission_progress")
 legacy.erase("codex")
 legacy.completed=["1-1"]
 legacy.gold=900
 profile.backend.write_data(legacy)
 await reload()
 check(profile.data.completed==["1-1"] and int(profile.data.gold)==900 and profile.data.mission_progress is Dictionary and profile.data.codex is Array,"An outdated save without progress/Codex keys loads with safe defaults")
 main.start_episode()
 await process_frame
 check(main.scene_name=="episode","An outdated save can start Episode 1 normally")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
