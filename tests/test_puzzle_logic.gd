extends SceneTree
# Episode 3 M3: the three puzzles' rules are solvable, start unsolved, give feedback, and keep state. Pure logic (no scene).
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
func run() -> void:
 # ---- signal frequency
 var s=PuzzleLogic.signal_default()
 check(not PuzzleLogic.signal_solved(s) and PuzzleLogic.signal_distance(s)>0,"Signal: starts unsolved and off-tune")
 var ok=true
 for r in PuzzleLogic.SIGNAL_ROUNDS:
  if r.freq<PuzzleLogic.FREQ_MIN or r.freq>PuzzleLogic.FREQ_MAX or r.amp<PuzzleLogic.AMP_MIN or r.amp>PuzzleLogic.AMP_MAX: ok=false
 check(ok,"Signal: every target is reachable with the knob ranges")
 var walked=PuzzleLogic.signal_default()
 for round_i in range(3):
  var t=PuzzleLogic.signal_target(walked)
  var guard=0
  while PuzzleLogic.signal_distance(walked)>0 and guard<40:
   walked=PuzzleLogic.signal_step(walked,signi(int(t.freq)-int(walked.freq)),signi(int(t.amp)-int(walked.amp)))
   guard+=1
  walked=PuzzleLogic.signal_lock(walked)
 check(PuzzleLogic.signal_solved(walked),"Signal: stepping the knobs one notch at a time solves all three rounds")
 var off=PuzzleLogic.signal_default()
 check(PuzzleLogic.signal_lock(off)==off,"Signal: LOCK does nothing while the pattern does not match")
 var near=PuzzleLogic.signal_step(PuzzleLogic.signal_default(),-2,0)   # freq 4 vs 3, amp 4 vs 3 -> distance 2
 check(PuzzleLogic.signal_feedback(near).begins_with("VERY CLOSE") and PuzzleLogic.signal_feedback(PuzzleLogic.signal_default()).begins_with("CLOSE"),"Signal: feedback reports proximity without giving the answer")
 check(PuzzleLogic.signal_step(PuzzleLogic.signal_default(),99,99).freq==PuzzleLogic.FREQ_MAX and PuzzleLogic.signal_step(PuzzleLogic.signal_default(),-99,-99).amp==PuzzleLogic.AMP_MIN,"Signal: the knobs are clamped")
 var h1=PuzzleLogic.signal_hint({"round":0,"freq":6,"amp":4,"hints":1})
 var h2=PuzzleLogic.signal_hint({"round":0,"freq":6,"amp":4,"hints":2})
 check(not h1.contains("too") and h2.contains("too") and not h2.contains("3"),"Signal: hint 1 is descriptive, hint 2 gives a direction, neither states the answer")
 # ---- power routing
 check(PuzzleLogic.route_solvable(),"Power: the board is solvable (a rotation exists that connects source to relay)")
 var rs=PuzzleLogic.route_default()
 check(not PuzzleLogic.route_solved(rs) and PuzzleLogic.route_powered(rs).has(PuzzleLogic.SOURCE_CELL),"Power: starts unsolved with only the source live")
 var applied=rs.duplicate(true)
 for cell in PuzzleLogic.ROUTE_SOLUTION:
  applied.rots[cell]=PuzzleLogic.ROUTE_SOLUTION[cell]
 check(PuzzleLogic.route_solved(applied),"Power: the intended rotations connect the relay")
 var none_start=true
 for cell in PuzzleLogic.ROUTE_SOLUTION:
  if PuzzleLogic.ROUTE_START[cell]==PuzzleLogic.ROUTE_SOLUTION[cell]: none_start=false
 check(none_start,"Power: no path tile starts in its solving rotation")
 # solve by the player's own moves: tap tiles until each matches
 var play=PuzzleLogic.route_default()
 var taps=0
 for cell in PuzzleLogic.ROUTE_SOLUTION:
  while play.rots[cell]!=PuzzleLogic.ROUTE_SOLUTION[cell]:
   play=PuzzleLogic.route_rotate(play,cell)
   taps+=1
 check(PuzzleLogic.route_solved(play) and taps<=7*3,"Power: solvable by tapping tiles (%d taps)" % taps)
 check(PuzzleLogic.route_rotate(rs,PuzzleLogic.SOURCE_CELL)==rs and PuzzleLogic.route_rotate(rs,PuzzleLogic.RELAY_CELL)==rs and PuzzleLogic.route_rotate(rs,0)==rs,"Power: the source, relay and burnt-out tile do not rotate")
 check(PuzzleLogic.rotate_mask(PuzzleLogic.N,1)==PuzzleLogic.E and PuzzleLogic.rotate_mask(PuzzleLogic.W,1)==PuzzleLogic.N and PuzzleLogic.rotate_mask(PuzzleLogic.N|PuzzleLogic.S,1)==(PuzzleLogic.E|PuzzleLogic.W),"Power: rotation turns sides clockwise")
 var hint=PuzzleLogic.route_hint_cell(rs)
 check(hint>=0 and PuzzleLogic.ROUTE_PATH.has(hint) and PuzzleLogic.route_hint_cell(applied)==-1,"Power: the hint marks a tile on the intended path and goes quiet when solved")
 # scan every 2-tile state of the first tap sequence: the powered set only ever grows along a connected chain
 var chain_ok=true
 var st=PuzzleLogic.route_default()
 for cell in PuzzleLogic.ROUTE_PATH:
  while st.rots[cell]!=PuzzleLogic.ROUTE_SOLUTION.get(cell,st.rots[cell]):
   st=PuzzleLogic.route_rotate(st,cell)
  for p in PuzzleLogic.route_powered(st):
   if p!=PuzzleLogic.SOURCE_CELL and PuzzleLogic.cell_mask(p,st.rots)==0: chain_ok=false
 check(chain_ok,"Power: only tiles with open sides ever carry current")
 # ---- memory reconstruction
 var all_clues=["tx_2","tx_3","terminal","records"]
 check(PuzzleLogic.memory_cards_for([]).is_empty() and PuzzleLogic.memory_cards_for(all_clues).size()==4,"Memory: fragments appear only for clues the player has found")
 check(PuzzleLogic.memory_cards_for(["records","terminal"])==["records","terminal"],"Memory: a clue unlocks exactly its own fragment")
 var m=PuzzleLogic.memory_default()
 for i in range(4):
  m=PuzzleLogic.memory_place(m,PuzzleLogic.MEMORY_ORDER[(i+1)%4],i)
 check(not PuzzleLogic.memory_solved(m) and PuzzleLogic.memory_score(m)<4 and PuzzleLogic.memory_feedback(m).contains("OF 4 IN PLACE"),"Memory: a wrong order is not solved and says how many are in place")
 for i in range(4):
  m=PuzzleLogic.memory_place(m,PuzzleLogic.MEMORY_ORDER[i],i)
 check(PuzzleLogic.memory_solved(m) and PuzzleLogic.memory_feedback(m).begins_with("THE MEMORY HOLDS") and PuzzleLogic.memory_tray(m,all_clues).is_empty(),"Memory: the clue order solves it and empties the tray")
 var moved=PuzzleLogic.memory_place(PuzzleLogic.memory_default(),"records",2)
 moved=PuzzleLogic.memory_place(moved,"records",0)
 check(moved.slots==["records","","",""] and PuzzleLogic.memory_tray(moved,all_clues).size()==3,"Memory: moving a placed card frees its old slot")
 check(PuzzleLogic.memory_remove(moved,0).slots==["","","",""],"Memory: a placed card can be taken back")
 check(PuzzleLogic.memory_feedback(PuzzleLogic.memory_default()).begins_with("PLACE ALL FOUR"),"Memory: an incomplete board asks for all four fragments first")
 # every order of four cards reaches the solution by feedback alone (no dead ends): brute-force 24 permutations
 var solvable=0
 var perms=[]
 for a in range(4):
  for b in range(4):
   for c in range(4):
    for d in range(4):
     if a!=b and a!=c and a!=d and b!=c and b!=d and c!=d: perms.append([a,b,c,d])
 for p in perms:
  var st2=PuzzleLogic.memory_default()
  for i in range(4): st2=PuzzleLogic.memory_place(st2,PuzzleLogic.MEMORY_ORDER[p[i]],i)
  if PuzzleLogic.memory_score(st2)==4 and p==[0,1,2,3] or PuzzleLogic.memory_score(st2)<4 and p!=[0,1,2,3]: solvable+=1
 check(solvable==24 and perms.size()==24,"Memory: exactly one of the 24 orders is correct")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
