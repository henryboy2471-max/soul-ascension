extends SceneTree
# Robustness fuzz of the exploration scene (Episode 1 and Episode 3 market): thousands of frames of random input, hitches, locking (conversations), teleports and facing changes with a fixed seed,
# checking invariants every frame: finite positions, the Hero and camera inside the world, a breath scale within 1%, an opaque sprite when no dissolve is running, no lingering dissolve, valid animation.
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
 create_timer(240.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func make(zone:String):
 var ex=load("res://scripts/world/explore.gd").new()
 if zone!="":
  ex.config=load("res://scripts/world/zone_defs.gd").explore_config(zone,load("res://scripts/world/relay_art.gd"))
 root.add_child(ex)
 return ex
var cov={}
func fuzz(ex, seed:int, steps:int) -> String:
 var rng=RandomNumberGenerator.new()
 rng.seed=seed
 var dts=[1.0/144.0,1.0/60.0,1.0/60.0,1.0/30.0,0.05,0.2]
 var dirs=[Vector2.ZERO,Vector2(1,0),Vector2(-1,0),Vector2(0,1),Vector2(0,-1),Vector2(1,1),Vector2(-1,-1),Vector2(0.4,0.2)]
 var dir=Vector2.ZERO
 var blend_age=0.0
 cov={"dissolves":0,"locks":0,"teleports":0,"hitches":0,"walking_frames":0,"idle_frames":0}
 var was_blend=1.0
 for i in range(steps):
  if rng.randf()<0.02:
   dir=dirs[rng.randi()%dirs.size()]
   ex.stick.direction=dir
  if rng.randf()<0.003:
   ex.locked=not ex.locked
   cov.locks+=1
  if rng.randf()<0.0015:
   ex.px=rng.randf_range(100.0,ex.world_w-100.0)   # a checkpoint / resume teleport
   cov.teleports+=1
  if rng.randf()<0.01:
   ex.player.facing=-ex.player.facing
  var dt=dts[rng.randi()%dts.size()]
  if dt>=0.2:
   cov.hitches+=1
  ex._process(dt)
  ex.player._process(dt)
  ex.npc._process(dt)
  var p=ex.player
  var sp=p.sprite
  if was_blend>=1.0 and p.blend_t<1.0:
   cov.dissolves+=1
  was_blend=p.blend_t
  if sp.animation=="walk":
   cov.walking_frames+=1
  else:
   cov.idle_frames+=1
  if is_nan(ex.px) or is_nan(ex.py) or is_nan(ex.cam) or is_nan(ex.vel.x) or is_nan(ex.vel.y) or is_nan(ex.npc_x):
   return "NaN at step %d" % i
  if ex.px<79.9 or ex.px>ex.world_w-79.9 or ex.py<514.9 or ex.py>585.1:
   return "Hero outside the world at step %d (%.1f, %.1f)" % [i,ex.px,ex.py]
  if ex.cam<-0.01 or ex.cam>ex.world_w-1280.0+0.01:
   return "camera outside the world at step %d (%.1f)" % [i,ex.cam]
  if absf(sp.scale.y/p.base_scale.y-1.0)>0.0105 or absf(sp.scale.x/p.base_scale.x-1.0)>0.0045:
   return "breath scale out of range at step %d" % i
  if sp.modulate.a<-0.001 or sp.modulate.a>1.001:
   return "sprite alpha out of range at step %d" % i
  if p.blend_t>=1.0 and (sp.modulate.a!=1.0 or (p.blend!=null and p.blend.visible)):
   return "dissolve left behind at step %d" % i
  if p.blend_t<1.0:
   blend_age+=dt
   if blend_age>1.0:
    return "dissolve stuck at step %d" % i
  else:
   blend_age=0.0
  if not sp.animation in ["idle","walk"]:
   return "unexpected animation %s at step %d" % [sp.animation,i]
  if ex.npc.sprite!=null and not ex.npc.sprite.animation in ["idle","run"]:
   return "unexpected companion animation %s at step %d" % [ex.npc.sprite.animation,i]
  if ex.npc_x<79.9 or ex.npc_x>ex.world_w-79.9:
   return "companion outside the world at step %d" % i
 return ""
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 profile.data.settings.music=false
 for zone in ["","market","arena"]:
  var ep3=zone!=""
  for seed in [1,2,3,4]:
   var ex=make(zone)
   await process_frame
   var why=fuzz(ex,seed*7919+zone.length(),12000)
   check(cov.dissolves>=40 and cov.locks>=15 and cov.teleports>=5 and cov.hitches>=500 and cov.walking_frames>1000 and cov.idle_frames>1000,"%s, seed %d: the fuzz really exercised it %s" % [("Warden chamber" if zone=="arena" else "Episode 3") if ep3 else "Episode 1",seed,str(cov)])
   check(why=="","%s, seed %d: 12000 random frames keep every invariant%s" % [("Warden chamber" if zone=="arena" else "Episode 3") if ep3 else "Episode 1",seed,"" if why=="" else " ("+why+")"])
   ex.queue_free()
   await process_frame
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
