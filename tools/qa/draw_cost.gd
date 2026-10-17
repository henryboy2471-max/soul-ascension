extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func frame_ms(n:int=200) -> float:
 var s=Time.get_ticks_usec()
 for i in range(n): await process_frame
 return float(Time.get_ticks_usec()-s)/1000.0/float(n)
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 var base=Node2D.new()
 root.add_child(base)
 await process_frame
 print("baseline empty frame = %.3f ms" % await frame_ms())
 for count in [100,300]:
  for c in base.get_children(): c.queue_free()
  await process_frame
  for i in range(count):
   var f=Fighter.new()
   f.ground_marker=false
   f.look="ped"
   f.armed=false
   f.position=Vector2(i%40*30,300+i/40*10)
   base.add_child(f)
  await process_frame
  var procedural=await frame_ms()
  print("%d procedural pedestrians redrawing every frame = %.3f ms -> %.1f us each" % [count,procedural,(procedural-6.9)*1000.0/count])
 for c in base.get_children(): c.queue_free()
 await process_frame
 for i in range(300):
  var f=Fighter.new()
  f.ground_marker=false
  f.load_sprite_set("res://assets/characters/hero/frames.tres",170.0)
  f.position=Vector2(i%40*30,300+i/40*10)
  base.add_child(f)
 await process_frame
 var sp=await frame_ms()
 print("300 sprite characters (hero frames, redraw every frame) = %.3f ms -> %.1f us each" % [sp,(sp-6.9)*1000.0/300.0])
 quit()
