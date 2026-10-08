extends SceneTree
# Episode 2 (Lantern Quarter) screenshots: godot --path . --script res://tests/capture_episode2.gd -- PREFIX (xvfb, opengl3)
var prefix="e2"
var n=0
func shot(name:String, wait:float=0.4) -> void:
 await create_timer(wait).timeout
 n+=1
 get_root().get_viewport().get_texture().get_image().save_png("user://%s_%02d_%s.png" % [prefix,n,name])
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
 call_deferred("run")
func skip(ep:Node) -> void:
 for c in ep.get_children():
  if c.has_method("finish_all"): c.finish_all()
  elif c.has_method("finish"): c.finish()
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1"]
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.show_home()
 await shot("home",0.6)
 main.show_missions()
 await shot("missions",0.4)
 main.close_modal()
 main.start_episode("1-2")
 await shot("title",2.4)
 var ep=main.screen.get_child(0)
 skip(ep)
 await shot("opening",1.6)
 skip(ep)
 await shot("district_start",1.4)
 var ex=ep.explore
 ex.px=470.0
 await shot("depot_prompt",0.9)
 ep.on_interact("depot")
 await shot("depot_dialogue",1.5)
 skip(ep)
 await create_timer(1.0).timeout
 ex.px=900.0
 await shot("sleepers",0.9)
 ex.px=980.0
 await create_timer(0.6).timeout
 ep.on_interact("mira")
 await shot("mira_dialogue",1.4)
 for i in range(5):
  for c in ep.get_children():
   if c.has_method("advance"): c.advance(); c.advance()
 await shot("pell_radio",0.4)
 skip(ep)
 await create_timer(1.0).timeout
 ex.px=1350.0
 await shot("resonator_prompt",0.9)
 ex.channel_t=0.6
 await shot("resonator_hold",0.05)
 ep.on_interact("res_a")
 await create_timer(0.7).timeout
 await shot("memory",1.2)
 skip(ep)
 await create_timer(1.0).timeout
 ex.px=1550.0
 await shot("notice_prompt_counter_1",0.9)
 ep.on_interact("res_c")
 await create_timer(0.7).timeout
 skip(ep)
 await create_timer(1.2).timeout
 ex.px=2300.0
 await shot("gate_locked_2of3",1.0)
 ex.px=2380.0
 await create_timer(0.7).timeout
 await shot("gate_prompt",0.4)
 ex.px=2150.0
 ep.on_interact("res_b")
 await create_timer(0.8).timeout
 await shot("three_of_three",0.4)
 skip(ep)
 await create_timer(0.8).timeout
 skip(ep)
 await create_timer(1.0).timeout
 ex.px=2420.0
 await shot("roof_open",1.0)
 ex.px=2600.0
 await shot("array_prompt",1.0)
 ep.on_interact("array")
 await create_timer(0.5).timeout
 skip(ep)
 await shot("array_dialogue",0.3)
 skip(ep)
 await create_timer(1.8).timeout
 await shot("breach_open",0.2)
 print("EP2 CAPS DONE %d" % n)
 quit()
