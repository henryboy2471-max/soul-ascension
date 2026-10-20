extends SceneTree
# Combat fairness: PULSE and RIFT pressed out of reach cost nothing (no energy, no cooldown, no swing), in reach they cost energy and start their cooldown; the basic attack still swings and misses.
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
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 main.start_battle()
 await process_frame
 var b=main.screen.get_child(0)
 b.intro=0
 b.energy=100.0
 b.hero.position=Vector2(200,420)
 b.foe.position=Vector2(1100,420)   # 900 px apart: out of reach of everything but the ultimate
 b.act("pulse")
 check(b.energy==100.0 and b.cooldowns.pulse==0.0 and b.hero.swing==0.0,"PULSE out of reach: no energy spent, no cooldown, no swing")
 b.act("rift")
 check(b.energy==100.0 and b.cooldowns.rift==0.0 and b.hero.swing==0.0,"RIFT out of reach (900 > 520): no energy spent, no cooldown, no swing")
 check(str(b.status.text).begins_with("Get closer to use RIFT"),"the player is told to get closer (%s)" % b.status.text)
 b.act("attack")
 check(b.cooldowns.attack>0.0 and b.hero.swing>0.0,"the basic attack still swings and misses out of reach")
 b.cooldowns.attack=0.0
 b.hero.swing=0.0
 b.foe.position=Vector2(700,420)   # 500 px: inside RIFT's 520, outside PULSE's 230
 b.act("pulse")
 check(b.energy==100.0 and b.cooldowns.pulse==0.0,"PULSE at 500 px is still out of reach (230)")
 b.act("rift")
 check(is_equal_approx(b.energy,65.0) and b.cooldowns.rift>0.0,"RIFT at 500 px connects: 35 energy spent, cooldown started")
 b.foe.position=Vector2(330,420)   # 130 px
 b.energy=100.0
 b.act("pulse")
 check(is_equal_approx(b.energy,75.0) and b.cooldowns.pulse>0.0,"PULSE in reach: 25 energy spent, cooldown started")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
