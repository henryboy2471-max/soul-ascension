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
 await create_timer(1.6).timeout
 b.intro=0
 b.hero.position=Vector2(480,470)
 b.foe.position=Vector2(780,470)
 await shot("bt_0_before",0.3)
 b.foe.health=b.foe.max_health*0.45
 await shot("bt_1_dark",0.3)
 await shot("bt_2_charge",0.3)
 await shot("bt_3_reveal",0.3)
 await shot("bt_4_after",0.9)
 print("BOSS TRANSFORM CAPS DONE")
 quit()
