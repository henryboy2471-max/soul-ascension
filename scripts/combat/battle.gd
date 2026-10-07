extends Control
class_name Battle
signal finished(won:bool)
signal retreat
var hero:Fighter
var foe:Fighter
var arena:Node2D
var telegraph_art:Node2D
var sparks:Node2D
var stick:VirtualStick
var controls={}
var energy=100.0
var ultimate=0.0
var combo=0
var combo_timer=0.0
var cooldowns={"attack":0.0,"heavy":0.0,"dodge":0.0,"pulse":0.0,"rift":0.0,"mend":0.0,"ultimate":0.0}
var maxima={"attack":0.36,"heavy":1.3,"dodge":1.2,"pulse":4.0,"rift":7.0,"mend":10.0,"ultimate":1.0}
var enemy_wait=1.5
var telegraph=-1.0
var target=Vector2.ZERO
var ended=false
var intro=0.8
var auto=false
var hp:ProgressBar
var ep:ProgressBar
var enemy_hp:ProgressBar
var combo_label:Label
var tip:Label
var status:Label
var shake=0.0
var tutorial_hits=0
var ultimate_title:Label
var ultimate_sub:Label
var dash=Vector2.ZERO
var dash_time=0.0
var buffered=""
var buffer_time=0.0
var hitstop=0.0
var hp_text:Label
var foe_text:Label
var ult_bar:ProgressBar
var ult_text:Label
var retreat_button:Button
var retreat_armed=0.0
var bar_top:ColorRect
var bar_bottom:ColorRect
var flash_rect:ColorRect
var dim_rect:ColorRect
var intro_card:Label
var intro_sub:Label
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 arena=Node2D.new()
 add_child(arena)
 arena.add_child(ArenaArt.new())
 dim_rect=ColorRect.new()
 dim_rect.color=Color(0.02,0.0,0.07,0.0)
 dim_rect.size=Vector2(1280,720)
 dim_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 arena.add_child(dim_rect)
 hero=Fighter.new()
 var s=HeroData.stats(int(Profile.data.level))
 hero.max_health=s.health
 hero.health=s.health
 hero.attack=s.attack
 hero.defense=s.defense
 hero.body=Profile.data.body
 hero.speed=s.speed
 hero.position=Vector2(400,450)
 arena.add_child(hero)
 foe=Fighter.new()
 foe.enemy=true
 foe.health=650
 foe.max_health=650
 foe.attack=28
 foe.defense=6
 foe.position=Vector2(850,450)
 foe.facing=-1
 arena.add_child(foe)
 telegraph_art=load("res://scripts/combat/telegraph.gd").new()
 telegraph_art.battle=self
 add_child(telegraph_art)
 sparks=load("res://scripts/combat/impact.gd").new()
 add_child(sparks)
 hero.struck.connect(func(amount,critical): damage_number(hero.position,amount,critical,Color("ff8597")); Sound.play("hurt"))
 foe.struck.connect(func(amount,critical): damage_number(foe.position,amount,critical,UI.GOLD))
 hero.defeated.connect(func(): end(false))
 foe.defeated.connect(func(): end(true))
 UI.panel(self,Rect2(24,22,390,104))
 UI.label(self,Profile.data.name.to_upper()+"  /  LV. "+str(Profile.data.level),Vector2(42,34),20)
 hp=UI.bar(self,Rect2(42,66,352,14),Color("b48bff"),hero.max_health)
 ep=UI.bar(self,Rect2(42,85,352,8),Color("6fd7e4"),100)
 ult_bar=UI.bar(self,Rect2(42,97,352,6),UI.GOLD,100)
 hp_text=UI.label(self,"",Vector2(42,64),12,Color.WHITE,346)
 hp_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 UI.label(self,"AETHER",Vector2(42,106),11,UI.MUTED)
 ult_text=UI.label(self,"",Vector2(200,106),11,UI.GOLD,194)
 ult_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 UI.panel(self,Rect2(866,22,390,104))
 UI.label(self,"MERIDIAN ENFORCER",Vector2(884,34),20)
 enemy_hp=UI.bar(self,Rect2(884,66,352,14),Color("ec708e"),650)
 foe_text=UI.label(self,"",Vector2(884,64),12,Color.WHITE,346)
 foe_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 UI.label(self,"SUPPRESSION CLASS  /  NEUTRAL",Vector2(884,95),12,UI.MUTED)
 UI.label(self,"01—01  /  SKYBRIDGE 09",Vector2(475,28),16,UI.GOLD)
 retreat_button=UI.button(self,"RETREAT",Rect2(572,66,136,46),request_retreat)
 retreat_button.add_theme_font_size_override("font_size",15)
 tip=UI.label(self,"",Vector2(295,155),25,UI.GOLD,720)
 tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 combo_label=UI.label(self,"",Vector2(560,220),32,UI.GOLD)
 status=UI.label(self,"",Vector2(395,513),18,UI.VIOLET,550)
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 UI.label(self,"PROTOTYPE COMBAT ART",Vector2(22,475),11,UI.MUTED)
 stick=VirtualStick.new()
 stick.position=Vector2(36,520)
 stick.size=Vector2(180,180)
 add_child(stick)
 UI.label(self,"MOVE  /  WASD",Vector2(61,698),12,UI.MUTED)
 var definitions=[
  ["pulse","PULSE","Q · 25",Vector2(757,521)],
  ["rift","RIFT","E · 35",Vector2(855,521)],
  ["mend","MEND","R · 30",Vector2(953,521)],
  ["dodge","DODGE","SPACE",Vector2(855,619)],
  ["block","BLOCK","L · HOLD",Vector2(953,619)],
  ["heavy","HEAVY","K",Vector2(1051,521)],
  ["attack","STRIKE","J · HOLD",Vector2(1051,619)],
  ["ultimate","ULTIMATE","F · 100%",Vector2(642,611)]
 ]
 for spec in definitions:
  var control=TouchAction.new()
  control.title=spec[1]
  control.subtitle=spec[2]
  control.position=spec[3]
  control.size=Vector2(88,88)
  if spec[0]=="ultimate":
   control.tint=UI.GOLD
   control.charge=0.0
   control.size=Vector2(104,104)
  add_child(control)
  controls[spec[0]]=control
  control.activated.connect(act.bind(spec[0]))
 if Profile.data.completed.has("1-1"):
  UI.button(self,"AUTO: OFF",Rect2(263,629,177,66),toggle_auto)
 else:
  UI.label(self,"Auto unlocks after first clear",Vector2(249,655),13,UI.MUTED)
 ultimate_title=UI.label(self,"",Vector2(235,300),55,Color.WHITE,850)
 ultimate_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ultimate_sub=UI.label(self,"",Vector2(235,368),20,UI.GOLD,850)
 ultimate_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 intro_card=UI.label(self,"MERIDIAN ENFORCER",Vector2(190,196),52,Color.WHITE,900)
 intro_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 intro_sub=UI.label(self,"SUPPRESSION CLASS  /  SKYBRIDGE 09  /  SURVIVE THE SCAN",Vector2(190,262),18,UI.GOLD,900)
 intro_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 flash_rect=ColorRect.new()
 flash_rect.color=Color(1,1,1,0)
 flash_rect.size=Vector2(1280,720)
 flash_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(flash_rect)
 bar_top=ColorRect.new()
 bar_top.color=Color.BLACK
 bar_top.size=Vector2(1280,40)
 bar_top.position=Vector2(0,-40)
 bar_top.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(bar_top)
 bar_bottom=ColorRect.new()
 bar_bottom.color=Color.BLACK
 bar_bottom.size=Vector2(1280,40)
 bar_bottom.position=Vector2(0,720)
 bar_bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(bar_bottom)
 # Menu-style buttons must never keep keyboard focus, or Space/Enter would activate them instead of dodging.
 for child in get_children():
  if child is Button:
   child.focus_mode=Control.FOCUS_NONE
 boss_intro()
func boss_intro() -> void:
 intro_card.modulate.a=0
 intro_sub.modulate.a=0
 cinematic_bars(1.5)
 var tween=create_tween()
 tween.tween_property(intro_card,"modulate:a",1.0,0.2)
 tween.parallel().tween_property(intro_sub,"modulate:a",1.0,0.2)
 tween.tween_interval(0.9)
 tween.tween_property(intro_card,"modulate:a",0.0,0.35)
 tween.parallel().tween_property(intro_sub,"modulate:a",0.0,0.35)
 tween.tween_callback(func(): tip.text="Move close, then STRIKE [J]. Red circle? DODGE [SPACE].")
func cinematic_bars(hold:float) -> void:
 var tween=create_tween().set_parallel(true)
 tween.tween_property(bar_top,"position:y",0.0,0.2)
 tween.tween_property(bar_bottom,"position:y",680.0,0.2)
 tween.chain().tween_interval(hold)
 tween.chain().tween_property(bar_top,"position:y",-40.0,0.3)
 tween.parallel().tween_property(bar_bottom,"position:y",720.0,0.3)
func request_retreat() -> void:
 if ended:
  return
 if retreat_armed>0:
  retreat.emit()
  return
 retreat_armed=2.0
 retreat_button.text="CONFIRM?"
func move_input() -> Vector2:
 var move=stick.direction
 if Input.is_physical_key_pressed(KEY_A): move.x-=1
 if Input.is_physical_key_pressed(KEY_D): move.x+=1
 if Input.is_physical_key_pressed(KEY_W): move.y-=1
 if Input.is_physical_key_pressed(KEY_S): move.y+=1
 return move.limit_length()
func toggle_auto() -> void:
 auto=not auto
 for child in get_children():
  if child is Button and child.text.begins_with("AUTO"):
   child.text="AUTO: ON" if auto else "AUTO: OFF"
func _unhandled_key_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  var keys={KEY_J:"attack",KEY_K:"heavy",KEY_SPACE:"dodge",KEY_Q:"pulse",KEY_E:"rift",KEY_R:"mend",KEY_F:"ultimate"}
  if keys.has(event.physical_keycode):
   act(keys[event.physical_keycode])
func _process(delta:float) -> void:
 if ended:
  return
 hp.value=hero.health
 ep.value=energy
 ult_bar.value=ultimate
 enemy_hp.value=foe.health
 hp_text.text=str(int(ceil(hero.health)))+" / "+str(int(hero.max_health))
 foe_text.text=str(int(ceil(foe.health)))+" / "+str(int(foe.max_health))
 ult_text.text="ULTIMATE READY  ·  F" if ultimate>=100 else "ULTIMATE  "+str(int(ultimate))+"%"
 controls.ultimate.charge=ultimate/100.0
 hero.aura=ultimate>=100
 if retreat_armed>0:
  retreat_armed-=delta
  if retreat_armed<=0:
   retreat_button.text="RETREAT"
 for key in cooldowns:
  cooldowns[key]=maxf(0,cooldowns[key]-delta)
  if controls.has(key):
   controls[key].cooldown=cooldowns[key]/maxima[key]
 controls.ultimate.subtitle="READY · F" if ultimate>=100 else str(int(ultimate))+"% · F"
 combo_timer=maxf(0,combo_timer-delta)
 if combo_timer==0:
  combo=0
 combo_label.text=str(combo)+" HIT" if combo>1 else ""
 shake=maxf(0,shake-delta*30)
 arena.position=Vector2(randf_range(-shake,shake),randf_range(-shake,shake)) if Profile.data.settings.get("shake",true) else Vector2.ZERO
 if intro>0:
  intro-=delta
  return
 energy=minf(100,energy+delta*8)
 if tutorial_hits==0:
  pass
 elif tutorial_hits<3:
  tip.text="Build your combo. Hold BLOCK [L] to reduce incoming damage."
 else:
  tip.text="PULSE [Q] staggers. RIFT [E] reaches farther. MEND [R] restores health."
 var move=move_input()
 if buffer_time>0:
  buffer_time-=delta
  if cooldowns.get(buffered,0)<=0:
   var queued=buffered
   buffered=""
   buffer_time=0
   act(queued)
 hero.blocking=controls.block.held or Input.is_physical_key_pressed(KEY_L)
 if auto:
  move=hero.position.direction_to(foe.position) if hero.position.distance_to(foe.position)>95 else Vector2.ZERO
  act("pulse")
  act("attack")
  if hero.health<hero.max_health*0.5: act("mend")
  if ultimate>=100: act("ultimate")
 if controls.attack.held or Input.is_physical_key_pressed(KEY_J):
  act("attack")
 if hitstop>0:
  hitstop-=delta
  telegraph_art.queue_redraw()
  return
 if hero.stun<=0:
  hero.position+=move.limit_length()*hero.speed*delta*(0.55 if hero.blocking else 1.0)
 if dash_time>0:
  dash_time-=delta
  hero.position+=dash*delta
 hero.position.x=clampf(hero.position.x,75,1205)
 hero.position.y=clampf(hero.position.y,345,540)
 hero.moving=move.length()>0.1 or dash_time>0
 hero.facing=1 if foe.position.x>hero.position.x else -1
 foe.facing=1 if hero.position.x>foe.position.x else -1
 foe.moving=false
 if foe.stun>0:
  telegraph=-1
  telegraph_art.queue_redraw()
  return
 if telegraph>=0:
  telegraph-=delta
  if telegraph<=0:
   foe.swing=0.4
   if hero.position.distance_to(target)<100:
    hero.receive(foe.attack)
   enemy_wait=1.0
   telegraph=-1
 elif enemy_wait>0:
  enemy_wait-=delta
 else:
  var distance=foe.position.distance_to(hero.position)
  if distance>110:
   foe.moving=true
   foe.position+=foe.position.direction_to(hero.position)*170*delta
  else:
   telegraph=0.8
   target=hero.position
 telegraph_art.queue_redraw()
func act(kind:String) -> void:
 if ended or intro>0 or hero.stun>0 or kind=="block":
  return
 if cooldowns.get(kind,0)>0:
  if kind!="attack" or buffer_time<=0:
   buffered=kind
   buffer_time=0.18
  return
 var cost={"pulse":25,"rift":35,"mend":30,"dodge":12}.get(kind,0)
 if energy<cost:
  status.text="Aether recharging…"
  return
 if kind=="ultimate" and ultimate<100:
  status.text="Land attacks to charge your ultimate."
  return
 energy-=cost
 cooldowns[kind]=maxima[kind]
 if kind=="dodge":
  var direction=move_input()
  if direction.length()<0.1:
   direction=foe.position.direction_to(hero.position)
  dash=direction.normalized()*812.0
  dash_time=0.16
  hero.invincible=0.45
  Sound.play("special")
  return
 if kind=="mend":
  hero.health=minf(hero.max_health,hero.health+70)
  status.text="MEND  /  restored health"
  Sound.play("special")
  return
 hero.swing=0.30
 var reach={"attack":135,"heavy":155,"pulse":230,"rift":520,"ultimate":1500}.get(kind,135)
 var multiplier={"attack":1.0,"heavy":2.2,"pulse":2.5,"rift":3.1,"ultimate":7.5}.get(kind,1.0)
 Sound.play("hit" if kind in ["attack","heavy"] else "special")
 if kind=="ultimate":
  ultimate=0
  ultimate_title.text="ECHO : HORIZON BREAK"
  ultimate_sub.text="THE UNBOUND  /  ULTIMATE"
  ultimate_title.modulate.a=1
  ultimate_sub.modulate.a=1
  var tween=create_tween().set_parallel(true)
  tween.tween_property(ultimate_title,"modulate:a",0.0,1.4)
  tween.tween_property(ultimate_sub,"modulate:a",0.0,1.4)
  flash_rect.color=Color(1,1,1,0.75)
  tween.tween_property(flash_rect,"color:a",0.0,0.5)
  dim_rect.color.a=0.55
  tween.tween_property(dim_rect,"color:a",0.0,1.3)
  cinematic_bars(1.0)
  shake=16
  hero.invincible=1.4
 if hero.position.distance_to(foe.position)>reach:
  status.text="Get closer to land your strike."
  return
 var critical=randf()<0.12
 var damage=hero.attack*multiplier*(1.6 if critical else 1.0)
 sparks.burst(foe.position-Vector2(0,75),kind=="ultimate")
 foe.receive(damage,critical)
 hitstop=0.09 if critical or kind in ["heavy","ultimate"] else 0.0
 combo+=1
 combo_timer=2.4
 tutorial_hits+=1
 ultimate=minf(100,ultimate+12) if kind!="ultimate" else 0
 energy=minf(100,energy+5) if kind=="attack" else energy
 shake=maxf(shake,5 if not critical else 9)
 status.text="CRITICAL" if critical else kind.to_upper()+"  /  connected"
 if kind in ["heavy","pulse","rift","ultimate"]:
  foe.stun=0.5 if kind!="ultimate" else 1.6
func damage_number(point:Vector2, amount:int, critical:bool, color:Color) -> void:
 var label=UI.label(self,str(amount)+( "!" if critical else ""),point-Vector2(18,160),32 if critical else 24,color)
 var tween=create_tween().set_parallel(true)
 tween.tween_property(label,"position:y",label.position.y-60,0.7)
 tween.tween_property(label,"modulate:a",0.0,0.7)
 tween.chain().tween_callback(label.queue_free)
func end(won:bool) -> void:
 if ended: return
 ended=true
 hp.value=hero.health
 enemy_hp.value=foe.health
 Sound.play("win" if won else "hurt")
 await get_tree().create_timer(0.7).timeout
 finished.emit(won)
