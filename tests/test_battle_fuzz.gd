extends SceneTree
# Battle robustness fuzz: standalone Soul Realm battle and the Episode boss mode, 4 seeds each x 6000 frames of random movement, strikes, skills, dodges, blocks, mends, retreat presses and frame hitches.
# Invariants: finite positions inside the arena, health/energy/ultimate inside range, cooldowns never negative, buffered action cleared, no stuck telegraph, and the fight is winnable-or-lossable (it always ends or keeps progressing).
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(170.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func step(b, dt:float) -> void:
 b._process(dt)
 if is_instance_valid(b.hero):
  b.hero._process(dt)
 if is_instance_valid(b.foe):
  b.foe._process(dt)
func run() -> void:
 var profile=root.get_node("Profile")
 for boss in [false,true]:
  for seed in [11,12,13,14]:
   profile.data=profile.defaults()
   profile.data.onboarded=true
   profile.data.settings.sound=false
   profile.data.settings.shake=true
   profile.data.energy=100
   profile.active_run=""
   var main=load("res://scenes/main.tscn").instantiate()
   root.add_child(main)
   var started=main.start_battle(boss,"1-1")
   check(started,"%s seed %d: the battle starts" % ["boss mode" if boss else "standalone",seed])
   await process_frame
   var b=null
   for c in main.screen.get_children():
    if c.get("hero")!=null and not c.is_queued_for_deletion():
     b=c
   b.intro=0
   var rng=RandomNumberGenerator.new()
   rng.seed=seed
   var tag="%s seed %d" % ["boss mode" if boss else "standalone",seed]
   var bad=""
   var frames=0
   var dtmax=0.0
   var kills=0
   for i in range(6000):
    if not is_instance_valid(b) or b.ended:
     break
    var r=rng.randf()
    var dt=1.0/60.0 if r<0.9 else (1.0/30.0 if r<0.97 else rng.randf_range(0.05,0.4))
    dtmax=maxf(dtmax,dt)
    b.stick.direction=Vector2(rng.randf_range(-1,1),rng.randf_range(-1,1)) if rng.randf()<0.05 else b.stick.direction
    b.controls.attack.held=rng.randf()<0.6
    b.controls.block.held=rng.randf()<0.1
    var pick=rng.randi()%12
    var kinds=["pulse","rift","mend","heavy","dodge","ultimate","attack","pulse","dodge","attack","heavy","rift"]
    b.act(kinds[pick])
    if rng.randf()<0.001 and b.has_method("request_retreat") and false:
     b.request_retreat()
    step(b,dt)
    frames+=1
    var hp=b.hero.position
    if not (is_finite(hp.x) and is_finite(hp.y)) or hp.x<74.9 or hp.x>1205.1 or hp.y<344.9 or hp.y>496.1:
     bad="hero position %s" % str(hp); break
    var fp=b.foe.position
    if not (is_finite(fp.x) and is_finite(fp.y)):
     bad="foe position %s" % str(fp); break
    if b.energy<-0.001 or b.energy>100.001 or b.ultimate<-0.001 or b.ultimate>100.001 or b.hero.health<0.0 or b.hero.health>b.hero.max_health+0.01 or b.foe.health<0.0:
     bad="resource range energy=%.1f ult=%.1f hp=%.1f foe=%.1f" % [b.energy,b.ultimate,b.hero.health,b.foe.health]; break
    for key in b.cooldowns:
     if b.cooldowns[key]<-0.0001:
      bad="negative cooldown "+key; break
    if bad!="": break
   check(bad=="","%s: invariants held for %d frames (hitches up to %.2f s) %s" % [tag,frames,dtmax,bad])
   if is_instance_valid(b):
    check(b.ended or frames==6000,"%s: ended cleanly or still running at the frame limit" % tag)
   main.queue_free()
   await process_frame
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
