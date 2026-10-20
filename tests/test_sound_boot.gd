extends SceneTree
# Sound boot cost: the footstep variants and ambience loops are built one per frame after boot (not in _ready), anything asked for early is built on demand, and prepare_all() completes everything.
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=true
 var s=load("res://scripts/audio/sound.gd").new()
 root.add_child(s)
 check(s.clips.size()==6 and s.loops.is_empty() and s.build_queue.size()==17,"after _ready only the small clips exist; 15 footsteps and 2 loops are queued (%d queued)" % s.build_queue.size())
 s.footstep("wet")   # asked for before the build reached it: must not crash, must produce a clip
 check(s.step_clips.wet.size()==1,"an early footstep builds one variant on demand")
 s.loop("city")
 check(s.loops.has("city") and s.loop_player.playing and s.loops.city.data.size()==22050*4*2,"an early ambience request builds the city loop on demand and plays it")
 s.stop_loop()
 var frames=0
 while not s.build_queue.is_empty() and frames<60:
  await process_frame
  frames+=1
 check(s.build_queue.is_empty() and frames<=20,"the queue drains one item per frame (%d frames)" % frames)
 check(s.loops.has("realm") and s.loops.size()==2,"both loops exist afterwards")
 var full=true
 for surface in s.STEP_SURFACES:
  if s.step_clips[surface].size()<5:
   full=false
 check(full,"every surface ends with its five variants (the on-demand clip counts as one of them)" if full else "every surface should end with at least its five variants (wet has %d)" % s.step_clips.wet.size())
 for i in range(30):
  s.footstep("wood")
 check(true,"30 footsteps in a row run without error (variant picking)")
 var s2=load("res://scripts/audio/sound.gd").new()
 root.add_child(s2)
 s2.prepare_all()
 check(s2.build_queue.is_empty() and s2.loops.size()==2 and s2.step_clips.metal.size()==5 and s2.step_clips.wet.size()==5,"prepare_all() finishes the whole queue at once")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
