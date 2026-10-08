extends SceneTree
# Episode 1 release-candidate checks: player-visible wording, fresh-save flow, replay/first-clear rewards, settings and audio
# toggles, out-of-energy path, and REAL touch-event joystick drags (district and battle).
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
 create_timer(150.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func texts(node:Node, out:Array) -> void:
 if node is Label or node is Button or node is LineEdit or node is CheckButton:
  if node.visible and str(node.text)!="":
   out.append(str(node.text))
 for c in node.get_children():
  texts(c,out)
func banned(list:Array, extra:String="") -> Array:
 var re=RegEx.new()
 re.compile("(?i)(prototype|placeholder|debug|todo|lorem|development build|\\bwip\\b|api key|phase\\s*0?[134]\\b"+extra+")")
 var bad=[]
 for s in list:
  if re.search(s)!=null: bad.append(s)
 return bad
func finish_dialogues(ep) -> void:
 for c in ep.get_children():
  if c.has_method("finish_all"): c.finish_all()
func touch(index:int, pressed:bool, pos:Vector2) -> void:
 var e=InputEventScreenTouch.new()
 e.index=index
 e.pressed=pressed
 e.position=pos
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func drag(index:int, pos:Vector2, rel:Vector2) -> void:
 var e=InputEventScreenDrag.new()
 e.index=index
 e.position=pos
 e.relative=rel
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func run() -> void:
 # The headless window is 64x64; give it the design size so touch positions map 1:1 onto the 1280x720 canvas.
 root.size=Vector2i(1280,720)
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 var sound=root.get_node("Sound")
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 await process_frame
 # --- fresh save: onboarding is shown, wording is clean, there is no no-op gender selector ---
 var all=[]
 texts(main,all)
 check(not profile.data.onboarded and all.has("YOUR SIGNAL HAS AWAKENED"),"A fresh save opens the awakening (onboarding) panel")
 check(banned(all).is_empty(),"Onboarding shows no prototype/placeholder wording: "+str(banned(all)))
 var has_option=false
 var stack=[main]
 while not stack.is_empty():
  var n=stack.pop_back()
  if n is OptionButton: has_option=true
  stack.append_array(n.get_children())
 check(not has_option,"Onboarding has no selector that does nothing (the Hero art is fixed)")
 # finish onboarding like a player: press the button
 var begin=null
 stack=[main]
 while not stack.is_empty():
  var n=stack.pop_back()
  if n is Button and n.text=="BEGIN YOUR AWAKENING": begin=n
  stack.append_array(n.get_children())
 check(begin!=null,"BEGIN YOUR AWAKENING button exists")
 begin.pressed.emit()
 await process_frame
 await process_frame
 check(profile.data.onboarded and profile.data.body=="male" and profile.data.energy==60,"Onboarding completes without spending energy")
 main.close_modal()
 # --- wording audit across every menu screen ---
 var screens={"home":func(): main.show_home(),"mission":func(): main.show_mission(),"missions":func(): main.show_missions(),"hero":func(): main.show_hero(),"upgrade":func(): main.show_upgrade(),"settings":func(): main.show_settings(),"codex":func(): main.show_codex()}
 for key in screens:
  main.show_home()
  await process_frame
  screens[key].call()
  await process_frame
  var list=[]
  texts(main,list)
  var bad=banned(list)
  check(bad.is_empty(),"Screen '%s' has no prototype/debug wording %s" % [key,str(bad)])
 for item in ["SUMMON","SHOP","EVENTS","BATTLE PASS","VIP"]:
  main.show_home()
  await process_frame
  var button=null
  var nodes=[main]
  while not nodes.is_empty():
   var n=nodes.pop_back()
   if n is Button and n.text.begins_with(item): button=n
   nodes.append_array(n.get_children())
  button.pressed.emit()
  await process_frame
  var planned_texts=[]
  texts(main,planned_texts)
  var bad_planned=banned(planned_texts,"|not playable|planned feature|in this build")
  check(bad_planned.is_empty() and planned_texts.has("COMING SOON"),"'%s' coming-soon card has no prototype wording %s" % [item,str(bad_planned)])
  main.close_modal()
 profile.data.energy=0
 main.show_home()
 main.start_battle(false)
 await process_frame
 var energy_texts=[]
 texts(main,energy_texts)
 var bad_energy=banned(energy_texts,"|not playable|planned feature|in this build|playable build")
 check(energy_texts.has("ENERGY RECHARGING") and bad_energy.is_empty() and not energy_texts.has("PLANNED FEATURE  /  NOT PLAYABLE YET"),"Out-of-energy card reads as a game message, not a roadmap note %s" % str(bad_energy))
 main.close_modal()
 profile.data.energy=60
 main.show_home()
 await process_frame
 var home_list=[]
 texts(main,home_list)
 check(home_list.has("NOW PLAYING") and not home_list.has("DEVELOPMENT BUILD"),"Home shows NOW PLAYING instead of DEVELOPMENT BUILD")
 # --- settings and audio toggles ---
 main.show_settings()
 await process_frame
 var checks=[]
 stack=[main]
 while not stack.is_empty():
  var n=stack.pop_back()
  if n is CheckButton and n.visible: checks.append(n)
  stack.append_array(n.get_children())
 check(checks.size()==3,"Settings lists Sound, Screen shake and Reduced motion toggles")
 for c in checks:
  c.button_pressed=not c.button_pressed
  c.toggled.emit(c.button_pressed)
 check(profile.data.settings.sound==true and profile.data.settings.shake==false and profile.data.settings.reduced_motion==true,"Each toggle writes its own setting")
 check(profile.backend.read_data().settings.shake==false,"Settings are saved")
 sound.loop("city")
 check(sound.loop_kind=="city","Sound on: ambient loop starts")
 for c in checks:
  c.button_pressed=not c.button_pressed
  c.toggled.emit(c.button_pressed)
 sound.loop("city")
 check(sound.loop_kind=="" and not sound.loop_player.playing,"Sound off: ambient loop stops and stays off")
 profile.data.settings.sound=false
 profile.data.settings.shake=true
 profile.data.settings.reduced_motion=false
 main.close_modal()
 # --- out of energy: the breach explains instead of failing ---
 profile.data.energy=0
 main.start_episode()
 await process_frame
 var ep=main.screen.get_child(0)
 for c in ep.get_children():
  if c.has_method("finish") and not c.has_method("finish_all"): c.finish()
 await create_timer(0.3).timeout
 finish_dialogues(ep)
 await create_timer(0.8).timeout
 ep.set_step(2)
 ep.explore.px=2200.0
 ep.on_interact("breach")
 await create_timer(0.5).timeout
 finish_dialogues(ep)
 await create_timer(2.6).timeout
 finish_dialogues(ep)
 await create_timer(0.8).timeout
 var out_text=[]
 texts(main,out_text)
 check(main.scene_name=="episode" and profile.active_run=="","With no energy the breach does not start a run")
 await create_timer(0.6).timeout
 check(not ep.busy and not ep.explore.locked,"The district is playable again after the no-energy message")
 main.queue_free()
 await process_frame
 # --- first clear then replay rewards ---
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var gold0=int(profile.data.gold)
 profile.begin_run("1-1")
 var first=profile.finish_run(true)
 check(first.first and first.xp==120 and first.gold==250 and int(profile.data.gold)==gold0+250,"First clear pays 120 XP / 250 gold once")
 profile.data.energy=60
 profile.begin_run("1-1")
 var replay=profile.finish_run(true)
 check(not replay.first and replay.xp==55 and replay.gold==100 and profile.data.completed.count("1-1")==1,"Replay pays 55 XP / 100 gold and does not repeat the first clear")
 check(profile.finish_run(true).is_empty(),"Rewards cannot be claimed twice for one run")
 # --- real touch joystick drag: battle ---
 profile.data.energy=60
 profile.data.settings.shake=false
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_battle(true)
 await process_frame
 var b=main.screen.get_child(0)
 b.intro=0
 b.foe.position=Vector2(1000,400)
 b.enemy_wait=99.0
 b.hero.position=Vector2(300,450)
 await process_frame
 var x0=b.hero.position.x
 touch(1,true,Vector2(120,610))
 drag(1,Vector2(190,610),Vector2(70,0))
 for i in range(30):
  await process_frame
 check(b.stick.direction.x>0.7 and b.stick.finger==1,"Touch drag right sets the battle stick direction")
 check(b.hero.position.x>x0+20.0,"Dragging the joystick right moves the Hero right")
 var y0=b.hero.position.y
 drag(1,Vector2(50,540),Vector2(-70,-70))
 for i in range(30):
  await process_frame
 check(b.stick.direction.x<-0.3 and b.stick.direction.y<-0.3 and b.hero.position.y<y0,"Dragging up-left moves the Hero up-left (diagonals work)")
 # second finger presses STRIKE while the first keeps dragging
 var strike=b.controls.attack
 b.foe.position=b.hero.position+Vector2(90,0)
 b.cooldowns.attack=0.0
 var hp0=b.foe.health
 touch(2,true,strike.global_position+strike.size/2.0)
 await process_frame
 await process_frame
 touch(2,false,strike.global_position+strike.size/2.0)
 check(b.foe.health<hp0 and b.stick.finger==1,"A second finger can STRIKE while the joystick finger is still dragging")
 touch(1,false,Vector2(120,540))
 await process_frame
 await process_frame
 var xr=b.hero.position
 for i in range(10):
  await process_frame
 check(b.stick.direction==Vector2.ZERO and b.hero.position.distance_to(xr)<1.0,"Releasing the stick stops the Hero")
 main.queue_free()
 await process_frame
 # --- real touch joystick drag: district ---
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_episode()
 await process_frame
 ep=main.screen.get_child(0)
 for c in ep.get_children():
  if c.has_method("finish") and not c.has_method("finish_all"): c.finish()
 await create_timer(0.3).timeout
 finish_dialogues(ep)
 await create_timer(1.0).timeout
 var ex=ep.explore
 var px0=ex.px
 touch(1,true,Vector2(120,610))
 drag(1,Vector2(200,610),Vector2(80,0))
 for i in range(40):
  await process_frame
 check(ex.stick.direction.x>0.7 and ex.px>px0+20.0,"District: dragging the joystick right walks the Hero right")
 touch(1,false,Vector2(200,610))
 await process_frame
 await process_frame
 var pxr=ex.px
 for i in range(10):
  await process_frame
 check(absf(ex.px-pxr)<0.5,"District: releasing the joystick stops the Hero")
 # ACT button by touch near Mira
 ex.px=470.0
 await create_timer(0.6).timeout
 var act=ex.act_button
 touch(3,true,act.global_position+act.size/2.0)
 await process_frame
 touch(3,false,act.global_position+act.size/2.0)
 await create_timer(0.8).timeout
 check(ep.busy,"District: the ACT touch button starts the conversation with Mira")
 finish_dialogues(ep)
 await create_timer(1.0).timeout
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
