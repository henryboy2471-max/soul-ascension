extends SceneTree
# Measures exploration movement the same way on any commit (duck-typed, no new APIs needed): steady speed, time to cover a distance, ease-in/out, pedestrians, the companion,
# the walk animation's pace, the camera, and frame-rate independence, in an Episode 1 scene (no companion) and an Episode 3 market scene (companion Mira).
# usage: godot --headless --path . --script res://tools/qa/measure_walk_speed.gd      (prints "KEY = value" lines)
func _initialize() -> void:
 call_deferred("run")
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
func say(k:String, v) -> void:
 print("%s = %s" % [k,str(v)])
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 profile.data.settings.music=false
 for ep3 in [false,true]:
  var tag="ep3" if ep3 else "ep1"
  # ---- frame-rate independence + steady speed + time to travel 600 px, per frame rate
  for fps in [30,60,144,240]:
   var ex=make(ep3)
   await process_frame
   var dt=1.0/float(fps)
   ex.px=300.0
   ex.py=585.0
   ex.vel=Vector2.ZERO
   ex.stick.direction=Vector2(1,0)
   var t=0.0
   var x0=ex.px
   var t600=-1.0
   var t95=-1.0
   var top=0.0
   var mid_x=0.0
   var mid_t=0.0
   var dist6=0.0
   var end_x=0.0
   var end_t=0.0
   for i in range(int(10.0*fps)):
    tick(ex,dt)
    t+=dt
    if t600<0.0 and ex.px-x0>=600.0:
     t600=t
    if t95<0.0 and ex.vel.x>=0.95*(ex.top_speed() if ex.has_method("top_speed") else 300.0):
     t95=t
    if absf(t-2.0)<dt*0.5:
     mid_x=ex.px
     mid_t=t
    if absf(t-6.0)<dt*0.5:
     dist6=ex.px-x0
    if absf(t-2.5)<dt*0.5:
     end_x=ex.px
     end_t=t
   var steady=(end_x-mid_x)/(end_t-mid_t)
   say("%s fps%d: distance in 6 s from rest (px)" % [tag,fps],snappedf(dist6,0.1))
   say("%s fps%d: steady speed between 2.0 s and 2.5 s (px/s)" % [tag,fps],snappedf(steady,0.1))
   say("%s fps%d: time to cover 600 px from rest (s)" % [tag,fps],snappedf(t600,0.01))
   say("%s fps%d: time to reach 95%% of top speed (s)" % [tag,fps],snappedf(t95,0.01))
   if fps==60:
    ex.px=700.0   # past the first 640 px (the camera is still at 0 there) and far enough from the end of the world that the camera never reaches its clamp
    ex.py=585.0
    ex.vel=Vector2.ZERO
    ex.update_positions(1.0)
    ex.stick.direction=Vector2(1,0)
    for i in range(int(2.0*fps)):
     tick(ex,dt)
    # animation pace while walking at steady speed
    var sp=ex.player.sprite
    var g=ex.player.get("gait")
    var anim_fps=sp.sprite_frames.get_animation_speed("walk")*sp.speed_scale
    var frames=sp.sprite_frames.get_frame_count("walk")
    say("%s: hero walk animation: playback speed scale" % tag,snappedf(sp.speed_scale,0.001))
    say("%s: hero walk animation: frames per second" % tag,snappedf(anim_fps,0.01))
    say("%s: hero walk animation: seconds per cycle (%d frames)" % [tag,frames],snappedf(float(frames)/anim_fps,0.01))
    say("%s: ground covered per walk cycle (px; the cycle was authored for 240)" % tag,snappedf(steady*float(frames)/anim_fps,0.1))
    say("%s: gait value" % tag,"none (fixed 1.0)" if g==null else snappedf(float(g),0.001))
    # camera while walking steadily
    var cam_a=ex.cam
    var px_a=ex.px
    for i in range(60):
     tick(ex,dt)
    say("%s: camera speed at steady walk (px/s)" % tag,snappedf(ex.cam-cam_a,0.1))
    say("%s: camera lag behind the hero (hero x - camera - 640, px)" % tag,snappedf(ex.px-ex.cam-640.0,0.1))
    # release: stopping distance and time
    ex.stick.direction=Vector2.ZERO
    var sx=ex.px
    var ts=0.0
    var stop_t=-1.0
    for i in range(int(2.0*fps)):
     tick(ex,dt)
     ts+=dt
     if stop_t<0.0 and ex.vel.length()<0.01:
      stop_t=ts
    say("%s: time from release to full stop (s)" % tag,snappedf(stop_t,0.01))
    say("%s: distance covered after release (px)" % tag,snappedf(ex.px-sx,0.1))
    # camera settles
    var settle=0.0
    var last_cam=ex.cam
    var tt=0.0
    for i in range(int(2.0*fps)):
     tick(ex,dt)
     tt+=dt
     if absf(ex.cam-last_cam)>0.01:
      settle=tt
     last_cam=ex.cam
    say("%s: camera still moving this long after the hero stopped (s)" % tag,snappedf(stop_t+settle,0.01))
    # vertical walking speed
    ex.py=515.0
    ex.vel=Vector2.ZERO
    ex.stick.direction=Vector2(0,1)
    var vmax=0.0
    for i in range(int(1.2*fps)):
     tick(ex,dt)
     vmax=maxf(vmax,ex.vel.y)
    say("%s: vertical (down the street) top speed (px/s)" % tag,snappedf(vmax,0.1))
    # pedestrians
    var sps=[]
    for w in ex.walkers:
     if float(w.speed)>0.0:
      sps.append(float(w.speed))
    if sps.size()>0:
     say("%s: ambient pedestrian speeds, slowest / fastest (px/s)" % tag,"%.1f / %.1f" % [sps.min(),sps.max()])
    # companion: steady follow speed and fastest speed after the hero turns around
    if ep3:
     ex.py=585.0
     ex.stick.direction=Vector2(1,0)
     for i in range(int(3.0*fps)):
      tick(ex,dt)
     var n0=ex.npc_x
     for i in range(fps):
      tick(ex,dt)
     say("ep3: Mira's steady follow speed (px/s)",snappedf(ex.npc_x-n0,0.1))
     ex.stick.direction=Vector2(-1,0)
     var peak=0.0
     var prev=ex.npc_x
     for i in range(int(2.0*fps)):
      tick(ex,dt)
      peak=maxf(peak,absf(ex.npc_x-prev)/dt)
      prev=ex.npc_x
     say("ep3: Mira's fastest speed after the hero turns around (px/s)",snappedf(peak,0.1))
     var msp=ex.npc.sprite
     say("ep3: Mira run animation: playback speed scale at top follow speed",snappedf(msp.speed_scale,0.001))
   ex.queue_free()
   await process_frame
 quit(0)
