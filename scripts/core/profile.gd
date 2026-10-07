extends Node
signal changed
var backend=LocalSave.new()
var data:Dictionary
var save_ok=true
var active_run=""
var clock=0.0
func defaults() -> Dictionary:
 return {"name":"Ascendant","body":"male","onboarded":false,"level":1,"xp":0,"gold":500,"crystals":0,"energy":60,"energy_at":int(Time.get_unix_time_from_system()),"completed":[],"codex":[],"heroes":{"echo":{"level":1,"stars":1}},"inventory":[],"equipment":{},"achievements":[],"purchases":[],"vip_xp":0,"battle_pass_xp":0,"settings":{"sound":true,"shake":true,"reduced_motion":false}}
func _ready() -> void:
 data=defaults()
 var loaded=backend.read_data()
 for key in data:
  if loaded.has(key):
   data[key]=loaded[key]
 for key in ["level","xp","gold","crystals","energy","energy_at","vip_xp","battle_pass_xp"]:
  data[key]=int(data[key])
 Economy.regenerate(data,int(Time.get_unix_time_from_system()))
func _process(delta:float) -> void:
 clock+=delta
 if clock>=10:
  clock=0
  var previous=int(data.energy)
  Economy.regenerate(data,int(Time.get_unix_time_from_system()))
  if previous!=data.energy:
   persist()
func persist() -> bool:
 save_ok=backend.write_data(data)
 changed.emit()
 return save_ok
func unlock_codex(id:String) -> bool:
 if data.codex.has(id):
  return false
 data.codex.append(id)
 persist()
 return true
func begin_run(id:String) -> bool:
 if active_run!="" or id!="1-1":
  return false
 Economy.regenerate(data,int(Time.get_unix_time_from_system()))
 if not Economy.spend(data,"energy",6):
  return false
 active_run=id
 persist()
 return true
func finish_run(won:bool) -> Dictionary:
 if active_run=="":
  return {}
 var id=active_run
 active_run=""
 var reward={"xp":0,"gold":0,"levels":0,"first":false}
 if won:
  reward.first=not data.completed.has(id)
  reward.xp=120 if reward.first else 55
  reward.gold=250 if reward.first else 100
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
