extends Episode
class_name RelayEpisode
# Episode 3 (The Relay Keeper) flow controller. M1: connected exploration. Seven Explore strips (five areas; the tower has three floors) are
# swapped under a fade; progress (zone, discoveries, unlocked exits, visited zones) is saved per step in mission_progress["1-3"].
# Episode 1-2 progress keys are never touched. M2 (investigation): what each spot says and changes comes from Episode3Data.respond(); the saved `clues`
# list drives the quest objective (Episode3Data.next_step), hidden spots, codex entries and the tower lock. Puzzles and the Warden arrive in M3-M4.
const START_ZONE = "market"
var zone_id=START_ZONE
var progress:Dictionary={}
var fade:ColorRect
var traveling=false
func load_progress() -> void:
 progress=Profile.mission_progress(mission_id).duplicate(true)
 for key in ["discoveries","unlocks","visited","clues"]:
  if not progress.get(key) is Array:
   progress[key]=[]
func save_progress() -> void:
 Profile.set_mission_progress(mission_id,progress.duplicate(true))
func run_intro() -> void:
 load_progress()
 if progress.get("intro",false):
  begin_zone(str(progress.get("zone",START_ZONE)),-1.0)
  return
 await card(mission.number+"  /  "+mission.season,mission.title,mission.card_location,true,mission.intro_card_length)
 progress["intro"]=true
 save_progress()
 begin_zone(START_ZONE,-1.0)
func say(lines:Array) -> void:
 var box=DialogueBox.new()
 box.speakers=Episode3Data.SPEAKERS
 box.setup(lines,hero_name())
 add_child(box)
 await box.finished
 box.queue_free()
func fade_rect() -> ColorRect:
 if fade==null:
  fade=ColorRect.new()
  fade.color=Color(0,0,0,0)
  fade.size=Vector2(1280,720)
  fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(fade)
 move_child(fade,get_child_count()-1)
 return fade
func fade_to(alpha:float, seconds:float) -> void:
 var rect=fade_rect()
 var tween=create_tween()
 tween.tween_property(rect,"color:a",alpha,seconds)
 await tween.finished
func zone_valid(id:String) -> bool:
 return not ZoneDefs.zone(id).is_empty()
func begin_zone(id:String, spawn_x:float) -> void:
 if not zone_valid(id):
  id=START_ZONE
  spawn_x=-1.0
 zone_id=id
 RelayArt.zone=id
 RelayArt.found=progress.discoveries
 if is_instance_valid(explore):
  explore.queue_free()
 var def=ZoneDefs.zone(id)
 explore=Explore.new()
 var config=ZoneDefs.explore_config(id,RelayArt)
 if spawn_x>=0.0:
  config["start_px"]=spawn_x
 explore.config=config
 add_child(explore)
 move_child(explore,0)
 explore.interact.connect(on_interact)
 explore.exit_requested.connect(func(): exit_requested.emit())
 progress["zone"]=id
 if not progress.visited.has(id):
  progress.visited.append(id)
 if id.begins_with("tower_") and not progress.clues.has("tower_reached"):
  progress.clues.append("tower_reached")
 save_progress()
 refresh_objective(false)
# Quest tracking: the objective is derived from the saved clues, so it always matches the save. In the step's own zone the waypoint points at the
# next spot (the nearest open transmission for the 0/3 counter); elsewhere it points at the exit that leads there.
func refresh_objective(announce:bool) -> void:
 if not is_instance_valid(explore):
  return
 var def=ZoneDefs.zone(zone_id)
 var step=Episode3Data.next_step(progress.clues)
 if progress.clues.has("records") and explore.enabled.has("registry_hidden"):
  explore.enabled["registry_hidden"]=true
 if step.is_empty():
  explore.clear_counter()
  explore.set_objective(str(def.objective) if zone_id!="workshop" else Episode3Data.TOWER_OBJECTIVE,float(def.objective_x))
  return
 var targets=[]
 if zone_id==step.zone:
  for sid in step.spots:
   targets.append(ZoneDefs.spot_x(zone_id,sid))
 else:
  var x=ZoneDefs.route_x(zone_id,str(step.zone),progress.unlocks)
  targets.append(x if x>=0.0 else float(def.objective_x))
 if step.id=="tx":
  explore.set_counter_objective(str(step.text),targets if zone_id==step.zone else [],int(step.done),int(step.total))
  if zone_id!=step.zone:
   explore.target_x=targets[0]
 else:
  explore.clear_counter()
  explore.set_objective(str(step.text),float(targets[0]))
func unlock_clue_codex(id:String) -> bool:
 if not Profile.unlock_codex(id):
  return false
 for entry in Episode3Data.CODEX:
  if entry.id==id:
   explore.toast("CODEX UPDATED  /  "+entry.title)
 return true
func exit_open(exit:Dictionary) -> bool:
 var lock=str(exit.get("lock",""))
 return lock=="" or progress.unlocks.has(lock)
func spot_of(id:String) -> Dictionary:
 for sp in ZoneDefs.zone(zone_id).get("spots",[]):
  if sp.id==id:
   return sp
 return {}
func travel(spot:Dictionary) -> void:
 var exit=spot.exit
 if not exit_open(exit):
  explore.toast(str(Episode3Data.LOCKED.get(str(exit.lock),"LOCKED")))
  return
 traveling=true
 await fade_to(1.0,0.22)
 begin_zone(str(exit.to),float(exit.spawn_x))
 await fade_to(0.0,0.3)
 traveling=false
func investigate(id:String) -> void:
 var r=Episode3Data.respond(id,progress.clues)
 await say(r.lines)
 var first=not progress.discoveries.has(id)
 if first:
  progress.discoveries.append(id)
  RelayArt.found=progress.discoveries
 var gained=false
 for clue in r.add:
  if not progress.clues.has(clue):
   progress.clues.append(clue)
   gained=true
 var toast=str(r.toast)
 if id=="lever" and not progress.unlocks.has("shortcut"):
  progress.unlocks.append("shortcut")
  toast="SHORTCUT OPENED  /  ALLEYWAYS TO STATION"
 if str(r.unlock)!="" and not progress.unlocks.has(r.unlock):
  progress.unlocks.append(r.unlock)
 save_progress()
 var codex_shown=false
 for cid in r.codex:
  if toast=="" and unlock_clue_codex(cid):
   codex_shown=true
  else:
   Profile.unlock_codex(cid)
 if toast!="":
  explore.toast(toast)
 elif first and not codex_shown and not gained:
  explore.toast("INVESTIGATED  /  "+id.replace("_"," ").to_upper())
 refresh_objective(true)
func on_interact(id:String) -> void:
 if busy or traveling:
  return
 busy=true
 explore.locked=true
 var spot=spot_of(id)
 if spot.has("exit"):
  await travel(spot)
 else:
  await investigate(id)
 busy=false
 if is_instance_valid(explore):
  explore.act_block=0.45
  explore.locked=false
