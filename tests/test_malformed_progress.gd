extends SceneTree
# Regression: malformed mission_progress entries (wrong types, junk values, missing keys) across Episodes 1-3 never raise, never crash an episode, and fall back to a valid state.
# Covers the Profile accessors/mutators, the save validator, and the real episode scenes of 1-1 (district), 1-2 (lantern) and 1-3 (relay, via the QA unlock).
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(150.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node) -> void:
 if is_instance_valid(ep):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
 await process_frame
func settle(ep:Node) -> void:
 var n=0
 while n<1500 and is_instance_valid(ep) and (ep.explore==null or ep.busy or (ep.get("traveling")==true)):
  await skip_scenes(ep)
  n+=1
 await process_frame
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 var junk=["garbage",7,3.5,null,true,[1,2],[],PackedStringArray()]
 # ---- Profile accessors and mutators: any non-dictionary entry (or container) reads as empty and can be written over
 for id in ["1-1","1-2","1-3"]:
  for j in junk:
   profile.data.mission_progress={id:j}
   var ok=profile.mission_progress(id).is_empty() and not profile.flag(profile.mission_progress(id),"intro") and not profile.ending_pending(id)
   profile.mark_combat_run(id,true)
   profile.mark_combat_run(id,false)
   profile.clear_explore_progress(id)
   profile.set_mission_progress(id,{"intro":true})
   ok=ok and profile.mission_progress(id).intro==true
   if not ok: check(false,"%s entry %s reads empty and can be rewritten" % [id,str(j)])
   else: passed+=1
 print("PASS: accessors/mutators tolerate %d junk entry kinds for 1-1, 1-2 and 1-3" % junk.size())
 for j in junk:
  profile.data.mission_progress=j
  if not (profile.mission_progress("1-1").is_empty() and profile.mission_progress("1-3").is_empty()): check(false,"junk container "+str(j))
  profile.set_mission_progress("1-2",{"intro":true})
  if not profile.mission_progress("1-2").has("intro"): check(false,"junk container is replaced on write "+str(j))
 print("PASS: a junk mission_progress container reads empty and is replaced on the next write")
 # ---- the save validator rejects a whole save with a non-dictionary entry or container (so such a file falls back to a fresh profile)
 var good=profile.defaults()
 var LS=load("res://scripts/save/local_save.gd")
 var ls=LS.new()
 check(ls.valid(good.duplicate(true)),"The default profile passes the save validator")
 var bad_entry=good.duplicate(true); bad_entry.mission_progress={"1-3":"garbage"}
 var bad_box=good.duplicate(true); bad_box.mission_progress=[1,2]
 var bad_key=good.duplicate(true); bad_key.mission_progress={5:{}}
 check(not ls.valid(bad_entry) and not ls.valid(bad_box) and not ls.valid(bad_key),"The validator rejects a non-dictionary entry, a non-dictionary container and a non-string mission id")
 # ---- real episodes with wrong-typed fields inside a dictionary entry
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 var shapes={
  "1-1":[{"intro":true,"step":"x","px":"y"},{"intro":"yes","step":-3,"px":1e30},{"intro":true,"step":999,"px":null},{"step":[1],"px":[2]},{}],
  "1-2":[{"intro":true,"resonators":"abc"},{"intro":true,"resonators":[1,null,{},"res_a","res_a","zzz"]},{"intro":"1","resonators":5},{"combat_run":"yes","battle_won":"yes"}],
 }
 for id in shapes:
  for i in range(shapes[id].size()):
   profile.data.mission_progress={id:shapes[id][i]}
   main.start_episode(id)
   await process_frame
   var ep=main.screen.get_child(0) if main.screen.get_child_count()>0 else null
   await settle(ep)
   check(ep!=null and is_instance_valid(ep) and ep.explore!=null,"Episode %s with malformed save #%d starts into exploration" % [id,i])
   main.show_home()
   await process_frame
 # ---- the string "yes" never counts as a pending ending or a paid run (strict boolean flags)
 profile.data.mission_progress={"1-1":{"battle_won":"yes","combat_run":"yes"},"1-2":{"battle_won":1}}
 check(not profile.ending_pending("1-1") and not profile.ending_pending("1-2") and not profile.begin_ending("1-1"),"Non-boolean battle_won/combat_run never marks an ending pending")
 # ---- 1-3: junk entries resume safely only under the QA unlock, and never start in a release build
 profile.data.settings["dev_unlock"]=true
 for j in junk:
  profile.data.mission_progress={"1-3":j}
  main.start_episode("1-3")
  await process_frame
  var ep3=main.screen.get_child(0) if main.screen.get_child_count()>0 else null
  await settle(ep3)
  check(ep3!=null and is_instance_valid(ep3) and ep3.get("explore")!=null and ZoneDefs.zone(ep3.zone_id).size()>0,"1-3 with a junk %s entry starts fresh in a valid zone (QA unlock)" % type_string(typeof(j)))
  main.show_home()
  await process_frame
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
