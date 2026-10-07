extends SceneTree
func shot(name:String) -> void:
 await process_frame
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
 main.start_battle()
 var b=main.screen.get_child(0)
 await create_timer(0.55).timeout
 await shot("cap_intro")
 await create_timer(1.2).timeout
 b.hero.position=Vector2(640,470)
 b.foe.position=Vector2(780,430)
 b.ultimate=100
 b.foe.health=420
 await create_timer(0.3).timeout
 await shot("cap_ready")
 b.act("ultimate")
 await create_timer(0.35).timeout
 await shot("cap_ultimate")
 print("CAPS DONE")
 quit()
