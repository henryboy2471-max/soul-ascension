extends SceneTree
# M4: Episode 2 ending: calm Soul Realm, Lantern Quarter aftermath, completion + rewards, NEXT EPISODE teaser, reload/idempotence.
var passed=0
var failed=0
var main
var profile
var recorded:Array=[]
var snap:Dictionary={}
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
const READY={"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true}
func fresh(progress:Dictionary=READY) -> void:
 if main!=null and is_instance_valid(main):
  main.queue_free()
  await process_frame
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.data.completed=["1-1"]
 profile.active_run=""
 if not progress.is_empty():
  profile.data.mission_progress={"1-2":progress.duplicate(true)}
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
func start():
 main.start_episode("1-2")
 await process_frame
 var ep=main.screen.get_child(0)
 await skip(ep,func(): return ep.explore!=null)
 return ep
func spot_label(ep:Node, id:String) -> String:
 for sp in ep.explore.spots:
  if sp.id==id: return str(sp.label)
 return ""
func prompt_of(ep:Node):
 for c in ep.get_children():
  if c.has_method("decide") and "paid" in c: return c
 return null
# Walks to the breach, opens the confirmation and returns it (not decided yet).
func open_prompt(ep):
 ep.explore.px=2600.0
 await process_frame
 ep.on_interact("breach")
 var guard=0
 while prompt_of(ep)==null and guard<60:
  await process_frame
  guard+=1
 var prompt=prompt_of(ep)
 if prompt!=null:
  prompt.armed=0.0
 return prompt
# Full entry: breach-ready save, enough energy, confirm. Returns the Battle.
func enter_battle(energy:int=60):
 await fresh()
 profile.data.energy=energy
 profile.data.energy_at=int(Time.get_unix_time_from_system())
 var ep=await start()
 var prompt=await open_prompt(ep)
 prompt.decide(true)
 await process_frame
 await process_frame
 var battle=main.screen.get_child(0)
 return battle
func skip_intro(battle) -> void:
 battle.skip_whispers()
 battle.intro=0.0
 battle.tip.text=""
func kill_foe(battle) -> void:
 battle.foe.receive(1000000.0)
 await create_timer(0.8).timeout
func Progression_required(level:int) -> int:
 return 100+(level-1)*65
func _levels_xp(from_level:int, to_level:int) -> int:
 var total=0
 for l in range(from_level,to_level):
  total+=Progression_required(l)
 return total
func on_node(node:Node) -> void:
 if "lines" in node and node.has_method("finish_all"):
  for line in node.lines:
   recorded.append("D:"+str(line.who)+":"+str(line.text))
 elif "kicker" in node and node.has_method("finish"):
  recorded.append("C:"+str(node.title))
# Skips dialogue boxes / cards every frame until cond is true (real-time limited: the ending uses real timers).
func drive(cond:Callable, seconds:float=60.0) -> bool:
 var t0=Time.get_ticks_msec()
 while Time.get_ticks_msec()-t0<seconds*1000.0:
  if cond.call():
   return true
  var ep=main.screen.get_child(0) if main.screen.get_child_count()>0 else null
  if ep!=null:
   for c in ep.get_children():
    if c.has_method("finish_all"): c.finish_all()
    elif c.has_method("finish"): c.finish()
   if ep.get("explore")!=null and is_instance_valid(ep.explore) and "props" in ep.explore and recorded.any(func(s): return s.begins_with("D:VAUST")) and snap.is_empty():
    var st=ep.explore.props.lantern_state
    snap={"rain":st.rain,"calm":st.calm,"broadcast":st.broadcast,"synced":st.synced.duplicate(),"closing":ep.explore.props.breach_closing,"completed":profile.data.completed.duplicate(),"scene":main.scene_name}
  await process_frame
 return cond.call()
func start_ending_from_battle(energy:int=60):
 # real flow: breach prompt -> battle -> both foes down; returns when the ending scene starts
 var battle=await enter_battle(energy)
 skip_intro(battle)
 await kill_foe(battle)
 skip_intro(battle)
 battle.intro=0.0
 battle.foe.receive(1000000.0)
 var guard=0
 while main.scene_name!="ending" and guard<400:
  await create_timer(0.1).timeout
  guard+=1
 return battle
func result_texts() -> Array:
 var t=[]
 texts(main,t)
 return t
func run() -> void:
 root.size=Vector2i(1280,720)
 profile=root.get_node("Profile")
 root.get_tree().node_added.connect(on_node)
 # ---------------- Cantor defeat -> ending (not completed yet) ----------------
 recorded.clear()
 await start_ending_from_battle(60)
 check(main.scene_name=="ending" and not profile.data.completed.has("1-2"),"Cantor defeat starts the ending; mission 1-2 is not completed yet")
 var gold0=int(profile.data.gold)
 var level0=int(profile.data.level)
 var xp0=int(profile.data.xp)
 check(int(profile.data.energy)==54 and profile.active_run=="1-2" and profile.mission_progress("1-2").get("battle_won",false) and not profile.mission_progress("1-2").has("combat_run"),"Energy stays at 54 (already paid); battle_won saved, combat_run cleared")
 check(profile.data.codex.has("hollow_cantor"),"Hollow Cantor Codex entry is kept")
 # ---------------- drive the ending to the rewards screen ----------------
 var reached=await drive(func(): return main.scene_name=="result",90.0)
 check(reached,"The ending sequence plays through to the rewards screen")
 var lines=recorded.filter(func(s): return s.begins_with("D:"))
 var order=[]
 for key in ["The bell stops","Echo. Say something","I'm here. It wasn't","The resonators held","Somebody wrote that chorus","Rain Array 7. Think about","Then we follow the signal","Come home first","The breach folds shut","...The voice stopped","Depot 4 to Mira","Citizens of Neon District","1 ASCENDANT FLAGGED","...They have your name","Then they've been listening"]:
  var idx=-1
  for n in range(lines.size()):
   if lines[n].contains(key):
    idx=n
    break
  order.append(idx)
 var in_order=true
 for n in range(order.size()):
  if order[n]<0 or (n>0 and order[n]<=order[n-1]): in_order=false
 print("INFO order ",order)
 check(in_order,"Story order: calm realm (bell stops, Mira, resonators, Cantor was a chorus, six more arrays) then the Lantern Quarter (breach shuts, sleeper, Pell, Vaust broadcast, registry, Mira)")
 check(not snap.is_empty() and snap.rain<0.5 and snap.calm and snap.broadcast>0.9 and snap.synced==[true,true,true] and snap.closing,"Aftermath: rain settled (0.45), resonators steady and all synced, breach closing, Meridian screens lit")
 check(not snap.completed.has("1-2") and snap.scene=="ending","Completion is not recorded while the ending is still playing")
 # ---------------- completion + rewards ----------------
 check(profile.data.completed.has("1-2") and profile.data.completed.count("1-2")==1,"Mission 1-2 is completed after the sequence finishes (once)")
 check(int(profile.data.gold)==gold0+300,"First clear pays 300 gold")
 var xp_total=xp0
 for l in range(level0,int(profile.data.level)):
  xp_total+=Progression_required(l)
 xp_total=xp_total-xp0
 check(int(profile.data.xp)+_levels_xp(level0,int(profile.data.level))-xp0==150,"First clear pays 150 XP")
 var t=result_texts()
 check(t.has("MISSION COMPLETE") and t.has("THE CHORUS FALLS SILENT") and t.has("+150") and t.has("+300") and t.has("NEXT EPISODE"),"Rewards screen shows +150 XP, +300 gold and NEXT EPISODE")
 var prog=profile.mission_progress("1-2")
 check(profile.active_run=="" and not prog.has("combat_run") and not prog.has("battle_won") and prog.flags.cantor_defeated and prog.flags.ending_seen and prog.flags.arrays_remaining==6 and prog.flags.amnesty_declared,"Run cleared; story flags saved; pending flags consumed")
 check(prog.resonators.size()==3 and prog.get("array",false) and profile.data.codex.has("hollow_cantor"),"Resonator progress and the Hollow Cantor Codex entry are preserved")
 var saved=profile.backend.read_data()
 check(saved.completed.has("1-2") and int(saved.gold)==gold0+300 and saved.mission_progress["1-2"].flags.ending_seen,"Completion is saved to disk")
 # idempotence: settling again changes nothing
 var gold1=int(profile.data.gold)
 main.show_result(true)
 var again=profile.finish_run(true)
 profile.mark_battle_won("1-2")
 check(again.is_empty() and int(profile.data.gold)==gold1 and profile.data.completed.count("1-2")==1 and not profile.mission_progress("1-2").has("battle_won"),"Settling twice cannot duplicate rewards or story state")
 # ---------------- teaser ----------------
 recorded.clear()
 main.show_result(true)
 check(main.scene_name=="result","(result screen stays idempotent: no duplicate rewards even when re-shown)")
 profile.active_run=""
 # Go through the real button on a fresh result screen state
 await fresh({"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true,"battle_won":true})
 profile.active_run="1-2"
 main.current_mission="1-2"
 main.show_result(true)
 await process_frame
 var next_button=null
 for c in main.screen.get_children():
  if c is Button and c.text=="NEXT EPISODE": next_button=c
 check(next_button!=null,"The rewards screen offers a NEXT EPISODE button")
 next_button.pressed.emit()
 await process_frame
 await process_frame
 check(main.scene_name=="teaser" and recorded.any(func(s): return s=="C:EPISODE 3  /  THE RELAY KEEPER"),"NEXT EPISODE plays the Episode 3 teaser card")
 var card=main.screen.get_child(0)
 check(card.subtitle=="SIX ARRAYS REMAIN" and card.kicker=="NEXT EPISODE","Teaser hints at the next threat (six more arrays) without explaining it")
 card.finish()
 await create_timer(0.8).timeout
 check(main.scene_name=="home","The teaser returns cleanly to the home screen")
 # ---------------- reload mid-ending cannot duplicate or re-charge ----------------
 await fresh({"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true,"battle_won":true})
 profile.data.energy=54
 profile.data.energy_at=int(Time.get_unix_time_from_system())
 profile.data.codex.append("hollow_cantor")
 profile.persist()
 gold0=int(profile.data.gold)
 for reload in range(2):
  main.queue_free()
  await process_frame
  profile.active_run=""
  profile._ready()
  main=load("res://scenes/main.tscn").instantiate()
  root.add_child(main)
  await process_frame
  main.close_modal()
  main.start_episode("1-2")
  await process_frame
  check(main.scene_name=="ending" and profile.active_run=="1-2" and int(profile.data.energy)==54 and not profile.data.completed.has("1-2"),"Reload %d during the ending resumes the ending: no fight, no energy charge, nothing paid yet" % (reload+1))
  await create_timer(0.5).timeout
 snap={}
 recorded.clear()
 reached=await drive(func(): return main.scene_name=="result",90.0)
 check(reached and int(profile.data.gold)==gold0+300 and profile.data.completed.count("1-2")==1 and int(profile.data.energy)==54,"After reloading twice mid-ending the rewards are paid exactly once and energy is untouched")
 # reload after completion: no ending, no rewards, no charge
 main.queue_free()
 await process_frame
 profile.active_run=""
 profile._ready()
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 gold1=int(profile.data.gold)
 var done_state=main.start_episode("1-2")
 await process_frame
 check(main.scene_name=="episode" and not profile.begin_ending("1-2") and int(profile.data.gold)==gold1 and int(profile.data.energy)==54 and profile.data.completed.count("1-2")==1,"Reloading after completion does not replay the ending, pay again or charge energy")
 var ep=main.screen.get_child(0)
 await skip(ep,func(): return ep.explore!=null)
 check(ep.step==4 and profile.mission_progress("1-2").flags.ending_seen,"A completed Episode 2 reopens at the breach (replay) with its story flags intact")
 main.show_home()
 await process_frame
 t=result_texts()
 check(t.any(func(s): return s.begins_with("CLEARED") and s.contains("REPLAY +65 XP") and s.contains("+120 GOLD")),"Home shows the Episode 2 replay rewards (65 XP / 120 gold) once cleared")
 # ---------------- replay: replay rewards only ----------------
 main.current_mission="1-2"
 check(profile.begin_run("1-2") and int(profile.data.energy)==48,"Replay entry charges 6 again (a new run)")
 main.on_battle_finished(true,true)
 await process_frame
 check(main.scene_name=="ending" and profile.mission_progress("1-2").get("battle_won",false),"Replay win plays the ending again")
 snap={}
 gold1=int(profile.data.gold)
 reached=await drive(func(): return main.scene_name=="result",90.0)
 check(reached and int(profile.data.gold)==gold1+120 and profile.data.completed.count("1-2")==1,"Replay pays the replay reward (120 gold) and does not repeat the first clear")
 t=result_texts()
 check(t.has("+65") and t.has("+120"),"Replay rewards screen shows +65 XP / +120 gold")
 # ---------------- Codex ----------------
 main.show_codex()
 await process_frame
 t=result_texts()
 check(t.any(func(x): return x.begins_with("A choir of every sleeper")) and t.any(func(x): return x.begins_with("STORY AND WORLD ENTRIES") and x.contains("OF 10 FOUND")),"Codex lists the found Hollow Cantor entry among 10")
 main.close_modal()
 # ---------------- wording ----------------
 var bad=[]
 var re=RegEx.new()
 re.compile("(?i)(prototype|placeholder|debug|todo|lorem|\\bm[1-4]\\b|\\bwip\\b|not playable|pending)")
 var speakers=load("res://scripts/story/episode_data.gd").SPEAKERS
 var data=load("res://scripts/story/episode2_data.gd")
 for name in ["ENDING_REALM","ENDING_RETURN_A","ENDING_RETURN_B"]:
  for line in data.get(name):
   if not speakers.has(line.who) or re.search(line.text) or line.text.length()>300: bad.append(line.text.substr(0,30))
 check(bad.is_empty(),"Ending script uses known speakers, stays concise and has no prototype wording %s" % str(bad))
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
