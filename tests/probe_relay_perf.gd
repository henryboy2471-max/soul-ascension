extends SceneTree
# Frame-time probe for every Episode 3 zone (run under xvfb with --rendering-driver opengl3). Software GL: NOT representative of phones; use it to compare zones, not as a device claim.
func _initialize() -> void:
 call_deferred("run")
func measure(label:String) -> void:
 var ms=[]
 for i in range(180):
  var s=Time.get_ticks_usec()
  await process_frame
  ms.append(Time.get_ticks_usec()-s)
 ms.sort()
 print("PERF ",label," median_ms=",ms[90]/1000.0," p95_ms=",ms[171]/1000.0," draw_calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 for i in range(900):
  if not ep.busy and ep.explore!=null: break
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
 for z in ZoneDefs.zones().keys():
  ep.begin_zone(z,-1.0)
  await process_frame
  await process_frame
  await measure(str(z))
 quit()
