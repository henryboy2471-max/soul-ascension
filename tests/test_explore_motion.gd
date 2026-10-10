extends SceneTree
# Focused test for eased exploration movement and the camera look-ahead (no scene flow needed).
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
 create_timer(60.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var ex=load("res://scripts/world/explore.gd").new()
 root.add_child(ex)
 await process_frame
 ex.locked=false
 ex.px=500.0
 ex.vel=Vector2.ZERO
 # ramp-up: not an instant snap, but at full speed within ~0.15 s
 ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.vel.x>0.0 and ex.vel.x<ex.SPEED*0.5,"First frame of walking is eased in (%.0f px/s)" % ex.vel.x)
 for i in range(9):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(is_equal_approx(ex.vel.x,ex.SPEED),"Full walking speed is reached within 10 frames at 60 fps")
 var x_run=ex.px
 # camera leads in the facing direction, never beyond the lookahead
 for i in range(120):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.lead>ex.LOOK_AHEAD*0.8 and ex.lead<=ex.LOOK_AHEAD+0.01,"Camera look-ahead builds toward %.0f px while walking (now %.1f)" % [ex.LOOK_AHEAD,ex.lead])
 # stop: decelerates within ~0.1 s and covers only a few pixels
 var before=ex.px
 for i in range(8):
  ex.advance_motion(Vector2.ZERO,1.0/60.0)
 check(ex.vel.length()<0.01 and ex.px-before<14.0,"Stops within ~8 frames and slides less than 14 px (%.1f)" % (ex.px-before))
 # distance covered in 1 s of walking is close to the old instant-speed model (within 10 percent)
 ex.px=500.0
 ex.vel=Vector2.ZERO
 for i in range(60):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.px-500.0>ex.SPEED*0.9 and ex.px-500.0<=ex.SPEED+0.5,"One second of walking covers 90-100 percent of the old distance (%.0f px)" % (ex.px-500.0))
 # world bounds and the locked gate still stop the player (no velocity carried into walls)
 ex.px=ex.world_w-100.0
 for i in range(60):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.px<=ex.world_w-80.0+0.01 and ex.vel.x==0.0,"World edge clamps position and zeroes velocity")
 ex.gate_locked=true
 ex.gate_x=900.0
 ex.px=840.0
 for i in range(60):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.px<=860.01,"A locked gate still blocks the player")
 ex.gate_locked=false
 # conversations freeze movement immediately
 ex.px=500.0
 ex.vel=Vector2(300,0)
 ex.locked=true
 ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.vel==Vector2.ZERO and ex.px==500.0,"Locked (dialogue) state stops movement instantly")
 # vertical depth lane keeps its limits
 ex.locked=false
 ex.py=580.0
 for i in range(60):
  ex.advance_motion(Vector2(0,1),1.0/60.0)
 check(ex.py<=585.0 and ex.py>=515.0,"Depth lane stays inside its band")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
