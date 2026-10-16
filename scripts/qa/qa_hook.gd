extends Node
# QA FLAVOR ONLY ("Web QA" export preset, custom feature qa_unlock). Publishes the game state to window.__qa for the browser driver (tools/qa/ep3_browser.cjs)
# and computes puzzle/arena "plans" so the driver can act with real input (keys, mouse, touch). The production "Web" preset excludes scripts/qa/*,
# and Main only loads this file when the qa_unlock feature is present.
var main
var acc=0.0
var rail_key=""
var rail_plan=null
func _process(delta:float) -> void:
 if main==null or not OS.has_feature("web"):
  return
 # per frame: only the player's x and the arena dodge direction (the full snapshot lags up to 0.2 s, which is ~80 px of walking)
 run_command()
 var ep=main.screen.get_child(0) if main.screen!=null and main.screen.get_child_count()>0 else null
 if ep!=null and ep.has_method("spot_of") and ep.get("explore")!=null and is_instance_valid(ep.explore):
  var dodge=0
  if ep.arena!=null and is_instance_valid(ep.arena):
   dodge=dodge_dir(ep.arena.state,float(ep.explore.px))
  JavaScriptBridge.eval("window.__qa_f=[%f,%d]" % [float(ep.explore.px),dodge])
 else:
  JavaScriptBridge.eval("window.__qa_f=null")
 acc+=delta
 if acc<0.2:
  return
 acc=0.0
 JavaScriptBridge.eval("window.__qa=JSON.parse("+JSON.stringify(JSON.stringify(snapshot()))+")")
# the driver sets window.__qa_cmd; QA-only save seeding (the same save shapes the Godot playthroughs start from), through the normal Profile API
func run_command() -> void:
 var cmd=JavaScriptBridge.eval("(function(){const c=window.__qa_cmd||'';window.__qa_cmd='';return c})()",true)
 if str(cmd)=="seed_tower":
  var clues=["tx_1","tx_2","tx_3","terminal","anselm_met","anselm_admits","records","scraped_entry","teo_met","decoded","theory","puzzle_rail","puzzle_map","seen_exposure","seen_teo_reveal","tower_reached"]
  for id in ["1-1","1-2"]:
   if not Profile.data.completed.has(id):
    Profile.data.completed.append(id)
  Profile.set_mission_progress("1-3",{"intro":true,"zone":"tower_1","visited":["market","station","alleys","workshop","tower_1"],"unlocks":["shortcut","tower"],"discoveries":[],"clues":clues,"puzzles":{}})
func rects_of(root:Node) -> Array:
 var out=[]
 if root==null or not is_instance_valid(root):
  return out
 for b in root.find_children("*","Button",true,false):
  if b.is_visible_in_tree():
   var r=b.get_global_rect()
   out.append({"text":str(b.text),"x":r.position.x,"y":r.position.y,"w":r.size.x,"h":r.size.y})
 return out
func snapshot() -> Dictionary:
 var d={"scene":main.scene_name,"completed":Profile.data.completed,"gold":int(Profile.data.gold),"xp":int(Profile.data.xp),"buttons":rects_of(main.modal)+rects_of(main.screen),
  "save":{"state":Profile.save_state,"ok":Profile.save_ok,"sha":Profile.backend.last_sha,"source":Profile.backend.last_source},"progress":Profile.mission_progress("1-3")}
 var ep=main.screen.get_child(0) if main.screen!=null and main.screen.get_child_count()>0 else null
 if ep!=null and ep.has_method("spot_of") and ep.get("explore")!=null and is_instance_valid(ep.explore):
  d["ep"]=episode_state(ep)
 return d
func episode_state(ep) -> Dictionary:
 var ex=ep.explore
 var spots=[]
 for sp in ZoneDefs.zone(ep.zone_id).get("spots",[]):
  spots.append({"id":str(sp.id),"x":float(sp.x),"enabled":bool(ex.enabled.get(sp.id,true)),"exit":sp.has("exit"),"kind":str(sp.get("kind","talk")),"range":float(sp.get("range",110.0))})
 var puzzle=null
 var dialogue=false
 for c in ep.get_children():
  if c.has_method("request_hint") and c.has_method("paint"):
   puzzle=c
  elif c.has_method("finish_all"):
   dialogue=true
 var clues=ep.progress.clues
 var step=Episode3Data.next_step(clues)
 var e={"zone":str(ep.zone_id),"busy":bool(ep.busy),"traveling":bool(ep.traveling),"locked":bool(ex.locked),"px":float(ex.px),"objective":str(ex.objective_text),
  "clues":clues,"unlocks":ep.progress.unlocks,"spots":spots,"dialogue":dialogue,"step":step.get("id",""),"target":target_of(ep,step),"puzzle":puzzle_state(puzzle) if puzzle!=null else null}
 if ep.arena!=null and is_instance_valid(ep.arena):
  var st=ep.arena.state
  e["arena"]={"phase":str(st.phase),"hp":int(st.hp),"timer":float(st.timer),"zones":st.zones,"dodge":dodge_dir(st,float(ex.px))}
 return e
# the spot the main quest line wants next: a spot in this zone, or the exit that leads towards the step's zone
func target_of(ep, step:Dictionary) -> String:
 if step.is_empty():
  return ""
 if ep.zone_id==step.zone:
  return str(step.spots[0])   # next_step already lists only the spots still open (the next mechanism in the arena)
 var x=ZoneDefs.route_x(ep.zone_id,str(step.zone),ep.progress.unlocks)
 if x>=0.0:
  for sp in ZoneDefs.zone(ep.zone_id).get("spots",[]):
   if absf(float(sp.x)-x)<1.0 and sp.has("exit"):
    return str(sp.id)
 return ""
func dodge_dir(st:Dictionary, px:float) -> int:
 if str(st.phase)=="telegraph" and WardenLogic.in_zones(st.zones,px):
  var best=px
  var bd=INF
  for z in st.zones:
   for edge in [float(z[0])-40.0,float(z[1])+40.0]:
    if edge>=WardenLogic.PLAYER_MIN and edge<=WardenLogic.PLAYER_MAX and not WardenLogic.in_zones(st.zones,edge) and absf(edge-px)<bd:
     bd=absf(edge-px)
     best=edge
  return 1 if best>px else -1
 return 0
func cell_center(origin:Vector2, size:float, col:int, row:int) -> Dictionary:
 return {"x":origin.x+(col+0.5)*size,"y":origin.y+(row+0.5)*size}
func turns_needed(cell:int, want_rot:int, state:Dictionary, level:String) -> int:
 if level=="power":
  return posmod(want_rot-int(state.rots[cell]),4)
 var want=PuzzleLogic.rotate_mask(PuzzleLogic.base_mask(PuzzleLogic.cell_kind(cell,"map")),want_rot)
 var rots=state.rots.duplicate()
 for k in range(4):
  if PuzzleLogic.cell_mask(cell,rots,"map")==want:
   return k
  rots[cell]=posmod(int(rots[cell])+1,4)
 return 0
func puzzle_state(sc) -> Dictionary:
 var st=sc.state
 var p={"kind":str(sc.kind),"state":st,"done":bool(sc.done),"cursor":int(sc.cursor),"sel":int(sc.sel),"hints":int(st.get("hints",0)),"buttons":rects_of(sc)}
 match str(sc.kind):
  "signal":
   var t=PuzzleLogic.signal_target(st)
   p["plan"]={"df":int(t.freq)-int(st.freq),"da":int(t.amp)-int(st.amp),"round":int(st.round)}
  "power":
   var cells=[]
   for cell in PuzzleLogic.ROUTE_PATH:
    if PuzzleLogic.ROUTE_SOLUTION.has(cell):
     var n=turns_needed(cell,int(PuzzleLogic.ROUTE_SOLUTION[cell]),st,"power")
     if n>0:
      var c=cell_center(PuzzleScreen.BOARD_ORIGIN,PuzzleScreen.CELL,cell%PuzzleLogic.COLS,cell/PuzzleLogic.COLS)
      cells.append({"cell":cell,"col":cell%PuzzleLogic.COLS,"row":cell/PuzzleLogic.COLS,"turns":n,"x":c.x,"y":c.y})
   p["plan"]={"cells":cells,"cols":PuzzleLogic.COLS}
  "map":
   var cells=[]
   var keys=PuzzleLogic.MAP_SOLUTION.keys()
   keys.sort()
   for cell in keys:
    var n=turns_needed(int(cell),int(PuzzleLogic.MAP_SOLUTION[cell]),st,"map")
    if n>0:
     var c=cell_center(PuzzleScreen.BOARD_ORIGIN,PuzzleScreen.MAP_CELL,int(cell)%7,int(cell)/7)
     cells.append({"cell":int(cell),"col":int(cell)%7,"row":int(cell)/7,"turns":n,"x":c.x,"y":c.y})
   p["plan"]={"cells":cells,"cols":7}
  "rail":
   var key=str(st.blocks)
   if key!=rail_key:
    rail_key=key
    rail_plan=PuzzleLogic.rail_solve(st)
   if rail_plan!=null and rail_plan.size()>0:
    var mv=rail_plan[0]
    var blk=st.blocks[int(mv[0])]
    var horizontal=blk[3]=="h"
    var to_col=int(blk[0])+(int(blk[2]) if int(mv[1])>0 else -1) if horizontal else int(blk[0])
    var to_row=int(blk[1]) if horizontal else int(blk[1])+(int(blk[2]) if int(mv[1])>0 else -1)
    var pick=cell_center(PuzzleScreen.BOARD_ORIGIN,PuzzleScreen.RAIL_CELL,int(blk[0]),int(blk[1]))
    var to=cell_center(PuzzleScreen.BOARD_ORIGIN,PuzzleScreen.RAIL_CELL,to_col,to_row)
    p["plan"]={"block":int(mv[0]),"dir":int(mv[1]),"axis":str(blk[3]),"left":rail_plan.size(),"pick":pick,"to":to}
  "memory":
   p["plan"]=memory_plan(sc)
 return p
func memory_plan(sc) -> Dictionary:
 var st=sc.state
 var want=PuzzleLogic.MEMORY_ORDER
 var tray=PuzzleLogic.memory_tray(st,sc.clues)
 var ts=-1
 for i in range(4):
  if str(st.slots[i])!=want[i]:
   ts=i
   break
 if ts==-1:
  var r=sc.action_button.get_global_rect()
  return {"action":"check","x":r.get_center().x,"y":r.get_center().y}
 var idx=-1
 if str(sc.selected)!="":
  idx=tray.size()+ts if str(sc.selected)==want[ts] else tray.find(sc.selected)
 elif str(st.slots[ts])!="":
  idx=tray.size()+ts
 else:
  var holder=st.slots.find(want[ts])
  idx=tray.size()+holder if holder>=0 else tray.find(want[ts])
 if idx<0 or idx>=sc.memory_buttons.size():
  return {"action":"none"}
 var rc=sc.memory_buttons[idx].get_global_rect()
 return {"action":"click","x":rc.get_center().x,"y":rc.get_center().y}
