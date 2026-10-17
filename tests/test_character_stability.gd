extends SceneTree
# Standing characters stay put: 30 seconds of simulated standing in an Episode 1 and an Episode 3 scene (Hero, and Mira in Episode 3), then walk -> stop -> idle, turning around, and a conversation.
# The Hero and Mira hold ONE idle frame with a slight smooth breath (under 1%, anchored at the feet); the aligned idle and walk frames keep the feet under the canvas centre so a stop or a turn does not shift the character.
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
# midpoint of the outer solid leg/boot columns just above the ground shadow (the same anchor tools/align_character_frames.py uses)
func feet_centre(img:Image) -> float:
 var w=img.get_width()
 var h=img.get_height()
 var y1=-1
 for y in range(h-1,-1,-1):
  for x in range(w):
   if img.get_pixel(x,y).a>0.784:
    y1=y
    break
  if y1>=0:
   break
 var lo=w
 var hi=-1
 for x in range(w):
  var n=0
  for y in range(y1-16,y1-2):
   if y>=0 and img.get_pixel(x,y).a>0.784:
    n+=1
  if n>=2:
   lo=mini(lo,x)
   hi=maxi(hi,x)
 return (lo+hi)/2.0
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 profile.data.settings.music=false
 # ---- the aligned frames: feet midpoint within 1 source px of the canvas centre in every idle and walk frame
 var frames=load("res://assets/characters/hero/frames.tres")
 var worst=0.0
 var using_aligned=true
 for anim in ["idle","walk"]:
  for i in range(frames.get_frame_count(anim)):
   var tex=frames.get_frame_texture(anim,i)
   if not tex.resource_path.contains("frames_aligned"):
    using_aligned=false
   var img=Image.load_from_file(ProjectSettings.globalize_path(tex.resource_path))
   worst=maxf(worst,absf(feet_centre(img)-img.get_width()/2.0))
 check(using_aligned,"The Hero's idle and walk frames come from the aligned set (originals untouched)")
 check(worst<=1.0,"Every aligned idle and walk frame has its feet midpoint within 1 px of the canvas centre (worst %.1f px)" % worst)
 for ep3 in [false,true]:
  var label="Episode 3" if ep3 else "Episode 1"
  for kind in ["60","ragged"]:
   var ex=make(ep3)
   await process_frame
   var tag=label+" @"+kind
   var who=[["Hero",ex.player]]
   if ep3:
    who.append(["Mira",ex.npc])
   # ---- 30 s of standing still
   var t=0.0
   var n=0
   var rec={}
   for w in who:
    rec[w[0]]={"x":[],"y":[],"sx":[],"sy":[],"frame":[],"anim":{},"playing":0}
   while t<30.0:
    var dt=1.0/60.0 if kind=="60" or n%3!=2 else 0.05
    if kind=="ragged" and n%3!=2:
     dt=1.0/30.0
    tick(ex,dt)
    t+=dt
    n+=1
    if t>2.0:   # after the one-second ease-in of the breath
     for w in who:
      var f=w[1]
      var r=rec[w[0]]
      r.x.append(f.position.x)
      r.y.append(f.position.y)
      r.sx.append(f.sprite.scale.x)
      r.sy.append(f.sprite.scale.y)
      r.frame.append(f.sprite.frame)
      r.anim[f.sprite.animation]=true
      if f.sprite.is_playing():
       r.playing+=1
   for w in who:
    var r=rec[w[0]]
    var f=w[1]
    var frames_ok=r.frame.min()==0 and r.frame.max()==0 and r.anim.size()==1 and r.anim.has("idle") and r.playing==0
    check(frames_ok,"%s, %s: stands on one idle frame for 30 s (no frame cycling)" % [tag,w[0]])
    check(r.x.max()-r.x.min()<0.001 and r.y.max()-r.y.min()<0.001,"%s, %s: node position does not move for 30 s (range %.4f px)" % [tag,w[0],r.x.max()-r.x.min()])
    var base=f.base_scale.y
    var amp=(r.sy.max()-r.sy.min())/base
    var maxstep=0.0
    var maxjerk=0.0
    for i in range(1,r.sy.size()):
     maxstep=maxf(maxstep,absf(r.sy[i]-r.sy[i-1])/base)
     if i>1:
      maxjerk=maxf(maxjerk,absf(r.sy[i]-2.0*r.sy[i-1]+r.sy[i-2])/base)
    check(amp<=0.0105 and amp>0.004,"%s, %s: the breath is %.2f%% tall (subtle)" % [tag,w[0],amp*100.0])
    check(maxstep<0.0006 and maxjerk<0.0003,"%s, %s: the breath is smooth (largest change per frame %.5f)" % [tag,w[0],maxstep])
    check(absf(f.sprite.offset.y+f.sprite.sprite_frames.get_frame_texture("idle",0).get_height()/2.0)<0.001 and f.sprite.position==Vector2.ZERO,"%s, %s: the breath is anchored at the feet (sprite bottom stays on the ground)" % [tag,w[0]])
   # ---- walk, stop, idle: no pop in position, and the idle pose is reached promptly
   ex.stick.direction=Vector2(1,0)
   var wt=0.0
   while wt<2.0:
    tick(ex,1.0/60.0)
    wt+=1.0/60.0
   check(ex.player.sprite.animation=="walk" and ex.player.sprite.is_playing(),tag+": walking plays the walk cycle")
   ex.stick.direction=Vector2.ZERO
   var st=0.0
   while st<1.0:
    tick(ex,1.0/60.0)
    st+=1.0/60.0
   var px_a=ex.player.position.x
   var py_a=ex.player.position.y
   var scale_a=ex.player.sprite.scale
   var s2=0.0
   while s2<3.0:
    tick(ex,1.0/60.0)
    s2+=1.0/60.0
   check(ex.player.sprite.animation=="idle" and ex.player.sprite.frame==0 and not ex.player.sprite.is_playing(),tag+": after stopping the Hero returns to the steady idle pose")
   check(absf(ex.player.position.x-px_a)<0.001 and absf(ex.player.position.y-py_a)<0.001,tag+": a stopped Hero does not drift on screen (camera has settled)")
   # ---- turning around: the flip mirrors about the feet, so the feet do not move
   ex.stick.direction=Vector2(-1,0)
   var tt=0.0
   while tt<1.5:
    tick(ex,1.0/60.0)
    tt+=1.0/60.0
   ex.stick.direction=Vector2.ZERO
   while tt<3.5:
    tick(ex,1.0/60.0)
    tt+=1.0/60.0
   check(ex.player.sprite.flip_h and ex.player.sprite.animation=="idle" and absf(ex.player.sprite.offset.x)<0.001,tag+": turning flips the sprite about its centre (offset x 0) and the Hero settles on the idle pose")
   # ---- a conversation (locked, the street lifts): the Hero holds the idle pose
   ex.locked=true
   var ct=0.0
   while ct<2.0:
    tick(ex,1.0/60.0)
    ct+=1.0/60.0
   check(ex.player.sprite.animation=="idle" and ex.player.sprite.frame==0 and ex.player.position.x==ex.player.position.x and not ex.player.sprite.is_playing(),tag+": during a conversation the Hero holds the idle pose")
   var lx=ex.player.position.x
   var lt=0.0
   while lt<3.0:
    tick(ex,1.0/60.0)
    lt+=1.0/60.0
   check(absf(ex.player.position.x-lx)<0.001,tag+": during a conversation the Hero does not move sideways")
   ex.queue_free()
   await process_frame
 # ---- dissolves: walk <-> idle and turning fade the new pose in over the old one (exploration only; battle fighters are untouched)
 var dx=make(false)
 await process_frame
 dx.stick.direction=Vector2(1,0)
 var q=0.0
 while q<1.5:
  tick(dx,1.0/60.0)
  q+=1.0/60.0
 check(dx.player.sprite.animation=="walk" and dx.player.sprite.modulate.a==1.0,"Dissolve: a walking Hero is fully opaque")
 dx.stick.direction=Vector2.ZERO
 var saw_blend=false
 var min_alpha=1.0
 q=0.0
 while q<1.0:
  tick(dx,1.0/60.0)
  q+=1.0/60.0
  if dx.player.blend!=null and dx.player.blend.visible:
   saw_blend=true
   min_alpha=minf(min_alpha,dx.player.sprite.modulate.a)
 check(saw_blend and min_alpha<0.5,"Dissolve: stopping fades the idle pose in over the walk pose (lowest alpha %.2f)" % min_alpha)
 check(not dx.player.blend.visible and dx.player.sprite.modulate.a==1.0 and dx.player.sprite.animation=="idle","Dissolve: it finishes within a second and leaves nothing behind")
 dx.stick.direction=Vector2(-1,0)
 q=0.0
 saw_blend=false
 while q<0.3:
  tick(dx,1.0/60.0)
  q+=1.0/60.0
  if dx.player.blend!=null and dx.player.blend.visible and dx.player.blend.flip_h==false:
   saw_blend=true   # the old (right-facing) pose stays underneath while the left-facing one fades in
 check(saw_blend,"Dissolve: turning around keeps the old pose underneath while the new one fades in")
 var fx=Fighter.new()
 fx.load_sprite_set("res://assets/characters/hero/frames.tres",170.0)
 root.add_child(fx)
 await process_frame
 fx.facing=-1
 fx.update_sprite(1.0/60.0)
 fx.facing=1
 fx.update_sprite(1.0/60.0)
 check(fx.blend==null and fx.sprite.modulate.a==1.0,"Dissolve: fighters outside exploration (battle) never dissolve")
 dx.queue_free()
 fx.queue_free()
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
