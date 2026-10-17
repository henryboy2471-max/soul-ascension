extends SceneTree
# CPU-side frame cost of an exploration scene (headless: scripts, scene tree and draw-command recording, no GPU). Attribution: frame cost with each group hidden.
# usage: godot --headless --path . --script res://tools/qa/cpu_frame_cost.gd      (prints "KEY = value")
func _initialize() -> void:
 Engine.max_fps=0   # no frame limiter: the frame time is then the CPU work itself
 call_deferred("run")
func measure(n:int=400) -> Array:
 var ms=[]
 for i in range(n):
  var s=Time.get_ticks_usec()
  await process_frame
  ms.append((Time.get_ticks_usec()-s)/1000.0)
 ms.sort()
 var sum=0.0
 for m in ms: sum+=m
 return [sum/ms.size(),ms[ms.size()/2],ms[int(ms.size()*0.95)]]
func line(label:String, r:Array) -> void:
 print("%s = mean %.3f ms  median %.3f ms  p95 %.3f ms" % [label,r[0],r[1],r[2]])
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.music=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.start_episode()
 var ep=main.screen.get_child(0)
 for i in range(30):
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
 var ex=ep.explore
 ex.px=1200.0
 ex.update_positions(1.0)
 await process_frame
 line("ep1 standing: whole frame",await measure())
 print("ep1 node count = %d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
 var groups={"layers":ex.layers,"props":[ex.props],"fore":[ex.fore],"plate":[ex.foreground_plate] if ex.foreground_plate!=null else [],"fighters":[ex.player,ex.npc]+ex.walkers.map(func(w): return w.node),"hud":ex.hud_nodes}
 var atmo=[]
 for n in main.screen.find_children("*","Control",false,false):
  if n.get_script()!=null and str(n.get_script().resource_path).ends_with("atmosphere.gd"):
   atmo.append(n)
 groups["atmosphere"]=atmo
 for g in groups:
  for n in groups[g]:
   if is_instance_valid(n): n.visible=false
  line("ep1 standing, %s hidden" % g,await measure(200))
  for n in groups[g]:
   if is_instance_valid(n): n.visible=true
 ex.stick.direction=Vector2(1,0)
 line("ep1 walking: whole frame",await measure())
 quit()
