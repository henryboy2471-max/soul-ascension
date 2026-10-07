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
 var ep=main.screen.get_child(0)
 for i in range(40):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
  if ep.explore!=null: break
 ep.explore.px=470.0
 await shot("m_district",0.8)
 await create_timer(0.5).timeout
 ep.explore.act_edge=true
 await shot("m_portrait",0.9)
 print("MIRA CAPS DONE")
 quit()
