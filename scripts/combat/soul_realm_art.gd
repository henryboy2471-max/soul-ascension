extends Node2D
class_name SoulRealmArt
# Mission-zone arena for story battles: a violet void with a mirrored Skybridge hanging overhead,
# a runic ley-line floor, drifting shards and rising soul motes.
var time=0.0
var motes:Array=[]
var shards:Array=[]
var mode="root"
func _ready() -> void:
 if mode=="root":
  # Static scenery is baked once into a texture; only the halo, shards, runes and motes animate.
  var vp=SubViewport.new()
  vp.size=Vector2i(1280,720)
  vp.disable_3d=true
  vp.render_target_update_mode=SubViewport.UPDATE_ONCE
  var painter=SoulRealmArt.new()
  painter.mode="static"
  vp.add_child(painter)
  add_child(vp)
  var sprite=Sprite2D.new()
  sprite.centered=false
  sprite.texture=vp.get_texture()
  add_child(sprite)
  var live=SoulRealmArt.new()
  live.mode="dynamic"
  add_child(live)
  return
 if mode=="static":
  return
 var rng=RandomNumberGenerator.new()
 rng.seed=77
 for i in range(46):
  motes.append({"x":rng.randf_range(0,1280),"y":rng.randf_range(0,720),"s":rng.randf_range(14,46),"r":rng.randf_range(1.5,3.6),"c":rng.randi()%3})
 for i in range(11):
  shards.append({"x":rng.randf_range(60,1220),"y":rng.randf_range(60,300),"w":rng.randf_range(14,38),"h":rng.randf_range(40,110),"p":rng.randf_range(0,TAU),"a":rng.randf_range(-0.5,0.5)})
func _process(delta:float) -> void:
 if mode!="dynamic":
  return
 if not Profile.data.settings.get("reduced_motion",false):
  time+=delta
 queue_redraw()
func gradient_rect(rect:Rect2, top:Color, bottom:Color) -> void:
 draw_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),PackedColorArray([top,top,bottom,bottom]))
func _draw() -> void:
 if mode=="static":
  draw_static()
 elif mode=="dynamic":
  draw_dynamic()
func draw_static() -> void:
 gradient_rect(Rect2(0,0,1280,720),Color(0.015,0.008,0.05),Color(0.2,0.09,0.34))
 # mirrored city hanging from the top edge
 var rng=RandomNumberGenerator.new()
 rng.seed=5
 var x=-20.0
 while x<1300:
  var w=rng.randf_range(44,110)
  var h=rng.randf_range(60,210)
  draw_rect(Rect2(x,0,w,h),Color(0.07,0.04,0.17,0.85))
  draw_rect(Rect2(x+w-4,0,4,h),Color(0.5,0.35,0.95,0.35))
  for r in range(int(h/24)):
   if rng.randf()<0.4:
    draw_rect(Rect2(x+8,h-10-r*24,8,10),Color(0.6,0.5,1.0,0.4))
  x+=w+rng.randf_range(4,26)
 # floor
 gradient_rect(Rect2(0,320,1280,400),Color(0.1,0.05,0.2),Color(0.02,0.01,0.06))
 draw_line(Vector2(0,320),Vector2(1280,320),Color(0.75,0.55,1.0,0.9),3)
 draw_line(Vector2(0,330),Vector2(1280,330),Color(0.6,0.4,1.0,0.22),12)
 for i in range(17):
  draw_line(Vector2(640,320),Vector2(640+(i-8)*190,720),Color(0.5,0.35,0.9,0.16),1)
 for y in [345,385,445,530,650]:
  draw_line(Vector2(0,y),Vector2(1280,y),Color(0.5,0.35,0.9,0.12),1)
func draw_dynamic() -> void:
 # fractured halo
 var center=Vector2(640,210)
 for i in range(5):
  draw_arc(center,260.0+i*6,0,TAU,96,Color(0.6,0.4,1.0,0.05),16-i*2)
 draw_arc(center,256,0,TAU,96,Color(0.82,0.66,1.0,0.5),3)
 for i in range(10):
  var start=time*0.15+i*0.63
  draw_arc(center,282,start,start+0.28,16,Color(0.85,0.7,1.0,0.6),3)
 draw_circle(center,60,Color(0.9,0.8,1.0,0.07+0.03*sin(time*2.0)))
 # drifting shards
 for sh in shards:
  var bob=sin(time*0.8+sh.p)*10.0
  var c=Vector2(sh.x,sh.y+bob)
  var pts=PackedVector2Array([c+Vector2(0,-sh.h*0.5),c+Vector2(sh.w*0.5,sh.a*30),c+Vector2(0,sh.h*0.5),c+Vector2(-sh.w*0.5,-sh.a*30)])
  draw_colored_polygon(pts,Color(0.16,0.1,0.34,0.9))
  draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[0]]),Color(0.7,0.55,1.0,0.7),2)
 # runic circle under the fighters
 draw_set_transform(Vector2(640,458),time*0.12,Vector2(1,0.24))
 for r in [330.0,270.0,200.0]:
  draw_arc(Vector2.ZERO,r,0,TAU,96,Color(0.7,0.5,1.0,0.5),2)
 for i in range(24):
  var a=i*TAU/24.0
  draw_line(Vector2.from_angle(a)*270,Vector2.from_angle(a)*(300 if i%2==0 else 288),Color(0.8,0.65,1.0,0.7),2)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 # soul motes rising
 var palette=[Color(0.6,0.9,1.0),Color(0.8,0.65,1.0),Color(1.0,0.85,0.6)]
 for m in motes:
  var y=fposmod(m.y-time*m.s,740.0)
  var xo=m.x+sin(time*0.7+m.y)*14.0
  var fade=clampf(y/200.0,0.0,1.0)
  draw_circle(Vector2(xo,y),m.r*2.4,Color(palette[m.c],0.08*fade))
  draw_circle(Vector2(xo,y),m.r,Color(palette[m.c],0.8*fade))
