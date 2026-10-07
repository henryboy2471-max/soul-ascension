extends SceneTree
# Resonance Shade sprite art (assets/enemies/resonance_shade): frames, first-wave encounter, scale vs the Hero, boss handoff.
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
 check(probe.load_sprite_set("res://assets/enemies/resonance_shade/frames.tres"),"Resonance Shade frames.tres loads")
 var frames=probe.sprite_frames
 check(frames.get_frame_count("idle")==8 and frames.get_frame_count("walk")==5,"Imported animations have the expected frame counts")
 var leaked=false
 for flagged in ["run","dash","hurt","defeat","attack1","attack2","attack3","skill","finisher","jump","land"]:
  if frames.has_animation(flagged) and frames.get_frame_count(flagged)>0:
   leaked=true
 check(not leaked,"Flagged animations are not exported (flagged, not invented)")
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/resonance_shade/manifest.json"))
 var ground=int(manifest.ground_row)
 var size=frames.get_frame_texture("idle",0).get_size()
 var same_size=true
 var anchored=true
 for anim in ["idle","walk"]:
  for i in range(frames.get_frame_count(anim)):
   var tex=frames.get_frame_texture(anim,i)
   if tex.get_size()!=size: same_size=false
   if absi(solid_extent(tex).y-ground)>1: anchored=false
 check(same_size,"Every Shade frame shares one canvas size")
 check(anchored,"All idle and walk frames stand on the same ground row (no foot jitter)")
 check(probe.resolve_animation("run")=="walk" and probe.resolve_animation("attack1")=="idle" and probe.resolve_animation("hurt")=="idle" and probe.resolve_animation("defeat")=="idle","Missing animations fall back to walk/idle")
 # --- first Soul Realm wave ---
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
 check(battle.wave==0 and shade.look=="shade" and shade.sprite!=null,"First wave Resonance Shade uses the sprite art")
 # scale vs the Hero
 var hero_h=displayed_height(hero)
 var shade_h=displayed_height(shade)
 var ratio=shade_h/hero_h
 print("INFO: displayed standing height in battle  hero=%.1f px  shade=%.1f px  ratio=%.3f" % [hero_h,shade_h,ratio])
 check(ratio>=1.0 and ratio<=1.2,"Shade stands 0-20% taller than the Hero (threatening, not oversized)")
 check(absf(shade_h-hero_h)<=35.0,"Shade is within 35 px of the Hero's height")
 # walking toward the hero
 hero.position=Vector2(250,450)
 shade.position=Vector2(900,450)
 battle.enemy_wait=0.0
 var saw_walk=false
 var t=0.0
 while t<1.5:
  await process_frame
  t+=0.016
  if shade.moving and shade.current_anim=="walk":
   saw_walk=true
 await create_timer(0.4).timeout
 check(saw_walk,"The Shade plays its walk animation while chasing the Hero")
 check(shade.position.x<900.0,"The Shade closes the distance")
 # hit reaction
 hero.position=Vector2(500,450)
 shade.position=Vector2(580,450)
 battle.cooldowns.attack=0
 battle.act("attack")
 await process_frame
 await process_frame
 check(shade.health<shade.max_health and shade.flash>0.0 and shade.sprite.self_modulate.r>1.0,"Hitting the Shade damages it and flashes the sprite")
 # its attack: telegraph, then damage to the Hero
 hero.invincible=0
 hero.position=Vector2(500,450)
 shade.position=Vector2(580,450)
 var before=hero.health
 battle.telegraph=0.05
 battle.target=hero.position
 await create_timer(0.35).timeout
 check(hero.health<before and shade.current_anim in ["idle","walk"],"The Shade's attack still damages the Hero (code-drawn VFX, idle fallback)")
 # defeat and handoff to the boss
 hero.health=hero.max_health
 shade.invincible=0
 shade.receive(100000)
 await process_frame
 check(shade.dead and battle.wave==1,"Defeating the Shade advances to the boss wave")
 await create_timer(0.8).timeout
 check(not is_instance_valid(shade) or shade.is_queued_for_deletion() or shade.modulate.a<=0.05,"The defeated Shade dissolves away")
 check(battle.foe.look=="warped" and battle.foe.max_health==820 and not battle.ended,"The Soul-Warped Enforcer takes over with full health")
 check(is_instance_valid(battle.foe) and battle.hero.health>=battle.hero.max_health-1.0,"Hero is healed by the wave transition")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
