extends Node
signal changed
signal save_state_changed
var backend=LocalSave.new()
# "saved" (durably stored), "saving" (written, the browser has not confirmed it yet), "unconfirmed" (the browser never confirmed it), "failed" (the write failed)
var save_state="saved"
var save_poll=0.0
var data:Dictionary
var save_ok=true
var active_run=""
var clock=0.0
func defaults() -> Dictionary:
 return {"name":"Ascendant","body":"male","onboarded":false,"level":1,"xp":0,"gold":500,"crystals":0,"energy":60,"energy_at":int(Time.get_unix_time_from_system()),"completed":[],"codex":[],"heroes":{"echo":{"level":1,"stars":1}},"inventory":[],"equipment":{},"achievements":[],"purchases":[],"vip_xp":0,"battle_pass_xp":0,"settings":{"sound":true,"shake":true,"reduced_motion":false},"mission_progress":{}}
func _ready() -> void:
 data=defaults()
 var loaded=backend.read_data()
 for key in data:
  if loaded.has(key):
   data[key]=loaded[key]
 for key in ["level","xp","gold","crystals","energy","energy_at","vip_xp","battle_pass_xp"]:
  data[key]=int(data[key])
 Economy.regenerate(data,int(Time.get_unix_time_from_system()))
 if backend.last_source=="mirror":
  persist()   # the browser's write-ahead copy was newer than the stored file (a reload right after a save): bring the file and IndexedDB up to date
func refresh_save_state() -> void:
 var s=backend.durability() if save_ok else "failed"
 if s!=save_state:
  save_state=s
  save_state_changed.emit()
func _process(delta:float) -> void:
 save_poll+=delta
 if save_poll>=0.2 and save_state!="saved":
  save_poll=0.0
  refresh_save_state()
 clock+=delta
 if clock>=10:
  clock=0
  var previous=int(data.energy)
  Economy.regenerate(data,int(Time.get_unix_time_from_system()))
  if previous!=data.energy:
   persist()
func persist() -> bool:
 save_ok=backend.write_data(data)
 refresh_save_state()
 changed.emit()
 return save_ok
# Strict boolean read for saved flags: only a real `true` counts, so a corrupted value ("yes", 1, [true]) can never mark an attempt paid or an ending pending.
func flag(d:Dictionary, key:String) -> bool:
 var v=d.get(key,false)
 return typeof(v)==TYPE_BOOL and v
func unlock_codex(id:String) -> bool:
 if data.codex.has(id):
  return false
 data.codex.append(id)
 persist()
 return true
# Per-mission story progress (e.g. which Episode 2 resonators are synced), saved with the profile so a mission can be resumed.
func mission_progress(id:String) -> Dictionary:
 var all=data.get("mission_progress",{})
 var p=all.get(id,{}) if all is Dictionary else {}
 return p if p is Dictionary else {}   # a damaged or hand-edited save entry reads as "no progress" instead of raising
func set_mission_progress(id:String, progress:Dictionary) -> void:
 if not data.get("mission_progress") is Dictionary:
  data["mission_progress"]={}
 data.mission_progress[id]=progress
 persist()
func begin_run(id:String) -> bool:
 # Any defined mission whose unlock requirement is met can be started; the UI only offers missions marked playable.
 if active_run!="" or not MissionDefs.has_mission(id) or not MissionDefs.is_unlocked(id,data.completed):
  return false
 Economy.regenerate(data,int(Time.get_unix_time_from_system()))
 var resumable=bool(MissionDefs.get_def(id).get("resume_run",false))
 if resumable and flag(mission_progress(id),"combat_run"):
  # The energy for this run was already paid and saved (the app was closed or reloaded mid-run): resume without charging again.
  active_run=id
  return true
 if not Economy.spend(data,"energy",MissionDefs.energy_cost(id)):
  return false
 active_run=id
 if resumable:
  mark_combat_run(id,true)
 persist()
 return true
# Saves (or clears) the "energy paid, run active" state of a resumable mission inside its mission progress.
func mark_combat_run(id:String, active:bool) -> void:
 var progress=mission_progress(id).duplicate(true)
 if not active and not progress.has("combat_run"):
  return
 if active:
  progress["combat_run"]=true
 else:
  progress.erase("combat_run")
 if not data.get("mission_progress") is Dictionary:
  data["mission_progress"]={}
 data.mission_progress[id]=progress
# The boss fell: the paid run is over (combat_run cleared, saved) and the ending is pending. Rewards and completion come only from
# finish_run, after the ending sequence. The run stays open in memory so finish_run can settle it.
func mark_battle_won(id:String) -> void:
 if active_run!=id:
  return
 mark_combat_run(id,false)
 var progress=mission_progress(id).duplicate(true)
 progress["battle_won"]=true
 data.mission_progress[id]=progress
 persist()
# Reload/resume while the ending is pending: reopens the (already paid) run so finish_run can settle it. Never charges energy.
func begin_ending(id:String) -> bool:
 if active_run!="" or data.completed.has(id) or not flag(mission_progress(id),"battle_won"):
  return false
 active_run=id
 return true
func ending_pending(id:String) -> bool:
 return flag(mission_progress(id),"battle_won") and not data.completed.has(id)
# Win bookkeeping for story missions that track an ending: the pending flag is consumed and the story flags are recorded.
func settle_story(id:String) -> void:
 var progress=mission_progress(id).duplicate(true)
 if not progress.has("battle_won"):
  return
 progress.erase("battle_won")
 var flags=progress.get("flags",{}).duplicate(true)
 for key in MissionDefs.get_def(id).get("story_flags",{}):
  flags[key]=MissionDefs.get_def(id).story_flags[key]
 progress["flags"]=flags
 data.mission_progress[id]=progress
# District-flow (Episode 1) and relay-flow (Episode 3) episodes save where the player is (intro seen, objective step, position, puzzles). Finishing the
# mission clears that so the next play-through starts the story again; Lantern-flow episodes manage their own progress and are left alone.
func clear_explore_progress(id:String) -> void:
 if not MissionDefs.has_mission(id) or not ["district","relay"].has(MissionDefs.get_def(id).get("flow","district")):
  return
 var progress=mission_progress(id).duplicate(true)
 if MissionDefs.get_def(id).get("flow","district")=="relay":
  progress={}   # zone, clues, unlocks, puzzles and checkpoints all start over on a replay (completion, rewards and the Codex stay)
 for key in ["intro","step","px"]:
  progress.erase(key)
 if not data.get("mission_progress") is Dictionary:
  data["mission_progress"]={}
 data.mission_progress[id]=progress
func finish_run(won:bool) -> Dictionary:
 if active_run=="":
  return {}
 var id=active_run
 active_run=""
 mark_combat_run(id,false)
 var reward={"xp":0,"gold":0,"levels":0,"first":false,"id":id}
 if won:
  settle_story(id)
  clear_explore_progress(id)
 if won:
  reward.first=not data.completed.has(id)
  var amounts=MissionDefs.reward(id,reward.first)
  reward.xp=amounts.xp
  reward.gold=amounts.gold
  data.gold+=reward.gold
  reward.levels=Progression.grant(data,reward.xp)
  data.heroes.echo.level=data.level
  if reward.first:
   data.completed.append(id)
 persist()
 return reward
func _notification(what:int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED or what==NOTIFICATION_WM_CLOSE_REQUEST:
  persist()
