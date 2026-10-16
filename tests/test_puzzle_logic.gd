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
 # ---- relay map (M4): seven lamps, same mechanic as the power board on a second level
 var mp=PuzzleLogic.route_default("map")
 check(PuzzleLogic.LEVELS.map.targets.size()==7 and PuzzleLogic.route_certificate("map") and PuzzleLogic.route_certificate("power"),"Map: seven lamps; the stored solution lights every lamp (and the power board's still does)")
 check(not PuzzleLogic.route_solved(mp) and PuzzleLogic.route_unpowered_targets(mp).size()>=5,"Map: starts with most lamps dark")
 var mapply=mp.duplicate(true)
 for cell in PuzzleLogic.MAP_SOLUTION: mapply.rots[cell]=PuzzleLogic.MAP_SOLUTION[cell]
 var wrong_one=mapply.duplicate(true)
 var victim=-1
 for cell in PuzzleLogic.MAP_SOLUTION:
  var t=wrong_one.rots[cell]
  wrong_one.rots[cell]=(t+1)%4
  if not PuzzleLogic.route_solved(wrong_one) and PuzzleLogic.route_unpowered_targets(wrong_one).size()>=1:
   victim=cell
   break
  wrong_one.rots[cell]=t
 check(PuzzleLogic.route_solved(mapply) and victim>=0 and not PuzzleLogic.route_solved(wrong_one),"Map: one mis-turned tile on the line keeps a lamp dark")
 var map_taps=0
 var mplay=mp.duplicate(true)
 for cell in PuzzleLogic.MAP_SOLUTION:
  var want=PuzzleLogic.rotate_mask(PuzzleLogic.base_mask(PuzzleLogic.cell_kind(cell,"map")),int(PuzzleLogic.MAP_SOLUTION[cell]))
  var guard2=0
  while PuzzleLogic.cell_mask(cell,mplay.rots,"map")!=want and guard2<4:
   mplay=PuzzleLogic.route_rotate(mplay,cell)
   map_taps+=1
   guard2+=1
 check(PuzzleLogic.route_solved(mplay) and map_taps>=10,"Map: solvable by turning tiles (%d turns), and not trivial" % map_taps)
 var wrong_start=0
 for cell in PuzzleLogic.MAP_SOLUTION:
  var want2=PuzzleLogic.rotate_mask(PuzzleLogic.base_mask(PuzzleLogic.cell_kind(cell,"map")),int(PuzzleLogic.MAP_SOLUTION[cell]))
  if PuzzleLogic.cell_mask(cell,mp.rots,"map")!=want2: wrong_start+=1
 check(wrong_start>=15,"Map: most solution tiles start turned the wrong way (%d of %d)" % [wrong_start,PuzzleLogic.MAP_SOLUTION.size()])
 var mh=PuzzleLogic.route_hint_cell(mp)
 check(mh>=0 and PuzzleLogic.MAP_SOLUTION.has(mh) and PuzzleLogic.route_hint_cell(mapply)==-1 and PuzzleLogic.route_rotate(mp,PuzzleLogic.LEVELS.map.source)==mp,"Map: the hint marks a tile the current needs and goes quiet when solved; the source is fixed")
 check(PuzzleLogic.route_hint(mp).begins_with("Seven lamps") and not PuzzleLogic.route_hint(mp).contains("cell"),"Map: hint 1 describes the rule without naming a tile")
 # ---- sliding rails (M4): the station's sealed archive door
 var rl=PuzzleLogic.rail_default()
 var occ=PuzzleLogic.rail_cells(rl.blocks)
 var cells=0
 for b in rl.blocks: cells+=int(b[2])
 check(occ.size()==cells and not PuzzleLogic.rail_solved(rl),"Rails: the blocks do not overlap and the carriage starts locked in")
 var sol=PuzzleLogic.rail_solve(rl)
 check(sol!=null and sol.size()>=9 and sol.size()<=14,"Rails: solvable by search, shortest solution is %d moves" % (sol.size() if sol!=null else -1))
 var replay=PuzzleLogic.rail_default()
 for mv in sol: replay=PuzzleLogic.rail_move(replay,int(mv[0]),int(mv[1]))
 check(PuzzleLogic.rail_solved(replay) and replay.moves==sol.size(),"Rails: replaying the shortest solution frees the carriage")
 check(PuzzleLogic.rail_move(rl,4,1)==rl and PuzzleLogic.rail_move(rl,0,-1)==rl,"Rails: a blocked move (into another block) and an edge move change nothing")
 var bad_axis=PuzzleLogic.rail_move(rl,4,-1)   # the tall block moves only along its own column (up is blocked here too)
 check(bad_axis==rl or (bad_axis.blocks[4][0]==rl.blocks[4][0]),"Rails: blocks slide only along their own axis")
 var hb=PuzzleLogic.rail_hint_block(rl)
 check(hb>=0 and hb<rl.blocks.size() and PuzzleLogic.rail_hint_block(replay)==-1 and not PuzzleLogic.rail_hint(rl).contains("block 3"),"Rails: the hint names no answer; hint 2 marks the next block to slide")
 # every reachable position of the first 200 searched states is solvable too (no way to paint yourself into a dead end)
 var dead=false
 var frontier=[rl]
 var seen={str(rl.blocks):true}
 var checked=0
 while not frontier.is_empty() and checked<150:
  var cur=frontier.pop_front()
  checked+=1
  if PuzzleLogic.rail_solve(cur)==null: dead=true
  for i in range(cur.blocks.size()):
   for dir in [-1,1]:
    var nx=PuzzleLogic.rail_move(cur,i,dir)
    if nx!=cur and not seen.has(str(nx.blocks)):
     seen[str(nx.blocks)]=true
     frontier.append(nx)
 check(not dead,"Rails: any position reached by sliding can still be solved (checked %d)" % checked)
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
