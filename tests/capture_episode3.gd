extends SceneTree
# Episode 2 battle screenshots (breach prompt, whispers, Shade, Cantor, telegraph, Phase 2, Mira support, hand-off):
# godot --path . --script res://tests/capture_episode3.gd -- PREFIX   (xvfb, --rendering-driver opengl3)
var prefix="e3"
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
 profile.data.level=3
 profile.data.mission_progress={"1-2":{"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true}}
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_episode("1-2")
 await create_timer(0.8).timeout
 var ep=main.screen.get_child(0)
 ep.explore.px=2560.0
 await shot("breach_open",1.0)
 ep.on_interact("breach")
 await shot("breach_prompt",0.8)
 for c in ep.get_children():
  if c.has_method("decide"):
   c.armed=0.0
   c.decide(true)
 await shot("whisper_1",1.2)
 await shot("whisper_2",1.7)
 var battle=main.screen.get_child(0)
 await shot("shade_card",2.0)
 battle.skip_whispers()
 battle.intro=0.0
 battle.hero.position=battle.foe.position-Vector2(120,0)
 await shot("shade_fight",1.0)
 battle.foe.receive(100000.0)
 await shot("cantor_card",1.0)
 await shot("cantor_intro",1.0)
 battle.intro=0.0
 await shot("cantor_idle",2.0)
 battle.hero.position=Vector2(700,450)
 battle.target=battle.hero.position
 battle.telegraph=0.6
 battle.telegraph_len=1.0
 await shot("cantor_telegraph",0.15)
 battle.hero.health=battle.hero.max_health*0.45
 battle.foe.health=battle.foe.max_health*0.49
 await shot("phase2_flash",0.45)
 await shot("phase2_support",0.6)
 await shot("phase2_after",2.2)
 battle.target=battle.hero.position
 battle.telegraph=0.3
 await shot("phase2_telegraph",0.1)
 battle.foe.receive(100000.0)
 await shot("cantor_finisher",1.0)
 await shot("complete",3.5)
 main.show_codex()
 await shot("codex",0.5)
 quit()
