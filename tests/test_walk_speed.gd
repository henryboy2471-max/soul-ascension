extends SceneTree
# Exploration walking pace: 30% of the original 300 px/s (90 px/s), the same at every frame rate, eased in and out, with the walk cycle, the companion, the pedestrians and the camera
# following the same pace, and the Warden chamber (whose dodge timing is built for full speed) left at 300 px/s. Episode 1 and Episode 3 scenes, simulated frame by frame.
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
 create_timer(180.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func make(ep3:bool, zone:String="market"):
 var ex=load("res://scripts/world/explore.gd").new()
 if ep3:
  ex.config=load("res://scripts/world/zone_defs.gd").explore_config(zone,load("res://scripts/world/relay_art.gd"))
 root.add_child(ex)
 return ex
func tick(ex, dt:float) -> void:
 ex._process(dt)
 ex.player._process(dt)
 ex.npc._process(dt)
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 profile.data.settings.music=false
 for ep3 in [false,true]:
  var label="Episode 3" if ep3 else "Episode 1"
  var dists=[]
  for fps in [30,60,144,240]:
   var ex=make(ep3)
   await process_frame
   var dt=1.0/float(fps)
   ex.px=300.0
   ex.py=585.0
   ex.vel=Vector2.ZERO
   ex.stick.direction=Vector2(1,0)
   var t=0.0
   var t95=-1.0
   var x0=ex.px
   var x2=0.0
   var x3=0.0
   for i in range(int(6.0*fps)):
    tick(ex,dt)
    t+=dt
    if t95<0.0 and ex.vel.x>=0.95*90.0:
     t95=t
    if absf(t-2.0)<dt*0.5:
     x2=ex.px
    if absf(t-3.0)<dt*0.5:
     x3=ex.px
   dists.append(ex.px-x0)
   if fps==60:
    check(is_equal_approx(ex.top_speed(),90.0) and is_equal_approx(ex.walk_scale,0.3),"%s: top walking speed is 90 px/s, 30%% of the original 300" % label)
    check(absf((x3-x2)-90.0)<0.5,"%s: steady speed is 90 px/s (%.2f)" % [label,x3-x2])
    check(t95>0.22 and t95<0.4,"%s: ease-in takes %.2f s (no instant launch)" % [label,t95])
    # the walk cycle follows the ground speed: 8 frames at 10 fps plant the feet at 170 px/s (one cycle = ~136 px of ground), so 90 px/s plays at 5.3 fps
    var sp=ex.player.sprite
    var fps_eff=sp.sprite_frames.get_animation_speed("walk")*sp.speed_scale
    var ground_per_cycle=90.0*float(sp.sprite_frames.get_frame_count("walk"))/fps_eff
    check(absf(fps_eff-5.3)<0.15 and absf(ground_per_cycle-136.0)<4.0,"%s: walk animation plays at %.1f fps, covering %.0f px of ground per cycle (foot spacing in the art: ~136): feet match the ground" % [label,fps_eff,ground_per_cycle])
    # the camera follows at the hero's pace (mid-world, away from both clamps)
    var ex2=make(ep3)
    await process_frame
    ex2.px=700.0
    ex2.py=585.0
    ex2.vel=Vector2.ZERO
    ex2.update_positions(1.0)
    ex2.stick.direction=Vector2(1,0)
    for i in range(120):
     tick(ex2,dt)
    var cam_a=ex2.cam
    for i in range(60):
     tick(ex2,dt)
    check(absf((ex2.cam-cam_a)-90.0)<1.0,"%s: the camera follows at the hero's 90 px/s (%.1f)" % [label,ex2.cam-cam_a])
    # release: eases out instead of stopping dead, and the camera settles with it
    ex2.stick.direction=Vector2.ZERO
    var ts=0.0
    var stop_t=-1.0
    var sx=ex2.px
    for i in range(120):
     tick(ex2,dt)
     ts+=dt
     if stop_t<0.0 and ex2.vel.length()<0.01:
      stop_t=ts
    check(stop_t>0.2 and stop_t<0.35 and ex2.px-sx<14.0,"%s: eases to a stop in %.2f s over %.1f px" % [label,stop_t,ex2.px-sx])
    # vertical walking is 55% of the horizontal pace
    ex2.py=515.0
    ex2.vel=Vector2.ZERO
    ex2.stick.direction=Vector2(0,1)
    var vmax=0.0
    for i in range(72):
     tick(ex2,dt)
     vmax=maxf(vmax,ex2.vel.y)
    check(absf(vmax-49.5)<0.5,"%s: walking down the street is 49.5 px/s (%.1f)" % [label,vmax])
    # pedestrians: the original 35-70 px/s range, at 30%
    var sps=[]
    for w in ex.walkers:
     if float(w.speed)>0.0:
      sps.append(float(w.speed))
    if sps.size()>0:
     check(sps.min()>=10.4 and sps.max()<=21.1,"%s: pedestrians walk %.1f-%.1f px/s (30%% of 35-70)" % [label,sps.min(),sps.max()])
     check(absf(ex.walkers[0].node.gait-float(ex.walkers[0].speed)/55.0)<0.01 or ex.walkers[0].node.gait==0.15,"%s: pedestrian leg swing follows pedestrian pace" % label)
    ex2.queue_free()
    # companion
    if ep3:
     var ex3=make(true)
     await process_frame
     ex3.px=700.0
     ex3.npc_x=610.0   # already trailing the hero (otherwise she is still catching up at her speed cap)
     ex3.py=585.0
     ex3.stick.direction=Vector2(1,0)
     for i in range(240):
      tick(ex3,dt)
     var n0=ex3.npc_x
     for i in range(60):
      tick(ex3,dt)
     check(absf((ex3.npc_x-n0)-90.0)<1.5,"Episode 3: Mira follows at the hero's 90 px/s (%.1f)" % (ex3.npc_x-n0))
     ex3.stick.direction=Vector2(-1,0)
     var peak=0.0
     var prev=ex3.npc_x
     for i in range(120):
      tick(ex3,dt)
      peak=maxf(peak,absf(ex3.npc_x-prev)/dt)
      prev=ex3.npc_x
     check(peak<=90.0*1.15+0.5,"Episode 3: Mira never exceeds %.0f px/s even when the hero turns around (%.1f)" % [90.0*1.15,peak])
     check(ex3.npc.sprite.speed_scale<=0.6,"Episode 3: Mira's run animation is slowed to her pace (x%.2f)" % ex3.npc.sprite.speed_scale)
     ex3.queue_free()
   ex.queue_free()
   await process_frame
  var lo=dists.min()
  var hi=dists.max()
  check((hi-lo)/hi<0.01,"%s: the same ground is covered in 6 s at 30, 60, 144 and 240 fps (%.1f to %.1f px): no faster on high-refresh screens" % [label,lo,hi])
 # ---- the Warden chamber keeps the original full speed and quick response (its telegraphs are timed for it)
 var arena=make(true,"arena")
 await process_frame
 arena.px=300.0
 arena.py=585.0
 arena.vel=Vector2.ZERO
 arena.stick.direction=Vector2(1,0)
 var t95=-1.0
 var t=0.0
 for i in range(120):
  tick(arena,1.0/60.0)
  t+=1.0/60.0
  if t95<0.0 and arena.vel.x>=285.0:
   t95=t
 check(is_equal_approx(arena.top_speed(),300.0) and is_equal_approx(arena.vel.x,300.0) and t95<0.2,"Warden chamber: walking stays 300 px/s with the original quick response (95%% in %.2f s)" % t95)
 check(is_equal_approx(load("res://scripts/story/warden_logic.gd").SPEED,300.0),"Warden dodge timing still assumes 300 px/s")
 arena.queue_free()
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
