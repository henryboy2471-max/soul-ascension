extends SceneTree
# Script cost per frame of an exploration scene: each node's _process timed directly over many calls (headless; microseconds per call).
# usage: godot --headless --path . --script res://tools/qa/script_cost.gd
func _initialize() -> void:
 call_deferred("run")
func us(c:Callable, n:int=3000) -> float:
 var s=Time.get_ticks_usec()
 for i in range(n): c.call()
 return float(Time.get_ticks_usec()-s)/float(n)
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
 var dt=1.0/60.0
 var total=0.0
 var t=us(func(): ex._process(dt)); total+=t; print("Explore._process = %.1f us" % t)
 t=us(func(): ex.player._process(dt)); total+=t; print("Hero Fighter._process = %.1f us" % t)
 t=us(func(): ex.npc._process(dt)); total+=t; print("Mira/NPC Fighter._process = %.1f us" % t)
 var wsum=0.0
 for w in ex.walkers:
  wsum+=us(func(): w.node._process(dt),1000)
 total+=wsum; print("pedestrians (%d) Fighter._process = %.1f us total" % [ex.walkers.size(),wsum])
 for n in [ex.props,ex.fore]:
  t=us(func(): n._process(dt)); total+=t; print("WorldArt %s _process = %.1f us" % [n.kind,t])
 for n in main.screen.find_children("*","Control",false,false):
  if n.get_script()!=null and str(n.get_script().resource_path).ends_with("atmosphere.gd"):
   t=us(func(): n._process(dt)); total+=t; print("Atmosphere._process = %.1f us" % t)
 print("TOTAL script _process per frame = %.1f us (%.3f ms)" % [total,total/1000.0])
 quit()
