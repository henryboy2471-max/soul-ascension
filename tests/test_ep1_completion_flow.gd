extends SceneTree
# Episode 1 completion flow: ending scene -> rewards -> NEXT EPISODE -> teaser -> home (first clear and replay), and AUTO after the first clear.
var passed=0
var failed=0
var scenes:Array=[]
var main
var profile
func check(ok:bool, name:String) -> void:
 if ok: passed+=1; print("PASS: "+name)
 else: failed+=1; print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(170.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func note() -> void:
 if scenes.is_empty() or scenes[-1]!=main.scene_name: scenes.append(main.scene_name)
func wait_scene(name:String, secs:float=6.0) -> void:
 var t=0.0
 while main.scene_name!=name and t<secs:
  note()
  var ep=main.screen.get_child(0) if main.screen.get_child_count()>0 else null
  if ep!=null:
   for c in ep.get_children():
    if c.has_method("finish_all"): c.finish_all()
    elif c.has_method("finish"): c.finish()
  await create_timer(0.1).timeout
  t+=0.1
 note()
func button(text:String):
 for b in main.screen.find_children("*","Button",true,false):
  if b.text.begins_with(text) and b.visible and not b.disabled: return b
 return null
func run() -> void:
 profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 # --- AUTO is locked before the first clear
 check(not profile.data.completed.has("1-1") and not MissionDefs.is_unlocked("1-2",profile.data.completed),"Fresh save: 1-1 not cleared, Episode 2 locked")
 # --- first clear through the story battle
 var gold0=int(profile.data.gold)
 var xp0=int(profile.data.xp)
 check(main.start_battle(true,"1-1"),"Breach battle starts")
 var battle=main.screen.get_child(0)
 var hint=false
 var auto_button=false
 for c in battle.get_children():
  if c is Label and c.text.begins_with("Auto unlocks"): hint=true
  if c is Button and c.text.begins_with("AUTO"): auto_button=true
 check(hint and not auto_button,"AUTO is locked before the first clear")
 battle.intro=0
 battle.foe.receive(100000)
 await create_timer(0.4).timeout
 battle.intro=0
 battle.foe.receive(100000)
 await wait_scene("ending")
 check(scenes.has("ending") and not scenes.has("teaser") and not scenes.has("result"),"Boss win plays the ending first; no teaser or rewards yet")
 await wait_scene("result",20.0)
 check(main.scene_name=="result" and not scenes.has("teaser"),"Ending leads straight to the rewards screen (teaser not shown before rewards)")
 check(profile.data.completed==["1-1"] and int(profile.data.gold)==gold0+250,"First clear: completed once, +250 gold")
 var gained=int(profile.data.xp)-xp0
 for l in range(1,int(profile.data.level)): gained+=Progression.required(l)
 check(gained==120,"First clear pays 120 XP")
 check(MissionDefs.is_unlocked("1-2",profile.data.completed),"Episode 2 is unlocked after the first clear")
 var gold1=int(profile.data.gold)
 var next=button("NEXT EPISODE")
 check(next!=null and button("HOME")==null and button("REPLAY BATTLE")!=null,"Rewards screen offers NEXT EPISODE and REPLAY BATTLE")
 await create_timer(1.5).timeout
 check(main.scene_name=="result","Rewards screen waits for the player (no auto-advance to the teaser or Episode 2)")
 next.pressed.emit()
 await process_frame
 await process_frame
 check(main.scene_name=="teaser" and main.screen.get_child(0).title.contains("UNDER THE VIOLET RAIN") and main.screen.get_child(0).kicker=="NEXT EPISODE","NEXT EPISODE plays the EPISODE 2 / UNDER THE VIOLET RAIN teaser")
 main.screen.get_child(0).finish()
 await create_timer(1.0).timeout
 check(main.scene_name=="home" and profile.active_run=="","Teaser returns home; Episode 2 is not started")
 check(profile.data.completed==["1-1"] and int(profile.data.gold)==gold1 and MissionDefs.is_unlocked("1-2",profile.data.completed),"Teaser changes no rewards, completion or unlock")
 check(profile.backend.read_data().completed==["1-1"],"Completion is saved")
 # --- replay after the first clear: AUTO unlocked and working
 scenes.clear()
 var gold2=int(profile.data.gold)
 main.start_battle(false,"1-1")
 battle=main.screen.get_child(0)
 auto_button=false
 for c in battle.get_children():
  if c is Button and c.text=="AUTO: OFF": auto_button=true
 check(auto_button,"AUTO is available on replay after the first clear")
 battle.intro=0
 battle.toggle_auto()
 check(battle.auto,"AUTO toggles on")
 Engine.time_scale=8.0
 var elapsed=0.0
 while is_instance_valid(battle) and not battle.ended and elapsed<80:
  await create_timer(0.1).timeout
  elapsed+=0.1
 Engine.time_scale=1.0
 check(is_instance_valid(battle) and battle.foe.dead,"AUTO clears the replay battle")
 await wait_scene("result",10.0)
 check(main.scene_name=="result" and not scenes.has("teaser") and not scenes.has("ending"),"Replay goes to rewards with no teaser or ending first")
 check(int(profile.data.gold)==gold2+100 and profile.data.completed==["1-1"],"Replay pays 100 gold and does not repeat the first clear")
 var next2=button("NEXT EPISODE")
 check(next2!=null,"Replay rewards also offer NEXT EPISODE (optional)")
 next2.pressed.emit()
 await process_frame
 await process_frame
 check(main.scene_name=="teaser","Replay NEXT EPISODE plays the teaser")
 main.screen.get_child(0).finish()
 await create_timer(1.0).timeout
 check(main.scene_name=="home","Replay teaser returns home")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
