extends SceneTree
func shot(name:String) -> void:
 await create_timer(0.25).timeout
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
 main.show_mission(); await shot("s_mission")
 main.show_hero(); await shot("s_hero")
 main.show_upgrade(); await shot("s_upgrade")
 main.show_missions(); await shot("s_missions")
 main.show_settings(); await shot("s_settings")
 main.planned("SUMMON","Phase 3: hero banners, published odds, rarity guarantees, pity tracking, duplicate shards and summon history. No summons are available in this build."); await shot("s_planned")
 main.close_modal()
 main.start_battle(); main.screen.get_child(0).intro=0
 main.screen.get_child(0).foe.receive(100000)
 await create_timer(1.2).timeout
 await shot("s_result")
 print("SCREENS DONE")
 quit()
