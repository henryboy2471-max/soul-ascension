extends Node2D
var battle:Control
func _draw() -> void:
 if not is_instance_valid(battle) or battle.ended or battle.telegraph<=0: return
 var point=battle.target+battle.arena.position
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
