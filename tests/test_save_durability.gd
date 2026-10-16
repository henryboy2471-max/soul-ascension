extends SceneTree
# Save durability (web fix): newest-intact-copy selection between user:// and the localStorage write-ahead copy, the save envelope's timestamp, and the rule that the game
# only says "saved" once the backend reports the save durable (Profile.save_state / Main.save_line). The browser side (real IndexedDB) is tools/qa/save_reload_browser.cjs.
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
class FakeBackend extends LocalSave:
 var state="saving"
 var write_ok=true
 func write_data(_d:Dictionary, _p:String=PATH) -> bool:
  return write_ok
 func durability() -> String:
  return state
func envelope(data:Dictionary, ms:int, tamper:bool=false) -> String:
 var payload=JSON.stringify(data)
 return JSON.stringify({"schema":1,"payload":payload,"sha256":("bad" if tamper else payload.sha256_text()),"saved_ms":ms})
func _initialize() -> void:
 call_deferred("run")
 create_timer(60.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func run() -> void:
 var ls=LocalSave.new()
 var base=load("res://scripts/core/profile.gd").new().defaults()
 var dir=OS.get_environment("XDG_DATA_HOME")
 var path="user://_durability_test.json"
 for p in [path,path+".bak",path+".tmp"]:
  if FileAccess.file_exists(p): DirAccess.remove_absolute(p)
 # ---- the envelope carries a save time and still round-trips
 var a=base.duplicate(true); a.gold=111
 check(ls.write_data(a,path),"write_data succeeds")
 var raw=JSON.parse_string(FileAccess.get_file_as_string(path))
 check(raw.has("saved_ms") and int(raw.saved_ms)>1700000000000 and ls.read_candidates(path).gold==111 and ls.last_source=="file","The save envelope carries saved_ms and reads back (source: file)")
 # ---- file vs the browser's write-ahead copy
 var newer=base.duplicate(true); newer.gold=222
 var older=base.duplicate(true); older.gold=5
 var file_ms=int(raw.saved_ms)
 check(ls.read_candidates(path,envelope(newer,file_ms+5000)).gold==222 and ls.last_source=="mirror","A newer localStorage copy wins over the file (the reload-right-after-a-save case)")
 check(ls.read_candidates(path,envelope(older,file_ms-5000)).gold==111 and ls.last_source=="file","A stale localStorage copy loses to a newer file")
 check(ls.read_candidates(path,envelope(newer,file_ms)).gold==111 and ls.last_source=="file","On equal times the file wins")
 check(ls.read_candidates(path,envelope(newer,file_ms+5000,true)).gold==111,"A localStorage copy with a bad checksum is ignored")
 check(ls.read_candidates(path,"{not json").gold==111 and ls.read_candidates(path,"").gold==111,"Junk or empty localStorage text is ignored")
 var broken=base.duplicate(true); broken.level=0
 check(ls.read_candidates(path,envelope(broken,file_ms+9000)).gold==111,"A newer copy that fails profile validation is ignored")
 check(ls.read_candidates("user://_no_such_file.json",envelope(newer,1)).gold==222 and ls.last_source=="mirror","With no file at all the localStorage copy restores the save")
 check(ls.read_candidates("user://_no_such_file.json").is_empty(),"No file and no copy reads as an empty save")
 # a save written before saved_ms existed (ms=0) loses to any stamped copy but is still read when alone
 var legacy=JSON.stringify({"schema":1,"payload":JSON.stringify(a),"sha256":JSON.stringify(a).sha256_text()})
 var f=FileAccess.open(path,FileAccess.WRITE); f.store_string(legacy); f.close()
 check(ls.read_candidates(path).gold==111 and ls.read_candidates(path,envelope(newer,1)).gold==222,"A legacy save without saved_ms is read alone and loses to a stamped copy")
 for p in [path,path+".bak",path+".tmp"]:
  if FileAccess.file_exists(p): DirAccess.remove_absolute(p)
 # ---- Profile.save_state follows the backend; "saved" only when durable
 var profile=root.get_node("Profile")
 var real=profile.backend
 var fake=FakeBackend.new()
 profile.backend=fake
 var seen=[]
 profile.save_state_changed.connect(func(): seen.append(profile.save_state))
 profile.save_state="saved"
 fake.state="saving"
 profile.persist()
 check(profile.save_ok and profile.save_state=="saving","Right after a write the state is \"saving\", not \"saved\"")
 profile.save_poll=1.0
 profile._process(0.0)
 check(profile.save_state=="saving","While the backend is not durable the state stays \"saving\" across polls")
 fake.state="saved"
 profile.save_poll=1.0
 profile._process(0.0)
 check(profile.save_state=="saved" and seen==["saving","saved"],"Once the backend reports durable, the state becomes \"saved\" and the change is signalled")
 fake.state="unconfirmed"
 profile.persist()
 check(profile.save_state=="unconfirmed","A save the browser never confirmed is reported as \"unconfirmed\"")
 fake.state="saved"
 fake.write_ok=false
 profile.persist()
 check(not profile.save_ok and profile.save_state=="failed","A failed write is \"failed\" whatever the backend says")
 fake.write_ok=true
 profile.persist()
 check(profile.save_ok and profile.save_state=="saved","A later good write recovers to \"saved\"")
 # ---- what the screens say
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 fake.state="saving"
 profile.persist()
 check(main.save_line()[0]=="Saving progress…" and main.save_line(true)[0]=="Saving progress…" and main.notice.text=="Saving progress…" and main.save_chip.visible,"Home line, rewards line and the corner chip all say \"Saving progress…\" while unconfirmed")
 fake.state="unconfirmed"
 profile.persist()
 check(main.save_line()[0].begins_with("Save not confirmed") and not main.save_chip.visible,"An unconfirmed save is said to be unconfirmed (never \"saved\")")
 fake.state="saved"
 profile.persist()
 check(main.save_line()[0]=="Progress is saved on this device." and main.save_line(true)[0]=="Progress saved locally" and main.notice.text=="Progress is saved on this device." and not main.save_chip.visible,"Only a durable save shows the \"saved\" lines (texts unchanged from before)")
 profile.backend=real
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
