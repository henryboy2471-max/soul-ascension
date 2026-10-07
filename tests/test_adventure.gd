extends SceneTree
# Drives Episode 1 end to end: intro -> explore -> NPC -> terminal -> breach -> boss battle -> ending -> result.
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
 create_timer(120.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
# Dismisses any title card or dialogue box under `ep` until `until_call` returns true.
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
func run() -> void:
 profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 # Story data sanity.
 var ok=true
 for list in [EpisodeData.INTRO,EpisodeData.MIRA_TALK,EpisodeData.MIRA_REPEAT,EpisodeData.BOARD,EpisodeData.TERMINAL,EpisodeData.BREACH,EpisodeData.NO_ENERGY,EpisodeData.OUTRO]:
  if list.is_empty(): ok=false
  for line in list:
   if not EpisodeData.SPEAKERS.has(line.who) or str(line.text).is_empty(): ok=false
 check(ok,"Episode 1 script is complete and uses known speakers")
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 var energy_before=int(profile.data.energy)
 var gold_before=int(profile.data.gold)
 main.start_episode()
 await process_frame
 var ep=main.screen.get_child(0)
 check(main.scene_name=="episode" and profile.active_run=="","Episode starts without spending energy")
 await skip_scenes(ep,func(): return ep.explore!=null)
 check(ep.explore!=null and ep.step==0,"Title card and opening scene lead into exploration")
 var ex=ep.explore
 check(ex.objective_text!="" and ex.enabled.mira and not ex.enabled.terminal,"First objective set: talk to Mira")
 # Movement
 var x0=ex.px
 ex.stick.direction=Vector2(1,0)
 await create_timer(0.5).timeout
 ex.stick.direction=Vector2.ZERO
 check(ex.px-x0>110,"Walking covers ground at exploration speed")
 # Optional lore spot does not disturb the main objective
 ex.px=1860.0
 await process_frame
 ex.act_edge=true
 await process_frame
 await process_frame
 check(ep.busy and ep.step==0,"Optional Lantern mural opens a lore scene without advancing the story")
 await skip_scenes(ep,func(): return not ep.busy)
 var snd=root.get_node("Sound")
 check(snd.loops.has("city") and snd.loops.has("realm") and snd.loops.city.data.size()==22050*4*2 and snd.clips.has("step"),"Ambience loops and footstep clip are generated")
 # Talk to Mira
 await create_timer(0.55).timeout
 ex.px=540.0
 await process_frame
 ex.act_edge=true
 await process_frame
 await process_frame
 check(ep.busy and ex.locked,"Talking to Mira starts dialogue and locks movement")
 await skip_scenes(ep,func(): return not ep.busy)
 check(ep.step==1 and ex.enabled.terminal and not ex.locked,"Dialogue advances the objective to the relay terminal")
 # Pressing act right as a conversation closes must not immediately restart it
 ex.act_edge=true
 await process_frame
 await process_frame
 check(not ep.busy and ex.act_block>0.0,"Input guard stops a conversation from instantly re-triggering"
)
 # Hold-to-channel terminal
 ex.px=1560.0
 await process_frame
 ex.act_button.held=true
 var started=Time.get_ticks_msec()
 while not ep.busy and Time.get_ticks_msec()-started<4000:
  await process_frame
 var t=(Time.get_ticks_msec()-started)/1000.0
 ex.act_button.held=false
 check(ep.busy and t>1.0 and t<3.0,"Terminal needs a sustained hold (not an instant tap)")
 await skip_scenes(ep,func(): return not ep.busy)
 check(ep.step==2 and ex.props.breach_open and ex.enabled.breach,"Terminal reboot opens the Soul Realm breach")
 # Not enough energy: stays in the world, no battle
 await create_timer(0.55).timeout
 profile.data.energy=0
 ex.px=2200.0
 await process_frame
 ex.act_edge=true
 await skip_scenes(ep,func(): return ep.step==2 and not ep.busy and not ex.locked,600)
 check(main.scene_name=="episode" and profile.active_run=="","Breach without energy keeps the player in the district")
 profile.data.energy=energy_before
 # Enter the breach for real
 await create_timer(0.55).timeout
 ex.act_edge=true
 await skip_scenes(ep,func(): return main.scene_name=="battle",900)
 check(main.scene_name=="battle" and profile.active_run=="1-1","Breach transitions into the Soul Realm battle")
 check(int(profile.data.energy)==energy_before-6,"Entering the Soul Realm spends 6 energy")
 var battle=main.screen.get_child(0)
 check(battle.boss_mode,"Episode battle runs in boss mode")
 battle.intro=0
 # Boss phase two
 battle.foe.health=battle.foe.max_health*0.45
 await process_frame
 await process_frame
 check(battle.phase==2 and battle.foe.attack>28 and battle.telegraph_len<0.8,"Boss escalates at 50% health")
 # Win -> ending scene -> result
 battle.foe.receive(100000)
 await create_timer(1.0).timeout
 check(main.scene_name=="ending","Winning the boss fight plays the ending scene")
 var ending=main.screen.get_child(0)
 await skip_scenes(ending,func(): return main.scene_name=="result",900)
 check(main.scene_name=="result" and profile.active_run=="","Ending and next-episode teaser lead to rewards")
 check(profile.data.completed.has("1-1") and int(profile.data.gold)==gold_before+250,"First clear rewards are granted once")
 # Exit confirmation in the world
 main.start_episode()
 await process_frame
 ep=main.screen.get_child(0)
 await skip_scenes(ep,func(): return ep.explore!=null)
 ep.explore.request_exit()
 check(main.scene_name=="episode","First EXIT tap only arms the button")
 ep.explore.request_exit()
 await process_frame
 check(main.scene_name=="home","Second EXIT tap returns home")
 # Battle-only path still works without spending the episode
 check(main.start_battle(false) and main.scene_name=="battle","Battle-only mode is still available")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
