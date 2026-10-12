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
 ex.py=585.0   # front lane: these motion checks walk past Mira's x (she is solid on her own lane, see the NPC checks below)
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
 # NPC collision: the Hero cannot walk through Mira along her depth lane, can pass in front of her, and can walk out if placed inside
 ex.vel=Vector2.ZERO
 ex.px=ex.npc_x-120.0
 ex.py=548.0
 var entered=false
 var held_back=false
 for i in range(120):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
  entered=entered or ex.blocked(ex.px,ex.py)
  held_back=held_back or (ex.px>ex.npc_x-ex.NPC_HALF_W-4.0 and ex.px<=ex.npc_x-ex.NPC_HALF_W+0.01)
 check(not entered and held_back,"NPC is solid: the Hero reaches her edge and never enters her footprint")
 for i in range(120):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.px>ex.npc_x+ex.NPC_HALF_W,"Holding right against the NPC eases the Hero around her without a vertical key (px %.0f, py %.0f)" % [ex.px,ex.py])
 ex.vel=Vector2.ZERO
 ex.px=ex.npc_x-120.0
 ex.py=585.0
 for i in range(120):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.px>ex.npc_x+ex.NPC_HALF_W,"Hero can walk past the NPC in the front lane (px %.0f)" % ex.px)
 ex.vel=Vector2.ZERO
 ex.px=ex.npc_x+5.0
 ex.py=548.0
 for i in range(60):
  ex.advance_motion(Vector2(1,0),1.0/60.0)
 check(ex.px>ex.npc_x+ex.NPC_HALF_W,"Hero placed inside the NPC footprint can still walk out (px %.0f)" % ex.px)
 ex.px=ex.npc_x-100.0
 ex.py=585.0
 ex.enabled.mira=true
 ex.player.facing=-1
 ex.act_edge=true
 ex.act_block=0.0
 ex.locked=false
 await process_frame
 await process_frame
 check(ex.player.facing==1,"Hero turns toward the NPC when starting a conversation")
 # camera: rendered positions are whole pixels, never reverse while walking one way, and respect both world boundaries (variable frame times)
 ex.locked=false
 ex.px=300.0
 ex.py=585.0
 ex.vel=Vector2.ZERO
 ex.lead=0.0
 ex.update_positions(1.0)
 var dts=[1.0/30.0,1.0/144.0,1.0/60.0,1.0/90.0,1.0/60.0]
 var last_x=ex.layers[4].position.x
 var whole=true
 var reversals=0
 for i in range(400):
  var dt=dts[i%dts.size()]
  ex.advance_motion(Vector2(1,0),dt)
  ex.update_positions(1.0-exp(-dt*9.0))
  var lx=ex.layers[4].position.x
  whole=whole and lx==roundf(lx) and ex.props.position.x==roundf(ex.props.position.x) and ex.player.position.x==roundf(ex.player.position.x)
  if lx>last_x+0.01:
   reversals+=1
  last_x=lx
 check(whole,"Camera/parallax/sprite positions are whole pixels (no shimmer)")
 check(reversals==0,"Camera never reverses or stutters back while walking one way (variable frame times)")
 check(ex.cam>=0.0 and ex.cam<=ex.world_w-1280.0,"Camera stays inside the world boundaries at the far end (cam %.0f)" % ex.cam)
 ex.px=80.0
 for i in range(120):
  ex.advance_motion(Vector2(-1,0),1.0/60.0)
  ex.update_positions(1.0-exp(-9.0/60.0))
 check(ex.cam>=0.0 and ex.layers[4].position.x<=0.0,"Camera stops at the start boundary (cam %.1f)" % ex.cam)
 check(ex.temp_art_label!=null and "TEMPORARY" in ex.temp_art_label.text,"Temporary-art notice is shown in Explore")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
