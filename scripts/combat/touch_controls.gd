extends Control
class_name TouchAction
signal activated
var title="ATK"
var subtitle="J"
var held=false
var finger=-1
var cooldown=0.0
var charge=-1.0
var tint=Color("bc92ff")
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _input(event:InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed and finger==-1 and Rect2(global_position,size).grow(4).has_point(event.position):
   finger=event.index
   held=true
   activated.emit()
  elif not event.pressed and event.index==finger:
   finger=-1
   held=false
func _notification(what:int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  held=false
  finger=-1
func _process(_delta:float) -> void:
 queue_redraw()
func _draw() -> void:
 var mid=size/2
 var radius=minf(size.x,size.y)/2-3
 var ready=charge>=1.0
 var pulse=0.5+0.5*sin(Time.get_ticks_msec()/140.0)
 draw_circle(mid,radius,Color("2d2344") if held else Color(0.035,0.05,0.10,0.94))
 if ready:
  draw_circle(mid,radius+4+pulse*5,Color(tint,0.10+0.14*pulse))
 draw_arc(mid,radius,0,TAU,48,Color(tint,0.4 if cooldown>0 else 1),2)
 if charge>=0.0 and not ready:
  draw_arc(mid,radius-5,-PI/2,-PI/2+TAU*clampf(charge,0,1),48,Color(tint,0.85),4)
 if cooldown>0:
  draw_arc(mid,radius-5,-PI/2,-PI/2+TAU*clampf(cooldown,0,1),48,tint,4)
 var font=ThemeDB.fallback_font
 draw_string(font,Vector2(0,mid.y+2),title,HORIZONTAL_ALIGNMENT_CENTER,size.x,16 if title.length()<=6 else 13,tint)
 draw_string(font,Vector2(0,mid.y+21),subtitle,HORIZONTAL_ALIGNMENT_CENTER,size.x,12,Color("a6aec5"))
