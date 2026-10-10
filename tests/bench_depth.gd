extends SceneTree
# Architecture benchmark: the same street content built as (A) the 2D layered 2.5D stage and (B) a true-3D scene (Camera3D, textured ground/facade quads,
# Sprite3D billboard characters), both in the Compatibility renderer. Prints draw calls / objects / primitives / texture memory / frame time.
# Frame time here is software GL (llvmpipe) and is NOT representative of phones; the draw-call and memory counts are the comparable numbers.
#   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --path . --script res://tests/bench_depth.gd
const FRAMES = 240
func measure(label:String) -> void:
 for i in range(30):
  await process_frame
 var t0=Time.get_ticks_usec()
 var dc=0.0
 var obj=0.0
 var prim=0.0
 for i in range(FRAMES):
  await process_frame
  dc=maxf(dc,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
  obj=maxf(obj,Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
  prim=maxf(prim,Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
 var ms=float(Time.get_ticks_usec()-t0)/1000.0/FRAMES
 print("BENCH %s draw_calls=%d objects=%d primitives=%d tex_mem_mb=%.1f vram_mb=%.1f avg_frame_ms=%.1f nodes=%d" % [label,dc,obj,prim,Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,ms,Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 # ---- A: 2D 2.5D stage (the demo's street, fully built, intro skipped)
 var demo=load("res://scripts/demo/neon_demo.gd").new()
 root.add_child(demo)
 await create_timer(3.0).timeout
 var w=0.0
 while demo.intro_running and w<12.0:
  for c in demo.ui.get_children():
   if c.has_method("finish_all"):
    c.finish_all()
  await create_timer(0.3).timeout
  w+=0.3
 demo.stage.player.wx=1800.0
 demo.stage.snap_camera()
 await measure("A_2D_layered_stage")
 demo.queue_free()
 await process_frame
 await process_frame
 # ---- B: true 3D scene with billboards (same actor count, same baked textures)
 var root3=Node3D.new()
 root.add_child(root3)
 var cam=Camera3D.new()
 cam.position=Vector3(0,2.2,9)
 cam.rotation_degrees=Vector3(-8,0,0)
 cam.fov=45
 root3.add_child(cam)
 var ground=MeshInstance3D.new()
 var pm=PlaneMesh.new()
 pm.size=Vector2(60,12)
 ground.mesh=pm
 var gm=StandardMaterial3D.new()
 gm.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 gm.albedo_color=Color(0.12,0.1,0.24)
 ground.material_override=gm
 root3.add_child(ground)
 var vp_tex=load("res://assets/demo25d/chars/echo_front.png")
 for i in range(3):   # facade strips as textured quads at the back
  var q=MeshInstance3D.new()
  var qm=QuadMesh.new()
  qm.size=Vector2(20,6)
  q.mesh=qm
  var m=StandardMaterial3D.new()
  m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  m.albedo_color=Color(0.2+0.1*i,0.15,0.4)
  q.material_override=m
  q.position=Vector3(-20+i*20,3,-5)
  root3.add_child(q)
 for i in range(14):   # 14 actors (8 pedestrians + NPCs + player) as billboard sprites
  var s=Sprite3D.new()
  s.texture=vp_tex
  s.hframes=5
  s.pixel_size=0.0125
  s.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y
  s.shaded=false
  s.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
  s.position=Vector3(-8+i*1.2,1.8,randf_range(-2,3))
  root3.add_child(s)
 for i in range(12):   # 12 vehicles as boxes
  var v=MeshInstance3D.new()
  var bm=BoxMesh.new()
  bm.size=Vector3(2.4,0.6,1.0)
  v.mesh=bm
  v.position=Vector3(-12+i*2.5,0.4,-1.0)
  root3.add_child(v)
 for i in range(60):   # 60 additive glow billboards (signs/lamps)
  var g=Sprite3D.new()
  g.texture=vp_tex
  g.pixel_size=0.01
  g.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  g.shaded=false
  g.position=Vector3(-12+i*0.4,3.0,-4.5)
  root3.add_child(g)
 var cur=Camera3D.new()
 await measure("B_true3D_billboards")
 print("BENCH DONE")
 quit()
