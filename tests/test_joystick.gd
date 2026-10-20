extends SceneTree
# Virtual stick: a resting thumb (a few px of jitter) gives no movement, travel past the dead zone ramps up smoothly to exactly 1.0 at 60 px, release and focus loss stop at once, a second finger is ignored.
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func touch(index:int, pressed:bool, pos:Vector2):
 var e=InputEventScreenTouch.new()
 e.index=index
 e.pressed=pressed
 e.position=pos
 return e
func drag(index:int, pos:Vector2):
 var e=InputEventScreenDrag.new()
 e.index=index
 e.position=pos
 return e
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var s=VirtualStick.new()
 s.position=Vector2(36,520)
 s.size=Vector2(180,180)
 root.add_child(s)
 await process_frame
 var c=Vector2(126,610)
 s._input(touch(1,true,c))
 check(s.direction==Vector2.ZERO,"a touch on the stick centre gives no direction")
 s._input(drag(1,c+Vector2(5,-3)))
 check(s.direction==Vector2.ZERO,"5 px of thumb jitter gives no direction (dead zone)")
 s._input(drag(1,c+Vector2(7,0)))
 check(s.direction==Vector2.ZERO,"7.2 px (12%) is still inside the dead zone")
 s._input(drag(1,c+Vector2(30,0)))
 check(s.direction.x>0.3 and s.direction.x<0.5 and absf(s.direction.y)<0.001,"30 px ramps up smoothly (%.2f)" % s.direction.x)
 var prev=0.0
 var mono=true
 for px in range(8,61,4):
  s._input(drag(1,c+Vector2(px,0)))
  if s.direction.x<prev-0.0001:
   mono=false
  prev=s.direction.x
 check(mono,"the output grows monotonically with travel")
 s._input(drag(1,c+Vector2(60,0)))
 check(is_equal_approx(s.direction.length(),1.0),"60 px is exactly full speed (%.3f)" % s.direction.length())
 s._input(drag(1,c+Vector2(200,0)))
 check(is_equal_approx(s.direction.length(),1.0),"farther travel stays at 1.0")
 s._input(drag(1,c+Vector2(0,-60)))
 check(s.direction.y<-0.99 and absf(s.direction.x)<0.01,"upwards is a full-speed up vector")
 s._input(touch(2,true,c+Vector2(40,0)))
 s._input(drag(2,c+Vector2(60,0)))
 check(s.direction.y<-0.99,"a second finger is ignored")
 s._input(touch(1,false,c))
 check(s.direction==Vector2.ZERO and s.finger==-1,"release stops at once")
 s._input(touch(1,true,c))
 s._input(drag(1,c+Vector2(50,0)))
 s._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(s.direction==Vector2.ZERO and s.finger==-1,"focus loss stops at once")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
