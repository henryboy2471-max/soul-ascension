extends SceneTree
# Prints the Episode 1 player-visible trace as JSON (used to record tests/golden/episode1_trace.json from the locked commit).
func _initialize() -> void:
 call_deferred("run")
 create_timer(120.0).timeout.connect(func(): print("TRACE_FAIL timeout");quit(2))
func run() -> void:
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 var tracer=load("res://tests/support/episode1_trace.gd").new()
 var events=await tracer.run(root,main)
 print("TRACE_BEGIN")
 print(JSON.stringify(events,"  "))
 print("TRACE_END")
 quit()
