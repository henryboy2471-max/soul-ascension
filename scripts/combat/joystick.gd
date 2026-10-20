extends Control
class_name VirtualStick
# Fixed stick when the thumb lands on it; otherwise a floating stick anchored where the thumb lands inside `zone`.
var direction=Vector2.ZERO
var finger=-1
var zone=Rect2(0,250,600,470)
var base=Vector2.ZERO
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 base=global_position+size/2
func _input(event:InputEvent) -> void:
 if event is InputEventScreenTouch:
  if event.pressed and finger==-1 and (Rect2(global_position,size).has_point(event.position) or zone.has_point(event.position)):
   finger=event.index
   base=global_position+size/2 if Rect2(global_position,size).has_point(event.position) else event.position
   update_direction(event.position)
  elif event.index==finger and not event.pressed:
   finger=-1
   direction=Vector2.ZERO
   base=global_position+size/2
 if event is InputEventScreenDrag and event.index==finger:
  update_direction(event.position)
const DEAD=0.12   # a resting thumb jitters a few pixels: ignore the first 12% of the travel so the hero does not creep, and rescale so full travel is still 1.0
func update_direction(point:Vector2) -> void:
 var raw=((point-base)/60.0).limit_length()
 var m=raw.length()
 direction=Vector2.ZERO if m<=DEAD else raw/m*((m-DEAD)/(1.0-DEAD))
func _notification(what:int) -> void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  finger=-1
  direction=Vector2.ZERO
  base=global_position+size/2
func _process(_delta:float) -> void:
 queue_redraw()
func _draw() -> void:
 var mid=base-global_position
 draw_circle(mid,70,Color(0.03,0.05,0.11,0.78))
 draw_arc(mid,70,0,TAU,64,Color(0.7,0.65,0.9,0.3 if finger==-1 else 0.6),2)
 draw_arc(mid,44,0,TAU,40,Color(0.7,0.65,0.9,0.15),1)
 draw_circle(mid+direction*46,24,Color(0.67,0.53,0.85,0.6 if finger==-1 else 0.9))
