extends SceneTree
# Episode 3 M5 (polish and testing): mission 1-3 stays unplayable for players, and a damaged or hand-edited save for 1-3 never crashes or strands the player.
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
 create_timer(120.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node) -> void:
 if is_instance_valid(ep):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
 await process_frame
func settle(ep:Node) -> void:
 var n=0
 while n<1500 and (ep.busy or ep.traveling or not is_instance_valid(ep.explore)):
  await skip_scenes(ep)
  n+=1
 await process_frame
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 # ---- release gate: with Episodes 1-2 cleared, 1-3 is still not startable, featured or announced
 check(not MissionDefs.is_playable("1-3") and MissionDefs.is_unlocked("1-3",["1-1","1-2"]),"1-3 is unlocked by Episodes 1-2 but not playable")
 check(main.home_mission()!="1-3" and main.mission_status("1-3")=="PLANNED","The home screen does not feature 1-3 and the missions list shows it as PLANNED")
 main.start_episode("1-3")
 await process_frame
 await process_frame
 var started=false
 for c in main.screen.get_children():
  if c.has_method("on_interact"): started=true
 check(not started and main.scene_name!="episode" and profile.mission_progress("1-3").is_empty(),"start_episode('1-3') opens no episode and writes no progress")
 # ---- damaged saves (QA unlock on): every shape resumes into a valid zone with no crash
 profile.data.settings["dev_unlock"]=true
 var bad=[
  {"intro":true,"zone":"nonexistent"},
  {"intro":true,"zone":42},
  {"intro":true,"zone":null},
  {"intro":true,"clues":"x","unlocks":5,"discoveries":{},"visited":"m","puzzles":[]},
  {"intro":true,"zone":"arena"},
  {"intro":true,"zone":"workshop","clues":["not_a_real_clue",7,null]},
  {"zone":"tower_top"},
 ]
 for i in range(bad.size()):
  profile.data.mission_progress["1-3"]=bad[i]
  main.start_episode("1-3")
  await process_frame
  var ep=main.screen.get_child(0)
  await settle(ep)
  check(is_instance_valid(ep) and ep.explore!=null and ZoneDefs.zone(ep.zone_id).size()>0,"Damaged 1-3 save #%d resumes into a valid zone (%s)" % [i,str(ep.zone_id)])
  main.show_home()
  await process_frame
 # a save whose 1-3 entry (or the whole mission_progress) is not even a dictionary
 profile.data.mission_progress["1-3"]="garbage"
 main.start_episode("1-3")
 await process_frame
 var ep2=main.screen.get_child(0)
 await settle(ep2)
 check(is_instance_valid(ep2) and ep2.explore!=null and ZoneDefs.zone(ep2.zone_id).size()>0,"A non-dictionary 1-3 entry starts a fresh, valid episode")
 profile.data.mission_progress=[1,2]
 check(profile.mission_progress("1-3").is_empty() and profile.mission_progress("1-1").is_empty(),"A non-dictionary mission_progress reads as no progress for every mission")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
