extends SceneTree
# Screenshots + performance snapshot of the 2.5D Neon District demo. Needs a display:
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --script res://tests/capture_neon_demo.gd
func shot(name:String, wait:float=0.3) -> void:
 await create_timer(wait).timeout
 get_root().get_viewport().get_texture().get_image().save_png("user://"+name+".png")
 print("shot ",name)
func close_dialogs(demo) -> void:
 for c in demo.ui.get_children():
  if c.has_method("finish_all"):
   c.finish_all()
func walk(demo, dir:Vector2, seconds:float) -> void:
 demo.test_move=dir
 await create_timer(seconds).timeout
 demo.test_move=Vector2.ZERO
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 var demo=load("res://scripts/demo/neon_demo.gd").new()
 root.add_child(demo)
 await create_timer(3.2).timeout
 await shot("n_01_opening",0.1)
 var w=0.0
 while demo.intro_running and w<12.0:
  close_dialogs(demo)
  await create_timer(0.3).timeout
  w+=0.3
 var st=demo.stage
 for a in st.peds:
  a.get_meta("ped").speed*=1.0
 # Echo walking in four directions (3 frames each)
 st.player.wx=1250.0
 st.player.z=0.74
 st.snap_camera()
 await create_timer(0.8).timeout
 demo.test_move=Vector2(1,0)
 await shot("n_02_walk_right_a",0.35)
 await shot("n_02_walk_right_b",0.12)
 demo.test_move=Vector2.ZERO
 await create_timer(0.5).timeout
 demo.test_move=Vector2(0,1)
 await shot("n_03_walk_down",0.4)
 demo.test_move=Vector2.ZERO
 await create_timer(0.4).timeout
 demo.test_move=Vector2(-1,0)
 await shot("n_04_walk_left",0.5)
 demo.test_move=Vector2.ZERO
 await create_timer(0.4).timeout
 demo.test_move=Vector2(0,-1)
 await shot("n_05_walk_up",0.4)
 demo.test_move=Vector2.ZERO
 # crowd + environment
 st.player.wx=1560.0
 st.player.z=0.45
 st.snap_camera()
 await shot("n_06_npcs_kiosk",1.2)
 st.player.wx=2180.0
 st.player.z=0.5
 st.snap_camera()
 await shot("n_07_tower_plaza",1.2)
 st.player.wx=3150.0
 st.player.z=0.34
 st.snap_camera()
 await shot("n_08_junction",1.2)
 # dialogue sequence at Kofi's stall
 st.player.wx=560.0
 st.player.z=0.34
 st.snap_camera()
 await create_timer(0.8).timeout
 demo.on_spot(st.spot("kofi"))
 await shot("n_09_dialogue_1",1.6)
 for c in demo.ui.get_children():
  if c.has_method("advance"):
   c.advance()
   c.advance()
 await shot("n_10_dialogue_2",1.2)
 close_dialogs(demo)
 await create_timer(1.0).timeout
 # puzzle solved: hidden pathway open
 demo.flags.clue=true
 demo.hidden_door.hint=1.0
 st.player.wx=3300.0
 st.player.z=0.3
 st.snap_camera()
 demo.press_breaker("cyan")
 demo.press_breaker("gold")
 demo.press_breaker("violet")
 await shot("n_11_hidden_opening",2.2)
 close_dialogs(demo)
 await create_timer(0.8).timeout
 await shot("n_12_hidden_open",0.4)
 # interiors
 demo.on_spot(st.spot("noodle_door"))
 await shot("n_13_noodle_house",1.6)
 demo.on_spot(demo.stage.spot("exit"))
 await create_timer(1.4).timeout
 demo.on_spot(st.spot("hidden"))
 await create_timer(1.2).timeout
 await shot("n_14_hidden_alley",0.8)
 demo.on_spot(demo.stage.spot("arcade_door"))
 await shot("n_15_arcade",1.6)
 print(JSON.stringify(demo.perf_snapshot()))
 print("NEON CAPS DONE")
 quit()
func _initialize() -> void:
 call_deferred("run")
