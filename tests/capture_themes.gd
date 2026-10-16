extends SceneTree
# Screenshots for the per-episode themes, the circle-free walkers and the Music switch (needs a display):
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --resolution 1280x720 --script res://tests/capture_themes.gd -- OUTDIR
var out="/tmp"
func shot(name:String, wait:=0.6) -> void:
 await create_timer(wait).timeout
 root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out,name])
func skip(ep:Node) -> void:
 var n=0
 while n<2000 and (ep.explore==null or ep.get("busy")==true):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
  n+=1
func _initialize() -> void:
 var a=OS.get_cmdline_user_args()
 if a.size()>0: out=a[0]
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.dev_unlock=true
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await create_timer(0.8).timeout
 main.show_home()
 await shot("home_ep1")
 profile.data.completed=["1-1"]
 main.show_home()
 await shot("home_ep2")
 main.clear_screen(); main.backdrop("1-3")
 var lift=ColorRect.new(); lift.color=MissionDefs.theme("1-3").lift; lift.size=Vector2(1280,720); lift.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var mat=CanvasItemMaterial.new(); mat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD; lift.material=mat; main.screen.add_child(lift)
 await shot("wallpaper_ep3")
 profile.data.completed=[]
 main.start_episode("1-1")
 await create_timer(0.5).timeout
 var ep=main.screen.get_child(0)
 await skip(ep)
 await shot("explore_ep1",1.2)
 profile.data.completed=["1-1"]
 main.start_episode("1-2")
 await create_timer(0.5).timeout
 ep=main.screen.get_child(0)
 await skip(ep)
 await shot("explore_ep2",1.2)
 profile.data.completed=["1-1","1-2"]
 main.start_episode("1-3")
 await create_timer(0.5).timeout
 ep=main.screen.get_child(0)
 await skip(ep)
 await shot("explore_ep3",1.2)
 main.show_home()
 main.show_settings()
 await shot("settings_music",0.6)
 quit()
