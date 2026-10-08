extends Node2D
# Mira's lantern signal on the Hero: a rising golden ring, floating lantern lights and a column of warm light (about 1.4 s).
var t=0.0
func _process(delta:float) -> void:
 t+=delta
 queue_redraw()
 if t>=1.4:
  queue_free()
func _draw() -> void:
 var u=clampf(t/1.4,0.0,1.0)
 var fade=1.0-u
 var gold=Color("ffd98a")
 draw_arc(Vector2(0,-70),40.0+u*110.0,0,TAU,48,Color(gold,0.8*fade),5)
 draw_arc(Vector2(0,-70),24.0+u*70.0,0,TAU,40,Color(1,1,1,0.7*fade),2)
 draw_rect(Rect2(-34,-260+u*60.0,68,260),Color(gold,0.16*fade))
 for i in range(7):
  var a=i*TAU/7.0+u*2.0
  var p=Vector2(cos(a)*(46.0+u*26.0),-30.0-u*150.0-i*9.0)
  draw_circle(p,5.0,Color(gold,0.25*fade))
  draw_circle(p,2.4,Color(1,0.97,0.85,0.95*fade))
