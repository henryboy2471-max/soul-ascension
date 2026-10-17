extends SceneTree
# Exploration movement smoothness, simulated frame by frame at 60 fps, 30 fps and a ragged 30/20 fps mix, in an Episode 1 scene (no companion) and an Episode 3 scene (companion Mira):
# the companion glides instead of swooping, slow walkers move a steady amount every frame, the camera settles quickly, idle characters hold still, the walk cycle follows the real pace,
# and one long hitch cannot teleport the hero.
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
 create_timer(120.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func make(ep3:bool):
 var ex=load("res://scripts/world/explore.gd").new()
 if ep3:
  ex.config=load("res://scripts/world/zone_defs.gd").explore_config("market",load("res://scripts/world/relay_art.gd"))
 root.add_child(ex)
 return ex
func tick(ex, dt:float) -> void:
 ex._process(dt)
 ex.player._process(dt)
 ex.npc._process(dt)
func gait_of(f) -> float:
 var g=f.get("gait")
 return float(g) if g!=null else -1.0
func dts(kind:String, n:int) -> Array:
 var out=[]
 for i in range(n):
  match kind:
   "60": out.append(1.0/60.0)
   "30": out.append(1.0/30.0)
   _: out.append(1.0/30.0 if i%3!=2 else 0.05)
 return out
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 profile.data.settings.music=false
 for ep3 in [false,true]:
  var label="Episode 3" if ep3 else "Episode 1"
  for kind in ["60","30","ragged"]:
   var ex=make(ep3)
   await process_frame
   var tag=label+" @"+kind
   # --- slow walker with a still camera: the same step every frame (the old whole-pixel snapping gave 0,1,1,0,1)
   var w=ex.walkers[0] if ex.walkers.size()>0 else null
   if w!=null:
    w.x=800.0
    w.dir=1
    w.speed=37.0
    var xs=[]
    var seq=dts(kind,40)
    for dt in seq:
     tick(ex,dt)
     xs.append(w.node.position.x)
    # every frame's on-screen step must equal speed*dt (no quantising to whole pixels)
    var worst=0.0
    for i in range(1,xs.size()):
     worst=maxf(worst,absf((xs[i]-xs[i-1])-37.0*seq[i]))
    check(worst<0.01,tag+": a slow walker moves exactly speed*dt on screen every frame (worst error %.2f px)" % worst)
   # --- hero walks right, stops, then idles: camera settles quickly and nothing moves while idle
   ex.stick.direction=Vector2(1,0)
   for dt in dts(kind,int(60*1.0)):
    tick(ex,dt)
   ex.stick.direction=Vector2.ZERO
   var t=0.0
   var last_move_t=0.0
   var prev=ex.player.position.x
   var mira_prev=ex.npc.position.x
   var idle_hero=[]
   for dt in dts(kind,int(60*3.0)):
    tick(ex,dt)
    t+=dt
    if absf(ex.player.position.x-prev)>0.01:
     last_move_t=t
    prev=ex.player.position.x
    if t>1.5:
     idle_hero.append(ex.player.position.x)
   check(last_move_t<0.9,tag+": the hero stops moving on screen within 0.9 s of letting go (moved for %.2f s)" % last_move_t)
   var idle_range=(idle_hero.max()-idle_hero.min()) if idle_hero.size()>0 else 99.0
   check(idle_range<0.01,tag+": an idle hero is perfectly still on screen (range %.3f px)" % idle_range)
   check(not ex.player.moving and ex.player.sprite!=null and ex.player.sprite.animation=="idle","%s: the hero is in the idle animation once stopped" % tag)
   # --- walking pace: a vertical walk is slower, the cycle slows with it
   ex.py=520.0
   ex.stick.direction=Vector2(0,1)
   var walked=0.0
   for dt in dts(kind,40):
    if walked>=0.14:
     break
    tick(ex,dt)
    walked+=dt
   check(absf(gait_of(ex.player)-0.55)<0.1 and absf(ex.player.sprite.speed_scale-gait_of(ex.player))<0.001 and ex.player.sprite.animation=="walk","%s: the walk cycle runs at the pace the feet travel (gait %.2f, speed scale %.2f)" % [tag,gait_of(ex.player),ex.player.sprite.speed_scale])
   ex.stick.direction=Vector2.ZERO
   for dt in dts(kind,60):
    tick(ex,dt)
   check(ex.player.sprite.speed_scale==1.0,tag+": idle plays at normal speed")
   # --- one long hitch cannot teleport the hero
   ex.stick.direction=Vector2(-1,0)
   for dt in dts(kind,30):
    tick(ex,dt)
   var before=ex.px
   tick(ex,0.6)
   check(absf(ex.px-before)<=300.0*0.1+0.5,"%s: a 600 ms hitch moves the hero at most one capped frame (0.1 s) (%.1f px)" % [tag,absf(ex.px-before)])
   ex.stick.direction=Vector2.ZERO
   # --- companion (Episode 3): reversing direction makes Mira glide, never swoop
   if ep3 and kind!="ragged":
    var ex2=make(true)
    await process_frame
    ex2.stick.direction=Vector2(1,0)
    for dt in dts(kind,int(120)):
     tick(ex2,dt)
    ex2.stick.direction=Vector2(-1,0)
    var maxv=0.0
    var prev_npc=ex2.npc_x
    var dtv=1.0/60.0 if kind=="60" else 1.0/30.0
    for i in range(int(1.2/dtv)):
     tick(ex2,dtv)
     maxv=maxf(maxv,absf(ex2.npc_x-prev_npc)/dtv)
     prev_npc=ex2.npc_x
    check(maxv<=345.0+1.0,tag+": Mira's fastest move after a reversal is %.0f px/s (hero walks 300)" % maxv)
    ex2.queue_free()
   ex.queue_free()
   await process_frame
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
