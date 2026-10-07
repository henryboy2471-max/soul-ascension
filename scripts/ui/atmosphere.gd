extends Control
var time=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float) -> void:
 if Profile.data.settings.get("reduced_motion",false):
  return
 time+=delta
 queue_redraw()
func _draw() -> void:
 for i in range(45):
  var x=fmod(i*193.3+sin(time*0.2+i)*25,1280)
  var y=fmod(i*83.1-time*(12+i%6)+3000,720)
  var alpha=0.15+0.35*abs(sin(time+i))
  draw_circle(Vector2(x,y),1.2+i%3,Color(0.71,0.5,1.0,alpha))
 draw_line(Vector2(0,105),Vector2(1280,105),Color(0.7,0.6,0.9,0.16),1)
