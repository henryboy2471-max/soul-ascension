extends SceneTree
# M2: Episode 2 (Under the Violet Rain) exploration: lock, story order, resonator counter in every order, duplicate protection,
# roof lock, saved progress, Rain Array breach transition, Codex, wording, keyboard and touch input.
var passed=0
var failed=0
var main
var profile
var recorded:Array=[]
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(280.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func on_node(node:Node) -> void:
 if "lines" in node and node.has_method("finish_all"):
  recorded.append("D:"+str(node.lines[0].who)+":"+str(node.lines[0].text).substr(0,40))
 elif "kicker" in node and node.has_method("finish"):
  recorded.append("C:"+str(node.title))
func skip(ep:Node, until_call:Callable, max_frames:int=600) -> void:
 var frames=0
 while frames<max_frames:
  if until_call.call():
   return
  if is_instance_valid(ep):
   for c in ep.get_children():
    if c.has_method("finish_all"): c.finish_all()
    elif c.has_method("finish"): c.finish()
  await process_frame
  frames+=1
func fresh(cleared:bool, progress:Dictionary={}) -> void:
 if main!=null and is_instance_valid(main):
  main.queue_free()
  await process_frame
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 if cleared:
  profile.data.completed=["1-1"]
 if not progress.is_empty():
  profile.data.mission_progress={"1-2":progress}
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
func start(skip_intro:bool=true):
 main.start_episode("1-2")
 await process_frame
 var ep=main.screen.get_child(0)
 await skip(ep,func(): return ep.explore!=null)
 return ep
func resume_state(done:Array=[]) -> Dictionary:
 return {"intro":true,"depot":true,"mira":true,"resonators":done}
func sync(ep, id:String) -> void:
 ep.on_interact(id)
 await skip(ep,func(): return not ep.busy,600)
 await create_timer(0.1).timeout
func texts(node:Node, out:Array) -> void:
 if node is Label or node is Button:
  if node.visible and str(node.text)!="": out.append(str(node.text))
 for c in node.get_children(): texts(c,out)
func key(code:int, pressed:bool) -> void:
 var e=InputEventKey.new()
 e.physical_keycode=code
 e.keycode=code
 e.pressed=pressed
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func touch(index:int, pressed:bool, pos:Vector2) -> void:
 var e=InputEventScreenTouch.new()
 e.index=index
 e.pressed=pressed
 e.position=pos
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func drag(index:int, pos:Vector2) -> void:
 var e=InputEventScreenDrag.new()
 e.index=index
 e.position=pos
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func run() -> void:
 root.size=Vector2i(1280,720)
 profile=root.get_node("Profile")
 # --- locked until 1-1 is cleared ---
 await fresh(false)
 var energy0=int(profile.data.energy)
 main.show_home()
 await process_frame
 main.start_episode("1-2")
 await process_frame
 var t=[]
 texts(main,t)
 check(main.scene_name!="episode" and t.has("EPISODE LOCKED") and profile.mission_progress("1-2").is_empty(),"A fresh save cannot enter Episode 2 (locked card, no progress written)")
 main.close_modal()
 main.show_missions()
 await process_frame
 t=[]
 texts(main,t)
 check(not t.has("PLAY EPISODE 2") and t.has("PLAY EPISODE 1") and main.home_mission()=="1-1","Before clearing 1-1 the menus offer only Episode 1")
 main.close_modal()
 main.show_codex()
 await process_frame
 t=[]
 texts(main,t)
 check(t.has("STORY AND WORLD ENTRIES  /  0 OF 6 FOUND"),"Episode 2 Codex entries stay hidden while it is locked")
 # --- after clearing 1-1: launches, story order ---
 await fresh(true)
 root.get_tree().node_added.connect(on_node)
 var ep=await start()
 check(main.scene_name=="episode" and ep.get_script().get_global_name()=="LanternEpisode" and ep.mission_id=="1-2","After clearing 1-1, Episode 2 launches the Lantern Quarter flow")
 check(recorded.size()>=2 and recorded[0]=="C:UNDER THE VIOLET RAIN" and recorded[1].begins_with("D:NARRATOR:By dawn the storm had not ended"),"Title card, then the opening dialogue about the violet rain and the sleeping civilians")
 var ex=ep.explore
 check(ex.objective_text=="Enter Depot 4" and ex.enabled.depot and not ex.enabled.mira and ex.gate_locked,"Exploration starts with 'Enter Depot 4'; roof gate locked")
 check(int(profile.data.energy)==energy0,"Episode 2 exploration costs no energy")
 # depot -> sleepers -> Mira (+ Pell on the radio)
 ex.px=470.0
 await process_frame
 ep.on_interact("depot")
 await skip(ep,func(): return not ep.busy)
 check(ep.step==1 and ex.objective_text.begins_with("Find Mira Vey") and profile.data.codex.has("sleepers"),"Depot 4: the sleepers are shown, Codex 'sleepers' unlocks, objective moves to Mira")
 var sleepers_count=0
 for w in ex.walkers:
  if w.get("still",false): sleepers_count+=1
 check(sleepers_count==6,"Six sleepers stand still in the depot (existing ambient rigs, no new art)")
 await create_timer(0.5).timeout
 recorded.clear()
 ep.on_interact("mira")
 await process_frame
 var box=null
 for c in ep.get_children():
  if "lines" in c: box=c
 var has_pell=false
 if box!=null:
  for line in box.lines:
   if line.who=="PELL": has_pell=true
 check(has_pell and EpisodeData.SPEAKERS.PELL.portrait=="none","Pell speaks over the radio inside Mira's conversation (dialogue only, no portrait art)")
 await skip(ep,func(): return not ep.busy)
 check(ep.step==2 and profile.data.codex.has("violet_rain") and ex.objective_text=="Resonators Synced 0/3" and ex.counter_total==3 and ex.counter_done==0,"Mira's briefing unlocks 'violet_rain' and starts 'Resonators Synced 0/3'")
 check(ex.gate_locked and not ex.props.lantern_state.roof_open and not ex.enabled.array,"Roof stays locked at 0/3")
 # optional lore notice does not disturb the objective
 await create_timer(0.5).timeout
 ep.on_interact("notice")
 await skip(ep,func(): return not ep.busy)
 check(ep.step==2 and ex.counter_done==0 and profile.data.codex.has("rain_array") and ep.progress.get("notice",false),"The optional Meridian notice gives lore and Codex 'rain_array' without advancing the story")
 # --- hold-to-sync with the real hold input, counter 1/3 -> 3/3 ---
 await create_timer(0.5).timeout
 ex.px=1350.0
 await process_frame
 ex.act_button.held=true
 var started=Time.get_ticks_msec()
 while not ep.busy and Time.get_ticks_msec()-started<4000:
  await process_frame
 var held=(Time.get_ticks_msec()-started)/1000.0
 ex.act_button.held=false
 check(ep.busy and held>1.0 and held<3.0,"A resonator needs a sustained hold, not a tap")
 await skip(ep,func(): return not ep.busy)
 check(ep.synced==["res_a"] and ex.objective_text=="Resonators Synced 1/3" and ex.counter_done==1 and ex.gate_locked,"First resonator: counter 1/3, roof still locked")
 check(recorded.any(func(s): return s.begins_with("D:SYSTEM:Resonator synced")),"The sync reveals a short sleeper memory")
 await sync(ep,"res_c")
 check(ep.synced==["res_a","res_c"] and ex.objective_text=="Resonators Synced 2/3" and ex.gate_locked and not ex.props.lantern_state.roof_open and not ex.enabled.array,"Second resonator: counter 2/3, roof still locked")
 # Rain Array cannot open the breach before 3/3
 ep.on_interact("array")
 await skip(ep,func(): return not ep.busy)
 check(not ex.props.breach_open and not ep.progress.get("array",false) and main.scene_name=="episode","The Rain Array cannot open the breach before 3/3")
 # duplicate activation cannot count twice
 ep.on_interact("res_a")
 await skip(ep,func(): return not ep.busy)
 ep.on_interact("res_c")
 await skip(ep,func(): return not ep.busy)
 check(ep.synced.size()==2 and ex.counter_done==2,"Re-activating a synced resonator does not increment the counter")
 # saved partial progress is on disk
 var saved=profile.backend.read_data().mission_progress["1-2"]
 check(saved.resonators==["res_a","res_c"] and saved.get("mira",false) and saved.get("depot",false),"Partial progress is written to the save file")
 # --- resume restores which resonators are synced ---
 recorded.clear()
 main.show_home()
 await process_frame
 ep=await start()
 ex=ep.explore
 check(not recorded.any(func(s): return s.begins_with("C:")),"Returning to the mission skips the title card and opening scene")
 check(ep.synced==["res_a","res_c"] and ex.counter_done==2 and ex.objective_text=="Resonators Synced 2/3" and ex.props.lantern_state.synced==[true,false,true],"Resume restores 2/3 and the lit resonators")
 check(not ex.enabled.res_a and not ex.enabled.res_c and ex.enabled.res_b and ex.objective_targets==[1750.0],"Only the unsynced resonator is still active and is the waypoint")
 # third resonator: 3/3, roof unlocks exactly now
 ex.px=1750.0
 await process_frame
 ep.on_interact("res_b")
 await create_timer(0.8).timeout
 check(ex.objective_text=="Resonators Synced 3/3" and ex.counter_done==3 and not ex.gate_locked and ex.props.lantern_state.roof_open and ex.enabled.array,"Third resonator: the counter reads 3/3 and the roof unlocks exactly at 3/3")
 await skip(ep,func(): return not ep.busy)
 check(ep.step==3 and ex.objective_text=="Climb to the Rain Array" and profile.mission_progress("1-2").resonators.size()==3,"Roof access objective follows; 3/3 is saved")
 # roof access: walking past the gate is now possible
 ex.px=2300.0
 await process_frame
 ex.stick.direction=Vector2(1,0)
 await create_timer(1.0).timeout
 ex.stick.direction=Vector2.ZERO
 check(ex.px>2420.0,"With the roof open the Hero can walk past the gate")
 # Rain Array opens the breach (no combat)
 ex.px=2600.0
 await process_frame
 var scene_before=main.scene_name
 ep.on_interact("array")
 await skip(ep,func(): return ep.step==4,900)
 check(scene_before=="episode" and main.scene_name=="episode" and ep.step==4 and profile.mission_progress("1-2").get("array",false) and profile.active_run=="" and int(profile.data.energy)==energy0,"The Rain Array opens the breach; exploration stays free: no battle, no energy spent")
 check(profile.data.codex.has("violet_rain") and profile.data.codex.has("sleepers") and profile.data.codex.has("rain_array") and not profile.data.codex.has("hollow_cantor"),"Codex: violet_rain, sleepers and rain_array unlocked; hollow_cantor stays locked until the Cantor falls")
 main.show_codex()
 await process_frame
 t=[]
 texts(main,t)
 check(t.has("VIOLET RAIN") and t.has("THE SLEEPERS") and t.has("RAIN ARRAY 7"),"The Codex screen lists the three Episode 2 entries")
 main.close_modal()
 # resuming after the breach shows the portal open
 ep=await start()
 check(ep.explore.props.breach_open and ep.step==4,"Returning after the breach opened shows it open")
 root.get_tree().node_added.disconnect(on_node)
 # --- all six possible orders reach 3/3 with the roof locked until the last one ---
 var orders=[["res_a","res_b","res_c"],["res_a","res_c","res_b"],["res_b","res_a","res_c"],["res_b","res_c","res_a"],["res_c","res_a","res_b"],["res_c","res_b","res_a"]]
 var all_ok=true
 for order in orders:
  await fresh(true,resume_state())
  ep=await start()
  ex=ep.explore
  var ok=ex.counter_done==0 and ex.gate_locked
  for i in range(3):
   ep.on_interact(order[i])
   await skip(ep,func(): return not ep.busy)
   await create_timer(0.05).timeout
   ok=ok and ep.synced.size()==i+1 and (ex.counter_done==i+1 or i==2)
   if i<2:
    ok=ok and ex.gate_locked and not ex.props.lantern_state.roof_open and not ex.enabled.array
   else:
    ok=ok and not ex.gate_locked and ex.props.lantern_state.roof_open and ex.enabled.array and ep.step==3
  if not ok:
   all_ok=false
   print("INFO: order failed ",order)
 check(all_ok,"All six orders of the three resonators reach 3/3 (roof locked at 0, 1 and 2)")
 # --- the locked gate blocks walking and explains itself ---
 await fresh(true,resume_state(["res_a"]))
 ep=await start()
 ex=ep.explore
 ex.px=2300.0
 await process_frame
 ex.stick.direction=Vector2(1,0)
 await create_timer(1.2).timeout
 ex.stick.direction=Vector2.ZERO
 check(ex.px<=2420.0-39.0,"At 1/3 the roof gate stops the Hero")
 recorded.clear()
 root.get_tree().node_added.connect(on_node)
 ep.on_interact("gate")
 await process_frame
 await skip(ep,func(): return not ep.busy)
 check(recorded.any(func(s): return s.begins_with("D:GATE:Roof access locked")),"The locked gate explains what is needed")
 root.get_tree().node_added.disconnect(on_node)
 # --- keyboard navigation ---
 await fresh(true,{"intro":true})
 ep=await start()
 ex=ep.explore
 var x0=ex.px
 key(KEY_D,true)
 await create_timer(0.6).timeout
 key(KEY_D,false)
 check(ex.px-x0>120.0,"Keyboard: D walks the Hero right in the Lantern Quarter")
 ex.px=470.0
 await process_frame
 await create_timer(0.6).timeout
 key(KEY_E,true)
 key(KEY_E,false)
 await create_timer(0.4).timeout
 check(ep.busy,"Keyboard: E interacts at Depot 4")
 await skip(ep,func(): return not ep.busy)
 # --- touch navigation: real touch events for the stick and the ACT button ---
 await fresh(true,{"intro":true})
 ep=await start()
 ex=ep.explore
 x0=ex.px
 touch(1,true,Vector2(120,610))
 drag(1,Vector2(200,610))
 await create_timer(0.6).timeout
 check(ex.stick.direction.x>0.7 and ex.px-x0>100.0,"Touch: dragging the joystick walks the Hero right")
 touch(1,false,Vector2(200,610))
 await process_frame
 ex.px=470.0
 await create_timer(0.7).timeout
 var act=ex.act_button
 touch(2,true,act.global_position+act.size/2.0)
 await process_frame
 touch(2,false,act.global_position+act.size/2.0)
 await create_timer(0.5).timeout
 check(ep.busy,"Touch: the ACT button interacts at Depot 4")
 await skip(ep,func(): return not ep.busy)
 # --- wording ---
 var bad=[]
 var re=RegEx.new()
 re.compile("(?i)(prototype|placeholder|debug|todo|lorem|\\bm[1-4]\\b|\\bwip\\b|not playable)")
 for list in [Episode2Data.INTRO,Episode2Data.DEPOT,Episode2Data.MIRA_TALK,Episode2Data.MIRA_REPEAT,Episode2Data.MEMORY_A,Episode2Data.MEMORY_B,Episode2Data.MEMORY_C,Episode2Data.GATE_UNLOCK,Episode2Data.GATE_LOCKED,Episode2Data.NOTICE,Episode2Data.ARRAY]:
  for line in list:
   if not EpisodeData.SPEAKERS.has(line.who) or re.search(str(line.text))!=null: bad.append(line)
 check(bad.is_empty(),"Episode 2 script uses known speakers and has no prototype wording %s" % str(bad.size()))
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
