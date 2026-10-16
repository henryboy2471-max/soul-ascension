extends SceneTree
# Episode 3 M4: the sealed-door and relay-map puzzles with their cinematics, the Warden arena (checkpoints, failure, restoring), the finale,
# completion and rewards through the real main scene, and replay. Real RelayEpisode / PuzzleScreen / WardenArena (loaded dynamically: they use autoloads).
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
 create_timer(170.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node) -> void:
 if is_instance_valid(ep):
  for c in ep.get_children():
   if c.has_method("finish_all"):
    c.finish_all()
   elif c.has_method("finish"):
    c.finish()
 await process_frame
func screen_of(ep:Node):
 for c in ep.get_children():
  if c.has_method("request_hint") and c.has_method("paint"): return c
 return null
func wait_idle(ep:Node, max_frames:int=2400) -> void:
 var n=0
 while n<max_frames and (ep.busy or ep.traveling or not is_instance_valid(ep.explore)):
  await skip_scenes(ep)
  n+=1
 await process_frame
 await process_frame
func open_puzzle(ep:Node, id:String):
 ep.on_interact(id)
 var n=0
 while n<900 and screen_of(ep)==null and ep.busy:
  await skip_scenes(ep)
  n+=1
 return screen_of(ep)
func start_episode(profile, clues:Array, zone:String, unlocks:Array=["shortcut","tower","floor2","floor3"]) -> Node:
 profile.data.mission_progress={"1-3":{"intro":true,"zone":zone,"visited":["market","station","alleys","workshop"],"unlocks":unlocks,"discoveries":[],"clues":clues.duplicate()}}
 var ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 await wait_idle(ep)
 return ep
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.data.completed=["1-1","1-2"]
 var base=["tx_1","tx_2","tx_3","terminal","anselm_met","anselm_admits","records","scraped_entry","teo_met","decoded","theory"]
 # ---- data: every cinematic exists, every speaker has a style, finale extras follow the saved investigation
 var cine_ok=true
 for id in ["opening","exposure","teo_reveal","warden_wakes","recognition","recording"]:
  var lines=Episode3Data.cine_lines(id,[])
  if lines.size()<3: cine_ok=false
  for l in lines:
   if not (l.who in ["NARRATOR","PLAYER","MIRA"] or Episode3Data.SPEAKERS.has(l.who)): cine_ok=false
 check(cine_ok,"All five required cinematics (plus the chamber's arrival) are written, with a style for every speaker")
 var plain=Episode3Data.cine_lines("recording",[]).size()
 var full=Episode3Data.cine_lines("recording",["w_a","w_b","w_c","journal","hidden_registry","first_memory_fragment","pip_done"]).size()
 check(full==plain+5 and Episode3Data.finale_extras(["pip_done"]).size()==1 and Episode3Data.finale_extras([]).is_empty(),"The finale adds one extra line per investigated payoff (5 here); an uninvestigated run adds none")
 check(Episode3Data.cine_lines("recording",["pip_done"]).back().text.contains("ECHO"),"The extras play before the closing line: the Meridian screens flicker to ECHO")
 # ---- owner-approved wording revisions stay in place
 var chamber=Episode3Data.respond("sealed_chamber",[])
 var chamber_text=" ".join(chamber.lines.map(func(l): return str(l.text)))
 var extra_text=" ".join(Episode3Data.finale_extras(["first_memory_fragment"]).map(func(l): return str(l.text)))
 var codex_text=""
 for entry in Episode3Data.CODEX:
  if entry.id=="first_memory": codex_text=str(entry.text)
 check(chamber_text.contains("voice counts seven") and not chamber_text.contains("lamp") and not chamber_text.contains("kept it safe"),"Sealed chamber: only the voice counting seven (no lamp, no \"We kept it safe in the towers\")")
 check(extra_text.contains("voice counting seven") and not extra_text.contains("lamp") and not extra_text.contains("kept it safe") and not codex_text.contains("lamp") and not codex_text.contains("kept it safe"),"Finale payoff and Codex text for the sealed fragment keep only the voice counting seven")
 check(PuzzleLogic.MEMORY_CARDS.tone.text.contains("tonight") and not PuzzleLogic.memory_feedback(PuzzleLogic.memory_default()).contains("IN PLACE"),"The long-tone card keeps \"tonight\"; the memory feedback has no count")
 var all_cine=""
 for id in Episode3Data.CINE:
  for l in Episode3Data.CINE[id]: all_cine+=" "+str(l.text)+" "+str(l.who)
 var opening=" ".join(Episode3Data.CINE.opening.map(func(l): return str(l.text)))
 check(not opening.contains("morning") and not opening.contains("sunrise") and opening.contains("shortly after the Rain Array fell silent"),"The opening asserts no time of day: 'shortly after', not 'the morning after' or 'since sunrise'")
 var rec=" ".join(Episode3Data.CINE.recording.map(func(l): return str(l.text)))
 var rec_wake=" ".join(Episode3Data.CINE.recognition.map(func(l): return str(l.text)))
 check(rec.contains("exact") and rec.contains("matches yours exactly") and rec.contains("Vaust") and rec.contains("Then who is the First Echo?"),"The recording keeps the exact signature match and the Vaust hook, and ends on the open question")
 check(not rec.contains("That's you.") and not rec.contains("whoever I came from") and not rec.contains("the one who first sang it") and not rec_wake.contains("FILED FIRST") and not rec_wake.contains("RETURN") and not rec_wake.contains("Return?"),"Nothing in the finale states that Echo is, or came from, the First Echo")
 check(not rec.contains("lamp") and not rec_wake.contains("lamp"),"The recording and recognition scenes mention no lamp (the removed sealed-chamber detail)")
 var rw=MissionDefs.get_def("1-3").rewards
 check(rw.first.xp==180 and rw.first.gold==340 and rw.replay.xp==80 and rw.replay.gold==150 and bool(rw.get("provisional",false)),"Rewards stay 180 XP / 340 gold and 80 / 150, flagged provisional in the data")
 # ---- the sealed archive door (spatial rail puzzle) and Anselm's exposure
 var ep=await start_episode(profile,["tx_1","tx_2","tx_3","terminal","anselm_admits"],"station")
 ep.on_interact("archive_door")
 await wait_idle(ep)
 check(screen_of(ep)==null and not ep.progress.clues.has("seen_archive_door"),"Before the records are found the door only shows its old examine text (no puzzle)")
 ep.queue_free()
 await process_frame
 ep=await start_episode(profile,base,"station")
 var sc=await open_puzzle(ep,"archive_door")
 check(sc!=null and sc.kind=="rail" and ep.progress.clues.has("seen_archive_door"),"With the records found, the door opens the sliding-rail puzzle")
 var first_blocks=sc.state.blocks.duplicate(true)
 sc.rail_pick(4)
 check(sc.sel==4 and sc.state.moves==0,"Picking a block selects it without counting as a move")
 var sol=PuzzleLogic.rail_solve(sc.state)
 # play the first three moves by the shortest path, then leave and come back
 for i in range(3):
  sc.sel=int(sol[i][0])
  sc.rail_slide(int(sol[i][1]),str(sc.state.blocks[sc.sel][3]))
 check(sc.state.moves==3 and ep.progress.puzzles.rail.moves==3,"Moves are saved as they are made")
 sc.leave()
 await wait_idle(ep)
 sc=await open_puzzle(ep,"archive_door")
 check(sc!=null and sc.state.moves==3,"Leaving and returning keeps the rails where they were")
 # finish by tapping: select the block, tap the empty rail it must slide to
 var rest=PuzzleLogic.rail_solve(sc.state)
 for mv in rest:
  sc.sel=int(mv[0])
  sc.rail_slide(int(mv[1]),str(sc.state.blocks[sc.sel][3]))
 check(sc.done and PuzzleLogic.rail_solved(sc.state),"Sliding the blocks clear frees the carriage")
 await wait_idle(ep)
 check(ep.progress.clues.has("puzzle_rail") and ep.progress.clues.has("seen_exposure") and profile.data.codex.has("echo_entry"),"The door opens, Anselm's exposure plays and Echo's registry entry enters the Codex")
 check(Episode3Data.next_step(ep.progress.clues).id=="map","After the door the quest moves on to the relay map")
 ep.queue_free()
 await process_frame
 # ---- the relay map (power-routing mechanic, seven lamps) and Teo's reveal
 ep=await start_episode(profile,["tx_1","tx_2","tx_3","terminal","anselm_admits","records","teo_met","decoded"],"workshop")
 ep.on_interact("relay_map")
 await wait_idle(ep)
 check(screen_of(ep)==null,"Before the evidence board is assembled the map only shows its old examine text")
 ep.queue_free()
 await process_frame
 ep=await start_episode(profile,base+["puzzle_rail"],"workshop")
 sc=await open_puzzle(ep,"relay_map")
 check(sc!=null and sc.kind=="map" and PuzzleLogic.route_unpowered_targets(sc.state).size()>=5,"After the board the map opens its puzzle with most lamps dark")
 sc.request_hint()
 sc.request_hint()
 check(sc.hint_label.text.contains("marked") and PuzzleLogic.route_hint_cell(sc.state)>=0,"Hint 2 marks a tile the current needs")
 for cell in PuzzleLogic.MAP_SOLUTION:
  var want=PuzzleLogic.rotate_mask(PuzzleLogic.base_mask(PuzzleLogic.cell_kind(cell,"map")),int(PuzzleLogic.MAP_SOLUTION[cell]))
  var guard=0
  while PuzzleLogic.cell_mask(cell,sc.state.rots,"map")!=want and guard<4:
   sc.cursor=cell
   sc.turn_tile()
   guard+=1
  if sc.done: break
 check(sc.done and PuzzleLogic.route_solved(sc.state) and sc.header.text.contains("7 OF 7"),"Turning the tiles lights all seven array lamps")
 await wait_idle(ep)
 check(ep.progress.clues.has("puzzle_map") and ep.progress.clues.has("seen_teo_reveal") and profile.data.codex.has("seven_arrays"),"The map restores, Teo reveals the memory network and the Seven Arrays enter the Codex")
 ep.queue_free()
 await process_frame
 # ---- the archive gate needs the map and the door as well as the resonators
 var all_res=base+["puzzle_signal","puzzle_power","puzzle_memory"]
 ep=await start_episode(profile,all_res,"tower_3")
 ep.on_interact("archive_gate")
 await wait_idle(ep)
 check(not ep.progress.clues.has("archive_examined"),"The archive gate stays shut while the map and the sealed door are unrepaired")
 ep.queue_free()
 await process_frame
 var ready=all_res+["puzzle_rail","puzzle_map","seen_exposure","seen_teo_reveal","w_a","w_b","w_c","pip_done"]
 ep=await start_episode(profile,ready,"tower_3")
 check(not ep.explore.enabled.get("exit_arena",true),"The way into the chamber is hidden until the archive stirs")
 ep.on_interact("archive_gate")
 await wait_idle(ep)
 check(ep.progress.clues.has("archive_examined") and ep.explore.enabled.get("exit_arena",false),"With every key restored the archive stirs and the gate to the Central Relay appears")
 # ---- entering the arena: arrival cinematic once, the fight is live
 ep.on_interact("exit_arena")
 await wait_idle(ep)
 check(ep.zone_id=="arena" and ep.progress.clues.has("seen_arena") and is_instance_valid(ep.arena),"The chamber's arrival scene plays and the Warden is live")
 await create_timer(1.5).timeout
 check(ep.explore.scale==Vector2.ONE,"The arrival scene's slow push-in does not outlive the scene (the view is back to normal scale)")
 check(not ep.explore.prompt_label.visible,"After a cinematic the hidden prompt-text label stays hidden (no doubled prompt under the pill)")
 check(ep.explore.objective_text=="Enter the chamber and wake the three mechanisms in the right order" and is_equal_approx(ep.explore.target_x,330.0),"The objective points at the inscription first")
 ep.on_interact("inscription")
 await wait_idle(ep)
 check(ep.progress.clues.has("inscription_read") and is_equal_approx(ep.explore.target_x,1250.0),"Reading the plaque gives the order; the waypoint leads to the VALVE (not the nearest machine)")
 # a wrong mechanism first
 var hp0=int(ep.arena.state.hp)
 ep.on_interact("mech_1")
 await wait_idle(ep)
 check(int(ep.arena.state.hp)==hp0-1 and not ep.progress.clues.has("restored_mech_1"),"A mechanism out of order shocks Echo and restores nothing")
 # a hit from the Warden reduces resonance (put the player in a telegraphed zone)
 ep.arena.state=WardenLogic.default_state()
 ep.arena.state.phase="telegraph"
 ep.arena.state.timer=0.02
 ep.arena.state.zones=[[ep.explore.px-50.0,ep.explore.px+50.0]]
 await create_timer(0.2).timeout
 check(int(ep.arena.state.hp)==WardenLogic.MAX_HP-1,"A telegraphed strike under Echo costs one resonance point")
 # the right order, with a checkpoint after each
 ep.arena.state=WardenLogic.default_state()
 ep.on_interact("mech_2")
 await wait_idle(ep)
 check(ep.progress.clues.has("restored_mech_2") and ep.arena.state.phase=="stunned" and is_equal_approx(ep.explore.target_x,1800.0),"The VALVE restores, interrupts the Warden and the waypoint moves to the BELL")
 # failure returns to the checkpoint beside the last restored mechanism, keeping progress
 ep.arena.state.hp=1
 ep.arena.state.inv=0.0
 ep.on_interact("mech_1")
 await wait_idle(ep)
 await create_timer(1.2).timeout
 await wait_idle(ep)
 check(int(ep.arena.state.hp)==WardenLogic.MAX_HP and ep.progress.clues.has("restored_mech_2") and is_equal_approx(ep.explore.px,WardenLogic.checkpoint_x(["mech_2"])),"Running out of resonance returns to the checkpoint beside the VALVE with full resonance and progress kept")
 # resume inside the chamber lands at that checkpoint
 var snap=profile.data.mission_progress["1-3"].duplicate(true)
 ep.queue_free()
 await process_frame
 ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 await wait_idle(ep)
 check(ep.zone_id=="arena" and is_equal_approx(ep.explore.px,WardenLogic.checkpoint_x(["mech_2"])) and ep.restored_list()==["mech_2"],"Reloading mid-fight resumes at the last checkpoint with the same mechanisms restored")
 ep.on_interact("mech_3")
 await wait_idle(ep)
 ep.on_interact("mech_1")
 await wait_idle(ep)
 await wait_idle(ep)
 check(ep.progress.clues.has("warden_restored") and ep.progress.clues.has("restored_mech_1") and not is_instance_valid(ep.arena) and profile.data.codex.has("relay_warden"),"BELL then SEAL restore the Warden: the recognition scene plays and the guardian is restored, not destroyed")
 check(ep.explore.enabled.get("archive_core",false) and is_equal_approx(ep.explore.target_x,2300.0),"The archive core is open and the objective points at it")
 # ---- the finale and completion through the real main scene
 var done=[false]
 ep.completed.connect(func(): done[0]=true)
 ep.on_interact("archive_core")
 var guard=0
 while not done[0] and guard<2400:
  await skip_scenes(ep)
  guard+=1
 check(done[0] and ep.progress.clues.has("recording_heard") and profile.data.codex.has("first_echo"),"The First Echo recording plays (with the investigation's extra lines) and the episode completes")
 ep.queue_free()
 await process_frame
 var gold0=int(profile.data.gold)
 profile.data.settings.dev_unlock=true
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 profile.data.mission_progress={"1-3":{"intro":true,"zone":"arena","visited":["arena"],"unlocks":["tower","floor2","floor3"],"discoveries":[],"clues":ready+["archive_examined","seen_arena","inscription_read","restored_mech_2","restored_mech_3","restored_mech_1","warden_restored"],"puzzles":{"signal":{"round":3}}}}
 main.start_episode("1-3")
 await process_frame
 var live=main.screen.get_child(0)
 await wait_idle(live)
 live.on_interact("archive_core")
 guard=0
 while main.scene_name!="result" and guard<2400:
  await skip_scenes(live) if is_instance_valid(live) else await process_frame
  guard+=1
 await create_timer(0.8).timeout
 check(main.scene_name=="result" and profile.data.completed.has("1-3") and profile.data.completed.count("1-3")==1,"Completion opens the rewards screen and marks mission 1-3 completed once")
 check(int(profile.data.gold)==gold0+340,"First clear pays the placeholder 340 gold")
 var texts=[]
 for b in main.screen.find_children("*","Button",true,false): texts.append(str(b.text))
 for l in main.screen.find_children("*","Label",true,false): texts.append(str(l.text))
 check(texts.has("NEXT EPISODE") and texts.has("REPLAY EPISODE") and texts.has("THE RELAY KEEPER"),"The rewards screen offers NEXT EPISODE and REPLAY EPISODE")
 check(profile.mission_progress("1-3").is_empty() and profile.data.completed==["1-1","1-2","1-3"],"Mission progress is cleared on completion; Episode 1-2 completion is untouched")
 var gold1=int(profile.data.gold)
 for b in main.screen.find_children("*","Button",true,false):
  if b.text=="NEXT EPISODE": b.pressed.emit()
 await process_frame
 await process_frame
 check(main.scene_name=="teaser" and main.screen.get_child(0).title.contains("THE FIRST ECHO") and main.screen.get_child(0).kicker=="NEXT EPISODE","NEXT EPISODE plays the EPISODE 4 / THE FIRST ECHO teaser (no Episode 4 content)")
 main.screen.get_child(0).finish()
 await create_timer(1.0).timeout
 check(main.scene_name=="home" and int(profile.data.gold)==gold1,"The teaser returns home and changes nothing")
 # ---- replay starts the story again and pays the replay reward once
 main.start_episode("1-3")
 await process_frame
 var again=main.screen.get_child(0)
 var n2=0
 while again.explore==null and n2<900:
  await skip_scenes(again)
  n2+=1
 check(again.zone_id=="market" and again.progress.clues.is_empty() and profile.data.completed.count("1-3")==1,"Replaying 1-3 starts from the market with a clean story; completion is kept")
 profile.data.mission_progress["1-3"]["clues"]=ready+["archive_examined","seen_arena","restored_mech_2","restored_mech_3","restored_mech_1","warden_restored"]
 again.progress=profile.mission_progress("1-3").duplicate(true)
 again.progress["intro"]=true
 again.progress["zone"]="arena"
 again.save_progress()
 again.begin_zone("arena",170.0)
 await wait_idle(again)
 again.on_interact("archive_core")
 var gold2=int(profile.data.gold)
 guard=0
 while main.scene_name!="result" and guard<2400:
  await skip_scenes(again) if is_instance_valid(again) else await process_frame
  guard+=1
 await create_timer(0.8).timeout
 check(main.scene_name=="result" and int(profile.data.gold)==gold2+150 and profile.data.completed.count("1-3")==1,"A replay clear pays the 150-gold replay reward and does not repeat the first clear")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
