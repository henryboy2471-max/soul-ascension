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
 await shot("sh_intro",0.7)
 b.intro=0
 await create_timer(0.5).timeout
 b.hero.position=Vector2(560,470)
 b.foe.position=Vector2(740,470)
 await shot("sh_side_by_side",0.5)
 b.foe.position=Vector2(660,470)
 b.telegraph=0.5
 b.target=b.hero.position
 b.act("attack")
 await shot("sh_attack",0.15)
 b.foe.receive(100000)
 await shot("sh_dissolve",0.25)
 await shot("sh_boss",1.6)
 print("SHADE CAPS DONE")
 quit()
