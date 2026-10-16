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
 # ---- dev_unlock is honoured by debug/QA builds only; a release build ignores it even if the save says true
 profile.data.settings["dev_unlock"]=true
 check(main.dev_unlock_enabled(true) and not main.dev_unlock_enabled(false),"dev_unlock works in a debug/QA build and is ignored in a release build")
 profile.data.settings["dev_unlock"]="yes"
 check(not main.dev_unlock_enabled(true),"Only a real boolean true enables dev_unlock (\"yes\" does not)")
 profile.data.settings.erase("dev_unlock")
 check(not main.dev_unlock_enabled(true),"Without the flag nothing is unlocked, in any build")
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
 # ---- regression (found by the touch browser run): a tap on the empty cell next to a block slides it ONE step; that step must refresh, save and detect the solved lock
 var rail=load("res://scripts/puzzle/puzzle_screen.gd").new()
 rail.setup("rail",{"blocks":[[3,2,2,"h"],[0,0,2,"h"]]},[])
 var saved=[0]
 rail.changed.connect(func(_k,_s): saved[0]+=1)
 root.add_child(rail)
 await process_frame
 rail.rail_tap(Vector2i(5,2))
 check(PuzzleLogic.rail_solved(rail.state) and rail.done and saved[0]>=1,"Tapping the empty cell beside the carriage slides it one step, saves, and completes the rail lock")
 var rail2=load("res://scripts/puzzle/puzzle_screen.gd").new()
 rail2.setup("rail",{"blocks":[[1,2,2,"h"],[0,0,2,"h"]]},[])
 var saved2=[0]
 rail2.changed.connect(func(_k,_s): saved2[0]+=1)
 root.add_child(rail2)
 await process_frame
 rail2.rail_tap(Vector2i(3,2))
 check(int(rail2.state.blocks[0][0])==2 and saved2[0]>=1 and not rail2.done,"A one-step tap slide that does not finish the lock is still saved")
 rail2.rail_tap(Vector2i(0,4))
 check(int(rail2.state.blocks[0][0])==2 and saved2[0]==1,"A tap off the block's rail does nothing and saves nothing")
 rail.queue_free()
 rail2.queue_free()
 profile.data.mission_progress=[1,2]
 check(profile.mission_progress("1-3").is_empty() and profile.mission_progress("1-1").is_empty(),"A non-dictionary mission_progress reads as no progress for every mission")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
