extends Episode
class_name RelayEpisode
# Episode 3 (The Relay Keeper) flow controller. M1: connected exploration. Seven Explore strips (five areas; the tower has three floors) are
# swapped under a fade; progress (zone, discoveries, unlocked exits, visited zones) is saved per step in mission_progress["1-3"].
# Episode 1-2 progress keys are never touched. M2 (investigation): what each spot says and changes comes from Episode3Data.respond(); the saved `clues`
# list drives the quest objective (Episode3Data.next_step), hidden spots, codex entries and the tower lock. M3: the resonator puzzles. M4: the door and map
# puzzles with their cinematics, the Warden arena (WardenArena + WardenLogic, checkpoints saved as restored mechanisms), the finale and completion.
const START_ZONE = "market"
var zone_id=START_ZONE
var progress:Dictionary={}
var fade:ColorRect
var traveling=false
var arena:WardenArena
var bars_top:ColorRect
var bars_bottom:ColorRect
var failing=false
var push_tween:Tween
func load_progress() -> void:
 progress=Profile.mission_progress(mission_id).duplicate(true)
 for key in ["discoveries","unlocks","visited","clues"]:
  if not progress.get(key) is Array:
   progress[key]=[]
 if not progress.get("puzzles") is Dictionary:
  progress["puzzles"]={}
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
 await cine("opening")
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
 if is_instance_valid(arena):
  arena.queue_free()
  arena=null
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
 elif id=="arena":
  config["start_px"]=WardenLogic.checkpoint_x(restored_list())   # resuming inside the chamber: back at the last checkpoint
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
 if id=="arena" and not progress.clues.has("warden_restored"):
  arena=WardenArena.new()
  arena.host=self
  arena.setup(explore,restored_list())
  arena.failed.connect(on_arena_failed)
  add_child(arena)
 refresh_objective(false)
# the mechanisms restored so far, in the order they were restored (saved as clues restored_mech_N)
func restored_list() -> Array:
 var out=[]
 for m in WardenLogic.ORDER:
  if progress.clues.has("restored_"+m):
   out.append(m)
 return out
# Quest tracking: the objective is derived from the saved clues, so it always matches the save. In the step's own zone the waypoint points at the
# next spot (the nearest open transmission for the 0/3 counter); elsewhere it points at the exit that leads there.
func refresh_objective(announce:bool) -> void:
 if not is_instance_valid(explore):
  return
 var def=ZoneDefs.zone(zone_id)
 var step=Episode3Data.next_step(progress.clues)
 for sid in Episode3Data.HIDDEN:
  if explore.enabled.has(sid) and progress.clues.has(Episode3Data.HIDDEN[sid]):
   explore.enabled[sid]=true
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
 if zone_id=="arena" and not progress.clues.has("seen_arena"):
  progress.clues.append("seen_arena")
  save_progress()
  await cine("warden_wakes")
  refresh_objective(true)
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
# Resonator puzzle: intro lines (first visit), then the overlay. Every move is saved, so leaving and coming back resumes the same board.
func run_puzzle(id:String) -> void:
 var kind=str(Episode3Data.PUZZLES[id])
 var r=Episode3Data.respond(id,progress.clues)
 await say(r.lines)
 for c in r.add:
  if not progress.clues.has(c):
   progress.clues.append(c)
 save_progress()
 if progress.clues.has("puzzle_"+kind):
  return
 var screen=PuzzleScreen.new()
 screen.setup(kind,progress.puzzles.get(kind,{}),progress.clues)
 screen.changed.connect(func(k,s): progress.puzzles[k]=s; save_progress())
 var outcome=[false]
 screen.finished.connect(func(_k,solved): outcome[0]=solved)
 add_child(screen)
 await screen.finished
 screen.queue_free()
 if outcome[0]:
  await puzzle_done(kind,id)
func puzzle_done(kind:String, id:String) -> void:
 progress.clues.append("puzzle_"+kind)
 if not progress.discoveries.has(id):
  progress.discoveries.append(id)
 RelayArt.found=progress.discoveries
 var lock=str(Episode3Data.PUZZLE_UNLOCK.get(kind,""))
 if lock!="" and not progress.unlocks.has(lock):
  progress.unlocks.append(lock)
 save_progress()
 await say(Episode3Data.PUZZLE_DONE[kind])
 if kind=="rail":
  explore.toast("ARCHIVE DOOR OPEN")
  await cine("exposure")
  progress.clues.append("seen_exposure")
  unlock_clue_codex("echo_entry")
 elif kind=="map":
  explore.toast("RELAY MAP RESTORED")
  await cine("teo_reveal")
  progress.clues.append("seen_teo_reveal")
  unlock_clue_codex("seven_arrays")
 else:
  explore.toast("RESONATOR RESTORED  /  "+kind.to_upper())
 save_progress()
 refresh_objective(true)
func on_interact(id:String) -> void:
 if busy or traveling:
  return
 busy=true
 explore.locked=true
 var spot=spot_of(id)
 if spot.has("exit"):
  await travel(spot)
 elif Episode3Data.PUZZLES.has(id) and puzzle_ready(id):
  await run_puzzle(id)
 elif id.begins_with("mech_") and is_instance_valid(arena):
  await arena_activate(id)
 elif id=="archive_core":
  await finale()
 else:
  await investigate(id)
 busy=false
 if is_instance_valid(explore):
  explore.act_block=0.45
  explore.locked=false
func puzzle_ready(id:String) -> bool:
 var need=str(Episode3Data.PUZZLE_NEEDS.get(id,""))
 return need=="" or progress.clues.has(need)
# ---------------------------------------------------------------- cinematics: letterbox, a slow push-in, a flash, a shake; the dialogue box carries the subtitles
func bars(on:bool) -> void:
 if bars_top==null:
  bars_top=ColorRect.new()
  bars_bottom=ColorRect.new()
  for b in [bars_top,bars_bottom]:
   b.color=Color.BLACK
   b.size=Vector2(1280,0)
   b.mouse_filter=Control.MOUSE_FILTER_IGNORE
   add_child(b)
  bars_bottom.position=Vector2(0,720)
 var h=66.0 if on else 0.0
 var tween=create_tween().set_parallel(true)
 tween.tween_property(bars_top,"size:y",h,0.45)
 tween.tween_property(bars_bottom,"position:y",720.0-h,0.45)
 tween.tween_property(bars_bottom,"size:y",h,0.45)
 await tween.finished
func push_in(amount:float, seconds:float) -> void:
 if not is_instance_valid(explore):
  return
 explore.pivot_offset=Vector2(640,420)
 push_tween=create_tween()
 push_tween.tween_property(explore,"scale",Vector2(amount,amount),seconds).set_trans(Tween.TRANS_SINE)
func flash_screen(color:Color) -> void:
 var f=ColorRect.new()
 f.color=Color(color,0.0)
 f.size=Vector2(1280,720)
 f.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(f)
 var tween=create_tween()
 tween.tween_property(f,"color:a",0.55,0.08)
 tween.tween_property(f,"color:a",0.0,0.5)
 tween.tween_callback(f.queue_free)
func shake(amount:float=9.0) -> void:
 if not is_instance_valid(explore) or Profile.data.settings.get("shake",true)==false:
  return
 var tween=create_tween()
 for i in range(5):
  tween.tween_property(explore,"position",Vector2(randf_range(-amount,amount),randf_range(-amount,amount)),0.04)
 tween.tween_property(explore,"position",Vector2.ZERO,0.05)
func cine(id:String) -> void:
 var lines=Episode3Data.cine_lines(id,progress.clues)
 if lines.is_empty():
  return
 var was_busy=busy
 busy=true
 if is_instance_valid(explore):
  explore.set_cinematic(true)
 await bars(true)
 if id=="opening" or id=="warden_wakes":
  push_in(1.06,6.0)
 elif id=="recognition" or id=="recording":
  flash_screen(Color("bd95ff"))
  shake(6.0)
 await say(lines)
 await bars(false)
 if push_tween!=null and push_tween.is_valid():
  push_tween.kill()   # the slow push-in must not outlive its scene
 if is_instance_valid(explore):
  explore.scale=Vector2.ONE
  explore.set_cinematic(false)
  explore.act_block=0.45
 busy=was_busy
# ---------------------------------------------------------------- the Warden encounter
func arena_activate(id:String) -> void:
 if progress.clues.has("restored_"+id) or not is_instance_valid(arena):
  return
 var events=arena.activate(id)
 var name=str(WardenLogic.MECHANISMS[id].name)
 var all_done=false
 for e in events:
  if e.type=="restored":
   progress.clues.append("restored_"+id)
   if not progress.discoveries.has(id):
    progress.discoveries.append(id)
   RelayArt.found=progress.discoveries
   explore.toast("RESTORED  /  THE %s  /  THE WARDEN IS INTERRUPTED" % name)
  elif e.type=="wrong":
   explore.toast("WRONG ORDER  /  THE TOWER ANSWERS WITH ITS FEAR")
   shake()
  elif e.type=="restored_all":
   all_done=true
 save_progress()
 refresh_objective(true)
 if all_done:
  await arena_complete()
func arena_complete() -> void:
 await cine("recognition")
 progress.clues.append("warden_restored")
 save_progress()
 unlock_clue_codex("relay_warden")
 if is_instance_valid(arena):
  arena.queue_free()
  arena=null
 refresh_objective(true)
# Echo ran out of resonance: back to the last checkpoint (the entrance, or beside the last restored mechanism) with full resonance
func on_arena_failed() -> void:
 if failing or not is_instance_valid(arena):
  return
 failing=true
 busy=true
 await fade_to(1.0,0.4)
 var restored=restored_list()
 arena.reset(restored)
 explore.px=WardenLogic.checkpoint_x(restored)
 explore.cam=explore.px-640.0
 explore.toast("RESONANCE LOST  /  BACK TO THE LAST CHECKPOINT")
 await fade_to(0.0,0.4)
 busy=false
 failing=false
func finale() -> void:
 await cine("recording")
 progress.clues.append("recording_heard")
 save_progress()
 unlock_clue_codex("first_echo")
 await fade_to(1.0,0.9)
 completed.emit()
