extends SceneTree
# Episode 2 ending screenshots: godot --path . --script res://tests/capture_episode4.gd -- PREFIX   (xvfb, --rendering-driver opengl3)
var prefix="e4"
var n=0
func shot(name:String, wait:float=0.4) -> void:
 await create_timer(wait).timeout
 n+=1
 get_root().get_viewport().get_texture().get_image().save_png("user://%s_%02d_%s.png" % [prefix,n,name])
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
 call_deferred("run")
func box(ep:Node):
 for c in ep.get_children():
  if c.has_method("finish_all"): return c
 return null
var last_box=null
func wait_box(ep:Node) -> void:
 var t0=Time.get_ticks_msec()
 while (box(ep)==null or box(ep)==last_box) and Time.get_ticks_msec()-t0<30000:
  await process_frame
 last_box=box(ep)
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1"]
 profile.data.level=3
 profile.data.codex=["violet_rain","sleepers","rain_array","hollow_cantor"]
 profile.data.mission_progress={"1-2":{"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true,"battle_won":true}}
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_episode("1-2")
 var ep=main.screen.get_child(0)
 await shot("fade_in",0.5)
 await shot("bell_rings",1.2)
 await wait_box(ep)
 await shot("realm_line1",1.5)
 var b=box(ep)
 b.advance(); b.advance()
 await shot("realm_mira",1.6)
 for i in range(3): b.advance(); b.advance()
 await shot("realm_later",1.6)
 if is_instance_valid(b): b.finish_all()
 await wait_box(ep)
 await shot("quarter_a",1.4)
 b=box(ep)
 b.advance(); b.advance()
 await shot("quarter_sleeper",1.4)
 if is_instance_valid(b): b.finish_all()
 await create_timer(1.2).timeout
 await wait_box(ep)
 await shot("broadcast",1.6)
 b=box(ep)
 b.advance(); b.advance()
 await shot("vaust_registry",1.2)
 if is_instance_valid(b): b.finish_all()
 var t0=Time.get_ticks_msec()
 while main.scene_name!="result" and Time.get_ticks_msec()-t0<15000:
  await process_frame
 await shot("rewards",1.2)
 for c in main.screen.get_children():
  if c is Button and c.text=="NEXT EPISODE": c.pressed.emit()
 await shot("teaser",2.8)
 quit()
