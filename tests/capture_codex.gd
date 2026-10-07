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
 profile.data.codex=["mira","mural","terminal","breach"]
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.show_hero()
 await shot("c_hero",0.4)
 main.show_codex()
 await shot("c_codex",0.4)
 main.close_modal()
 main.set_portrait_hint(true)
 await shot("c_rotate",0.4)
 print("CODEX CAPS DONE")
 quit()
