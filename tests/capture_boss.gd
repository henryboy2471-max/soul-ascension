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
 await shot("b_intro",0.6)
 b.intro=0
 await create_timer(1.6).timeout
 b.hero.position=Vector2(560,470)
 b.foe.position=Vector2(780,440)
 b.act("attack")
 await shot("b_fight",0.12)
 b.foe.health=380
 await create_timer(0.5).timeout
 await shot("b_phase2",0.4)
 b.energy=100
 b.stick.direction=Vector2(1,0)
 b.act("dodge")
 await shot("b_dash",0.07)
 print("BOSS CAPS DONE")
 quit()
