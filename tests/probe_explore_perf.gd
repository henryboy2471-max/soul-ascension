extends SceneTree
# Frame-time probe for Episode 1 exploration at three camera positions (run under xvfb with --rendering-driver opengl3; software GL, not representative of phones).
func _initialize() -> void:
 call_deferred("run")
func measure(label:String) -> void:
 var ms=[]
 for i in range(240):
  var s=Time.get_ticks_usec()
  await process_frame
  ms.append(Time.get_ticks_usec()-s)
 ms.sort()
 print("PERF ",label," median_ms=",ms[120]/1000.0," p95_ms=",ms[228]/1000.0," draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
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
 var ex=ep.explore
 for x in [140.0,1200.0,2300.0]:
  ex.px=x
  ex.cam=clampf(x-640.0,0.0,ex.world_w-1280.0)
  await measure("explore_px%d" % int(x))
 for w in ex.walkers: w.node.visible=false
 ex.px=1200.0
 await measure("explore_px1200_no_walkers")
 quit()
