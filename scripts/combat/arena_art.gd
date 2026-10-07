extends Node2D
class_name ArenaArt
var time=0.0
func _process(delta:float) -> void:
 if not Profile.data.settings.get("reduced_motion",false):
  time+=delta
 queue_redraw()
func _draw() -> void:
 draw_rect(Rect2(0,0,1280,720),Color("080c1b"))
 draw_circle(Vector2(640,120),135,Color("151331"))
 draw_arc(Vector2(640,120),145,-PI,PI,64,Color("705494"),3)
 for i in range(26):
  var x=i*53.0
  var h=70.0+fmod(i*131.0,190)
  draw_rect(Rect2(x,300-h,45,h),Color("121b30"))
  draw_line(Vector2(x+43,300-h),Vector2(x+43,300),Color("354969"),2)
  for j in range(9):
   var y=300-h+j*26
   if y<290:
    draw_line(Vector2(x+10,y),Vector2(x+18,y),Color("627197") if i%4==0 else Color("293856"),2)
  if i%4==1:
   draw_rect(Rect2(x+6,315-h,5,50),Color("8264c5"))
 for i in range(6):
  var x=fmod(time*35+i*233,1400)-60
  var y=100+i*26
  draw_line(Vector2(x,y),Vector2(x+28,y),Color(0.3,0.7,1,0.5),2)
 draw_colored_polygon(PackedVector2Array([Vector2(0,310),Vector2(1280,310),Vector2(1280,720),Vector2(0,720)]),Color("10182b"))
 for i in range(15):
  draw_line(Vector2(640+(i-7)*65,310),Vector2(640+(i-7)*180,720),Color("25314a"),1)
 for y in [335,380,450,550,690]:
  draw_line(Vector2(0,y),Vector2(1280,y),Color("25314a"),1)
 draw_line(Vector2(0,310),Vector2(1280,310),Color("a580eb"),3)
 draw_line(Vector2(0,320),Vector2(1280,320),Color(0.6,0.4,1,0.2),8)
 for i in range(35):
  var x=fmod(i*93.3-time*55+5000,1280)
  var y=fmod(i*62.7+time*190,570)
  draw_line(Vector2(x,y),Vector2(x-8,y+18),Color(0.55,0.65,0.9,0.12),1)
