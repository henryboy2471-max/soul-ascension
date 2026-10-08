extends SceneTree
# UI polish: HUD structure, layout containment (nothing off-screen or overlapping the controls), Phase 2 HUD transition,
# cooldown/Aether indicators, dialogue lift, interaction prompt, toast.
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
 create_timer(100.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func inside(r:Rect2) -> bool:
 return Rect2(0,0,1280,720).encloses(r)
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_battle(true)
 await process_frame
 var b=main.screen.get_child(0)
 b.intro=0
 await process_frame
 # --- HUD layout ---
 var all_inside=true
 for key in b.controls:
  var c=b.controls[key]
  if not inside(Rect2(c.position,c.size)): all_inside=false
 check(all_inside,"Every battle button lies fully inside the 1280x720 screen")
 var overlap=false
 var keys=b.controls.keys()
 for i in range(keys.size()):
  for j in range(i+1,keys.size()):
   var a=Rect2(b.controls[keys[i]].position,b.controls[keys[i]].size)
   var o=Rect2(b.controls[keys[j]].position,b.controls[keys[j]].size)
   if a.intersects(o): overlap=true
 check(not overlap,"Battle buttons do not overlap each other")
 var hud_rects=[Rect2(24,24,406,116),Rect2(850,24,406,116)]
 var clear=true
 for r in hud_rects:
  for key in b.controls:
   if r.intersects(Rect2(b.controls[key].position,b.controls[key].size)): clear=false
 check(clear,"HUD panels do not overlap the buttons")
 check(b.foe.position.y>345 and b.hero.position.y>345,"Fighters stand below the HUD panels")
 b.hero.position=Vector2(1000,640)
 await process_frame
 await process_frame
 var lowest=Rect2(b.controls.attack.position,b.controls.attack.size)
 check(b.hero.position.y<=496.0 and b.hero.position.y<lowest.position.y,"The Hero cannot walk behind the touch buttons (feet stay above y 500)")
 b.hero.position=Vector2(300,450)
 check(b.enemy_hp.tick<0.0 and b.wave_chip.text=="WAVE 1/2","Wave 1 HUD: no phase tick, WAVE 1/2 chip")
 var shade_color=b.enemy_hp.color
 # --- cooldown + Aether indicators ---
 b.cooldowns.pulse=3.0
 b.energy=10.0
 await process_frame
 await process_frame
 check(b.controls.pulse.cooldown>0.5 and b.controls.pulse.seconds>2.0,"Cooldown sweep and remaining seconds are fed to the Pulse button")
 check(b.controls.rift.dim and b.controls.mend.dim and not b.controls.attack.dim,"Buttons dim when there is not enough Aether (attack never dims)")
 check(b.controls.ultimate.dim,"Ultimate looks locked until charged")
 b.energy=100.0
 await process_frame
 check(not b.controls.rift.dim,"Buttons light up again when Aether returns")
 # --- bar ghost (damage feedback) ---
 var before=b.hp.ghost
 b.hero.receive(60)
 await process_frame
 await process_frame
 check(b.hp.ghost>b.hp.value and b.hurt_vignette.strength>0.0,"Hero hit leaves a damage ghost on the HP bar and pulses the screen edge")
 # --- boss wave HUD ---
 b.foe.receive(100000)
 await create_timer(0.5).timeout
 check(b.wave==1 and b.wave_chip.text=="WAVE 2/2" and absf(b.enemy_hp.tick-0.5)<0.01,"Wave 2 HUD shows WAVE 2/2 and the 50% phase tick")
 check(b.enemy_hp.color!=shade_color,"Enforcer bar switches from Shade purple to boss orange")
 # --- Phase 2 HUD transition ---
 b.intro=0
 b.foe.health=b.foe.max_health*0.45
 await process_frame
 await process_frame
 check(b.phase==2 and b.wave_chip.text=="PHASE 2" and b.foe_sub_label.text.begins_with("SOUL ASCENDED") and b.enemy_hp.tick<0.0,"Phase 2 HUD: SOUL ASCENDED tag, PHASE 2 chip, tick removed")
 check(b.enemy_hp.color==Color("ff4f72") and b.transform_count==1,"Phase 2 bar turns red and the HUD change fires once")
 await create_timer(1.2).timeout
 check(b.wave_chip.text=="PHASE 2" and b.foe_panel.modulate.r<=1.05,"HUD settles after the transition")
 main.queue_free()
 await process_frame
 # --- explore UI ---
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_episode()
 await process_frame
 var ep=main.screen.get_child(0)
 for c in ep.get_children():
  if c.has_method("finish") and not c.has_method("finish_all"): c.finish()
 await create_timer(0.3).timeout
 for c in ep.get_children():
  if c.has_method("finish_all"): c.finish_all()
 await create_timer(0.8).timeout
 var ex=ep.explore
 check(ex.lift>-1.0 and ex.stick.visible and ex.act_button.visible,"Free exploration: street not lifted, touch controls visible")
 ex.px=470.0
 await create_timer(0.7).timeout
 check(not ex.active_spot.is_empty() and ex.active_spot.id=="mira","Near Mira the interaction spot is active (prompt pill is drawn from it)")
 ep.on_interact("mira")
 await create_timer(1.2).timeout
 check(ex.lift<-100.0,"During a conversation the street lifts so the dialogue box does not cover characters")
 check(not ex.stick.visible and not ex.act_button.visible,"Touch controls hide while the dialogue box is open")
 check(ex.player.position.y<468.0 and ex.npc.position.y<468.0,"Hero and Mira feet stay above the dialogue box (y < 468)")
 var box=null
 for c in ep.get_children():
  if c.has_method("finish_all"): box=c
 check(box!=null and box.name_plate.visible and box.counter.text=="1 / 5","Dialogue shows the speaker nameplate and a line counter")
 if box!=null: box.finish_all()
 await create_timer(1.0).timeout
 check(ex.lift>-5.0 and ex.stick.visible,"Street lowers and touch controls return after the conversation")
 ex.toast("CODEX UPDATED  /  Test Entry")
 await create_timer(0.4).timeout
 check(ex.toast_kicker.text=="CODEX UPDATED" and ex.toast_label.text=="Test Entry" and ex.toast_panel.modulate.a>0.5,"Codex toast shows kicker and entry title")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
