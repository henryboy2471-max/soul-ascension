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
# Optional sprite art. When `sprite` exists it replaces the procedural body; all gameplay state stays on this node.
var sprite:AnimatedSprite2D
var sprite_frames:SpriteFrames
var casting=0.0
var combo_step=0
var combo_idle=0.0
var last_swing=0.0
var current_anim=""
var run_speed_threshold=0.0
var death_t=0.0
var form_t=0.0
var burst_t=0.0
var boss_form=false
const ANIM_FALLBACKS = {
 "attack3":["attack2","attack1","skill"],"attack2":["attack1","skill"],"attack1":["skill"],
 "skill":["attack1"],"finisher":["skill","attack3","attack1"],
 "run":["walk"],"walk":["run"],"dash":["run","walk"],
 "land":["idle"],"jump":["idle"],"hurt":["idle"],"defeat":["hurt","idle"],"idle":[]
}
func phase2_vfx_active() -> bool:
 return boss_form or form_t>0.0
func set_boss_form(path:String="res://assets/enemies/soul_realm_boss/frames.tres", world_height:float=180.0, tint:Color=Color(1.12,0.58,0.55)) -> bool:
 # Phase 2 reveal: same Fighter (health, position, facing, AI state untouched), new look. Uses the Boss sprite set when
 # its frames.tres exists; otherwise the current sprite stays and gets a red Soul Realm tint plus code-drawn halo/core.
 boss_form=true
 var swapped=false
 if sprite!=null and ResourceLoader.exists(path):
  var frames=load(path)
  if frames is SpriteFrames and attach_frames(frames,world_height):
   swapped=true
   sprite.modulate=Color.WHITE
 if sprite!=null and not swapped:
  sprite.modulate=tint
 return swapped
func load_sprite_set(path:String, world_height:float=170.0, overlay:Color=Color(0,0,0,0)) -> bool:
 # Returns false (and keeps the procedural rig) when no SpriteFrames resource exists at `path`.
 if not ResourceLoader.exists(path):
  return false
 var frames=load(path)
 if not frames is SpriteFrames:
  return false
 var ok=attach_frames(frames,world_height)
 if ok and overlay.a>0:
  accent=overlay
 return ok
func attach_frames(frames:SpriteFrames, world_height:float=170.0) -> bool:
 if not frames.has_animation("idle") or frames.get_frame_count("idle")==0:
  return false
 sprite_frames=frames
 if is_instance_valid(sprite):
  sprite.queue_free()
 sprite=AnimatedSprite2D.new()
 sprite.sprite_frames=frames
 sprite.centered=true
 var tex=frames.get_frame_texture("idle",0)
 var h=float(tex.get_height())
 # Frames are normalized so the feet sit on the bottom-centre of the canvas: bottom-centre = this node's origin.
 sprite.offset=Vector2(0,-h/2.0)
 var factor=world_height/h
 sprite.scale=Vector2(factor,factor)
 add_child(sprite)
 current_anim=""
 play_animation("idle")
 return true
func has_animation(name:String) -> bool:
 return sprite_frames!=null and sprite_frames.has_animation(name) and sprite_frames.get_frame_count(name)>0
# Resolves an animation name to one the loaded art actually has (never invents frames); "" means nothing suitable.
func resolve_animation(name:String) -> String:
 if has_animation(name):
  return name
 for alt in ANIM_FALLBACKS.get(name,[]):
  if has_animation(alt):
   return alt
 return "idle" if has_animation("idle") else ""
func desired_animation() -> String:
 if dead:
  return "defeat"
 if flash>0.0:
  return "hurt"
 if casting>0.0:
  return "skill"
 if swing>0.0:
  return "attack"+str(clampi(combo_step,1,3))
 if trailing:
  return "dash"
 if moving:
  return "run" if run_speed_threshold>0.0 else "walk"
 return "idle"
func play_animation(name:String) -> void:
 var resolved=resolve_animation(name)
 if resolved=="" or resolved==current_anim:
  return
 current_anim=resolved
 sprite.play(resolved)
func update_sprite(delta:float) -> void:
 if swing>0.0 and last_swing<=0.0:
  combo_step=(combo_step%3)+1
  combo_idle=1.2
 elif combo_idle>0.0:
  combo_idle-=delta
  if combo_idle<=0.0:
   combo_step=0
 last_swing=swing
 casting=maxf(0.0,casting-delta)
 if dead:
  death_t+=delta
  if not has_animation("defeat"):
   sprite.pause()
   return
 sprite.flip_h=facing<0
 sprite.self_modulate=Color(2.2,2.2,2.2) if flash>0.0 else Color.WHITE
 var wanted=resolve_animation(desired_animation())
 if wanted==current_anim:
  return
 # Interrupt one-shot animations only for higher-priority states
 if current_anim in ["defeat"] and not dead:
  current_anim=""
 play_animation(wanted)
var ghosts:Array=[]
var ghost_timer=0.0
func _process(delta:float) -> void:
 invincible=maxf(0,invincible-delta)
 stun=maxf(0,stun-delta)
 flash=maxf(0,flash-delta)
 swing=maxf(0,swing-delta)
 step+=delta*(12 if moving else 2)
 if sprite!=null:
  update_sprite(delta)
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
 for g in (ghosts if sprite==null else []):
  draw_set_transform(to_local(g.pos),0,Vector2(facing,1))
  var fade=g.life/0.24*0.4
  draw_colored_polygon(PackedVector2Array([Vector2(-21,-107),Vector2(23,-102),Vector2(35,-20),Vector2(2,-42),Vector2(-36,-22)]),Color(color,fade))
  draw_circle(Vector2(5,-120),17,Color(color,fade))
 draw_set_transform(Vector2.ZERO,0,Vector2(1,0.32))
 draw_circle(Vector2.ZERO,44,Color(0,0,0,0.45))
 draw_arc(Vector2.ZERO,44,0,TAU,48,Color(color,0.4),2)
 draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
 if sprite!=null:
  draw_sprite_overlays(color)
  return
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
 draw_colored_polygon(PackedVector2Array([Vector2(-16,-113+bob),Vector2(25,-108+bob),Vector2(32,-94+bob),Vector2(-22,-99+bob)]),ink.lightened(0.08))
 draw_line(Vector2(-16,-113+bob),Vector2(25,-108+bob),Color(color,0.7),2)
 draw_circle(Vector2(5,-120+bob),17,skin_color if not enemy else Color("252d40"))
 if enemy:
  draw_line(Vector2(-9,-122+bob),Vector2(20,-122+bob),color,4)
  draw_line(Vector2(4,-136+bob),Vector2(6,-105+bob),Color("69718d"),3)
 else:
  var hair=PackedVector2Array([Vector2(-13,-117+bob),Vector2(-16,-139+bob),Vector2(-5,-148+bob),Vector2(0,-141+bob),Vector2(9,-151+bob),Vector2(16,-139+bob),Vector2(27,-141+bob),Vector2(21,-125+bob),Vector2(8,-132+bob)])
  draw_colored_polygon(hair,hair_color)
  draw_colored_polygon(PackedVector2Array([Vector2(-8,-142+bob),Vector2(-12,-159+bob),Vector2(-1,-146+bob)]),hair_color)
  draw_colored_polygon(PackedVector2Array([Vector2(18,-138+bob),Vector2(32,-151+bob),Vector2(25,-130+bob)]),hair_color)
  draw_line(Vector2(-4,-146+bob),Vector2(6,-139+bob),hair_color.lightened(0.4),2)
  draw_line(Vector2(10,-148+bob),Vector2(17,-140+bob),hair_color.lightened(0.4),2)
  draw_line(Vector2(-12,-132+bob),Vector2(-6,-122+bob),hair_color.darkened(0.25),3)
  if body=="female":
   draw_colored_polygon(PackedVector2Array([Vector2(-13,-136+bob),Vector2(-31,-90+bob),Vector2(-12,-103+bob)]),hair_color)
  if look=="mira":
   draw_line(Vector2(-16,-136+bob),Vector2(-36-sway,-96+bob),hair_color,7)
   draw_line(Vector2(-4,-132+bob),Vector2(22,-132+bob),Color("f9d991"),3)
  draw_line(Vector2(9,-128+bob),Vector2(21,-126+bob),Color("1b1626"),2)
  draw_circle(Vector2(16,-122+bob),5,Color("f9d991",0.22))
  draw_colored_polygon(PackedVector2Array([Vector2(10,-123+bob),Vector2(15,-125+bob),Vector2(21,-122+bob),Vector2(15,-120+bob)]),Color("f9d991"))
  draw_circle(Vector2(16,-122+bob),1.4,Color("3a2a10"))
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
 if look=="hero" and not enemy:
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
func draw_sprite_overlays(color:Color) -> void:
 if dead:
  # No reliable defeat frames: a code-drawn purple dissolve over the frozen sprite (the owner fades it out).
  if not has_animation("defeat"):
   var t=clampf(death_t/0.6,0.0,1.0)
   draw_arc(Vector2(0,-70),30+t*120,0,TAU,48,Color(color,0.7*(1.0-t)),5)
   draw_arc(Vector2(0,-70),20+t*80,0,TAU,40,Color(1,1,1,0.5*(1.0-t)),2)
   for i in range(14):
    var a=i*TAU/14.0+0.4
    var rise=t*(60+i%4*22)
    draw_circle(Vector2(cos(a)*(18+t*46),-70+sin(a)*30-rise),3.0*(1.0-t)+1.0,Color(color,0.8*(1.0-t)))
  return
 # Code-drawn effects stand in for animations the art pack could not supply (they are VFX, not character frames).
 if swing>0.0 and not has_animation("attack1"):
  var t=clampf(swing/0.3,0.0,1.0)
  var sc=color
  var rad=86.0
  if boss_form:
   # Phase 2 upgrade: larger, red-hot slash with a second echo arc
   sc=Color("ff4f72")
   rad=112.0
   draw_arc(Vector2(20,-78),rad+26,-1.7,1.1,28,Color(sc,0.25*t),10)
  draw_arc(Vector2(20,-78),rad,-1.6,1.0,28,Color(sc,0.18*t),22)
  draw_arc(Vector2(20,-78),rad,-1.6,1.0,28,Color(sc,0.55*t),8)
  draw_arc(Vector2(20,-78),rad,-1.4+(1.0-t)*0.8,1.0,28,Color(1,1,1,0.85*t),3)
 if casting>0.0 and not has_animation("skill"):
  var u=clampf(casting/0.45,0.0,1.0)
  var cc=Color("ff4f72") if boss_form else color
  draw_arc(Vector2(0,-70),60+(1.0-u)*50,0,TAU,40,Color(cc,0.7*u),4)
  if boss_form:
   draw_arc(Vector2(0,-70),90+(1.0-u)*80,0,TAU,40,Color(cc,0.4*u),3)
 if burst_t>0.0:
  # Transformation energy burst: expanding red/black rings and radial rays
  var e=1.0-burst_t
  draw_arc(Vector2(0,-95),30+e*190,0,TAU,56,Color("ff4f72",0.8*burst_t),8)
  draw_arc(Vector2(0,-95),18+e*120,0,TAU,48,Color(0.05,0.0,0.1,0.9*burst_t),10)
  for i in range(16):
   var ang=i*TAU/16.0
   draw_line(Vector2(0,-95)+Vector2.from_angle(ang)*(40+e*60),Vector2(0,-95)+Vector2.from_angle(ang)*(70+e*210),Color("ff4f72",0.7*burst_t),3)
 if trailing and not has_animation("dash"):
  for i in range(4):
   draw_line(Vector2(-40-i*14,-30-i*22),Vector2(-95-i*10,-30-i*22),Color(color,0.5-i*0.1),3)
 if form_t>0.0 or boss_form:
  # Chest core, halo and shoulder spikes (code-drawn VFX): charge up during the transformation, stay lit afterwards.
  var k=1.0 if boss_form else form_t
  var pulse=0.5+0.5*sin(Time.get_ticks_msec()/140.0)
  var red=Color("ff4f72")
  draw_arc(Vector2(4,-178),22+k*8,0,TAU,32,Color(red,0.85*k),3)
  draw_arc(Vector2(4,-178),30+k*10+pulse*3,0,TAU,32,Color(red,0.35*k),2)
  draw_circle(Vector2(6,-108),(10+pulse*3)*k,Color(red,0.35+0.3*pulse))
  draw_circle(Vector2(6,-108),4*k,Color.WHITE)
  draw_colored_polygon(PackedVector2Array([Vector2(-34,-132),Vector2(-52,-168),Vector2(-20,-138)]),Color(red,0.85*k))
  draw_colored_polygon(PackedVector2Array([Vector2(40,-128),Vector2(58,-162),Vector2(26,-136)]),Color(red,0.85*k))
  draw_arc(Vector2(0,-80),104+pulse*8,0,TAU,48,Color(red,0.25*k),2)
 if aura:
  var glow=0.5+0.5*sin(Time.get_ticks_msec()/160.0)
  draw_arc(Vector2(0,-65),88+glow*6,0,TAU,48,Color(aura_color,0.35+0.3*glow),3)
  draw_arc(Vector2(0,-65),100+glow*8,0,TAU,48,Color(aura_color,0.12+0.12*glow),2)
  if boss_form:
   draw_arc(Vector2(0,-75),118+glow*10,0,TAU,56,Color(aura_color,0.4+0.3*glow),4)
   draw_arc(Vector2(0,-75),134+glow*12,0,TAU,56,Color(0.05,0.0,0.1,0.35),6)
   for i in range(10):
    var ang=i*TAU/10.0+Time.get_ticks_msec()/900.0
    draw_circle(Vector2(0,-75)+Vector2.from_angle(ang)*(122+glow*8),3.0,Color(aura_color,0.8))
 if blocking:
  draw_arc(Vector2(8,-66),65,-1.5,1.5,30,Color(0.4,0.8,1,0.7),5)
 if invincible>0:
  draw_arc(Vector2(0,-65),83,0,TAU,40,Color(color,0.5),2)
