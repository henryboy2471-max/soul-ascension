extends Control
class_name WardenArena
# Episode 3 M4: the live Warden encounter inside the arena strip. Rules are WardenLogic (pure); this node feeds it the player's position every frame,
# draws the floor telegraphs, the Warden's strike and Echo's resonance meter, and reports what happened to the episode.
signal failed
signal event(e:Dictionary)
const FLOOR_Y = 505.0
const FLOOR_H = 110.0
var explore
var host          # the RelayEpisode: the fight pauses while it is busy (dialogue, cinematic, puzzle, travel)
var state:Dictionary={}
var time=0.0
var paused=false          # the episode pauses the fight during dialogue, cinematics and puzzles
var flash=0.0
var shown_hint=true
func setup(explore_node, restored:Array) -> void:
 explore=explore_node
 state=WardenLogic.default_state(restored)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 size=Vector2(1280,720)
func warden_entry():
 if explore==null: return null
 for e in explore.extra_npcs:
  if e.id=="warden": return e
 return null
func screen_x(world_x:float) -> float:
 return world_x-roundf(explore.cam)
func _process(delta:float) -> void:
 time+=delta
 flash=maxf(0.0,flash-delta*2.5)
 if explore==null or not is_instance_valid(explore):
  return
 var entry=warden_entry()
 if entry!=null:
  entry.x=float(state.x)
  var strike=str(state.phase)=="strike"
  entry.node.swing=1.0 if strike else 0.0
  entry.node.modulate=Color(0.7,0.8,1.0) if str(state.phase)=="stunned" else Color(1,1,1)
 var held=paused or explore.locked or (host!=null and (host.busy or host.traveling))
 if not held and not bool(state.done):
  var r=WardenLogic.step(state,delta,explore.px)
  state=r.state
  for e in r.events:
   handle(e)
 queue_redraw()
func handle(e:Dictionary) -> void:
 match str(e.type):
  "strike": flash=1.0
  "hit":
   explore.toast("RESONANCE  /  %d LEFT" % int(e.hp))
   if host!=null:
    host.shake(7.0)
  "fail":
   failed.emit()
 event.emit(e)
# Echo finished a mechanism (the episode calls this when the channel completes)
func activate(mech:String) -> Array:
 var r=WardenLogic.activate(state,mech)
 state=r.state
 for e in r.events:
  handle(e)
 return r.events
func reset(restored:Array) -> void:
 state=WardenLogic.default_state(restored)
func _draw() -> void:
 if explore==null or not is_instance_valid(explore):
  return
 var phase=str(state.phase)
 if phase=="telegraph" or phase=="strike":
  var total=WardenLogic.TELEGRAPH if phase=="telegraph" else WardenLogic.STRIKE
  var k=clampf(1.0-float(state.timer)/total,0.0,1.0)
  for z in state.zones:
   var x0=screen_x(float(z[0]))
   var x1=screen_x(float(z[1]))
   var r=Rect2(x0,FLOOR_Y,x1-x0,FLOOR_H)
   if phase=="telegraph":
    draw_rect(r,Color(1.0,0.35,0.5,0.10+0.22*k),true)
    draw_rect(r,Color(1.0,0.45,0.55,0.85),false,3)
    # a closing bar shows how long is left
    draw_rect(Rect2(x0,FLOOR_Y+FLOOR_H-8,(x1-x0)*k,8),Color(1.0,0.45,0.55,0.9),true)
   else:
    draw_rect(r,Color(1.0,0.9,0.95,0.75),true)
 # resonance meter
 var hp=int(state.hp)
 draw_string(ThemeDB.fallback_font,Vector2(500,36),"RESONANCE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(UI.MUTED))
 for i in range(WardenLogic.MAX_HP):
  var c=Vector2(612+i*30,32)
  draw_circle(c,10,Color("6fd7e4") if i<hp else Color(0.15,0.17,0.28))
  draw_arc(c,10,0,TAU,20,Color("6fd7e4",0.8),2)
 if phase=="stunned":
  draw_string(ThemeDB.fallback_font,Vector2(500,60),"THE WARDEN IS INTERRUPTED",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("9ff0b0"))
 elif phase=="done":
  draw_string(ThemeDB.fallback_font,Vector2(500,60),"THE WARDEN IS RESTORED",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("9ff0b0"))
 if flash>0.0:
  draw_rect(Rect2(0,0,1280,720),Color(1,1,1,0.18*flash),true)
