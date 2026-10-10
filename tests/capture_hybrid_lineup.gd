extends SceneTree
# Hybrid-art experiment: Hero / Shade / Cantor v2 / Cantor hybrid at real gameplay scale (1280x720 arena).
# godot --path . --script res://tests/capture_hybrid_lineup.gd -- PREFIX PHASE(1|2) HYBRID_PNG   (xvfb, --rendering-driver opengl3)
var prefix="hybrid"
var phase=1
var hybrid_png=""
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
 if args.size()>1: phase=int(args[1])
 if args.size()>2: hybrid_png=args[2]
 call_deferred("run")
func fighter(path:String, height:float, pos:Vector2, node_scale:float, facing:int, flag:String="") -> Node:
 var f=load("res://scripts/combat/fighter.gd").new()
 f.enemy=flag!="hero"
 f.load_sprite_set(path,height)
 f.position=pos
 f.scale=Vector2(node_scale,node_scale)
 f.facing=facing
 return f
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 root.size=Vector2i(1280,720)
 var arena=Node2D.new()
 root.add_child(arena)
 var art=load("res://scripts/combat/soul_realm_art.gd").new()
 art.theme_id="rain"
 arena.add_child(art)
 var p2=phase==2
 var sc=1.62 if p2 else 1.45
 var v2path="res://assets/enemies/hollow_cantor/phase2/frames.tres" if p2 else "res://assets/enemies/hollow_cantor/frames.tres"
 var hero=fighter("res://assets/characters/hero/frames.tres",170.0,Vector2(130,500),1.0,1,"hero")
 var shade=fighter("res://assets/enemies/resonance_shade/frames.tres",185.0,Vector2(360,500),1.0,-1)
 var cv2=fighter(v2path,213.46,Vector2(660 if p2 else 640,500),sc,-1)
 var cy=fighter("",213.46,Vector2(1070 if p2 else 990,500),sc,-1)
 var sf=SpriteFrames.new()
 sf.add_animation("idle")
 sf.set_animation_loop("idle",true)
 sf.add_frame("idle",ImageTexture.create_from_image(Image.load_from_file(hybrid_png)))
 cy.attach_frames(sf,213.46)
 for f in [cv2,cy]:
  f.cantor=true
  if p2:
   f.boss_form=true
   f.form_color=Color("e4d8ff")
 for f in [hero,shade,cv2,cy]:
  arena.add_child(f)
 for i in range(6):
  await process_frame
 await create_timer(0.7).timeout
 root.get_viewport().get_texture().get_image().save_png("user://%s.png" % prefix)
 quit()
