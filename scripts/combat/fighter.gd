extends Node2D
class_name Fighter
signal struck(amount:int, critical:bool)
signal defeated
var enemy=false
var body="male"
var max_health=260.0
var health=260.0
var attack=24.0
var defense=8.0
var speed=240.0
var facing=1.0
var blocking=false
var invincible=0.0
var stun=0.0
var flash=0.0
var swing=0.0
var step=0.0
var moving=false
var dead=false
var charge=0.0
var aura=false
var aura_color=Color("efce8e")
var accent=Color(0,0,0,0)
var hair_color=Color("dfdbef")
var skin_color=Color("b8866b")
var coat_color=Color("111625")
var armed=true
var look="hero"
var trailing=false
var ghosts:Array=[]
var ghost_timer=0.0
func _process(delta:float) -> void:
 invincible=maxf(0,invincible-delta)
 stun=maxf(0,stun-delta)
 flash=maxf(0,flash-delta)
 swing=maxf(0,swing-delta)
 step+=delta*(12 if moving else 2)
 if trailing:
  ghost_timer-=delta
  if ghost_timer<=0:
   ghosts.append({"pos":global_position,"life":0.24})
   ghost_timer=0.025
 for g in ghosts:
  g.life-=delta
 ghosts=ghosts.filter(func(g): return g.life>0)
 queue_redraw()
func receive(raw:float, critical:bool=false) -> int:
 if dead or invincible>0:
  return 0
 var damage=maxi(1,int(raw-defense*0.35))
 if blocking:
  damage=maxi(1,int(damage*0.2))
 health=maxf(0,health-damage)
 flash=0.14
 struck.emit(damage,critical)
 if health<=0:
  dead=true
  defeated.emit()
 return damage
func _draw() -> void:
 var color=Color("fa6f82") if enemy else Color("bc92ff")
 if accent.a>0:
  color=accent
 var ink=Color("151c30") if enemy else coat_color
 if flash>0:
  ink=Color("e9dbff")
 for g in ghosts:
  draw_set_transform(to_local(g.pos),0,Vector2(facing,1))
  var fade=g.life/0.24*0.4
  draw_colored_polygon(PackedVector2Array([Vector2(-21,-107),Vector2(23,-102),Vector2(35,-20),Vector2(2,-42),Vector2(-36,-22)]),Color(color,fade))
  draw_circle(Vector2(5,-120),17,Color(color,fade))
 draw_set_transform(Vector2.ZERO,0,Vector2(1,0.32))
 draw_circle(Vector2.ZERO,44,Color(0,0,0,0.45))
 draw_arc(Vector2.ZERO,44,0,TAU,48,Color(color,0.4),2)
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
 if dead:
  draw_line(Vector2(-35,-12),Vector2(35,-12),color,9)
  return
 var bob=sin(step)*2
 var sway=sin(step*0.5)*(5 if moving else 2)
 draw_colored_polygon(PackedVector2Array([Vector2(-14,-92+bob),Vector2(-34-sway,-48),Vector2(-44-sway*1.6,-14),Vector2(-8,-30)]),ink.darkened(0.25))
 draw_line(Vector2(-34-sway,-48),Vector2(-44-sway*1.6,-14),Color(color,0.55),2)
 var stride=sin(step)*8 if moving else 0.0
 # Original procedural placeholder rig: boots, coat, armor, face, hair and energy blade.
 draw_line(Vector2(-12,-46),Vector2(-16+stride,-8),Color("222a42"),14)
 draw_line(Vector2(12,-46),Vector2(18-stride,-8),Color("222a42"),14)
 draw_line(Vector2(-16+stride,-8),Vector2(-8+stride,-8),ink,12)
 draw_line(Vector2(18-stride,-8),Vector2(29-stride,-8),ink,12)
 draw_colored_polygon(PackedVector2Array([Vector2(-21,-107+bob),Vector2(23,-102+bob),Vector2(35,-20),Vector2(2,-42),Vector2(-36,-22)]),ink)
 draw_line(Vector2(-19,-99+bob),Vector2(-29,-28),color,3)
 draw_line(Vector2(11,-94+bob),Vector2(26,-35),color,2)
 draw_colored_polygon(PackedVector2Array([Vector2(-24,-106+bob),Vector2(0,-99+bob),Vector2(-14,-81+bob),Vector2(-30,-88+bob)]),Color("69718d"))
 draw_line(Vector2(18,-92+bob),Vector2(39,-64+bob),ink,15)
 draw_line(Vector2(-17,-92+bob),Vector2(-33,-64+bob),ink,13)
 draw_circle(Vector2(5,-120+bob),17,skin_color if not enemy else Color("252d40"))
 if enemy:
  draw_line(Vector2(-9,-122+bob),Vector2(20,-122+bob),color,4)
  draw_line(Vector2(4,-136+bob),Vector2(6,-105+bob),Color("69718d"),3)
 else:
  var hair=PackedVector2Array([Vector2(-13,-117+bob),Vector2(-16,-139+bob),Vector2(-5,-148+bob),Vector2(0,-141+bob),Vector2(9,-151+bob),Vector2(16,-139+bob),Vector2(27,-141+bob),Vector2(21,-125+bob),Vector2(8,-132+bob)])
  draw_colored_polygon(hair,hair_color)
  if body=="female":
   draw_colored_polygon(PackedVector2Array([Vector2(-13,-136+bob),Vector2(-31,-90+bob),Vector2(-12,-103+bob)]),hair_color)
  if look=="mira":
   draw_line(Vector2(-16,-136+bob),Vector2(-36-sway,-96+bob),hair_color,7)
   draw_line(Vector2(-4,-132+bob),Vector2(22,-132+bob),Color("f9d991"),3)
  draw_line(Vector2(11,-121+bob),Vector2(19,-123+bob),Color("f9d991"),2)
 if not armed:
  draw_circle(Vector2(38,-66+bob),6,Color(color,0.9))
  draw_arc(Vector2(38,-66+bob),11+sin(step)*2,0,TAU,16,Color(color,0.5),2)
  return
 var hand=Vector2(38,-66+bob)
 var tip=Vector2(69,-129+bob) if swing>0 else Vector2(77,-10+bob)
 draw_line(hand,tip,Color(color,0.12),18)
 draw_line(hand,tip,Color(color,0.35),9)
 draw_line(hand,tip,color,4)
 draw_line(hand,tip,Color.WHITE,1)
 if swing>0:
  draw_arc(Vector2(15,-64),76,-1.7,1.1,24,Color(color,swing*2),8)
 if look=="warped":
  var pulse=0.5+0.5*sin(Time.get_ticks_msec()/260.0)
  draw_arc(Vector2(6,-176+bob),24,0,TAU,32,Color(color,0.8),3)
  draw_arc(Vector2(6,-176+bob),30+pulse*3,0,TAU,32,Color(color,0.3),2)
  draw_circle(Vector2(10,-78+bob),9,Color(color,0.35+0.3*pulse))
  draw_circle(Vector2(10,-78+bob),4,Color.WHITE)
  draw_colored_polygon(PackedVector2Array([Vector2(-28,-104+bob),Vector2(-44,-134+bob),Vector2(-18,-110+bob)]),Color(color,0.9))
  draw_colored_polygon(PackedVector2Array([Vector2(34,-100+bob),Vector2(52,-128+bob),Vector2(24,-108+bob)]),Color(color,0.9))
 if look=="hero":
  draw_line(Vector2(21,-90+bob),Vector2(33,-72+bob),Color("b48bff"),2)
  draw_line(Vector2(26,-82+bob),Vector2(36,-70+bob),Color("dfc8ff"),1)
 if blocking:
  draw_arc(Vector2(8,-66),65,-1.5,1.5,30,Color(0.4,0.8,1,0.7),5)
 if aura:
  var glow=0.5+0.5*sin(Time.get_ticks_msec()/160.0)
  draw_arc(Vector2(0,-65),88+glow*6,0,TAU,48,Color(aura_color,0.35+0.3*glow),3)
  draw_arc(Vector2(0,-65),100+glow*8,0,TAU,48,Color(aura_color,0.12+0.12*glow),2)
 if invincible>0:
  draw_arc(Vector2(0,-65),83,0,TAU,40,Color(color,0.5),2)
