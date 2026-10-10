extends SceneTree
# Hero / Shade / Hollow Cantor Phase 1 / Phase 2 lineup at real gameplay scale in the Soul Realm arena:
# godot --path . --script res://tests/capture_lineup.gd -- PREFIX   (xvfb, --rendering-driver opengl3)
var prefix="lineup"
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
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
 var hero=fighter("res://assets/characters/hero/frames.tres",170.0,Vector2(190,500),1.0,1,"hero")
 var shade=fighter("res://assets/enemies/resonance_shade/frames.tres",185.0,Vector2(470,500),1.0,-1)
 var c1=fighter("res://assets/enemies/hollow_cantor/frames.tres",213.46,Vector2(790,500),1.45,-1)
 c1.cantor=true
 var c2=fighter("res://assets/enemies/hollow_cantor/phase2/frames.tres",213.46,Vector2(1085,500),1.62,-1)
 c2.cantor=true
 c2.boss_form=true
 c2.form_color=Color("e4d8ff")
 for f in [hero,shade,c1,c2]:
  arena.add_child(f)
 for i in range(6):
  await process_frame
 await create_timer(0.7).timeout
 root.get_viewport().get_texture().get_image().save_png("user://%s.png" % prefix)
 quit()
