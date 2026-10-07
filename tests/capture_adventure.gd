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
 main.start_episode()
 await shot("a_title",2.2)
 var ep=main.screen.get_child(0)
 for c in ep.get_children():
  if c.has_method("finish") and not c.has_method("finish_all"): c.finish()
 await shot("a_dialogue",1.6)
 for c in ep.get_children():
  if c.has_method("finish_all"):
   c.advance(); c.advance()
 await shot("a_dialogue2",1.0)
 for c in ep.get_children():
  if c.has_method("finish_all"): c.finish_all()
 await shot("a_explore1",1.2)
 ep.explore.px=470.0
 await shot("a_explore_mira",1.0)
 ep.explore.px=1500.0
 ep.set_step(1)
 await shot("a_explore_terminal",1.0)
 ep.set_step(2)
 ep.explore.px=2120.0
 await shot("a_explore_breach",2.0)
 print("ADV CAPS DONE")
 quit()
