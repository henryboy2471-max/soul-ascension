extends SceneTree
# Episode 3 zone screenshots: godot --path . --script res://tests/capture_relay.gd -- PREFIX (xvfb, --rendering-driver opengl3)
var prefix="relay"
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
 call_deferred("run")
func shot(name:String, wait:float=0.5) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("user://%s_%s.png" % [prefix,name])
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 var ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 for i in range(30):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
 var plan=[["market",170.0],["market",1000.0],["market",2380.0],["station",800.0],["station",1750.0],["alleys",900.0],["alleys",1560.0],["workshop",900.0],["tower_1",1300.0],["tower_2",1300.0],["tower_3",1300.0]]
 var n=0
 for p in plan:
  ep.begin_zone(p[0],p[1])
  ep.explore.px=p[1]
  ep.explore.update_positions(1.0)
  n+=1
  await shot("%02d_%s_%d" % [n,p[0],int(p[1])],0.6)
 quit()
