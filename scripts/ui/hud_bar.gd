extends Control
class_name HudBar
# Battle HUD bar: dark navy trough, coloured fill with a highlight, a trailing "ghost" that shows recent damage, an optional
# phase tick and a value readout. API matches ProgressBar for `value` / `max_value` so battle logic is unchanged.
var max_value=100.0
var value=100.0:
 set(v):
  if v<value-0.01:
   ghost_hold=0.45
   hit_flash=0.25
  value=v
var color=Color("4aa3ff")
var ghost=100.0
var ghost_hold=0.0
var hit_flash=0.0
var tick=-1.0
var readout=""
var readout_size=13
var low_warn=0.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 ghost=value
func _process(delta:float) -> void:
 ghost_hold=maxf(0.0,ghost_hold-delta)
 hit_flash=maxf(0.0,hit_flash-delta)
 if ghost>value and ghost_hold<=0.0:
  ghost=maxf(value,ghost-max_value*0.55*delta)
 elif ghost<value:
  ghost=value
 queue_redraw()
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size)
 var back=StyleBoxFlat.new()
 back.bg_color=Color(0.02,0.03,0.07,0.95)
 back.border_color=Color(color,0.55)
 back.set_border_width_all(1)
 back.set_corner_radius_all(4)
 draw_style_box(back,r)
 var inner=r.grow(-2.0)
 var frac=clampf(value/maxf(max_value,0.001),0.0,1.0)
 var gfrac=clampf(ghost/maxf(max_value,0.001),0.0,1.0)
 if gfrac>frac:
  draw_rect(Rect2(inner.position+Vector2(inner.size.x*frac,0),Vector2(inner.size.x*(gfrac-frac),inner.size.y)),Color(1.0,0.86,0.7,0.85))
 var fill_color=color
 if low_warn>0.0 and frac<low_warn:
  var p=0.5+0.5*sin(Time.get_ticks_msec()/110.0)
  fill_color=color.lerp(Color("ff4f72"),0.5+0.4*p)
 if frac>0.0:
  var w=inner.size.x*frac
  draw_rect(Rect2(inner.position,Vector2(w,inner.size.y)),fill_color)
  draw_rect(Rect2(inner.position,Vector2(w,inner.size.y*0.45)),Color(1,1,1,0.20))
  draw_rect(Rect2(inner.position+Vector2(0,inner.size.y*0.8),Vector2(w,inner.size.y*0.2)),Color(0,0,0,0.25))
  if hit_flash>0.0:
   draw_rect(Rect2(inner.position,Vector2(w,inner.size.y)),Color(1,1,1,hit_flash*2.0))
 if tick>0.0 and tick<1.0:
  var tx=inner.position.x+inner.size.x*tick
  draw_line(Vector2(tx,r.position.y-2),Vector2(tx,r.end.y+2),Color(1,1,1,0.85),2)
 if readout!="":
  var font=ThemeDB.fallback_font
  var y=size.y*0.5+readout_size*0.36
  draw_string(font,Vector2(1,y+1),readout,HORIZONTAL_ALIGNMENT_RIGHT,size.x-8,readout_size,Color(0,0,0,0.8))
  draw_string(font,Vector2(0,y),readout,HORIZONTAL_ALIGNMENT_RIGHT,size.x-9,readout_size,Color.WHITE)
