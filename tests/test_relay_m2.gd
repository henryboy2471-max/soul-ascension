extends SceneTree
# Episode 3 M2 (investigation): dialogue/clue data, gating, quest tracking, hidden spots, optional quests, codex, tower unlock, saves/resume.
# Episode3Data/ZoneDefs are pure (no autoloads) so the rules are tested directly; the episode flow runs the real RelayEpisode scene.
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
 create_timer(120.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node) -> void:
 if is_instance_valid(ep):
  for c in ep.get_children():
   if c.has_method("finish_all"):
    c.finish_all()
   elif c.has_method("finish"):
    c.finish()
 await process_frame
func wait_idle(ep:Node, max_frames:int=1500) -> void:
 var n=0
 while n<max_frames and (ep.busy or ep.traveling or not is_instance_valid(ep.explore)):
  await skip_scenes(ep)
  n+=1
func act(ep:Node, id:String) -> void:
 ep.on_interact(id)
 await wait_idle(ep)
# apply respond() to a clue list the way the episode does
func apply(id:String, clues:Array, unlocks:Array) -> void:
 var r=Episode3Data.respond(id,clues)
 for c in r.add:
  if not clues.has(c): clues.append(c)
 if r.unlock!="" and not unlocks.has(r.unlock): unlocks.append(r.unlock)
func all_spots() -> Array:
 var out=[]
 for z in ZoneDefs.zones():
  for sp in ZoneDefs.zone(z).spots:
   if not sp.has("exit"): out.append(sp.id)
 return out
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 profile.data.mission_progress={"1-2":{"intro":true,"sentinel":7}}
 var ep2_before=profile.data.mission_progress["1-2"].duplicate(true)
 # ---- data: every interaction has real content
 var spots=all_spots()
 var empty=[]
 var placeholder=[]
 var known_codex=[]
 for e in Episode3Data.CODEX: known_codex.append(e.id)
 var codex_ok=true
 for id in spots:
  var r=Episode3Data.respond(id,[])
  if r.lines.is_empty() or str(r.lines[0].text)=="Nothing here.": empty.append(id)
  for l in r.lines:
   if str(l.text).contains("placeholder"): placeholder.append(id)
   if not (l.who in ["NARRATOR","PLAYER","MIRA"] or Episode3Data.SPEAKERS.has(l.who)): codex_ok=false
  for c in r.codex:
   if not known_codex.has(c): codex_ok=false
 check(empty.is_empty() and placeholder.is_empty(),"All %d interactions have written dialogue (no placeholders)%s" % [spots.size(),str(empty+placeholder)])
 check(codex_ok,"Every speaker has a style and every Codex id the dialogue unlocks exists")
 var mission_codex=MissionDefs.get_def("1-3").codex
 var all_in_mission=true
 for id in known_codex:
  if not mission_codex.has(id): all_in_mission=false
 check(all_in_mission,"Mission 1-3 lists all its Codex entries (hidden until Episode 2 is cleared)")
 # ---- gating: the order matters only where the story needs it
 check(Episode3Data.respond("records",[]).add.is_empty() and Episode3Data.respond("records",["terminal"]).add.is_empty(),"The records give nothing until Anselm has admitted where they are")
 check(not Episode3Data.respond("anselm",[]).add.has("anselm_admits") and Episode3Data.respond("anselm",["terminal"]).add.has("anselm_admits"),"Anselm only admits it after the terminal log is found")
 check(Episode3Data.respond("decoder",["tx_1","tx_2","tx_3"]).add.is_empty() and Episode3Data.respond("decoder",["tx_1","tx_2"]).add.is_empty() and Episode3Data.respond("decoder",["teo_met","tx_1","tx_2"]).add.is_empty() and Episode3Data.respond("decoder",["teo_met","tx_1","tx_2","tx_3"]).add==["decoded"],"The decoder needs Teo's permission and all three transmissions")
 check(Episode3Data.respond("board",["teo_met","decoded"]).unlock=="" and Episode3Data.respond("board",["teo_met","decoded","records"]).unlock=="tower","The evidence board lists what is missing and only opens the tower with decoded signals, the registry and Teo")
 var missing=Episode3Data.respond("board",["teo_met"]).lines[0].text
 check(missing.contains("decoded signals") and missing.contains("old registry") and not missing.contains("Anselm"),"The board's feedback names the gaps without giving the solution away")
 check(Episode3Data.respond("registry_hidden",[]).add.is_empty() and Episode3Data.respond("registry_hidden",["records"]).add==["hidden_registry"],"The hidden registry panel only yields after the old records are found")
 check(Episode3Data.respond("pip",["pip_met","frag_1","frag_2"]).add.is_empty() and Episode3Data.respond("pip",["pip_met","frag_1","frag_2","frag_3"]).add==["pip_done"],"Pip's quest completes only with all three memory marks")
 # ---- solvable in any order: shuffle every interaction repeatedly
 var rng=RandomNumberGenerator.new()
 rng.seed=3
 var always=true
 var main_ids=spots.duplicate()
 for trial in range(60):
  var clues=[]
  var unlocks=[]
  var order=main_ids.duplicate()
  for pass_n in range(6):
   for i in range(order.size()-1,0,-1):
    var j=rng.randi_range(0,i)
    var t=order[i]; order[i]=order[j]; order[j]=t
   for id in order: apply(id,clues,unlocks)
  if not (clues.has("theory") and unlocks.has("tower") and clues.has("pip_done") and clues.has("hidden_registry") and clues.has("journal")): always=false
 check(always,"60 random orders of every interaction always reach the theory, open the tower and finish both optional quests (no dead ends)")
 # main path only (no optional content) still opens the tower
 var clues=[]
 var unlocks=[]
 for id in ["signal_1","signal_2","signal_3","terminal_a","anselm","records","teo","decoder","board"]: apply(id,clues,unlocks)
 check(unlocks.has("tower") and not clues.has("pip_done") and not clues.has("hidden_registry") and not clues.has("journal"),"The main path alone opens the tower: no optional quest blocks the story")
 # ---- quest tracking (pure)
 var s=Episode3Data.next_step([])
 check(s.id=="tx" and s.zone=="market" and s.done==0 and s.total==3 and s.spots==["signal_1","signal_2","signal_3"],"The first objective is the three transmissions (0/3)")
 s=Episode3Data.next_step(["tx_2"])
 check(s.done==1 and s.spots==["signal_1","signal_3"],"The counter shows 1/3 and points only at the transmissions still unscanned")
 var order_ok=true
 var seq=[["tx_1","tx_2","tx_3"],["terminal"],["anselm_admits"],["records"],["puzzle_rail"],["teo_met"],["decoded"],["theory"],["puzzle_map"],["tower_reached"],["puzzle_signal"],["puzzle_power"],["puzzle_memory"],["archive_examined"],["warden_restored"],["recording_heard"]]
 var have=[]
 var ids=[]
 for group in seq:
  ids.append(Episode3Data.next_step(have).get("id","done"))
  have+=group
 check(Episode3Data.next_step(have).is_empty() and ids==["tx","terminal","anselm","records","door","teo","decode","board","map","tower","signal","power","memory","archive","warden","recording"],"Objectives advance tx -> terminal -> Anselm -> records -> sealed door -> Teo -> decoder -> board -> relay map -> tower -> three resonators -> archive -> Warden -> recording, then finish")
 check(ZoneDefs.route_x("market","station")==3330.0 and ZoneDefs.route_x("station","workshop")==70.0 and ZoneDefs.route_x("station","workshop",["shortcut"])==2930.0 and ZoneDefs.route_x("station","tower_1")==-1.0 and ZoneDefs.route_x("station","tower_1",["tower"])==70.0 and ZoneDefs.route_x("market","market")==-1.0,"Waypoints route through open exits: the shortcut is used once open, and the sealed tower is unreachable until unlocked")
 # ---- the real episode flow
 var ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 await wait_idle(ep)
 check(ep.explore.objective_text=="Investigate the three unusual transmissions" and ep.explore.counter_total==3 and ep.explore.counter_done==0 and is_equal_approx(ep.explore.target_x,1000.0),"Episode 3 opens with the transmissions objective, a 0/3 counter and a waypoint at the first one")
 await act(ep,"signal_1")
 check(ep.progress.clues.has("tx_1") and ep.explore.counter_done==1 and is_equal_approx(ep.explore.target_x,1900.0),"Scanning a transmission advances the counter and the waypoint")
 await act(ep,"witness_a")
 await act(ep,"signal_2")
 await act(ep,"signal_3")
 check(ep.explore.objective_text=="Check the access terminal at the Transit Station" and ep.explore.counter_total==0 and is_equal_approx(ep.explore.target_x,3330.0),"After the third transmission the objective moves to the station terminal and the waypoint leads to the station exit")
 check(profile.data.mission_progress["1-3"].clues.has("tx_3"),"Clues are saved the moment they are found")
 # journal is a hidden market clue with a Codex entry
 await act(ep,"journal")
 check(profile.data.codex.has("relay_journal") and ep.progress.clues.has("journal"),"The hidden journal gives a clue and a Codex entry")
 # station: out-of-order attempts first
 ep.begin_zone("station",170.0)
 await wait_idle(ep)
 check(not ep.explore.enabled.get("registry_hidden",true),"The loose panel is hidden (not interactable) before the records are found")
 await act(ep,"records")
 check(not ep.progress.clues.has("records") and ep.explore.objective_text=="Check the access terminal at the Transit Station","Searching the records too early finds nothing and keeps the objective")
 await act(ep,"anselm")
 check(ep.progress.clues.has("anselm_met") and not ep.progress.clues.has("anselm_admits"),"Anselm stonewalls before the terminal log is found")
 await act(ep,"terminal_a")
 check(ep.explore.objective_text=="Question Anselm about the missing register" and is_equal_approx(ep.explore.target_x,1300.0),"The terminal log moves the objective to Anselm")
 await act(ep,"anselm")
 await act(ep,"records")
 check(ep.progress.clues.has("records") and ep.progress.clues.has("scraped_entry") and ep.explore.enabled.get("registry_hidden",false),"The old records are found and the hidden panel becomes available")
 check(profile.data.codex.has("anselm") and profile.data.codex.has("false_register"),"Anselm and the Missing Register enter the Codex")
 await act(ep,"registry_hidden")
 check(ep.progress.clues.has("hidden_registry") and profile.data.codex.has("earlier_candidates"),"The hidden registry ledger is an optional clue with its own Codex entry")
 check(ep.explore.objective_text=="Open the sealed archive door at the station","With the records found the objective leads to the sealed archive door (M4)")
 # the tower stays sealed until the board is assembled
 ep.begin_zone("workshop",170.0)
 await wait_idle(ep)
 await act(ep,"decoder")
 check(not ep.progress.clues.has("decoded"),"Teo's decoder refuses until he has been spoken to")
 await act(ep,"teo")
 await act(ep,"board")
 check(not ep.progress.clues.has("theory") and not ep.progress.unlocks.has("tower"),"The evidence board does not assemble until the signals are decoded")
 await act(ep,"decoder")
 check(ep.progress.clues.has("decoded") and profile.data.codex.has("relay_voices") and profile.data.codex.has("teo"),"The decoder reveals the relay voices are playback; Teo and the voices enter the Codex")
 ep.on_interact("exit_tower")
 await wait_idle(ep)
 check(ep.zone_id=="workshop","The tower is still sealed before the theory is assembled")
 await act(ep,"board")
 check(ep.progress.clues.has("theory") and ep.progress.unlocks.has("tower") and ep.explore.objective_text=="Open the sealed archive door at the station","Assembling the board opens the tower (the quest still names the unfinished sealed door first)")
 ep.on_interact("exit_tower")
 await wait_idle(ep)
 check(ep.zone_id=="tower_1" and ep.progress.clues.has("tower_reached") and ep.explore.objective_text=="Open the sealed archive door at the station","The player can enter the tower; the quest still names the unfinished door first (first missing step)")
 # ---- optional quest: Pip
 ep.begin_zone("alleys",170.0)
 await wait_idle(ep)
 await act(ep,"pip")
 await act(ep,"fragment_1")
 await act(ep,"fragment_2")
 await act(ep,"pip")
 check(not ep.progress.clues.has("pip_done"),"Pip's quest stays open with two of three marks")
 await act(ep,"fragment_3")
 await act(ep,"pip")
 check(ep.progress.clues.has("pip_done") and profile.data.codex.has("pips_trail"),"Pip's optional quest completes and enters the Codex")
 # ---- resume keeps clues, objective and hidden spots
 var snapshot=profile.data.mission_progress["1-3"].clues.duplicate()
 ep.queue_free()
 await process_frame
 var again=load("res://scripts/story/relay_episode.gd").new()
 again.mission_id="1-3"
 root.add_child(again)
 await wait_idle(again)
 check(again.progress.clues==snapshot and again.zone_id=="alleys","Resuming restores every clue and the zone")
 again.begin_zone("station",170.0)
 await wait_idle(again)
 check(again.explore.enabled.get("registry_hidden",false),"The hidden panel stays available after resuming")
 again.queue_free()
 # ---- Episode 1-2 untouched; the codex screen lists the new entries
 check(profile.data.completed==["1-1","1-2"] and profile.data.mission_progress["1-2"]==ep2_before,"Episode 1-2 progress and completion are untouched")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
