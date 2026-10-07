extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func measure(label:String) -> void:
 var ms=[]
 for i in range(150):
  var s=Time.get_ticks_usec()
  await process_frame
  ms.append(Time.get_ticks_usec()-s)
 ms.sort()
 print("PERF ",label," median_ms=",ms[75]/1000.0," p95_ms=",ms[142]/1000.0," draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
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
 for i in range(20):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
 ep.explore.px=1200.0
 var ex=ep.explore
 await measure("explore_all")
 ex.fore.visible=false
 await measure("no_fore")
 ex.props.visible=false
 await measure("no_fore_props")
 for l in ex.layers: l.visible=false
 await measure("nothing_but_chars")
 for w in ex.walkers: w.node.visible=false
 await measure("no_walkers")
 ex.fore.visible=true;ex.props.visible=true
 for l in ex.layers: l.visible=true
 for w in ex.walkers: w.node.visible=true
 main.start_battle(true)
 main.screen.get_child(0).intro=0
 await measure("boss_battle")
 quit()
