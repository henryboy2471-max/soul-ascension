extends SceneTree
# UI before/after capture. Run: godot --path . --script res://tests/capture_ui.gd -- PREFIX  (use xvfb + --rendering-driver opengl3;
# add --resolution 844x390 for the phone-landscape set). Images land in user:// as ui_PREFIX_NN_name.png
var prefix="x"
var n=0
func shot(name:String, wait:float=0.35) -> void:
 await create_timer(wait).timeout
 n+=1
 get_root().get_viewport().get_texture().get_image().save_png("user://ui_%s_%02d_%s.png" % [prefix,n,name])
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: prefix=args[0]
 call_deferred("run")
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 await shot("home",0.8)
 main.show_mission(); await shot("mission")
 main.close_modal()
 main.start_episode()
 await shot("title",2.2)
 var ep=main.screen.get_child(0)
 for c in ep.get_children():
  if c.has_method("finish") and not c.has_method("finish_all"): c.finish()
 await shot("dialogue_mira",1.8)
 for c in ep.get_children():
  if c.has_method("finish_all"): c.finish_all()
 await shot("explore_objective",1.2)
 ep.explore.px=470.0
 await shot("act_prompt_mira",1.0)
 ep.on_interact("mira")
 await shot("dialogue_mira",1.6)
 var box=null
 for c in ep.get_children():
  if c.has_method("finish_all"): box=c
 if box!=null:
  box.advance()
  box.advance()
 await shot("dialogue_mira_2",0.4)
 if box!=null: box.finish_all()
 await create_timer(1.0).timeout
 ep.explore.px=1500.0
 await shot("terminal_prompt",1.0)
 for i in range(12):
  ep.explore.channel_t=0.62
  await process_frame
 await shot("terminal_hold",0.0)
 ep.explore.toast("CODEX UPDATED  /  Relay Terminal")
 await shot("codex_toast",0.5)
 ep.set_step(2)
 ep.explore.px=2120.0
 await shot("breach_prompt",1.5)
 main.start_battle(true)
 var b=main.screen.get_child(0)
 await shot("battle_intro",0.7)
 b.intro=0
 await shot("battle_shade",1.2)
 b.hero.health=b.hero.max_health*0.62
 b.energy=48.0
 b.foe.health=b.foe.max_health*0.55
 b.hero.position=Vector2(480,470)
 b.foe.position=Vector2(700,470)
 b.damage_number(b.foe.position,57,true,Color("efce8e"))
 b.damage_number(b.hero.position+Vector2(0,30),18,false,Color("ff8597"))
 b.cooldowns.pulse=3.0
 b.cooldowns.dodge=0.5
 await shot("battle_shade_hit",0.15)
 b.foe.receive(100000)
 await shot("battle_enforcer_intro",1.3)
 b.intro=0
 b.hero.position=Vector2(480,470)
 b.foe.position=Vector2(780,470)
 await shot("battle_enforcer",0.8)
 b.foe.health=b.foe.max_health*0.45
 await shot("battle_phase2_transform",0.4)
 await shot("battle_phase2",1.6)
 b.foe.receive(100000)
 await shot("battle_finisher",0.5)
 await create_timer(2.2).timeout
 await shot("ending_dialogue",1.5)
 for c in main.screen.get_children():
  for d in c.get_children():
   if d.has_method("finish_all"): d.finish_all()
 await create_timer(0.5).timeout
 main.show_result(true)
 await shot("result",0.8)
 main.show_home()
 await shot("home_after",0.8)
 main.show_hero(); await shot("hero_screen")
 main.show_missions(); await shot("missions")
 print("UI CAPS DONE %d" % n)
 quit()
