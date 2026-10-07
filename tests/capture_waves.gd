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
 await shot("w_shade_intro",0.6)
 b.intro=0
 await create_timer(1.5).timeout
 b.foe.health=90
 await shot("w_shade_fight",0.2)
 b.foe.receive(100000)
 await shot("w_transition",0.45)
 await shot("w_boss",1.4)
 b.foe.health=1
 b.hero.position=Vector2(700,450)
 b.foe.position=Vector2(800,450)
 b.foe.invincible=0
 b.foe.receive(1000)
 await shot("w_finisher",0.45)
 print("WAVE CAPS DONE")
 quit()
