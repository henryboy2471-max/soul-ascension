extends Control
class_name Explore
# Walkable district. Movement: WASD / arrows / left stick. Act: E / Enter / ACT button (hold for channel spots).
signal interact(id:String)
signal exit_requested
const WORLD_W = 2500.0
const SPEED = 300.0
const ACCEL = 2600.0
const DECEL = 3600.0
const LOOK_AHEAD = 70.0
const CHANNEL_SECONDS = 1.4
var cam=0.0
var vel=Vector2.ZERO
var lead=0.0
var px=140.0
var py=548.0
var locked=false
var player:Fighter
var npc:Fighter
var layers:Array=[]
var props:WorldArt
var fore:WorldArt
var stick:VirtualStick
var act_button:TouchAction
var hud_node:Hud
# Optional per-mission setup (set before the node enters the tree). Defaults reproduce the Episode 1 district exactly.
# Keys: world_w, start_px, art (WorldArt script), npc_x, walker_count, sleepers [{x,facing}], spots, enabled, gate_x.
var config:Dictionary={}
var world_w=WORLD_W
var npc_x=560.0
var gate_x=-1.0
var gate_locked=false
var objective_targets:Array=[]
var counter_done=0
var counter_total=0
var spots=[
 {"id":"mira","x":560.0,"label":"TALK  /  MIRA VEY","kind":"talk","range":130.0},
 {"id":"board","x":1050.0,"label":"READ  /  TRAM BOARD","kind":"talk","range":110.0},
 {"id":"mural","x":1860.0,"label":"READ  /  LANTERN MURAL","kind":"talk","range":120.0},
 {"id":"terminal","x":1560.0,"label":"HOLD  /  REBOOT RELAY","kind":"channel","range":120.0},
 {"id":"breach","x":2200.0,"label":"ENTER  /  SOUL REALM BREACH","kind":"talk","range":150.0}
]
var enabled={"mira":false,"board":true,"mural":true,"terminal":false,"breach":false}
var act_edge=false
var walkers:Array=[]
var step_timer=0.0
var act_block=0.0
var toast_label:Label
var move_hint:Label
var act_hint:Label
var toast_panel:Panel
var toast_kicker:Label
var channel_t=0.0
var active_spot:Dictionary={}
var objective_text=""
var target_x=-1.0
var obj_label:Label
var dist_label:Label
var prompt_label:Label
var exit_button:Button
var exit_armed=0.0
var obj_panel:Panel
var flash_rect:ColorRect
var time=0.0
var lift=0.0
var floor_fill:ColorRect
var hud_nodes:Array=[]
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 world_w=float(config.get("world_w",WORLD_W))
 px=float(config.get("start_px",px))
 npc_x=float(config.get("npc_x",npc_x))
 gate_x=float(config.get("gate_x",gate_x))
 if config.has("spots"):
  spots=config.spots
  enabled=config.enabled
 var art_script=config.get("art",WorldArt)
 floor_fill=ColorRect.new()
 floor_fill.color=Color(0.02,0.025,0.06)
 floor_fill.position=Vector2(0,560)
 floor_fill.size=Vector2(1280,200)
 floor_fill.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(floor_fill)
 for spec in [["sky",0.03,1500.0],["far",0.12,1700.0],["mid",0.3,1800.0],["near",0.6,2300.0],["ground",1.0,world_w]]:
  var layer=art_script.new()
  layer.kind=spec[0]
  layer.width=spec[2]
  layer.set_meta("factor",spec[1])
  add_child(layer)
  layers.append(layer)
 props=art_script.new()
 props.kind="props"
 props.width=world_w
 add_child(props)
 var rng=RandomNumberGenerator.new()
 rng.seed=9
 for i in range(int(config.get("walker_count",5))):
  var walker=Fighter.new()
  walker.look="ped"
  walker.armed=false
  walker.coat_color=Color.from_hsv(rng.randf(),0.35,0.28)
  walker.accent=Color.from_hsv(rng.randf(),0.5,0.8)
  walker.hair_color=Color.from_hsv(rng.randf(),0.3,0.5)
  walker.skin_color=Color("8a6a58")
  walker.modulate=Color(0.55,0.55,0.7)
  walker.scale=Vector2(0.9,0.9)
  add_child(walker)
  walkers.append({"node":walker,"x":rng.randf_range(250,2300),"dir":1 if rng.randf()<0.5 else -1,"speed":rng.randf_range(35,70)})
 # Sleepers: the same ambient pedestrian rigs, standing still (no new character art).
 for s in config.get("sleepers",[]):
  var sleeper=Fighter.new()
  sleeper.look="ped"
  sleeper.armed=false
  sleeper.coat_color=Color.from_hsv(rng.randf(),0.3,0.3)
  sleeper.accent=Color(0.75,0.55,1.0)
  sleeper.hair_color=Color.from_hsv(rng.randf(),0.3,0.45)
  sleeper.skin_color=Color("8a6a58")
  sleeper.modulate=Color(0.62,0.55,0.8)
  sleeper.scale=Vector2(0.95,0.95)
  sleeper.facing=int(s.get("facing",1))
  add_child(sleeper)
  walkers.append({"node":sleeper,"x":float(s.x),"dir":sleeper.facing,"speed":0.0,"still":true})
 npc=Fighter.new()
 npc.look="mira"
 npc.accent=Color("ffd86b")
 npc.hair_color=Color("2b2233")
 npc.skin_color=Color("9a6a52")
 npc.coat_color=Color("2b3350")
 npc.armed=false
 npc.facing=-1
 # World height 155 puts Mira's standing figure about 5% shorter than the Hero's (measured, see tests/test_mira_sprites.gd).
 npc.load_sprite_set("res://assets/characters/mira/frames.tres",155.0,Color("c27bff"))
 npc.scale=Vector2(1.2,1.2)
 add_child(npc)
 player=Fighter.new()
 player.body=Profile.data.body
 player.scale=Vector2(1.2,1.2)
 player.load_sprite_set("res://assets/characters/hero/frames.tres",170.0,Color("4aa3ff"))
 add_child(player)
 fore=art_script.new()
 fore.kind="fore"
 add_child(fore)
 hud_node=Hud.new()
 hud_node.ex=self
 add_child(hud_node)
 var hud_start=get_child_count()
 build_hud()
 hud_nodes=get_children().slice(hud_start)
 update_positions(1.0)
 Sound.loop("city")
 flash_rect=ColorRect.new()
 flash_rect.color=Color(1,1,1,0)
 flash_rect.size=Vector2(1280,720)
 flash_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(flash_rect)
func build_hud() -> void:
 obj_panel=UI.panel(self,Rect2(24,20,440,82),Color(0.025,0.035,0.08,0.92),Color(UI.GOLD,0.45))
 UI.trim(self,Rect2(24,20,440,82),UI.GOLD)
 var obj_bar=ColorRect.new()
 obj_bar.color=UI.GOLD
 obj_bar.position=Vector2(24,34)
 obj_bar.size=Vector2(4,54)
 obj_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(obj_bar)
 UI.label(self,"OBJECTIVE",Vector2(44,25),16,UI.GOLD)
 obj_label=UI.label(self,"",Vector2(44,48),22,Color.WHITE,320)
 dist_label=UI.label(self,"",Vector2(352,26),17,UI.GOLD,96)
 dist_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 # The interaction prompt is drawn by paint_hud as a pill with a key cap; this label only carries its text.
 prompt_label=UI.label(self,"",Vector2(340,300),19,Color.WHITE,600)
 prompt_label.visible=false
 exit_button=UI.button(self,"EXIT",Rect2(1138,22,118,44),request_exit)
 exit_button.focus_mode=Control.FOCUS_NONE
 exit_button.add_theme_font_size_override("font_size",15)
 stick=VirtualStick.new()
 stick.position=Vector2(36,520)
 stick.size=Vector2(180,180)
 add_child(stick)
 act_button=TouchAction.new()
 act_button.title="ACT"
 act_button.subtitle="E"
 act_button.position=Vector2(1110,586)
 act_button.size=Vector2(104,104)
 act_button.tint=UI.GOLD
 add_child(act_button)
 act_button.activated.connect(func(): act_edge=true)
 toast_panel=UI.panel(self,Rect2(884,78,372,58),Color(0.025,0.035,0.08,0.96),Color(UI.GOLD,0.7))
 toast_kicker=UI.label(toast_panel,"CODEX UPDATED",Vector2(18,5),16,UI.GOLD)
 toast_label=UI.label(toast_panel,"",Vector2(18,26),21,Color.WHITE,340)
 toast_panel.modulate.a=0.0
 move_hint=UI.label(self,"MOVE  /  WASD",Vector2(61,696),16,UI.MUTED)
 act_hint=UI.label(self,"ACT  /  E",Vector2(1110,696),16,UI.MUTED)
# Cutscene mode: the objective panel, EXIT, toasts and touch hints are hidden and the Hero cannot walk (Episode 2 ending).
func set_cinematic(on:bool) -> void:
 for node in hud_nodes:
  if is_instance_valid(node) and node!=toast_panel:
   node.visible=not on
 locked=on
 act_block=99.0 if on else 0.0
func set_objective(text:String, x:float) -> void:
 objective_targets=[]
 objective_text=text
 target_x=x
 obj_label.text=text
 Sound.play("special")
 var tween=create_tween()
 obj_panel.modulate=Color(2.2,1.9,1.2)
 tween.tween_property(obj_panel,"modulate",Color.WHITE,0.8)
# Counter objective: "Resonators Synced n/3". `targets` are the waypoint x positions still to visit (the nearest one is shown).
func set_counter_objective(text:String, targets:Array, done:int, total:int) -> void:
 set_objective(text,float(targets[0]) if not targets.is_empty() else -1.0)
 objective_targets=targets
 counter_done=done
 counter_total=total
func clear_counter() -> void:
 counter_done=0
 counter_total=0
 objective_targets=[]
func set_gate_locked(value:bool) -> void:
 gate_locked=value
func toast(text:String) -> void:
 # "CODEX UPDATED  /  Title" -> kicker + title card that slides in under the EXIT button.
 var parts=text.split("/",false,1)
 toast_kicker.text=parts[0].strip_edges() if parts.size()>1 else "NOTICE"
 toast_label.text=parts[1].strip_edges() if parts.size()>1 else text
 toast_panel.position=Vector2(884,64)
 toast_panel.modulate.a=0.0
 var tween=create_tween()
 tween.tween_property(toast_panel,"modulate:a",1.0,0.2)
 tween.parallel().tween_property(toast_panel,"position:y",78.0,0.2)
 tween.tween_interval(1.8)
 tween.tween_property(toast_panel,"modulate:a",0.0,0.6)
func open_breach() -> void:
 props.breach_open=true
 enabled.breach=true
func set_terminal_done() -> void:
 props.terminal_done=true
func pulse_flash(color:Color=Color(1,1,1)) -> void:
 flash_rect.color=Color(color,0.7)
 create_tween().tween_property(flash_rect,"color:a",0.0,0.6)
func request_exit() -> void:
 if exit_armed>0:
  exit_requested.emit()
  return
 exit_armed=2.0
 exit_button.text="SURE?"
func _unhandled_key_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E,KEY_ENTER,KEY_KP_ENTER] and act_block<=0.0:
  act_edge=true
func move_input() -> Vector2:
 var move=stick.direction
 if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): move.x-=1
 if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): move.x+=1
 if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): move.y-=1
 if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): move.y+=1
 return move.limit_length()
func update_positions(blend:float) -> void:
 var goal=clampf(px-640.0+(lead if blend<1.0 else 0.0),0.0,world_w-1280.0)
 cam=goal if blend>=1.0 else lerpf(cam,goal,blend)
 for layer in layers:
  layer.position.x=-cam*layer.get_meta("factor")
 props.position.x=-cam
 # While a conversation is open the whole street lifts so the dialogue box never covers characters.
 for layer in layers:
  layer.position.y=lift
 props.position.y=lift
 npc.position=Vector2(npc_x-cam,548.0+lift)
 for w in walkers:
  w.node.position=Vector2(w.x-cam,516.0+lift)
 player.position=Vector2(px-cam,py+lift)
func _process(delta:float) -> void:
 time+=delta
 act_block=maxf(0.0,act_block-delta)
 for w in walkers:
  w.x+=w.dir*w.speed*delta
  if w.get("still",false):
   w.node.moving=false
   continue
  if w.x<150.0 or w.x>world_w-150.0:
   w.dir=-w.dir
  w.node.facing=w.dir
  w.node.moving=true
 if exit_armed>0:
  exit_armed-=delta
  if exit_armed<=0:
   exit_button.text="EXIT"
 var move=Vector2.ZERO
 if not locked:
  move=move_input()
 advance_motion(move,delta)
 if absf(move.x)>0.1:
  player.facing=1 if move.x>0 else -1
 player.moving=vel.length()>25.0
 if player.moving:
  step_timer-=delta*clampf(vel.length()/190.0,0.55,1.3)
  if step_timer<=0:
   Sound.footstep("wet",clampf(vel.length()/230.0,0.5,1.0))
   step_timer=0.30
 npc.facing=1 if px>npc_x else -1
 lift=lerpf(lift,-125.0 if locked else 0.0,1.0-exp(-delta*8.0))
 # touch controls step aside while a conversation is open, so nothing sits on top of the dialogue box
 for node in [stick,act_button,move_hint,act_hint]:
  node.visible=not locked
 update_positions(1.0-exp(-delta*9.0))
 # nearest enabled interaction spot
 active_spot={}
 var best=99999.0
 for spot in spots:
  if enabled.get(spot.id,false):
   var d=absf(px-spot.x)
   if d<spot.range and d<best:
    best=d
    active_spot=spot
 if locked or active_spot.is_empty() or act_block>0.0:
  prompt_label.text="" if (locked or active_spot.is_empty()) else active_spot.label
  channel_t=0.0
  act_edge=false
 else:
  prompt_label.text=active_spot.label
  prompt_label.position.x=clampf(active_spot.x-cam-300.0,10.0,670.0)
  if active_spot.kind=="talk":
   if act_edge:
    act_edge=false
    interact.emit(active_spot.id)
  else:
   var held=Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_ENTER) or act_button.held
   if held:
    channel_t+=delta/CHANNEL_SECONDS
    if channel_t>=1.0:
     channel_t=0.0
     act_edge=false
     interact.emit(active_spot.id)
   else:
    channel_t=maxf(0.0,channel_t-delta*2.0)
    act_edge=false
 if not objective_targets.is_empty():
  var nearest=float(objective_targets[0])
  for tx in objective_targets:
   if absf(px-float(tx))<absf(px-nearest):
    nearest=float(tx)
  target_x=nearest
 if target_x>=0:
  dist_label.text=str(int(absf(px-target_x)/12.0))+" M"
 else:
  dist_label.text=""
 hud_node.queue_redraw()
# Eased walking: speed ramps up in ~0.12 s and stops in ~0.08 s instead of snapping, and the camera leads slightly in the facing direction.
func advance_motion(move:Vector2, delta:float) -> void:
 if locked:
  vel=Vector2.ZERO
  lead=lerpf(lead,0.0,1.0-exp(-delta*6.0))
  return
 var goal=Vector2(move.x*SPEED,move.y*SPEED*0.55)
 var rate=ACCEL if goal.length()>vel.length()*0.98 and goal.length()>1.0 else DECEL
 vel=vel.move_toward(goal,rate*delta)
 var max_x=world_w-80.0
 if gate_locked and gate_x>0.0:
  max_x=minf(max_x,gate_x-40.0)
 var nx=clampf(px+vel.x*delta,80.0,max_x)
 if nx!=px+vel.x*delta:
  vel.x=0.0
 px=nx
 var ny=clampf(py+vel.y*delta,515.0,585.0)
 if ny!=py+vel.y*delta:
  vel.y=0.0
 py=ny
 var want=clampf(vel.x/SPEED,-1.0,1.0)*LOOK_AHEAD
 lead=lerpf(lead,want,1.0-exp(-delta*3.5))
func spot_accent(id:String) -> Color:
 match id:
  "terminal","res_a","res_b","res_c": return Color("6fd7e4")
  "breach","array": return Color("bd95ff")
  "mira","depot": return UI.GOLD
 return Color("c9cfe6")
func paint_prompt(c:Node2D) -> void:
 var spot=active_spot
 var accent=spot_accent(spot.id)
 var font=ThemeDB.fallback_font
 var words=str(spot.label)
 var fs=21
 var size=font.get_string_size(words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs)
 var w=size.x+84.0+(46.0 if spot.kind=="channel" else 0.0)
 var h=44.0
 var cx=clampf(spot.x-cam,w*0.5+16.0,1280.0-w*0.5-16.0)
 var top=Vector2(cx-w*0.5,262.0+lift*0.0)
 var box=StyleBoxFlat.new()
 box.bg_color=Color(0.02,0.03,0.07,0.92)
 box.border_color=Color(accent,0.85)
 box.set_border_width_all(1)
 box.set_corner_radius_all(8)
 box.shadow_color=Color(accent,0.25)
 box.shadow_size=8
 c.draw_style_box(box,Rect2(top,Vector2(w,h)))
 # key cap
 var key=Vector2(top.x+26.0,top.y+h*0.5)
 c.draw_circle(key,15.0,Color(accent,0.18))
 c.draw_arc(key,15.0,0,TAU,28,accent,2)
 c.draw_string(font,key+Vector2(-20,6),"E",HORIZONTAL_ALIGNMENT_CENTER,40,17,Color.WHITE)
 c.draw_string_outline(font,Vector2(top.x+50.0,top.y+h*0.5+7.0),words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,5,Color(0,0,0,0.8))
 c.draw_string(font,Vector2(top.x+50.0,top.y+h*0.5+7.0),words,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color.WHITE)
 # little pointer toward the interaction point
 c.draw_colored_polygon(PackedVector2Array([Vector2(cx-8,top.y+h),Vector2(cx+8,top.y+h),Vector2(cx,top.y+h+9)]),Color(accent,0.85))
 if spot.kind=="channel":
  # hold progress: bar along the bottom of the pill
  c.draw_rect(Rect2(top+Vector2(10,h-9),Vector2(w-20,6)),Color(0,0,0,0.65))
  c.draw_rect(Rect2(top+Vector2(10,h-9),Vector2((w-20)*clampf(channel_t,0.0,1.0),6)),accent)
  if channel_t>0.01:
   c.draw_string(font,Vector2(top.x+w-62,top.y+h*0.5+6.0),str(int(channel_t*100.0))+"%",HORIZONTAL_ALIGNMENT_RIGHT,50,16,accent)
func paint_hud(c:Node2D) -> void:
 if counter_total>0:
  # counter objective pips (Resonators Synced n/total), inside the objective panel
  for i in range(counter_total):
   var centre=Vector2(386.0+i*26.0,76.0)
   c.draw_circle(centre,9.0,Color(0.02,0.03,0.07,0.9))
   if i<counter_done:
    c.draw_circle(centre,7.0,Color("6fd7e4"))
   c.draw_arc(centre,9.0,0,TAU,20,Color("6fd7e4") if i<counter_done else Color(UI.GOLD,0.95),2)
 if target_x>=0 and not locked:
  var sx=target_x-cam
  var bob=sin(time*3.0)*5.0
  if sx>60 and sx<1220:
   for i in range(6):
    c.draw_line(Vector2(sx,250+bob),Vector2(sx,470),Color(0.94,0.81,0.56,0.05+i*0.015),22-i*3)
   c.draw_colored_polygon(PackedVector2Array([Vector2(sx,262+bob),Vector2(sx+13,244+bob),Vector2(sx,226+bob),Vector2(sx-13,244+bob)]),UI.GOLD)
   var meters=str(int(absf(px-target_x)/12.0))+" M"
   var font=ThemeDB.fallback_font
   c.draw_string_outline(font,Vector2(sx-40,214+bob),meters,HORIZONTAL_ALIGNMENT_CENTER,80,17,5,Color(0,0,0,0.85))
   c.draw_string(font,Vector2(sx-40,214+bob),meters,HORIZONTAL_ALIGNMENT_CENTER,80,17,UI.GOLD)
  else:
   var left=sx<=60
   var ex=34.0 if left else 1246.0
   var dir=-1.0 if left else 1.0
   c.draw_colored_polygon(PackedVector2Array([Vector2(ex+dir*18,330),Vector2(ex-dir*6,310),Vector2(ex-dir*6,350)]),Color(UI.GOLD,0.55+0.3*sin(time*4.0)))
 if not locked and act_block<=0.0 and not active_spot.is_empty():
  paint_prompt(c)
class Hud extends Node2D:
 var ex
 func _draw() -> void:
  if is_instance_valid(ex):
   ex.paint_hud(self)
