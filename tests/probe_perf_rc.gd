extends SceneTree
# Release-candidate performance probe: frame time and draw calls per game state.
# Run under xvfb with --rendering-driver opengl3 (software GL, so absolute frame times are pessimistic; compare states, not devices).
func measure(label:String, frames:int=120) -> void:
 var ft=[]
 for i in range(frames):
  var s=Time.get_ticks_usec()
  await process_frame
  ft.append((Time.get_ticks_usec()-s)/1000.0)
 ft.sort()
 print("PERF %-26s frame median=%.1f p95=%.1f max=%.1f ms | draw_calls=%d objects=%d" % [label,ft[frames/2],ft[int(frames*0.95)],ft[frames-1],RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),int(Performance.get_monitor(Performance.OBJECT_COUNT))])
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
 await measure("home")
 main.start_episode()
 var ep=main.screen.get_child(0)
 for i in range(20):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
 ep.explore.px=1200.0
 await measure("district (rain, 5 walkers)")
 main.start_battle(true)
 await process_frame
 var b=main.screen.get_child(0)
 b.intro=0
 b.hero.position=Vector2(500,450)
 b.foe.position=Vector2(700,450)
 await measure("battle: Resonance Shade")
 b.foe.receive(100000)
 await create_timer(0.8).timeout
 b.intro=0
 b.foe.position=Vector2(720,450)
 await measure("battle: Enforcer")
 b.foe.health=b.foe.max_health*0.45
 await measure("phase 2 transformation",50)
 await create_timer(1.2).timeout
 await measure("battle: Phase 2 aura")
 b.foe.receive(100000)
 await measure("finisher",40)
 await create_timer(2.0).timeout
 main.show_result(true)
 await measure("result screen")
 print("PERF DONE")
 quit()
