extends SceneTree
# Phase 2 Soul Realm Boss transformation: same foe, no reset, cinematic reveal, size, damage, defeat, finisher.
var passed=0
var failed=0
var main
var profile
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(100.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func solid_extent(tex:Texture2D, threshold:float=0.6) -> Vector2i:
 var img=tex.get_image()
 var top=-1
 var bottom=-1
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>threshold:
    if top<0: top=y
    bottom=y+1
    break
 return Vector2i(top,bottom)
func median(values:Array) -> float:
 var v=values.duplicate()
 v.sort()
 return float(v[v.size()/2])
func displayed_height(f) -> float:
 var heights=[]
 for i in range(f.sprite_frames.get_frame_count("idle")):
  var e=solid_extent(f.sprite_frames.get_frame_texture("idle",i))
  heights.append(e.y-e.x)
 return median(heights)*f.sprite.scale.y*f.scale.y
func fighters(arena) -> int:
 var n=0
 for c in arena.get_children():
  if c.get_script()!=null and c.has_method("receive"): n+=1
 return n
func run() -> void:
 profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 # the form swap itself works with a frames.tres (the Boss sheet is not delivered yet, so reuse the Enforcer set)
 var probe=load("res://scripts/combat/fighter.gd").new()
 probe.load_sprite_set("res://assets/enemies/enforcer/frames.tres",180.0)
 check(probe.set_boss_form("res://assets/enemies/enforcer/frames.tres",190.0) and probe.boss_form and probe.sprite!=null and probe.has_animation("idle"),"set_boss_form swaps in a Boss frames.tres when it exists")
 var tinted=load("res://scripts/combat/fighter.gd").new()
 tinted.load_sprite_set("res://assets/enemies/enforcer/frames.tres",180.0)
 check(not tinted.set_boss_form("res://assets/enemies/soul_realm_boss/frames.tres") and tinted.boss_form and tinted.sprite.modulate.g<0.8,"Without Boss art the Enforcer sprite gets the red Phase 2 tint (art-pending fallback)")
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_battle(true)
 await process_frame
 var battle=main.screen.get_child(0)
 battle.intro=0
 var hero=battle.hero
 # simulate a future Boss resource being dropped in: a distinct SpriteFrames saved at a custom path
 var fake=load("res://assets/enemies/enforcer/frames.tres").duplicate()
 check(ResourceSaver.save(fake,"user://fake_boss_frames.tres")==OK,"Test Boss frames resource written")
 battle.boss_frames_path="user://fake_boss_frames.tres"
 battle.foe.receive(100000)
 await create_timer(0.4).timeout
 battle.intro=0
 var boss=battle.foe
 check(battle.wave==1 and boss.look=="warped" and battle.phase==1 and not boss.boss_form,"Enforcer is on the field in its first form")
 var h1=displayed_height(boss)
 hero.position=Vector2(300,450)
 boss.position=Vector2(700,450)
 var pos=boss.position
 var count=fighters(battle.arena)
 boss.health=boss.max_health*0.45
 var hp_before=boss.health
 await process_frame
 await process_frame
 check(battle.phase==2 and boss.attack==36 and battle.telegraph_len<0.7 and battle.recovery<0.7 and boss.aura,"Phase 2 triggers at 50% with stronger attack and faster, more aggressive telegraphs")
 check(battle.transform_count==1 and Engine.time_scale<1.0,"Transformation fired once and combat is slowed")
 check(boss.position.distance_to(pos)<5.0 and boss.facing==-1,"Position and facing do not jump at the trigger")
 check(boss.phase2_vfx_active() and boss.aura_color==Color("ff4f72"),"Phase 2 VFX state activates (red aura, core/halo charging)")
 check(battle.foe==boss and boss.health==hp_before and boss.max_health==820,"Transformation keeps the same foe and does not reset health")
 check(fighters(battle.arena)<=count and battle.wave==1 and battle.waves.size()==2,"No additional enemy and no third wave")
 await create_timer(0.2).timeout
 check(battle.dim_rect.color.a>0.2,"The screen darkens at the start of the transformation")
 check(boss.form_t>0.0,"Core and halo charge up during the transformation")
 var before=boss.health
 boss.receive(50)
 check(boss.health<before,"The foe stays hittable mid-transformation (combat rules unchanged)")
 hp_before=boss.health
 await create_timer(1.1).timeout
 check(boss.boss_form and boss.form_t>=0.99,"The Phase 2 reveal switches to the Soul Realm Boss form")
 check(boss.position.distance_to(pos)<400.0 and boss.health==hp_before,"Position and health are preserved through the reveal")
 var h2=displayed_height(boss)
 var hero_h=displayed_height(hero)
 print("INFO: heights  hero=%.1f  enforcer=%.1f  boss=%.1f  boss/hero=%.3f  boss/enforcer=%.3f" % [hero_h,h1,h2,h2/hero_h,h2/h1])
 check(h2>h1*1.05 and h2/hero_h<=1.65 and h2<260.0,"Boss form is larger than the Enforcer but still fits the arena")
 check(battle.dim_rect.color.a<0.05 and Engine.time_scale==1.0,"Darkening clears and normal speed returns (control back quickly)")
 check(boss.sprite.sprite_frames.resource_path=="user://fake_boss_frames.tres","A Boss frames.tres at the hook path replaces the Enforcer art automatically")
 check(boss.burst_t<=0.01 and boss.form_t>=0.99 and boss.aura and boss.phase2_vfx_active(),"Phase 2 VFX stays active after the burst fades")
 # once only: heal back above 50% then cross again
 boss.health=boss.max_health*0.8
 await process_frame
 boss.health=boss.max_health*0.3
 await process_frame
 await process_frame
 check(battle.transform_count==1 and battle.phase==2 and Engine.time_scale==1.0,"Transformation never fires a second time")
 battle.transform_foe()
 check(battle.transform_count==1 and battle.transform_clock<0.0,"Direct re-trigger is a no-op")
 hp_before=boss.health
 check(battle.wave==1 and battle.waves.size()==2 and fighters(battle.arena)==2,"Still two waves: exactly the Hero and one foe on the field")
 # combat resumes
 hero.invincible=0
 hero.position=Vector2(500,450)
 boss.position=Vector2(580,450)
 var hh=hero.health
 battle.telegraph=0.05
 battle.target=hero.position
 await create_timer(0.35).timeout
 check(hero.health<hh,"The boss still attacks the Hero after the transformation")
 boss.invincible=0
 battle.cooldowns.attack=0
 var b2=boss.health
 battle.act("attack")
 await process_frame
 await process_frame
 check(boss.health<b2,"The Hero can damage the boss after the transformation")
 # AI resumes: it starts a new telegraph on its own
 boss.invincible=0
 hero.position=Vector2(450,450)
 boss.position=Vector2(560,450)
 battle.enemy_wait=0.0
 var saw_tele=false
 var tt=0.0
 while tt<2.0:
  await process_frame
  tt+=0.016
  if battle.telegraph>0.0: saw_tele=true
 check(saw_tele,"Enemy AI resumes and telegraphs attacks after the transformation")
 # defeat -> finisher
 hero.health=hero.max_health
 var done={"won":null}
 battle.finished.connect(func(w): done.won=w)
 boss.receive(100000)
 await process_frame
 check(boss.dead and battle.ended,"Defeating the Phase 2 boss ends the battle")
 await create_timer(2.2).timeout
 check(done.won==true,"The cinematic finisher completes and reports a win")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
