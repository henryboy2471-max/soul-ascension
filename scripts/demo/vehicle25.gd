extends Node2D
class_name Vehicle25
# A hover vehicle driving along a road lane. Origin = ground point below the vehicle centre; drawn facing right, mirrored when dir = -1.
var wx=0.0
var z=0.45
var dir=1
var speed=0.0          # current px/s (always >= 0, direction is `dir`)
var top_speed=170.0
var half=Vector2(105,11)
var body=Color("35e6ff")
var accent=Color("ff4fb0")
var kind=0
func setup(lane_z:float, d:int, colour:Color, k:int) -> Vehicle25:
 z=lane_z
 dir=d
 body=colour
 kind=k
 top_speed=randf_range(120.0,210.0)
 speed=top_speed
 return self
func _draw() -> void:
 draw_shape(1.0,false)
 # wet-road reflection: squashed, flipped, faint
 draw_set_transform(Vector2(0,10),0,Vector2(1,-0.4))
 draw_shape(0.18,true)
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_shape(a:float, refl:bool) -> void:
 var hover=-16.0
 var len=1.0 if kind!=2 else 0.82
 var hull=PackedVector2Array([Vector2(-100*len,hover-18),Vector2(-86*len,hover-40),Vector2(-30*len,hover-52),Vector2(26*len,hover-52),Vector2(70*len,hover-38),Vector2(104*len,hover-24),Vector2(106*len,hover-12),Vector2(92*len,hover-6),Vector2(-92*len,hover-6),Vector2(-102*len,hover-12)])
 var col=Color(body.darkened(0.55),a)
 draw_colored_polygon(hull,col)
 if not refl:
  var up=PackedVector2Array([Vector2(-86*len,hover-40),Vector2(-30*len,hover-52),Vector2(26*len,hover-52),Vector2(70*len,hover-38),Vector2(60*len,hover-30),Vector2(-80*len,hover-30)])
  draw_colored_polygon(up,Color(body.lightened(0.05),0.9))
  # glass canopy
  draw_colored_polygon(PackedVector2Array([Vector2(-40*len,hover-50),Vector2(14*len,hover-50),Vector2(48*len,hover-36),Vector2(-52*len,hover-36)]),Color(0.1,0.12,0.28,0.95))
  draw_colored_polygon(PackedVector2Array([Vector2(-34*len,hover-48),Vector2(-4*len,hover-48),Vector2(-20*len,hover-38),Vector2(-46*len,hover-38)]),Color(0.7,0.9,1.0,0.22))
  draw_line(Vector2(-96*len,hover-20),Vector2(100*len,hover-18),Color(accent,0.95),2.0)
  # headlights (front, +x) and tail lights
  draw_colored_polygon(PackedVector2Array([Vector2(104,hover-20),Vector2(210,hover-2),Vector2(210,hover+22),Vector2(104,hover-12)]),Color(1.0,0.95,0.8,0.10))
  draw_circle(Vector2(102*len,hover-18),4,Color(1,0.96,0.85))
  draw_circle(Vector2(-98*len,hover-20),3.5,Color("ff3040"))
  # underglow
  draw_set_transform(Vector2(0,-2),0,Vector2(1,0.18))
  draw_circle(Vector2.ZERO,100,Color(body,0.14))
  draw_circle(Vector2.ZERO,70,Color(body,0.14))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 else:
  draw_line(Vector2(-96*len,hover-20),Vector2(100*len,hover-18),Color(accent,a*1.5),2.0)
