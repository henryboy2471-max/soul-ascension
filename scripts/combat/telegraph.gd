extends Node2D
var battle:Control
func _draw() -> void:
 if not is_instance_valid(battle) or battle.ended or battle.telegraph<=0: return
 var point=battle.target+battle.arena.position
 draw_circle(point,100,Color(1,0.18,0.34,0.15))
 draw_arc(point,100,0,TAU,64,Color("ff6e89"),3)
 draw_arc(point,100*(1-battle.telegraph/battle.telegraph_len),0,TAU,64,Color("ff6e89"),2)
