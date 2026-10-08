extends Node2D
var battle:Control
func _draw() -> void:
 if not is_instance_valid(battle) or battle.ended or battle.telegraph<=0: return
 var point=battle.target+battle.arena.position
 if battle.telegraph_style=="bell":
  draw_bell_toll(point)
  return
 draw_circle(point,100,Color(1,0.18,0.34,0.15))
 draw_arc(point,100,0,TAU,64,Color("ff6e89"),3)
 draw_arc(point,100*(1-battle.telegraph/battle.telegraph_len),0,TAU,64,Color("ff6e89"),2)
 if battle.phase==2:
  # Phase 2: more aggressive telegraph (same hit radius, so it stays honest): pulsing outer ring, dark core, warning spikes
  var k=1.0-battle.telegraph/battle.telegraph_len
  var pulse=0.5+0.5*sin(Time.get_ticks_msec()/70.0)
  draw_circle(point,100,Color(0.35,0.0,0.08,0.18+0.12*pulse))
  draw_arc(point,104+pulse*6,0,TAU,64,Color("ff2d55",0.6+0.3*pulse),4)
  for i in range(8):
   var ang=i*TAU/8.0+k*1.5
   draw_line(point+Vector2.from_angle(ang)*(70+k*10),point+Vector2.from_angle(ang)*100,Color("ff4f72",0.9),3)
func draw_bell_toll(point:Vector2) -> void:
 # Larger bell-toll telegraph (radius = the real hit radius): rain-white/violet rings that close in, a bell glyph and tick marks.
 var r=battle.telegraph_radius
 var k=1.0-battle.telegraph/battle.telegraph_len
 var fast=battle.phase==2
 var pulse=0.5+0.5*sin(Time.get_ticks_msec()/(60.0 if fast else 110.0))
 var violet=Color("a98bff")
 var pale=Color("efe9ff")
 draw_circle(point,r,Color(0.45,0.3,0.95,0.14+0.1*k+(0.08*pulse if fast else 0.0)))
 draw_arc(point,r,0,TAU,72,Color(pale,0.9),4)
 draw_arc(point,r+10.0+pulse*5.0,0,TAU,72,Color(violet,0.55),3)
 draw_arc(point,r*(1.0-k),0,TAU,72,Color(pale,0.95),3)
 draw_arc(point,r*(1.0-k)*0.6,0,TAU,64,Color(violet,0.8),2)
 for i in range(12):
  var ang=i*TAU/12.0+k*2.0
  draw_line(point+Vector2.from_angle(ang)*(r-14.0),point+Vector2.from_angle(ang)*(r+(14.0 if fast else 4.0)),Color(pale,0.85),3)
 var b=point+Vector2(0,-6.0-sin(k*TAU*3.0)*4.0)
 draw_colored_polygon(PackedVector2Array([b+Vector2(-16,14),b+Vector2(-11,-10),b+Vector2(0,-20),b+Vector2(11,-10),b+Vector2(16,14)]),Color(pale,0.85))
 draw_circle(b+Vector2(0,19),4.0,Color(violet,0.95))
