extends Control
class_name TouchAction
signal activated
var title="ATK"
var subtitle="J"
var held=false
var finger=-1
var cooldown=0.0
var seconds=0.0
var dim=false
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
 var font=ThemeDB.fallback_font
 var cooling=cooldown>0.0
 var ring=Color(0.45,0.47,0.58,0.8) if dim else tint
 draw_circle(mid+Vector2(0,3),radius,Color(0,0,0,0.35))
 draw_circle(mid,radius,Color(tint,0.30) if held else Color(0.03,0.045,0.095,0.95))
 draw_arc(mid,radius-7,PI*1.1,PI*1.9,24,Color(1,1,1,0.07),8)
 if ready:
  draw_circle(mid,radius+4+pulse*5,Color(tint,0.10+0.14*pulse))
 if cooling:
  # dark sweep over the remaining fraction (clockwise from 12 o'clock) + the remaining seconds
  var pts=PackedVector2Array([mid])
  var steps=28
  for i in range(steps+1):
   var a=-PI/2+TAU*clampf(cooldown,0,1)*float(i)/float(steps)
   pts.append(mid+Vector2.from_angle(a)*(radius-1))
  if pts.size()>2:
   draw_colored_polygon(pts,Color(0.0,0.0,0.03,0.62))
 draw_arc(mid,radius,0,TAU,48,Color(ring,0.45 if cooling else 1.0),3 if held else 2)
 if charge>=0.0 and not ready:
  draw_arc(mid,radius-6,-PI/2,-PI/2+TAU*clampf(charge,0,1),48,Color(tint,0.9),4)
 if cooling and seconds>=0.05:
  var label=("%.1f" % seconds) if seconds<10.0 else str(int(seconds))
  draw_string_outline(font,Vector2(0,mid.y+9),label,HORIZONTAL_ALIGNMENT_CENTER,size.x,26,6,Color(0,0,0,0.9))
  draw_string(font,Vector2(0,mid.y+9),label,HORIZONTAL_ALIGNMENT_CENTER,size.x,26,Color.WHITE)
 else:
  var fs=18 if title.length()<=6 else 14
  draw_string_outline(font,Vector2(0,mid.y-1),title,HORIZONTAL_ALIGNMENT_CENTER,size.x,fs,4,Color(0,0,0,0.85))
  draw_string(font,Vector2(0,mid.y-1),title,HORIZONTAL_ALIGNMENT_CENTER,size.x,fs,Color(0.6,0.62,0.72) if dim else Color.WHITE)
  draw_string(font,Vector2(0,mid.y+19),subtitle,HORIZONTAL_ALIGNMENT_CENTER,size.x,16,Color("ff8597") if dim else Color(tint,0.95))
