extends SceneTree
# QA flavor: the gate logic (production vs QA), and the QA state hook computing a snapshot, plans for every puzzle kind and the arena dodge (loaded dynamically; it is only shipped in the "Web QA" export).
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
 create_timer(100.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 # ---- the gate matrix: production = neither the QA feature nor a debug build + flag
 profile.data.settings["dev_unlock"]=true
 check(not main.dev_unlock_enabled(false,false),"Production (release, no QA feature): dev_unlock in the save does nothing")
 check(main.dev_unlock_enabled(true,false),"Debug/editor build with the save flag: unlocked (tests, local runs)")
 check(main.dev_unlock_enabled(false,true),"QA flavor (feature qa_unlock): unlocked")
 profile.data.settings.erase("dev_unlock")
 check(not main.dev_unlock_enabled(true,false) and main.dev_unlock_enabled(false,true),"Debug build without the flag stays locked; the QA flavor needs no flag")
 check(not OS.has_feature("qa_unlock"),"This (non-QA) binary does not carry the qa_unlock feature, so no QA button or hook is created")
 main.show_missions()
 await process_frame
 var qa_buttons=0
 for b in main.modal.find_children("*","Button",true,false):
  if str(b.text).begins_with("QA:"): qa_buttons+=1
 check(qa_buttons==0,"The missions screen has no QA button outside the QA flavor")
 main.close_modal()
 # ---- the QA hook (compiled here by loading it; it is only attached in the QA flavor)
 var hook=load("res://scripts/qa/qa_hook.gd").new()
 hook.main=main
 var snap=hook.snapshot()
 check(snap.scene=="home" and snap.has("buttons") and not snap.has("ep"),"Hook snapshot on the home screen: scene, buttons, no episode")
 profile.data.settings["dev_unlock"]=true
 main.start_episode("1-3")
 await process_frame
 var ep=main.screen.get_child(0)
 var n=0
 while (ep.explore==null or ep.busy) and n<1500:
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
  n+=1
 snap=hook.snapshot()
 check(snap.has("ep") and snap.ep.zone=="market" and snap.ep.spots.size()>3 and snap.ep.step=="tx" and snap.ep.target.begins_with("signal_") and snap.ep.puzzle==null,"Hook snapshot in the market: zone, spots, quest step and the next target spot")
 check(JSON.stringify(snap).length()>200 and JSON.parse_string(JSON.stringify(snap))!=null,"The snapshot is valid JSON")
 # ---- puzzle plans for every kind
 var kinds={"signal":[],"power":[],"map":[],"rail":[],"memory":["tone","bulletin","terminal","records"]}
 for k in kinds:
  var sc=load("res://scripts/puzzle/puzzle_screen.gd").new()
  sc.setup(k,{},kinds[k])
  ep.add_child(sc)
  await process_frame
  var ps=hook.puzzle_state(sc)
  var ok=ps.kind==k and ps.has("plan") and ps.plan!=null
  if k=="signal": ok=ok and ps.plan.has("df") and ps.buttons.size()>=5
  if k in ["power","map"]: ok=ok and ps.plan.cells.size()>0 and ps.plan.cells[0].turns>0
  if k=="rail": ok=ok and ps.plan.left>0 and ps.plan.has("pick") and ps.plan.has("to")
  if k=="memory": ok=ok and ps.plan.action=="click"
  check(ok,"Hook plan for the %s puzzle" % k)
  sc.queue_free()
  await process_frame
 # ---- a power plan really solves the puzzle when followed (turn counts are right)
 var sp=load("res://scripts/puzzle/puzzle_screen.gd").new()
 sp.setup("power",{},[])
 ep.add_child(sp)
 await process_frame
 for cell in hook.puzzle_state(sp).plan.cells:
  for i in range(int(cell.turns)): sp.cursor=int(cell.cell); sp.turn_tile()
 check(PuzzleLogic.route_solved(sp.state),"Following the hook's power plan solves the puzzle")
 sp.queue_free()
 var sm=load("res://scripts/puzzle/puzzle_screen.gd").new()
 sm.setup("map",{},[])
 ep.add_child(sm)
 await process_frame
 for cell in hook.puzzle_state(sm).plan.cells:
  for i in range(int(cell.turns)): sm.cursor=int(cell.cell); sm.turn_tile()
 check(PuzzleLogic.route_solved(sm.state),"Following the hook's map plan solves the puzzle")
 sm.queue_free()
 # ---- arena dodge helper: inside a telegraphed zone it points out of it, outside it is 0
 var zones=[[1000.0,1300.0]]
 var st={"phase":"telegraph","zones":zones}
 check(hook.dodge_dir(st,1100.0)!=0 and hook.dodge_dir(st,500.0)==0 and hook.dodge_dir({"phase":"idle","zones":zones},1100.0)==0,"Arena dodge helper: out of a telegraphed zone, idle elsewhere")
 hook.free()
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
