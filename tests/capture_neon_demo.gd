extends SceneTree
# Screenshots + performance snapshot of the 2.5D Neon District demo. Needs a display: xvfb-run -a godot --rendering-driver opengl3 --path . --script res://tests/capture_neon_demo.gd
func shot(name:String, wait:float=0.4) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("user://"+name+".png")
 print("shot ",name)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 var demo=load("res://scripts/demo/neon_demo.gd").new()
 root.add_child(demo)
 await create_timer(4.0).timeout
 await shot("n_01_intro",0.2)
 for c in demo.ui.get_children():
  if c is DialogueBox: c.finish_all()
 await create_timer(1.5).timeout
 await shot("n_02_street",0.2)
 demo.stage.player.wx=1480.0
 demo.stage.player.z=0.5
 demo.stage.snap_camera()
 await shot("n_03_plaza",1.2)
 demo.stage.player.wx=2180.0
 demo.stage.player.z=0.9
 demo.stage.snap_camera()
 await shot("n_04_tower_front",1.0)
 print(JSON.stringify(demo.perf_snapshot()))
 print("NEON CAPS DONE")
 quit()
