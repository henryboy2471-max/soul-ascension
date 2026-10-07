extends SceneTree
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func key(code:int, down:bool) -> void:
 var e=InputEventKey.new()
 e.physical_keycode=code
 e.keycode=code
 e.pressed=down
 Input.parse_input_event(e)
func _initialize() -> void:
 call_deferred("run")
 create_timer(40.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.start_battle()
 var b=main.screen.get_child(0)
 check(HeroData.stats(1).speed>=320 and b.hero.speed==HeroData.stats(1).speed,"Hero speed raised and applied in battle")
 check(b.intro<=1.0,"Opening input lock is one second or less")
 # Movement is allowed as soon as the short intro ends.
 var waited=0.0
 while b.intro>0 and waited<3.0:
  await process_frame
  waited+=0.016
 check(b.intro<=0,"Intro ends on its own")
 b.set_process(false)
 b.foe.set_process(false)
 b.hero.set_process(false)
 # Keyboard dodge honours WASD instead of always fleeing the enemy.
 b.hero.position=Vector2(600,450)
 b.foe.position=Vector2(900,450)
 b.energy=100
 key(KEY_W,true)
 await process_frame
 b.act("dodge")
 check(b.dash.y<-700 and absf(b.dash.x)<1,"Keyboard dodge follows held direction (W = up)")
 key(KEY_W,false)
 # Dash covers roughly the old teleport distance over a short, visible time.
 b.set_process(true)
 var start=b.hero.position
 for i in range(40):
  await process_frame
 check(start.distance_to(b.hero.position)>100 and b.dash_time<=0,"Dodge is a short dash, not an instant teleport")
 b.set_process(false)
 # Input buffering: a dodge pressed just before cooldown ends is queued, not dropped.
 b.cooldowns.dodge=0.05
 b.act("dodge")
 check(b.buffered=="dodge" and b.buffer_time>0,"Early press during cooldown is buffered")
 # Floating stick: touch anywhere in the left zone steers relative to the touch point.
 var touch=InputEventScreenTouch.new()
 touch.index=3;touch.pressed=true;touch.position=Vector2(400,400)
 b.stick._input(touch)
 var drag=InputEventScreenDrag.new()
 drag.index=3;drag.position=Vector2(460,400)
 b.stick._input(drag)
 check(b.stick.direction.x>0.9 and absf(b.stick.direction.y)<0.01,"Floating stick works outside the fixed circle")
 touch=InputEventScreenTouch.new()
 touch.index=3;touch.pressed=false;touch.position=Vector2(460,400)
 b.stick._input(touch)
 check(b.stick.direction==Vector2.ZERO,"Floating stick resets on release")
 # No battle button can keep keyboard focus (Space would otherwise press it instead of dodging).
 var focusable=0
 for child in b.get_children():
  if child is Button and child.focus_mode!=Control.FOCUS_NONE: focusable+=1
 check(focusable==0,"Battle buttons cannot steal keyboard focus")
 # Ultimate charge ring/aura follow the real meter.
 b.set_process(true)
 b.ultimate=100
 await process_frame
 check(b.controls.ultimate.charge>=1.0 and b.hero.aura,"Ultimate ready shows charge ring and aura")
 b.ultimate=40
 await process_frame
 check(absf(b.controls.ultimate.charge-0.4)<0.01 and not b.hero.aura,"Ultimate charge ring tracks meter")
 # Retreat needs a confirming second tap.
 var emitted=[false]
 b.retreat.connect(func(): emitted[0]=true)
 b.request_retreat()
 check(not emitted[0] and b.retreat_button.text=="CONFIRM?","First retreat tap only arms the button")
 b.request_retreat()
 check(emitted[0],"Second retreat tap retreats")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
