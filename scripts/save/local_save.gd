extends RefCounted
class_name LocalSave
const PATH="user://soul_ascension_v1.json"
const MIRROR_KEY="soul_ascension_v1_mirror"
# Web: user:// is an in-memory file system that the browser copies into IndexedDB later and asynchronously (measured 0.8-4.3 s under software rendering, about 20 frames),
# so a reload right after a save could come back without it. Every save is therefore also written, synchronously, to localStorage (a write-ahead copy that survives an
# immediate reload), and the game only says "saved" once IndexedDB itself holds that exact save (durability()).
var last_error=""
var last_source="file"   # where read_data() got the save: "file" (user://) or "mirror" (the localStorage copy, when it is newer)
var web_tracking=false
var last_sha=""         # checksum of the most recent save written (the value the browser must confirm)
func write_data(data:Dictionary, path:String=PATH) -> bool:
 var payload=JSON.stringify(data)
 var sha=payload.sha256_text()
 var envelope=JSON.stringify({"schema":1,"payload":payload,"sha256":sha,"saved_ms":int(Time.get_unix_time_from_system()*1000.0)})
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
 last_sha=sha
 if path==PATH and OS.has_feature("web"):
  web_after_write(envelope,sha)
 return true
# A save envelope's text -> {"data","ms"} when it is intact (schema, checksum, valid profile), else {}.
func decode(text:String) -> Dictionary:
 var parser=JSON.new()
 if text=="" or parser.parse(text)!=OK:
  return {}
 var raw=parser.data
 if not raw is Dictionary or raw.get("schema",0)!=1 or not raw.get("payload") is String:
  return {}
 if raw.payload.sha256_text()!=raw.get("sha256",""):
  return {}
 var inner=JSON.new()
 if inner.parse(raw.payload)!=OK or not inner.data is Dictionary or not valid(inner.data):
  return {}
 var ms=raw.get("saved_ms",0)
 return {"data":inner.data,"ms":int(ms) if (ms is int or ms is float) else 0}
# The newest intact candidate wins; on equal times the earlier candidate (file before backup before mirror) does.
func pick_newest(candidates:Array) -> Dictionary:
 var best={}
 for c in candidates:
  if not c.is_empty() and (best.is_empty() or int(c.ms)>int(best.ms)):
   best=c
 return best
func read_candidates(path:String, mirror_text:String="") -> Dictionary:
 var found=[]
 for candidate in [path,path+".bak"]:
  if FileAccess.file_exists(candidate):
   var d=decode(FileAccess.get_file_as_string(candidate))
   if not d.is_empty():
    d["src"]="file"
    found.append(d)
 var m=decode(mirror_text)
 if not m.is_empty():
  m["src"]="mirror"
  found.append(m)
 var best=pick_newest(found)
 last_source=str(best.get("src","file"))
 return best.get("data",{})
func read_data(path:String=PATH) -> Dictionary:
 return read_candidates(path,web_mirror_text() if path==PATH else "")
# ---------------------------------------------------------------- web only
func js_str(v:String) -> String:
 return JSON.stringify(v)
func web_mirror_text() -> String:
 if not OS.has_feature("web"):
  return ""
 var v=JavaScriptBridge.eval("(function(k){try{return localStorage.getItem(k)||''}catch(e){return ''}})(%s)" % js_str(MIRROR_KEY),true)
 return v if v is String else ""
func web_after_write(envelope:String, sha:String) -> void:
 JavaScriptBridge.eval("(function(k,v){try{localStorage.setItem(k,v)}catch(e){}})(%s,%s)" % [js_str(MIRROR_KEY),js_str(envelope)],true)
 if not web_tracking:
  web_tracking=true
  JavaScriptBridge.eval(WEB_JS,true)
 JavaScriptBridge.eval("window.__soul_wait(%s,%s)" % [js_str(sha),js_str(ProjectSettings.globalize_path(PATH))],true)
# "saved" only when the browser's IndexedDB holds the latest save; "saving" while it does not yet; "unconfirmed" if it never did (storage blocked or 30 s passed); "failed" if the write itself failed.
func durability() -> String:
 if last_error!="":
  return "failed"
 if not web_tracking:
  return "saved"
 var st=JavaScriptBridge.eval("window.__soul?(window.__soul.pending?1:(window.__soul.error?2:0)):0",true)
 return "saving" if int(st)==1 else ("unconfirmed" if int(st)==2 else "saved")
# Installed once: after each save, polls the IndexedDB record behind user:// until its checksum equals the save just written (window.__soul is read by the game and by tests).
const WEB_JS = """
(function(){
 if(window.__soul_wait) return;
 const S=window.__soul={want:null,pending:false,error:null,key:null,t0:0,running:false,stored:null};
 const read=async()=>{
  const db=await new Promise((res,rej)=>{const r=indexedDB.open('/userfs');r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});
  try{
   const st=db.transaction('FILE_DATA').objectStore('FILE_DATA');
   const rec=await new Promise((res,rej)=>{const r=st.get(S.key);r.onsuccess=()=>res(r.result);r.onerror=()=>rej(r.error)});
   if(!rec||!rec.contents) return null;
   return JSON.parse(new TextDecoder().decode(new Uint8Array(rec.contents))).sha256||null;
  } finally { db.close(); }
 };
 const loop=async()=>{
  try{ const got=await read(); if(got===S.want){S.stored=got;S.pending=false;S.running=false;S.error=null;return;} }catch(e){ S.error=String(e); }
  if(performance.now()-S.t0>30000){ S.pending=false; S.running=false; S.error=S.error||'timeout'; return; }
  setTimeout(loop,60);
 };
 window.__soul_wait=function(sha,key){ S.want=sha; S.key=key; S.pending=true; S.error=null; S.t0=performance.now(); if(!S.running){S.running=true; loop();} };
})();
"""

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
 if d.has("mission_progress"):
  if not d.mission_progress is Dictionary: return false
  for id in d.mission_progress:
   if not id is String or not d.mission_progress[id] is Dictionary: return false
 if d.has("codex"):
  if not d.codex is Array: return false
  for id in d.codex:
   if not id is String: return false
 return true

