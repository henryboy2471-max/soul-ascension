extends SceneTree
# A boss killed soon after the Phase 2 change must not show the PHASE 2 banner under the FINISH cinematic.
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
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.5).timeout
 check(main.start_battle(true,"1-1"),"Episode 1 battle starts")
 await create_timer(0.5).timeout
 var b=null
 for c in main.screen.get_children():
  if c.has_method("enter_phase_two"): b=c
 check(b!=null,"Battle node exists")
 b.wave=1
 b.enter_phase_two()
 check(b.intro_card.modulate.a>0.9,"PHASE 2 banner is up right after the change")
 b.finisher()
 check(b.intro_card.modulate.a<0.01 and b.intro_sub.modulate.a<0.01,"FINISH hides the PHASE 2 banner immediately")
 check(b.ultimate_title.text=="FINISH" and b.ultimate_title.modulate.a>0.9,"FINISH title is shown")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
