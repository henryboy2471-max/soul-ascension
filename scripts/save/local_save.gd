extends RefCounted
class_name LocalSave
const PATH="user://soul_ascension_v1.json"
var last_error=""
func write_data(data:Dictionary, path:String=PATH) -> bool:
 var payload=JSON.stringify(data)
 var envelope=JSON.stringify({"schema":1,"payload":payload,"sha256":payload.sha256_text()})
 var f=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f==null:
  last_error="Could not open save file."
  return false
 f.store_string(envelope)
 f.flush()
 f.close()
 if FileAccess.file_exists(path):
  DirAccess.remove_absolute(path+".bak")
  if DirAccess.rename_absolute(path,path+".bak")!=OK:
   last_error="Could not back up save file."
   return false
 if DirAccess.rename_absolute(path+".tmp",path)!=OK:
  if FileAccess.file_exists(path+".bak"):
   DirAccess.rename_absolute(path+".bak",path)
  last_error="Could not commit save file."
  return false
 last_error=""
 return true
func read_data(path:String=PATH) -> Dictionary:
 for candidate in [path,path+".bak"]:
  if not FileAccess.file_exists(candidate):
   continue
  var parser=JSON.new()
  if parser.parse(FileAccess.get_file_as_string(candidate))!=OK:
   continue
  var raw=parser.data
  if not raw is Dictionary or raw.get("schema",0)!=1 or not raw.get("payload") is String:
   continue
  if raw.payload.sha256_text()!=raw.get("sha256",""):
   continue
  if parser.parse(raw.payload)!=OK:
   continue
  var data=parser.data
  if data is Dictionary and valid(data):
   return data
 return {}
func valid(d:Dictionary) -> bool:
 for key in ["level","xp","gold","crystals","energy","energy_at"]:
  if not d.get(key) is float and not d.get(key) is int:
   return false
  if not is_finite(float(d[key])) or float(d[key])<0:
   return false
 if d.level<1 or d.level>100 or d.energy>120 or d.xp>1000000 or d.gold>1000000000 or d.crystals>1000000000:
  return false
 if not d.get("name") is String or not d.get("completed") is Array or not d.get("settings") is Dictionary:
  return false
 if d.name.length()>18 or d.get("body") not in ["male","female"] or not d.get("onboarded") is bool:
  return false
 for key in ["heroes","equipment"]:
  if not d.get(key) is Dictionary: return false
 if not d.heroes.get("echo") is Dictionary: return false
 for key in ["inventory","achievements","purchases"]:
  if not d.get(key) is Array: return false
 for key in ["sound","shake","reduced_motion"]:
  if not d.settings.get(key) is bool: return false
 for id in d.completed:
  if not id is String: return false
 if d.has("codex"):
  if not d.codex is Array: return false
  for id in d.codex:
   if not id is String: return false
 return true

