extends RefCounted
# Records everything a player can observe while playing Episode 1 (story order, objectives, cards, dialogue, toasts, battle waves,
# rewards, menu and result texts) as one list of strings. The golden copy in tests/golden/episode1_trace.json was recorded from the
# unmodified Episode 1 (commit 80f54c3); tests compare a fresh trace against it, so any behaviour change shows up as a diff.
# Duck-typed on purpose: --script tests cannot reference class_name types that use autoloads.
var events:Array=[]
var tree:SceneTree
var last_objective=""
var last_toast=""
var seen_ids:Array=[]
func log(line:String) -> void:
 events.append(line)
func texts(node:Node, out:Array) -> void:
 if node is Label or node is Button or node is CheckButton:
  if node.visible and str(node.text)!="":
   out.append(str(node.text))
 for c in node.get_children():
  texts(c,out)
func snapshot(label:String, node:Node) -> void:
 var list=[]
 texts(node,list)
 events.append("SCREEN "+label+" :: "+" | ".join(list))
func on_node(node:Node) -> void:
 if "lines" in node and node.has_method("finish_all"):
  var parts=[]
  for line in node.lines:
   parts.append(str(line.who)+": "+str(line.text))
  events.append("DIALOGUE ["+str(node.lines.size())+"] "+" // ".join(parts))
 elif "kicker" in node and node.has_method("finish"):
  events.append("CARD "+str(node.kicker)+" | "+str(node.title)+" | "+str(node.subtitle)+" | art="+str(node.use_art)+" | "+str(node.duration))
func poll(ep) -> void:
 if is_instance_valid(ep) and ep.explore!=null:
  var ex=ep.explore
  var obj=str(ex.objective_text)+"@"+str(ex.target_x)
  if obj!=last_objective:
   last_objective=obj
   events.append("OBJECTIVE "+obj)
  var toast=str(ex.toast_label.text)
  if toast!=last_toast and toast!="":
   last_toast=toast
   events.append("TOAST "+toast)
func skip(ep:Node, until_call:Callable, max_frames:int=900) -> void:
 var frames=0
 while frames<max_frames:
  poll(ep)
  if until_call.call():
   return
  if is_instance_valid(ep):
   for c in ep.get_children():
    if c.has_method("finish_all"): c.finish_all()
    elif c.has_method("finish"): c.finish()
  await tree.process_frame
  frames+=1
func waves_summary(battle) -> void:
 for w in battle.waves:
  events.append("WAVE %s | %s | hp=%s atk=%s def=%s look=%s accent=%s scale=%s boss=%s | card=%s | %s" % [w.name,w.sub,w.hp,w.atk,w.def,w.look,w.accent.to_html(),w.scale,w.boss,w.card,w.card_sub])
func run(root:Window, main) -> Array:
 tree=root.get_tree()
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.data.energy=60
 tree.node_added.connect(on_node)
 main.close_modal()
 main.show_home()
 await tree.process_frame
 snapshot("home-fresh",main)
 main.show_mission()
 await tree.process_frame
 snapshot("mission-modal",main)
 main.close_modal()
 main.show_missions()
 await tree.process_frame
 snapshot("missions-fresh",main)
 main.close_modal()
 main.show_codex()
 await tree.process_frame
 snapshot("codex-fresh",main)
 main.close_modal()
 events.append("ENERGY-START %d" % int(profile.data.energy))
 main.start_episode()
 await tree.process_frame
 var ep=main.screen.get_child(0)
 await skip(ep,func(): return ep.explore!=null)
 var ex=ep.explore
 events.append("EXPLORE spots=%s" % str(ex.spots.map(func(s): return str(s.id)+"@"+str(s.x)+":"+str(s.label)+":"+str(s.kind)+":"+str(s.range))))
 # optional lore spots, then the main chain in story order
 ex.px=1860.0
 await tree.process_frame
 ex.act_edge=true
 await skip(ep,func(): return not ep.busy and ep.explore.act_block<=0.0 or false,300)
 await tree.create_timer(0.55).timeout
 ex.px=1050.0
 await tree.process_frame
 ex.act_edge=true
 await skip(ep,func(): return false,40)
 await skip(ep,func(): return not ep.busy,300)
 await tree.create_timer(0.55).timeout
 ex.px=540.0
 await tree.process_frame
 ex.act_edge=true
 await skip(ep,func(): return false,40)
 await skip(ep,func(): return not ep.busy,300)
 events.append("STEP %d" % ep.step)
 await tree.create_timer(0.55).timeout
 ex.px=540.0
 ex.act_edge=true
 await skip(ep,func(): return false,40)
 await skip(ep,func(): return not ep.busy,300)
 await tree.create_timer(0.55).timeout
 ex.px=1560.0
 await tree.process_frame
 ex.act_button.held=true
 var started=Time.get_ticks_msec()
 while not ep.busy and Time.get_ticks_msec()-started<4000:
  poll(ep)
  await tree.process_frame
 ex.act_button.held=false
 await skip(ep,func(): return not ep.busy,300)
 events.append("STEP %d breach_open=%s" % [ep.step,str(ex.props.breach_open)])
 # no energy: the breach explains instead of starting a run
 await tree.create_timer(0.55).timeout
 profile.data.energy=0
 ex.px=2200.0
 await tree.process_frame
 ex.act_edge=true
 await skip(ep,func(): return false,40)
 await skip(ep,func(): return ep.step==2 and not ep.busy and not ex.locked,600)
 events.append("NO-ENERGY scene=%s run=%s" % [main.scene_name,profile.active_run])
 profile.data.energy=60
 await tree.create_timer(0.55).timeout
 ex.act_edge=true
 await skip(ep,func(): return main.scene_name=="battle",900)
 events.append("BATTLE scene=%s run=%s energy=%d" % [main.scene_name,profile.active_run,int(profile.data.energy)])
 var battle=main.screen.get_child(0)
 battle.intro=0
 events.append("BOSS-MODE %s" % str(battle.boss_mode))
 waves_summary(battle)
 events.append("FOE-1 %s %s" % [battle.foe.look,str(battle.foe.max_health)])
 battle.foe.receive(100000)
 await tree.create_timer(0.4).timeout
 battle.intro=0
 events.append("FOE-2 %s %s wave=%d" % [battle.foe.look,str(battle.foe.max_health),battle.wave])
 battle.foe.health=battle.foe.max_health*0.45
 await tree.process_frame
 await tree.process_frame
 events.append("PHASE %d attack=%s telegraph=%s recovery=%s" % [battle.phase,str(battle.foe.attack),str(battle.telegraph_len),str(battle.recovery)])
 battle.foe.receive(100000)
 await tree.create_timer(2.0).timeout
 events.append("AFTER-BOSS scene=%s" % main.scene_name)
 var ending=main.screen.get_child(0)
 await skip(ending,func(): return main.scene_name=="result",900)
 await tree.create_timer(0.3).timeout
 snapshot("result-first-clear",main)
 events.append("REWARD gold=%d xp=%d level=%d completed=%s codex=%s energy=%d" % [int(profile.data.gold),int(profile.data.xp),int(profile.data.level),str(profile.data.completed),str(profile.data.codex),int(profile.data.energy)])
 main.show_home()
 await tree.process_frame
 snapshot("home-cleared",main)
 main.show_missions()
 await tree.process_frame
 snapshot("missions-cleared",main)
 main.close_modal()
 main.show_codex()
 await tree.process_frame
 snapshot("codex-cleared",main)
 main.close_modal()
 # replay through the battle-only path
 var gold1=int(profile.data.gold)
 var xp1=int(profile.data.xp)
 main.start_battle(false)
 await tree.process_frame
 var replay=main.screen.get_child(0)
 replay.intro=0
 events.append("REPLAY-BOSS-MODE %s" % str(replay.boss_mode))
 waves_summary(replay)
 replay.foe.receive(100000)
 await tree.create_timer(2.2).timeout
 snapshot("result-replay",main)
 events.append("REPLAY-REWARD gold+=%d xp+=%d completed=%s" % [int(profile.data.gold)-gold1,int(profile.data.xp)-xp1,str(profile.data.completed)])
 tree.node_added.disconnect(on_node)
 return events
