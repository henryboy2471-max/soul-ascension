extends SceneTree
# Hollow Cantor art screenshots (Phase 1, telegraph, attack, hurt, Phase 2, defeat): godot --path . --script res://tests/capture_cantor.gd -- PREFIX
var prefix="cn"
var n=0
func shot(name:String, wait:float=0.4) -> void:
 await create_timer(wait).timeout
 n+=1
 get_root().get_viewport().get_texture().get_image().save_png("user://%s_%02d_%s.png" % [prefix,n,name])
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.data.completed=["1-1"]
 profile.data.level=4
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_battle(true,"1-2")
 await process_frame
 var b=main.screen.get_child(0)
 b.skip_whispers()
 b.intro=0.0
 b.foe.receive(1000000.0)
 await create_timer(1.0).timeout
 b.intro=0.0
 b.tip.text=""
 b.hero.position=Vector2(470,450)
 await shot("phase1_idle",1.2)
 b.foe.position=Vector2(640,450)
 b.target=b.hero.position
 b.telegraph_len=1.0
 b.telegraph=0.55
 b.foe.stun=0.0
 await shot("telegraph",0.1)
 b.foe.swing=0.4
 await shot("attack",0.12)
 b.foe.flash=0.14
 await shot("hurt",0.02)
 b.hero.health=b.hero.max_health*0.5
 b.foe.health=b.foe.max_health*0.49
 await shot("phase2_banner",0.5)
 await shot("phase2_radio",2.3)
 b.foe.swing=0.4
 b.target=b.hero.position
 b.telegraph=0.4
 await shot("phase2_telegraph",0.1)
 await shot("phase2_attack",0.45)
 b.foe.receive(100000.0)
 await shot("defeat_a",0.25)
 await shot("defeat_b",0.45)
 await shot("defeat_c",0.5)
 quit()
