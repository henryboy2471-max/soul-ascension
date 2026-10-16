extends SceneTree
# Episode 3 M3 (puzzles): the real RelayEpisode + PuzzleScreen driven through keyboard events, mouse clicks and button presses.
# Floor locks, intro/success dialogue, persistence (leave and return), hints, the sealed-chamber optional quest, the archive and objectives.
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
# open the resonator, skipping its intro dialogue, until the puzzle overlay is up
func open_puzzle(ep:Node, id:String):
 ep.on_interact(id)
 var n=0
 while n<600 and screen_of(ep)==null and ep.busy:
  await skip_scenes(ep)
  n+=1
 return screen_of(ep)
func wait_idle(ep:Node, max_frames:int=1500) -> void:
 var n=0
 while n<max_frames and (ep.busy or ep.traveling or not is_instance_valid(ep.explore)):
  await skip_scenes(ep)
  n+=1
 await process_frame   # a freed puzzle screen is gone one frame later
 await process_frame
func key(code:int) -> void:
 var e=InputEventKey.new()
 e.physical_keycode=code
 e.keycode=code
 e.pressed=true
 Input.parse_input_event(e)
 await process_frame
func click_cell(screen, cell:int) -> void:
 var e=InputEventMouseButton.new()
 e.button_index=MOUSE_BUTTON_LEFT
 e.pressed=true
 var x=cell%PuzzleLogic.COLS
 var y=cell/PuzzleLogic.COLS
 var script=load("res://scripts/puzzle/puzzle_screen.gd")   # not by class_name: the screen uses autoloads (see CLAUDE.md)
 e.position=script.BOARD_ORIGIN+Vector2(x*script.CELL+40,y*script.CELL+40)
 screen.board_input(e)
 await process_frame
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.completed=["1-1","1-2"]
 var main_clues=["tx_1","tx_2","tx_3","terminal","anselm_met","anselm_admits","records","scraped_entry","puzzle_rail","seen_exposure","teo_met","decoded","theory","puzzle_map","seen_teo_reveal"]
 profile.data.mission_progress={"1-3":{"intro":true,"zone":"tower_1","visited":["market","tower_1"],"unlocks":["shortcut","tower"],"discoveries":[],"clues":main_clues.duplicate()}}
 var ep=load("res://scripts/story/relay_episode.gd").new()
 ep.mission_id="1-3"
 root.add_child(ep)
 await wait_idle(ep)
 check(ep.zone_id=="tower_1" and ep.explore.objective_text=="Restore the signal resonator on the first floor" and is_equal_approx(ep.explore.target_x,1300.0),"Resuming in the tower: the objective is the first resonator, waypoint at it")
 # ---- floor locks
 ep.on_interact("exit_up_1")
 await wait_idle(ep)
 check(ep.zone_id=="tower_1","The stairs up stay locked until the signal resonator is restored")
 # ---- signal puzzle: keyboard path, persistence, hints
 var sc=await open_puzzle(ep,"resonator_1")
 check(sc!=null and sc.kind=="signal" and ep.progress.clues.has("seen_resonator_1"),"The resonator shows its intro and opens the signal puzzle")
 check(sc.header.text.contains("TRANSMISSION 1 OF 3") and sc.feedback.text.begins_with("CLOSE") or sc.feedback.text.begins_with("OFF"),"The puzzle names the transmission and reports proximity")
 await key(KEY_RIGHT)
 await key(KEY_UP)
 check(sc.state.freq==7 and sc.state.amp==5,"Arrow keys turn the frequency and height knobs")
 await key(KEY_H)
 check(sc.hint_label.text!="" and sc.state.hints==1 and not sc.hint_label.text.contains("too"),"H shows a hint that describes the pattern without giving the answer")
 await key(KEY_H)
 check(sc.hint_label.text.contains("too"),"A second hint gives a direction, never the value")
 var saved=profile.data.mission_progress["1-3"].puzzles.signal
 check(saved.freq==7 and saved.amp==5 and saved.hints==2,"Every move is saved the moment it is made")
 await key(KEY_ESCAPE)
 await wait_idle(ep)
 check(screen_of(ep)==null and not ep.progress.clues.has("puzzle_signal") and ep.explore.locked==false,"Esc leaves the puzzle and returns control to the player")
 sc=await open_puzzle(ep,"resonator_1")
 check(sc.state.freq==7 and sc.state.amp==5 and sc.state.hints==2,"Returning resumes the same tuning and hints")
 # solve all three rounds by tuning each target with the buttons' own callbacks
 for r in range(3):
  var t=PuzzleLogic.signal_target(sc.state)
  var guard=0
  while PuzzleLogic.signal_distance(sc.state)>0 and guard<40:
   sc.nudge(signi(int(t.freq)-int(sc.state.freq)),signi(int(t.amp)-int(sc.state.amp)))
   guard+=1
  if r==0:
   check(sc.feedback.text.begins_with("LOCKED"),"A matching wave reports LOCKED")
  sc.lock_signal()
  await process_frame
 check(sc.done and PuzzleLogic.signal_solved(sc.state),"Locking all three transmissions solves the puzzle")
 await wait_idle(ep)
 check(ep.progress.clues.has("puzzle_signal") and ep.progress.unlocks.has("floor2") and ep.progress.discoveries.has("resonator_1"),"Solving saves the clue, opens the stairs and quiets the resonator")
 check(ep.explore.objective_text=="Restore the power resonator on the second floor","The objective moves up to the power resonator")
 ep.on_interact("resonator_1")
 await wait_idle(ep)
 check(screen_of(ep)==null,"A restored resonator does not reopen its puzzle")
 # ---- floor 2: power puzzle with mouse clicks
 ep.on_interact("exit_up_1")
 await wait_idle(ep)
 check(ep.zone_id=="tower_2" and not ep.explore.enabled.get("sealed_chamber",true),"The stairs now open; the sealed chamber is hidden until power is restored")
 ep.on_interact("exit_up_2")
 await wait_idle(ep)
 check(ep.zone_id=="tower_2","The next stairs stay locked until the power resonator is restored")
 sc=await open_puzzle(ep,"resonator_2")
 check(sc!=null and sc.kind=="power" and PuzzleLogic.route_powered(sc.state).size()==1,"The power puzzle opens with only the source live")
 var first=sc.state.rots.duplicate()
 await click_cell(sc,PuzzleLogic.ROUTE_PATH[1])
 check(sc.state.rots[PuzzleLogic.ROUTE_PATH[1]]==(first[PuzzleLogic.ROUTE_PATH[1]]+1)%4,"Clicking a tile turns it")
 await click_cell(sc,PuzzleLogic.SOURCE_CELL)
 check(sc.state.rots==ep.progress.puzzles.power.rots and sc.state.rots[PuzzleLogic.SOURCE_CELL]==first[PuzzleLogic.SOURCE_CELL],"The fixed source does not turn; the board is saved after every click")
 await key(KEY_H)
 await key(KEY_H)
 check(sc.hint_label.text.contains("marked") and PuzzleLogic.route_hint_cell(sc.state)>=0,"Hint 2 marks a tile that is on the way")
 for cell in PuzzleLogic.ROUTE_SOLUTION:
  var guard=0
  while sc.state.rots[cell]!=PuzzleLogic.ROUTE_SOLUTION[cell] and guard<4:
   await click_cell(sc,cell)
   guard+=1
 check(sc.done and PuzzleLogic.route_solved(sc.state),"Turning the path tiles lights the relay and solves the board")
 await wait_idle(ep)
 check(ep.progress.clues.has("puzzle_power") and ep.progress.unlocks.has("floor3") and ep.explore.enabled.get("sealed_chamber",false),"Power restored: stairs open and the sealed chamber appears")
 # optional quest: the sealed chamber
 ep.on_interact("sealed_chamber")
 await wait_idle(ep)
 check(ep.progress.clues.has("first_memory_fragment") and profile.data.codex.has("first_memory"),"The sealed chamber gives an optional fragment and a Codex entry")
 # ---- floor 3: memory puzzle with the keyboard cursor and buttons
 ep.on_interact("exit_up_2")
 await wait_idle(ep)
 check(ep.zone_id=="tower_3","The top floor opens once the power resonator is restored")
 ep.on_interact("archive_gate")
 await wait_idle(ep)
 check(not ep.progress.clues.has("archive_examined"),"The archive gate stays sealed while a resonator is silent")
 sc=await open_puzzle(ep,"resonator_3")
 check(sc!=null and sc.kind=="memory" and PuzzleLogic.memory_tray(sc.state,sc.clues).size()==4,"The memory puzzle offers all four fragments the player found")
 # wrong order first: shows how many are in place
 var wrong=["tone","records","bulletin","terminal"]
 for i in range(4):
  sc.pick_card(wrong[i])
  sc.press_slot(i)
 sc.check_memory()
 check(sc.feedback.text.contains("OF 4 IN PLACE") and not sc.done,"A wrong order reports how many fragments are in place and keeps the puzzle open")
 sc.press_slot(0)
 check(sc.state.slots[0]=="" and PuzzleLogic.memory_tray(sc.state,sc.clues).size()==1,"Tapping a placed fragment takes it back")
 # keyboard: cursor to the tray card, select, move down to slot 1, place
 sc.cursor=0
 await key(KEY_ENTER)
 check(sc.selected=="tone","Enter selects the fragment under the cursor")
 await key(KEY_DOWN)
 await key(KEY_ENTER)
 check(sc.state.slots[0]=="tone" and sc.selected=="","Enter on a slot places the selected fragment")
 # now arrange the true order with the button callbacks
 for i in range(4):
  sc.pick_card(PuzzleLogic.MEMORY_ORDER[i])
  sc.press_slot(i)
 sc.check_memory()
 check(sc.done and PuzzleLogic.memory_solved(sc.state),"The clue order solves the memory puzzle")
 await wait_idle(ep)
 check(ep.progress.clues.has("puzzle_memory") and ep.explore.objective_text=="Examine the sealed archive at the top of the tower","Objective: examine the archive")
 ep.on_interact("archive_gate")
 await wait_idle(ep)
 check(ep.progress.clues.has("archive_examined") and Episode3Data.next_step(ep.progress.clues).id=="warden","With all three resonators restored the archive stirs; the quest line moves on to the Warden (M4)")
 # ---- persistence across a restart; Episode 1-2 untouched
 var snap=profile.data.mission_progress["1-3"].duplicate(true)
 ep.queue_free()
 await process_frame
 var again=load("res://scripts/story/relay_episode.gd").new()
 again.mission_id="1-3"
 root.add_child(again)
 await wait_idle(again)
 check(again.progress.puzzles==snap.puzzles and again.progress.clues==snap.clues and again.zone_id=="tower_3","Resuming restores every puzzle state, clue and the zone")
 again.queue_free()
 check(profile.data.completed==["1-1","1-2"],"Episode 1-2 completion is untouched")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
