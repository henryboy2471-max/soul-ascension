extends SceneTree
func shot(name:String, wait:float=0.3) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("user://"+name+".png")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.start_battle(true)
 var b=main.screen.get_child(0)
 b.intro=0
 b.foe.receive(100000)
 await shot("en_intro",0.8)
 b.intro=0
 b.hero.position=Vector2(520,470)
 b.foe.position=Vector2(760,470)
 await shot("en_side_by_side",0.4)
 b.foe.position=Vector2(660,470)
 b.telegraph=0.5
 b.target=b.hero.position
 await shot("en_attack",0.15)
 b.foe.health=b.foe.max_health*0.4
 await shot("en_phase2",0.6)
 b.foe.receive(100000)
 await shot("en_finish",0.9)
 print("ENFORCER CAPS DONE")
 quit()
