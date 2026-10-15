extends SceneTree
# Renders the home screen for review (run under xvfb with --rendering-driver opengl3 and --resolution WxH): -- fresh | resume | cleared | resume2
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var state=OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size()>0 else "fresh"
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 if state=="resume":
  profile.data.mission_progress={"1-1":{"intro":true,"step":1,"px":520.0}}
  profile.data.codex=["mira"]
 elif state=="cleared":
  profile.data.completed=["1-1"]
  profile.data.level=2
  profile.data.xp=20
  profile.data.gold=750
  profile.data.energy=54
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(1.2).timeout
 var img=root.get_viewport().get_texture().get_image()
 img.save_png("/tmp/home_%s_%dx%d.png" % [state,img.get_width(),img.get_height()])
 print("SAVED ",state,img.get_size())
 quit()
