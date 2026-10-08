extends Control
class_name HurtVignette
# Red edge flash when the Hero is hit: nested frame strips that fade toward the centre, so the middle of the screen
# (characters, telegraphs) stays clear.
var strength=0.0
var color=Color("ff3355")
func pulse(amount:float=0.6) -> void:
 strength=maxf(strength,amount)
func _process(delta:float) -> void:
 if strength>0.0:
  strength=maxf(0.0,strength-delta*2.2)
  queue_redraw()
func _draw() -> void:
 if strength<=0.01:
  return
 for i in range(10):
  var inset=float(i)*14.0
  var a=strength*0.5*(1.0-float(i)/10.0)
  var r=Rect2(Vector2(inset,inset),size-Vector2(inset,inset)*2.0)
  draw_rect(r,Color(color,a),false,16.0)
