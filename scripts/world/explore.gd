extends Control
class_name Explore
# Walkable district. Movement: WASD / arrows / left stick. Act: E / Enter / ACT button (hold for channel spots).
signal interact(id:String)
signal exit_requested
const WORLD_W = 2500.0
const SPEED = 300.0
const CHANNEL_SECONDS = 1.4
var cam=0.0
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
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 for spec in [["sky",0.03,1500.0],["far",0.12,1700.0],["mid",0.3,1800.0],["near",0.6,2300.0],["ground",1.0,WORLD_W]]:
  var layer=WorldArt.new()
  layer.kind=spec[0]
  layer.width=spec[2]
  layer.set_meta("factor",spec[1])
  add_child(layer)
  layers.append(layer)
 props=WorldArt.new()
 props.kind="props"
 props.width=WORLD_W
 add_child(props)
 var rng=RandomNumberGenerator.new()
 rng.seed=9
 for i in range(5):
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
 npc=Fighter.new()
 npc.look="mira"
 npc.accent=Color("ffd86b")
 npc.hair_color=Color("2b2233")
 npc.skin_color=Color("9a6a52")
 npc.coat_color=Color("2b3350")
 npc.armed=false
 npc.facing=-1
 npc.scale=Vector2(1.2,1.2)
 add_child(npc)
 player=Fighter.new()
 player.body=Profile.data.body
 player.scale=Vector2(1.2,1.2)
 player.load_sprite_set("res://assets/characters/hero/frames.tres")
 add_child(player)
 fore=WorldArt.new()
 fore.kind="fore"
 add_child(fore)
 hud_node=Hud.new()
 hud_node.ex=self
 add_child(hud_node)
 build_hud()
 update_positions(1.0)
 Sound.loop("city")
 flash_rect=ColorRect.new()
 flash_rect.color=Color(1,1,1,0)
 flash_rect.size=Vector2(1280,720)
 flash_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(flash_rect)
func build_hud() -> void:
 obj_panel=UI.panel(self,Rect2(24,20,440,82))
 UI.label(self,"OBJECTIVE",Vector2(42,30),11,UI.GOLD)
 obj_label=UI.label(self,"",Vector2(42,48),19,Color.WHITE,300)
 dist_label=UI.label(self,"",Vector2(350,30),12,UI.MUTED,100)
 dist_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 prompt_label=UI.label(self,"",Vector2(340,300),19,Color.WHITE,600)
 prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 prompt_label.add_theme_color_override("font_outline_color",Color(0.01,0.01,0.05))
 prompt_label.add_theme_constant_override("outline_size",8)
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
 toast_label=UI.label(self,"",Vector2(340,112),16,UI.GOLD,600)
 toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 toast_label.modulate.a=0.0
 UI.label(self,"MOVE  /  WASD",Vector2(61,698),12,UI.MUTED)
 UI.label(self,"ACT  /  E",Vector2(1110,696),12,UI.MUTED)
func set_objective(text:String, x:float) -> void:
 objective_text=text
 target_x=x
 obj_label.text=text
 Sound.play("special")
 var tween=create_tween()
 obj_panel.modulate=Color(2.2,1.9,1.2)
 tween.tween_property(obj_panel,"modulate",Color.WHITE,0.8)
func toast(text:String) -> void:
 toast_label.text=text
 toast_label.modulate.a=1.0
 var tween=create_tween()
 tween.tween_interval(1.6)
 tween.tween_property(toast_label,"modulate:a",0.0,0.6)
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
 var goal=clampf(px-640.0,0.0,WORLD_W-1280.0)
 cam=goal if blend>=1.0 else lerpf(cam,goal,blend)
 for layer in layers:
  layer.position.x=-cam*layer.get_meta("factor")
 props.position.x=-cam
 npc.position=Vector2(560.0-cam,548.0)
 for w in walkers:
  w.node.position=Vector2(w.x-cam,516.0)
 player.position=Vector2(px-cam,py)
func _process(delta:float) -> void:
 time+=delta
 act_block=maxf(0.0,act_block-delta)
 for w in walkers:
  w.x+=w.dir*w.speed*delta
  if w.x<150.0 or w.x>WORLD_W-150.0:
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
  px=clampf(px+move.x*SPEED*delta,80.0,WORLD_W-80.0)
  py=clampf(py+move.y*SPEED*0.55*delta,515.0,585.0)
  if absf(move.x)>0.1:
   player.facing=1 if move.x>0 else -1
 player.moving=move.length()>0.1
 if player.moving:
  step_timer-=delta
  if step_timer<=0:
   Sound.play("step")
   step_timer=0.28
 npc.facing=1 if px>560.0 else -1
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
 if target_x>=0:
  dist_label.text=str(int(absf(px-target_x)/12.0))+" M"
 else:
  dist_label.text=""
 hud_node.queue_redraw()
func paint_hud(c:Node2D) -> void:
 if target_x>=0 and not locked:
  var sx=target_x-cam
  var bob=sin(time*3.0)*5.0
  if sx>60 and sx<1220:
   for i in range(6):
    c.draw_line(Vector2(sx,250+bob),Vector2(sx,470),Color(0.94,0.81,0.56,0.05+i*0.015),22-i*3)
   c.draw_colored_polygon(PackedVector2Array([Vector2(sx,262+bob),Vector2(sx+13,244+bob),Vector2(sx,226+bob),Vector2(sx-13,244+bob)]),UI.GOLD)
  else:
   var left=sx<=60
   var ex=34.0 if left else 1246.0
   var dir=-1.0 if left else 1.0
   c.draw_colored_polygon(PackedVector2Array([Vector2(ex+dir*18,330),Vector2(ex-dir*6,310),Vector2(ex-dir*6,350)]),Color(UI.GOLD,0.55+0.3*sin(time*4.0)))
 if channel_t>0.01 and not active_spot.is_empty():
  var center=Vector2(active_spot.x-cam,380)
  c.draw_arc(center,34,0,TAU,40,Color(0,0,0,0.5),9)
  c.draw_arc(center,34,-PI/2,-PI/2+TAU*channel_t,40,Color("6fd7e4"),7)
class Hud extends Node2D:
 var ex
 func _draw() -> void:
  if is_instance_valid(ex):
   ex.paint_hud(self)
