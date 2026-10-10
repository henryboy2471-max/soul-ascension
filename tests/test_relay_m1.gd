extends SceneTree
# Episode 3 M1 (exploration): zone data integrity, connected traversal through all seven strips, locks, saves/resume, and that Episode 1-2
# progress is untouched. Classes that use autoloads are loaded dynamically (see CLAUDE.md gotcha).
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
 create_timer(110.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node, frames:int=1) -> void:
 for i in range(frames):
  if is_instance_valid(ep):
   for c in ep.get_children():
    if c.has_method("finish_all"):
     c.finish_all()
    elif c.has_method("finish"):
     c.finish()
  await process_frame
func wait_until(cond:Callable, ep:Node, max_frames:int=1500) -> bool:
 var n=0
 while n<max_frames:
  if cond.call():
   return true
  await skip_scenes(ep)
  n+=1
 return cond.call()
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 profile.data.mission_progress={"1-2":{"intro":true,"array":true,"resonators":["res_a","res_b","res_c"],"sentinel":42}}
 var ep2_before=profile.data.mission_progress["1-2"].duplicate(true)
 var zones=ZoneDefs.zones()
 # ---- data integrity
 var areas={}
 for id in zones:
  areas[ZoneDefs.AREAS[id]]=true
 check(zones.size()==7 and areas.size()==5 and areas.has("A") and areas.has("B") and areas.has("C") and areas.has("D") and areas.has("E"),"Five areas (A-E) are defined; the Central Relay Tower is three connected floors (7 strips)")
 var ok=true
 var unique=true
 var in_bounds=true
 var reachable_spots=true
 for id in zones:
  var z=zones[id]
  var seen={}
  for sp in z.spots:
   if seen.has(sp.id): unique=false
   seen[sp.id]=true
   if sp.x<0.0 or sp.x>z.world_w: in_bounds=false
   var nearest=clampf(sp.x,80.0,z.world_w-80.0)
   if absf(nearest-sp.x)>sp.range*0.9: reachable_spots=false
 check(unique and in_bounds and reachable_spots,"Every spot id is unique, inside its zone and reachable by walking (the player is clamped to 80 px from the edges)")
 var links=true
 var spawns=true
 for id in zones:
  for e in ZoneDefs.exits_of(id):
   if not zones.has(e.to):
    links=false
    continue
   var back=false
   for r in ZoneDefs.exits_of(e.to):
    if r.to==id:
     back=true
   if not back: links=false
   var dz=zones[e.to]
   if e.spawn_x<80.0 or e.spawn_x>dz.world_w-80.0: spawns=false
 check(links and spawns,"Every exit leads to an existing zone that has a way back, and spawns the player inside the walkable range")
 check(ZoneDefs.reachable("market").size()==4 and ZoneDefs.reachable("market",["shortcut","tower"]).size()==7,"Locks work as designed: 4 strips open, all 7 once the shortcut and tower locks are open")
 # ---- art/config build for every zone
 var art_script=load("res://scripts/world/relay_art.gd")
 var explore_script=load("res://scripts/world/explore.gd")
 var built=true
 for id in zones:
  art_script.zone=id
  art_script.found=[]
  var ex=explore_script.new()
  ex.config=ZoneDefs.explore_config(id,art_script)
  root.add_child(ex)
  await process_frame
  var npc_count=zones[id].get("npcs",[]).size()
  if ex.extra_npcs.size()!=npc_count or ex.spots.size()!=zones[id].spots.size() or ex.world_w!=zones[id].world_w:
   built=false
   print("  zone %s: npcs %d/%d spots %d/%d world %.0f/%.0f" % [id,ex.extra_npcs.size(),npc_count,ex.spots.size(),zones[id].spots.size(),ex.world_w,zones[id].world_w])
  # walk right for 3 simulated seconds: the player advances, the companion trails behind
  ex.locked=false
  var x0=ex.px
  for i in range(180):
   ex.stick.direction=Vector2(1,0)   # the virtual stick feeds the same input path as keys
   ex._process(1.0/60.0)
  if ex.px<=x0+250.0 or ex.npc_x>=ex.px:
   built=false
   print("  zone %s: px %.0f from %.0f, companion %.0f" % [id,ex.px,x0,ex.npc_x])
  ex.queue_free()
  await process_frame
 check(built,"All 7 zones build with their NPCs and spots; the player walks and the companion follows")
 # ---- episode flow
 var ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 await wait_until(func(): return is_instance_valid(ep.explore),ep)
 check(is_instance_valid(ep.explore) and ep.zone_id=="market","Episode 3 starts in Lantern Market after the title card")
 check(profile.data.mission_progress["1-3"].zone=="market" and profile.data.mission_progress["1-3"].intro==true,"Opening progress is saved under mission 1-3")
 # inspect something (placeholder content) and a witness
 ep.on_interact("signal_1")
 await wait_until(func(): return not ep.busy,ep)
 check(ep.progress.discoveries.has("signal_1") and not ep.explore.locked,"Investigating a signal records the discovery and returns control to the player")
 # travel market -> station -> back; locked exit refuses
 ep.on_interact("exit_station")
 await wait_until(func(): return not ep.busy and ep.zone_id=="station",ep)
 check(ep.zone_id=="station" and is_equal_approx(ep.explore.px,170.0),"The market exit leads to the Transit Station and spawns the player at its entrance")
 ep.on_interact("exit_alleys_s")
 await wait_until(func(): return not ep.busy,ep)
 check(ep.zone_id=="station","The locked shortcut refuses to open until it is unlocked (stays in the station)")
 ep.on_interact("exit_market")
 await wait_until(func(): return not ep.busy and ep.zone_id=="market",ep)
 check(ep.zone_id=="market" and ep.explore.px>3200.0,"Returning to the market spawns the player at the station end")
 # alleys: pull the lever, shortcut opens, use it both ways
 ep.on_interact("exit_alleys")
 await wait_until(func(): return not ep.busy and ep.zone_id=="alleys",ep)
 ep.on_interact("lever")
 await wait_until(func(): return not ep.busy,ep)
 check(ep.progress.unlocks.has("shortcut"),"The alley lever unlocks the shortcut (optional investigation unlock)")
 ep.on_interact("exit_station_a")
 await wait_until(func(): return not ep.busy and ep.zone_id=="station",ep)
 check(ep.zone_id=="station","The unlocked shortcut connects the alleyways to the station")
 # tower stays locked until its lock is opened; then traverse every strip up to the top floor
 ep.on_interact("exit_alleys_s")
 await wait_until(func(): return not ep.busy and ep.zone_id=="alleys",ep)
 ep.on_interact("exit_workshop")
 await wait_until(func(): return not ep.busy and ep.zone_id=="workshop",ep)
 ep.on_interact("exit_tower")
 await wait_until(func(): return not ep.busy,ep)
 check(ep.zone_id=="workshop","The tower door stays locked in the workshop until opened by progress")
 ep.progress.unlocks.append("tower")
 for step in ["exit_tower","exit_up_1","exit_up_2"]:
  ep.on_interact(step)
  await wait_until(func(): return not ep.busy,ep)
 check(ep.zone_id=="tower_3","With the tower open the player climbs three floors to the top")
 # ---- saving and resuming
 var saved=profile.data.mission_progress["1-3"]
 check(saved.zone=="tower_3" and saved.visited.size()==7 and saved.unlocks.has("shortcut") and saved.discoveries.has("lever"),"Zone, visited strips, unlocks and discoveries are saved")
 ep.queue_free()
 await process_frame
 var again=load("res://scripts/story/relay_episode.gd").new()
 again.mission_id="1-3"
 root.add_child(again)
 await wait_until(func(): return is_instance_valid(again.explore),again)
 check(again.zone_id=="tower_3" and again.progress.discoveries.has("signal_1") and again.explore.px==170.0,"Returning to the mission resumes at the saved zone entrance with discoveries intact")
 again.queue_free()
 # ---- Episode 1-2 untouched, mission data present
 check(profile.data.completed==["1-1","1-2"] and profile.data.mission_progress["1-2"]==ep2_before,"Episode 1-2 progress and completion are untouched by Episode 3")
 var d=MissionDefs.get_def("1-3")
 check(d.flow=="relay" and not MissionDefs.is_playable("1-3") and MissionDefs.is_unlocked("1-3",["1-1","1-2"]) and not MissionDefs.is_unlocked("1-3",["1-1"]),"Mission 1-3 exists in the data (unlocks after Episode 2, not yet playable for players)")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
