extends SceneTree
# Soul-Warped Enforcer sprite art (assets/enemies/enforcer): frames, wave-2 spawn, scale vs Hero and Shade, chase, damage, Phase 2, defeat, finisher, ending.
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
func run() -> void:
 profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 var fighter_script=load("res://scripts/combat/fighter.gd")
 var probe=fighter_script.new()
 check(probe.load_sprite_set("res://assets/enemies/enforcer/frames.tres"),"Enforcer frames.tres loads")
 var frames=probe.sprite_frames
 check(frames.get_frame_count("idle")==8 and frames.get_frame_count("walk")==4 and frames.get_frame_count("run")==6,"Imported animations have the expected frame counts")
 var leaked=false
 for flagged in ["dash","hurt","defeat","attack1","attack2","attack3","skill","finisher","jump","land"]:
  if frames.has_animation(flagged) and frames.get_frame_count(flagged)>0:
   leaked=true
 check(not leaked,"Flagged animations are not exported (flagged, not invented)")
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/enforcer/manifest.json"))
 var ground=int(manifest.ground_row)
 var size=frames.get_frame_texture("idle",0).get_size()
 var same_size=true
 var anchored=true
 for anim in ["idle","walk","run"]:
  for i in range(frames.get_frame_count(anim)):
   var tex=frames.get_frame_texture(anim,i)
   if tex.get_size()!=size: same_size=false
   if absi(solid_extent(tex).y-ground)>1: anchored=false
 check(same_size,"Every Enforcer frame shares one canvas size")
 check(anchored,"All idle, walk and run frames stand on the same ground row (no foot jitter)")
 check(probe.resolve_animation("run")=="run" and probe.resolve_animation("dash")=="run" and probe.resolve_animation("attack1")=="idle" and probe.resolve_animation("hurt")=="idle" and probe.resolve_animation("defeat")=="idle","Missing animations fall back to walk/idle")

 # --- Shade -> Enforcer handoff ---
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_battle(true)
 await process_frame
 var battle=main.screen.get_child(0)
 battle.intro=0
 var shade=battle.foe
 var hero=battle.hero
 var shade_h=displayed_height(shade)
 check(battle.wave==0 and shade.look=="shade","Wave 1 is still the Resonance Shade")
 shade.receive(100000)
 await create_timer(0.4).timeout
 var boss=battle.foe
 battle.intro=0
 check(battle.wave==1 and boss.look=="warped" and boss.sprite!=null and boss.max_health==820 and not battle.ended,"Shade handoff spawns the Enforcer with sprite art and full health")
 var hero_h=displayed_height(hero)
 var boss_h=displayed_height(boss)
 print("INFO: displayed standing height  hero=%.1f  shade=%.1f  enforcer=%.1f  enforcer/hero=%.3f  enforcer/shade=%.3f" % [hero_h,shade_h,boss_h,boss_h/hero_h,boss_h/shade_h])
 check(boss_h/hero_h>=1.2 and boss_h/hero_h<=1.45,"Enforcer stands 20-45% taller than the Hero")
 check(boss_h>shade_h*1.1 and boss_h<300.0,"Enforcer is larger than the Shade but fits the arena")
 # chase
 hero.position=Vector2(250,450)
 boss.position=Vector2(900,450)
 battle.enemy_wait=0.0
 var saw_walk=false
 var t=0.0
 while t<1.5:
  await process_frame
  t+=0.016
  if boss.moving and boss.current_anim=="walk":
   saw_walk=true
 await create_timer(0.4).timeout
 check(saw_walk and boss.position.x<900.0,"The Enforcer walks toward and closes on the Hero")
 # Hero damages Enforcer
 hero.position=Vector2(500,450)
 boss.position=Vector2(580,450)
 battle.cooldowns.attack=0
 battle.act("attack")
 await process_frame
 await process_frame
 check(boss.health<boss.max_health and boss.flash>0.0 and boss.sprite.self_modulate.r>1.0,"Hero damages the Enforcer and the sprite flashes")
 # Enforcer damages Hero
 hero.invincible=0
 hero.position=Vector2(500,450)
 boss.position=Vector2(580,450)
 var before=hero.health
 battle.telegraph=0.05
 battle.target=hero.position
 await create_timer(0.35).timeout
 check(hero.health<before,"The Enforcer's attack damages the Hero (code-drawn fire VFX)")
 # Phase 2
 boss.health=boss.max_health*0.45
 await process_frame
 await process_frame
 check(battle.phase==2 and boss.attack>28 and battle.telegraph_len<0.8 and boss.aura,"Phase 2 triggers at 50% health with escalation and red aura")
 # defeat -> finisher -> ending
 hero.health=hero.max_health
 boss.invincible=0
 var done={"won":null}
 battle.finished.connect(func(w): done.won=w)
 boss.receive(100000)
 await process_frame
 await process_frame
 check(boss.dead and battle.ended,"Defeating the Enforcer ends the battle")
 await create_timer(0.5).timeout
 check(boss.death_t>0.0 or boss.modulate.a<1.0 or boss.dead,"Defeated Enforcer plays its dissolve (no defeat art)")
 await create_timer(1.6).timeout
 check(done.won==true,"The cinematic finisher completes and the battle reports a win")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
