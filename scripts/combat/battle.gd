extends Control
class_name Battle
signal finished(won:bool)
signal retreat
var hero:Fighter
var foe:Fighter
var waves:Array=[]
var wave=0
var foe_name_label:Label
var foe_sub_label:Label
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
var boss_scale=1.32
var boss_frames_path="res://assets/enemies/soul_realm_boss/frames.tres"
var transform_count=0
var transform_clock=-1.0
var transform_revealed=false
var transform_foe_ref:Fighter
var telegraph=-1.0
var telegraph_len=0.8
var recovery=1.0
var phase=1
var boss_mode=false
var target=Vector2.ZERO
var ended=false
var intro=0.8
var auto=false
var hp:HudBar
var ep:HudBar
var enemy_hp:HudBar
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
var ult_bar:HudBar
var retreat_button:Button
var retreat_armed=0.0
var bar_top:ColorRect
var bar_bottom:ColorRect
var foe_panel:Panel
var foe_trim:Control
var wave_chip:Label
var hurt_vignette:Control
const HERO_BLUE=Color("4aa3ff")
const ACTION_COST={"pulse":25,"rift":35,"mend":30,"dodge":12}
var flash_rect:ColorRect
var dim_rect:ColorRect
var intro_card:Label
var intro_sub:Label
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 arena=Node2D.new()
 add_child(arena)
 if boss_mode:
  arena.add_child(SoulRealmArt.new())
 else:
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
 hero.load_sprite_set("res://assets/characters/hero/frames.tres",170.0,Color("4aa3ff"))
 hero.run_speed_threshold=1.0
 hero.position=Vector2(400,450)
 arena.add_child(hero)
 waves=wave_defs()
 spawn_foe(waves[0])
 telegraph_art=load("res://scripts/combat/telegraph.gd").new()
 telegraph_art.battle=self
 add_child(telegraph_art)
 sparks=load("res://scripts/combat/impact.gd").new()
 add_child(sparks)
 hero.struck.connect(func(amount,critical): damage_number(hero.position,amount,critical,Color("ff8597")); hurt_vignette.pulse(0.55 if critical else 0.4); Sound.play("hurt"))
 hero.defeated.connect(func(): end(false))
 # --- HUD: black/navy panels, gold trim, Hero blue (left), foe accent (right: Shade purple, Enforcer orange, Phase 2 red) ---
 UI.panel(self,Rect2(24,24,406,116),Color(0.025,0.035,0.08,0.94),Color(HERO_BLUE,0.55))
 UI.trim(self,Rect2(24,24,406,116),UI.GOLD)
 UI.label(self,Profile.data.name.to_upper(),Vector2(42,32),22)
 UI.chip(self,"LV. "+str(Profile.data.level),Rect2(338,34,72,22),UI.GOLD,13)
 UI.label(self,"HP",Vector2(42,64),14,HERO_BLUE)
 hp=UI.hud_bar(self,Rect2(76,62,334,22),HERO_BLUE,hero.max_health)
 hp.low_warn=0.3
 hp.readout_size=14
 UI.label(self,"AETHER",Vector2(42,88),13,UI.MUTED)
 ep=UI.hud_bar(self,Rect2(104,88,306,14),Color("6fd7e4"),100)
 ep.readout_size=12
 UI.label(self,"ULT",Vector2(42,105),13,UI.GOLD)
 ult_bar=UI.hud_bar(self,Rect2(76,107,334,12),UI.GOLD,100)
 ult_bar.readout_size=11
 foe_panel=UI.panel(self,Rect2(850,24,406,116),Color(0.035,0.025,0.06,0.94),Color(foe_accent(waves[0]),0.6))
 foe_trim=UI.trim(self,Rect2(850,24,406,116),foe_accent(waves[0]))
 foe_sub_label=UI.label(self,waves[0].sub,Vector2(868,32),12,foe_accent(waves[0]),292)
 foe_name_label=UI.label(self,waves[0].name,Vector2(868,50),24,Color.WHITE,380)
 wave_chip=UI.chip(self,"WAVE 1/"+str(waves.size()) if boss_mode else "STAGE 1",Rect2(1166,32,74,22),foe_accent(waves[0]),13)
 enemy_hp=UI.hud_bar(self,Rect2(868,90,372,24),foe_accent(waves[0]),foe.max_health)
 enemy_hp.readout_size=14
 var stage=UI.label(self,"SOUL REALM  /  RESONANT BRIDGE" if boss_mode else "01—01  /  SKYBRIDGE 09",Vector2(440,30),15,UI.GOLD,400)
 stage.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 UI.outline(stage,5)
 retreat_button=UI.button(self,"RETREAT",Rect2(576,66,128,42),request_retreat)
 retreat_button.add_theme_font_size_override("font_size",14)
 tip=UI.label(self,"",Vector2(260,148),21,UI.GOLD,760)
 tip.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 UI.outline(tip,7)
 combo_label=UI.label(self,"",Vector2(560,222),34,UI.GOLD)
 UI.outline(combo_label,8)
 status=UI.label(self,"",Vector2(340,182),17,UI.VIOLET,600)
 status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 UI.outline(status,6)
 UI.label(self,"PROTOTYPE COMBAT ART",Vector2(540,700),11,Color(UI.MUTED,0.55),200)
 stick=VirtualStick.new()
 stick.position=Vector2(36,520)
 stick.size=Vector2(180,180)
 add_child(stick)
 UI.label(self,"MOVE  /  WASD",Vector2(61,698),14,UI.MUTED)
 var definitions=[
  ["pulse","PULSE","Q · 25",Vector2(828,500),Color("b48bff")],
  ["rift","RIFT","E · 35",Vector2(932,500),Color("8f9bff")],
  ["mend","MEND","R · 30",Vector2(1036,500),Color("5fe0b0")],
  ["heavy","HEAVY","K",Vector2(1140,500),Color("ff9a4a")],
  ["dodge","DODGE","SPACE",Vector2(932,600),Color("4aa3ff")],
  ["block","BLOCK","L · HOLD",Vector2(1036,600),Color("6fb6ff")],
  ["attack","STRIKE","J · HOLD",Vector2(1140,600),Color("efce8e")],
  ["ultimate","ULTIMATE","F · 100%",Vector2(690,586),Color("efce8e")]
 ]
 for spec in definitions:
  var control=TouchAction.new()
  control.title=spec[1]
  control.subtitle=spec[2]
  control.position=spec[3]
  control.size=Vector2(96,96)
  control.tint=spec[4]
  if spec[0]=="ultimate":
   control.charge=0.0
   control.size=Vector2(112,112)
  add_child(control)
  controls[spec[0]]=control
  control.activated.connect(act.bind(spec[0]))
 if Profile.data.completed.has("1-1"):
  UI.button(self,"AUTO: OFF",Rect2(250,632,150,56),toggle_auto)
 else:
  var auto_hint=UI.label(self,"Auto unlocks after first clear",Vector2(236,664),13,Color(UI.MUTED,0.8),200)
  UI.outline(auto_hint,4)
 hurt_vignette=HurtVignette.new()
 hurt_vignette.size=Vector2(1280,720)
 hurt_vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(hurt_vignette)
 ultimate_title=UI.label(self,"",Vector2(235,300),55,Color.WHITE,850)
 ultimate_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ultimate_sub=UI.label(self,"",Vector2(235,368),20,UI.GOLD,850)
 ultimate_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 intro_card=UI.label(self,waves[0].card,Vector2(190,196),52,Color.WHITE,900)
 intro_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 intro_sub=UI.label(self,waves[0].card_sub,Vector2(190,262),18,UI.GOLD,900)
 intro_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 flash_rect=ColorRect.new()
 flash_rect.color=Color(1,1,1,0)
 flash_rect.size=Vector2(1280,720)
 flash_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(flash_rect)
 bar_top=ColorRect.new()
 bar_top.color=Color.BLACK
 bar_top.size=Vector2(1280,22)
 bar_top.position=Vector2(0,-22)
 bar_top.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(bar_top)
 bar_bottom=ColorRect.new()
 bar_bottom.color=Color.BLACK
 bar_bottom.size=Vector2(1280,22)
 bar_bottom.position=Vector2(0,720)
 bar_bottom.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(bar_bottom)
 # Menu-style buttons must never keep keyboard focus, or Space/Enter would activate them instead of dodging.
 for child in get_children():
  if child is Button:
   child.focus_mode=Control.FOCUS_NONE
 if boss_mode:
  Sound.loop("realm")
 else:
  Sound.stop_loop()
 boss_intro()
func boss_intro(card_text:String="", card_sub:String="") -> void:
 if card_text!="":
  intro_card.text=card_text
  intro_sub.text=card_sub
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
 tween.tween_property(bar_bottom,"position:y",698.0,0.2)
 tween.chain().tween_interval(hold)
 tween.chain().tween_property(bar_top,"position:y",-22.0,0.3)
 tween.parallel().tween_property(bar_bottom,"position:y",720.0,0.3)
func wave_defs() -> Array:
 if boss_mode:
  return [
   {"name":"RESONANCE SHADE","sub":"SOUL REALM ECHO  /  UNSTABLE","hp":240.0,"atk":20.0,"def":3.0,"look":"shade","accent":Color("6fd7e4"),"scale":1.0,"boss":false,"card":"RESONANCE SHADE","card_sub":"AN ECHO OF THE SUPPRESSION SCAN  /  CLEAR IT"},
   {"name":"MERIDIAN ENFORCER","sub":"SOUL-WARPED CONSTRUCT  /  SUPPRESSION","hp":820.0,"atk":28.0,"def":6.0,"look":"warped","accent":Color("c27bff"),"scale":1.2,"boss":true,"card":"SOUL-WARPED ENFORCER","card_sub":"A MERIDIAN CONSTRUCT TWISTED BY YOUR ECHO  /  SURVIVE IT"}
  ]
 return [{"name":"MERIDIAN ENFORCER","sub":"SUPPRESSION CLASS  /  NEUTRAL","hp":650.0,"atk":28.0,"def":6.0,"look":"enforcer","accent":Color(0,0,0,0),"scale":1.0,"boss":false,"card":"MERIDIAN ENFORCER","card_sub":"SUPPRESSION CLASS  /  SKYBRIDGE 09  /  SURVIVE THE SCAN"}]
func spawn_foe(def:Dictionary) -> void:
 foe=Fighter.new()
 foe.enemy=true
 foe.health=def.hp
 foe.max_health=def.hp
 foe.attack=def.atk
 foe.defense=def.def
 foe.look=def.look
 foe.accent=def.accent
 foe.scale=Vector2(def.scale,def.scale)
 if def.look=="shade":
  # Sprite art when present (world height 185 = about 10% taller than the Hero); the procedural rig stays as fallback.
  foe.load_sprite_set("res://assets/enemies/resonance_shade/frames.tres",185.0,Color("b46bff"))
 elif def.look=="warped":
  # Soul-Warped Enforcer sprite art; world height 180 x node scale 1.2 stands about 1.3x the Hero. Orange fire VFX for missing attack frames.
  foe.load_sprite_set("res://assets/enemies/enforcer/frames.tres",180.0,Color("ff8a2a"))
 foe.position=Vector2(850,450)
 foe.facing=-1
 arena.add_child(foe)
 var current=foe
 current.struck.connect(func(amount,critical): damage_number(current.position,amount,critical,UI.GOLD))
 current.defeated.connect(on_foe_defeated.bind(current))
 phase=1
 telegraph=-1.0
 telegraph_len=0.8
 recovery=1.0
 enemy_wait=1.5
 if is_instance_valid(foe_name_label):
  foe_name_label.text=def.name
  foe_sub_label.text=def.sub
  enemy_hp.max_value=def.hp
  enemy_hp.value=def.hp
  enemy_hp.ghost=def.hp
  var accent=foe_accent(def)
  foe_sub_label.add_theme_color_override("font_color",accent)
  enemy_hp.color=accent
  enemy_hp.tick=0.5 if def.boss else -1.0
  foe_trim.accent=accent
  foe_trim.queue_redraw()
  var style=foe_panel.get_theme_stylebox("panel").duplicate()
  style.border_color=Color(accent,0.6)
  foe_panel.add_theme_stylebox_override("panel",style)
  if boss_mode:
   wave_chip.text="WAVE "+str(wave+1)+"/"+str(waves.size())
   UI.chip_color(wave_chip,accent)
func foe_accent(def:Dictionary) -> Color:
 return Color("b46bff") if def.look=="shade" else Color("ff8a2a")
func hud_phase_two() -> void:
 # HUD transition: foe panel, bar and tag turn Phase 2 red, sub-title reads SOUL ASCENDED.
 var red=Color("ff4f72")
 foe_sub_label.text="SOUL ASCENDED  /  PHASE 2"
 foe_sub_label.add_theme_color_override("font_color",red)
 enemy_hp.color=red
 enemy_hp.tick=-1.0
 foe_trim.accent=red
 foe_trim.queue_redraw()
 wave_chip.text="PHASE 2"
 UI.chip_color(wave_chip,red)
 var style=foe_panel.get_theme_stylebox("panel").duplicate()
 style.border_color=Color(red,0.8)
 foe_panel.add_theme_stylebox_override("panel",style)
 foe_panel.modulate=Color(2.0,1.3,1.4)
 create_tween().tween_property(foe_panel,"modulate",Color.WHITE,0.7)
 hurt_vignette.pulse(0.35)
func on_foe_defeated(defeated_foe:Fighter) -> void:
 if defeated_foe!=foe or ended:
  return
 if wave+1<waves.size():
  next_wave()
 else:
  end(true)
func next_wave() -> void:
 wave+=1
 var old=foe
 var fade=create_tween()
 fade.tween_property(old,"modulate:a",0.0,0.5)
 fade.tween_callback(old.queue_free)
 hero.health=minf(hero.max_health,hero.health+60.0)
 energy=minf(100.0,energy+40.0)
 spawn_foe(waves[wave])
 foe.modulate.a=0.0
 create_tween().tween_property(foe,"modulate:a",1.0,0.5)
 intro=0.5
 sparks.burst(old.position-Vector2(0,75),false)
 status.text="WAVE CLEARED  /  +60 HEALTH"
 Sound.play("win")
 boss_intro(waves[wave].card,waves[wave].card_sub)
func transform_foe() -> void:
 # Phase 2 reveal on the SAME foe: no new enemy, health/position/facing/AI untouched, damage rules unchanged (still hittable).
 # Runs as a real-time state machine (transform_clock, ~0.9 s): slow-motion + darken + red/black pulse + core/halo charge,
 # then reveal (form swap, energy burst, shake), then control is fully back.
 if transform_count>0:
  return
 transform_count=1
 transform_clock=0.0
 transform_revealed=false
 transform_foe_ref=foe
 foe.form_t=0.05
 enemy_wait=maxf(enemy_wait,0.5)
 Engine.time_scale=0.25
 dim_rect.color=Color(0.1,0.0,0.03,0.0)
 flash_rect.color=Color(1,0.1,0.2,0.55)
 shake=10
 get_tree().create_timer(1.5,true,false,true).timeout.connect(restore_time)
func _exit_tree() -> void:
 restore_time()
func restore_time() -> void:
 Engine.time_scale=1.0
func update_transform(delta:float) -> void:
 if transform_clock<0.0:
  return
 transform_clock+=delta/maxf(Engine.time_scale,0.05)
 var c=transform_clock
 var f=transform_foe_ref
 if is_instance_valid(f):
  f.form_t=clampf(c/0.55,0.0,1.0)
 flash_rect.color.a=maxf(0.0,0.55*(1.0-c/0.4)) if not transform_revealed else flash_rect.color.a
 if c<0.55:
  dim_rect.color.a=minf(0.65,c/0.25*0.65)
 elif not transform_revealed:
  transform_revealed=true
  restore_time()
  if is_instance_valid(f):
   f.set_boss_form(boss_frames_path)
   f.burst_t=1.0
   f.scale=Vector2(f.scale.x*0.95,f.scale.y*0.95)
   create_tween().tween_property(f,"scale",Vector2(boss_scale,boss_scale),0.25)
   sparks.burst(f.position-Vector2(0,90),true)
  flash_rect.color=Color(1,0.7,0.75,0.7)
  create_tween().tween_property(flash_rect,"color:a",0.0,0.35)
  shake=18
  Sound.play("special")
 if transform_revealed:
  dim_rect.color.a=maxf(0.0,0.65*(1.0-(c-0.55)/0.35))
  if is_instance_valid(f):
   f.burst_t=maxf(0.0,1.0-(c-0.55)/0.5)
  if c>=0.9:
   dim_rect.color=Color(0.02,0.0,0.07,0.0)
   if is_instance_valid(f):
    f.burst_t=0.0
   transform_clock=-1.0
func enter_phase_two() -> void:
 phase=2
 foe.attack=36
 telegraph_len=0.62
 recovery=0.65
 foe.aura=true
 foe.aura_color=Color("ff4f72")
 transform_foe()
 hud_phase_two()
 intro_card.text="PHASE 2"
 intro_sub.text="SOUL ASCENDED  /  ATTACKS FASTER AND HIT HARDER"
 intro_card.modulate.a=1
 intro_sub.modulate.a=1
 var tween=create_tween()
 tween.tween_interval(1.1)
 tween.tween_property(intro_card,"modulate:a",0.0,0.4)
 tween.parallel().tween_property(intro_sub,"modulate:a",0.0,0.4)
 flash_rect.color=Color(1,0.3,0.4,0.5)
 create_tween().tween_property(flash_rect,"color:a",0.0,0.5)
 cinematic_bars(0.9)
 shake=12
 status.text="PHASE 2  /  the enforcer escalates"
 Sound.play("hurt")
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
 update_transform(delta)
 hp.value=hero.health
 ep.value=energy
 ult_bar.value=ultimate
 if phase==1 and waves[wave].boss and not ended and foe.health>0 and foe.health<=foe.max_health*0.5:
  enter_phase_two()
 enemy_hp.value=foe.health
 hp.readout=str(int(ceil(hero.health)))+" / "+str(int(hero.max_health))
 enemy_hp.readout=str(int(ceil(foe.health)))+" / "+str(int(foe.max_health))
 ep.readout=str(int(energy))
 ult_bar.readout="READY  ·  F" if ultimate>=100 else str(int(ultimate))+"%"
 ult_bar.color=UI.GOLD if ultimate<100 else Color("fff0b8")
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
   controls[key].seconds=cooldowns[key]
   var cost=ACTION_COST.get(key,0)
   controls[key].dim=energy<cost
 controls.ultimate.dim=ultimate<100
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
  if wave>=1:
   tip.text=""
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
 hero.trailing=dash_time>0
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
   enemy_wait=recovery
   telegraph=-1
 elif enemy_wait>0:
  enemy_wait-=delta
 else:
  var distance=foe.position.distance_to(hero.position)
  if distance>110:
   foe.moving=true
   foe.position+=foe.position.direction_to(hero.position)*170*delta
  else:
   telegraph=telegraph_len
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
  hero.casting=0.45
  hero.health=minf(hero.max_health,hero.health+70)
  status.text="MEND  /  restored health"
  Sound.play("special")
  return
 hero.swing=0.30
 if kind in ["pulse","rift","ultimate"]:
  hero.casting=0.45
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
 # Outlined, popping numbers: bigger and warmer on criticals; spread sideways so stacked hits stay readable.
 var label=UI.label(self,str(amount)+( "!" if critical else ""),point+Vector2(randf_range(-26,26)-14,-175),40 if critical else 28,Color("ffd27a") if critical and color==UI.GOLD else color)
 UI.outline(label,9 if critical else 7)
 label.pivot_offset=Vector2(14,16)
 label.scale=Vector2(0.6,0.6)
 var tween=create_tween().set_parallel(true)
 tween.tween_property(label,"scale",Vector2(1.2,1.2) if critical else Vector2(1.0,1.0),0.12)
 tween.tween_property(label,"position:y",label.position.y-70,0.8)
 tween.tween_property(label,"modulate:a",0.0,0.35).set_delay(0.45)
 tween.chain().tween_callback(label.queue_free)
func finisher() -> void:
 ultimate_title.text="FINISH"
 ultimate_sub.text="THE UNBOUND  /  RESONANCE STRIKE"
 ultimate_title.modulate.a=1
 ultimate_sub.modulate.a=1
 flash_rect.color=Color(1,1,1,0.9)
 var tween=create_tween().set_parallel(true)
 tween.tween_property(flash_rect,"color:a",0.0,0.7)
 tween.tween_property(ultimate_title,"modulate:a",0.0,1.3)
 tween.tween_property(ultimate_sub,"modulate:a",0.0,1.3)
 # Push in on the fallen foe
 tween.tween_property(arena,"scale",Vector2(1.14,1.14),0.9)
 tween.tween_property(arena,"position",foe.position*-0.14,0.9)
 cinematic_bars(1.0)
 sparks.burst(foe.position-Vector2(0,75),true)
func end(won:bool) -> void:
 if ended: return
 ended=true
 restore_time()
 transform_clock=-1.0
 hp.value=hero.health
 enemy_hp.value=foe.health
 Sound.play("win" if won else "hurt")
 var wait=0.7
 if won and boss_mode:
  wait=1.5
  finisher()
 await get_tree().create_timer(wait).timeout
 finished.emit(won)
