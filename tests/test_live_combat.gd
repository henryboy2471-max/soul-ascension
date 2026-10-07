extends SceneTree
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
 var battle=main.screen.get_child(0)
 battle.intro=0
 Engine.time_scale=8.0
 var elapsed=0.0
 while is_instance_valid(battle) and not battle.ended and elapsed<60:
  battle.stick.direction=battle.hero.position.direction_to(battle.foe.position) if battle.hero.position.distance_to(battle.foe.position)>105 else Vector2.ZERO
  battle.controls.attack.held=true
  # Novice pattern: approach, strike, occasionally pulse and heal.
  if battle.energy>45: battle.act("pulse")
  if battle.hero.health<150: battle.act("mend")
  if battle.ultimate>=100: battle.act("ultimate")
  await create_timer(0.1).timeout
  elapsed+=0.1
 var won=battle.foe.dead if is_instance_valid(battle) else false
 print("LIVE MANUAL PATTERN: "+("PASS" if won else "FAIL"))
 await create_timer(1.0).timeout
 if not won or not profile.data.completed.has("1-1"):
  quit(1);return
 main.start_battle()
 battle=main.screen.get_child(0)
 battle.intro=0
 battle.toggle_auto()
 elapsed=0
 while is_instance_valid(battle) and not battle.ended and elapsed<60:
  await create_timer(0.1).timeout
  elapsed+=0.1
 won=battle.foe.dead if is_instance_valid(battle) else false
 print("LIVE AUTO REPLAY: "+("PASS" if won else "FAIL"))
 await create_timer(1).timeout
 Engine.time_scale=1
 main.queue_free()
 quit(0 if won else 1)
