extends SceneTree
# Sprite layer: animation selection, fallbacks, anchoring, procedural fallback. Uses in-memory test frames only.
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func make_frames(names:Array, w:int=200, h:int=300) -> SpriteFrames:
 var frames=SpriteFrames.new()
 frames.remove_animation("default")
 var hue=0.0
 for anim in names:
  frames.add_animation(anim)
  frames.set_animation_loop(anim,anim in ["idle","walk","run"])
  for i in range(2):
   var img=Image.create(w,h,false,Image.FORMAT_RGBA8)
   img.fill(Color.from_hsv(hue,0.8,0.9))
   frames.add_frame(anim,ImageTexture.create_from_image(img))
  hue+=0.09
 return frames
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var script=load("res://scripts/combat/fighter.gd")
 # Without art the procedural rig stays in place
 var plain=script.new()
 check(not plain.load_sprite_set("res://assets/characters/hero/frames.tres") or plain.sprite!=null,"Missing art keeps the procedural rig (or loads real art if present)")
 var bare=script.new()
 check(not bare.attach_frames(make_frames(["walk"])) and bare.sprite==null,"Frames without an idle animation are rejected")
 var f=script.new()
 var frames=make_frames(["idle","walk","run","dash","attack1","attack2","attack3","skill","hurt","defeat"])
 check(f.attach_frames(frames,170.0),"Sprite frames attach")
 check(is_equal_approx(f.sprite.offset.y,-150.0) and is_equal_approx(f.sprite.scale.x,170.0/300.0),"Feet anchor at the node origin and height is normalized")
 f.update_sprite(0.016)
 check(f.current_anim=="idle","Idle by default")
 f.moving=true
 f.update_sprite(0.016)
 check(f.current_anim=="walk","Moving plays walk")
 f.run_speed_threshold=1.0
 f.update_sprite(0.016)
 check(f.current_anim=="run","Battle movement plays run")
 f.trailing=true
 f.update_sprite(0.016)
 check(f.current_anim=="dash","Dashing plays dash")
 f.trailing=false
 f.moving=false
 var seq=[]
 for i in range(4):
  f.swing=0.3
  f.update_sprite(0.016)
  seq.append(f.current_anim)
  f.swing=0.0
  f.update_sprite(0.016)
 check(seq==["attack1","attack2","attack3","attack1"],"Combo cycles attack1, attack2, attack3 and wraps")
 f.casting=0.4
 f.update_sprite(0.016)
 check(f.current_anim=="skill","Casting plays skill")
 f.casting=0.0
 f.flash=0.1
 f.update_sprite(0.016)
 check(f.current_anim=="hurt" and f.sprite.self_modulate.r>1.0,"Taking a hit plays hurt with a flash")
 f.flash=0.0
 f.facing=-1
 f.update_sprite(0.016)
 check(f.sprite.flip_h,"Facing left flips the sprite")
 f.dead=true
 f.update_sprite(0.016)
 check(f.current_anim=="defeat","Defeat plays defeat")
 # Unsupported animations fall back instead of inventing frames
 check(f.resolve_animation("finisher")=="skill","Missing finisher falls back to skill")
 check(f.resolve_animation("jump")=="idle" and f.resolve_animation("land")=="idle","Missing jump/land fall back to idle")
 var small=script.new()
 small.attach_frames(make_frames(["idle","attack1"]))
 check(small.resolve_animation("attack3")=="attack1" and small.resolve_animation("skill")=="attack1" and small.resolve_animation("run")=="idle","Sparse art degrades gracefully")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
