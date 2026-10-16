extends RefCounted
class_name PuzzleLogic
# Episode 3 M3: the three resonator puzzles as pure rules (no scene, no autoloads) so they can be tested for solvability directly.
#   signal : tune frequency + amplitude until the live wave matches the recorded transmission (3 rounds: the three transmissions the player scanned)
#   power  : rotate pipe tiles so current flows from the source to the damaged relay
#   memory : place four evidence fragments in the order the clues say they happened (oldest to newest)
# Each puzzle keeps a plain Dictionary state (saved in mission_progress["1-3"].puzzles) so leaving and returning never loses progress.
# ---------------------------------------------------------------- signal frequency
const FREQ_MIN = 1
const FREQ_MAX = 12
const AMP_MIN = 1
const AMP_MAX = 8
const SIGNAL_ROUNDS = [
 {"name":"THE LULLABY","freq":3,"amp":3,"hint":"Slow and soft: only a few waves, and none of them tall."},
 {"name":"THE BULLETIN","freq":8,"amp":5,"hint":"Quick and clipped: many waves, of middling height."},
 {"name":"THE LONG TONE","freq":5,"amp":7,"hint":"A steady note with a deep swell: a middling count of tall waves."}
]
static func signal_default() -> Dictionary:
 return {"round":0,"freq":6,"amp":4,"hints":0}
static func signal_solved(state:Dictionary) -> bool:
 return int(state.get("round",0))>=SIGNAL_ROUNDS.size()
static func signal_target(state:Dictionary) -> Dictionary:
 return SIGNAL_ROUNDS[mini(int(state.get("round",0)),SIGNAL_ROUNDS.size()-1)]
static func signal_step(state:Dictionary, dfreq:int, damp:int) -> Dictionary:
 var s=state.duplicate()
 s["freq"]=clampi(int(s.get("freq",6))+dfreq,FREQ_MIN,FREQ_MAX)
 s["amp"]=clampi(int(s.get("amp",4))+damp,AMP_MIN,AMP_MAX)
 return s
# wave height at x in 0..1 for a given tuning (what is drawn); amp is scaled to 0..1
static func signal_wave(freq:int, amp:int, x:float) -> float:
 return float(amp)/float(AMP_MAX)*sin(x*float(freq)*TAU)
# how far off the live tuning is: 0 = locked. Used for the proximity feedback; directions are only revealed by the hint.
static func signal_distance(state:Dictionary) -> int:
 var t=signal_target(state)
 return absi(int(state.freq)-int(t.freq))+absi(int(state.amp)-int(t.amp))
static func signal_feedback(state:Dictionary) -> String:
 var d=signal_distance(state)
 if d==0: return "LOCKED  /  THE PATTERNS MATCH"
 if d<=2: return "VERY CLOSE  /  ONE MORE TURN"
 if d<=5: return "CLOSE  /  THE PATTERN ALMOST FITS"
 return "OFF  /  THE WAVES DO NOT FIT YET"
# LOCK: advances to the next round when matched (knobs reset), otherwise changes nothing
static func signal_lock(state:Dictionary) -> Dictionary:
 if signal_solved(state) or signal_distance(state)!=0:
  return state
 var s=state.duplicate()
 s["round"]=int(s.round)+1
 s["freq"]=6
 s["amp"]=4
 return s
static func signal_hint(state:Dictionary) -> String:
 var level=int(state.get("hints",0))
 var t=signal_target(state)
 if level<=1:
  return str(t.hint)
 var f="FREQUENCY: right" if int(state.freq)==int(t.freq) else ("FREQUENCY: too high" if int(state.freq)>int(t.freq) else "FREQUENCY: too low")
 var a="HEIGHT: right" if int(state.amp)==int(t.amp) else ("HEIGHT: too tall" if int(state.amp)>int(t.amp) else "HEIGHT: too short")
 return f+"   /   "+a
# ---------------------------------------------------------------- power routing (and the relay map: same mechanic, a second level)
const N = 1
const E = 2
const S = 4
const W = 8
# the M3 power board keeps its own constants (tests and saves use them); every routing function takes the level from state.level (default "power")
const COLS = 6
const ROWS = 4
# kind per cell, row-major (y*COLS+x). "src" and "relay" are fixed; "none" is a burnt-out tile that carries nothing; "end" is a one-sided lamp that rotates;
# everything else rotates.
const ROUTE_KINDS = [
 "none","straight","corner","corner","straight","corner",
 "corner","corner","tee","corner","tee","relay",
 "src","corner","tee","corner","straight","corner",
 "straight","corner","tee","corner","straight","none"
]
# the intended path (cell indexes, source to relay) and the rotation each path tile needs; every other tile is a decoy
const ROUTE_PATH = [12,13,7,8,9,15,16,17,11]
const ROUTE_SOLUTION = {13:3,7:1,8:0,9:2,15:0,16:1,17:3}
# a fixed scramble: no path tile starts in its solving rotation
const ROUTE_START = [0,2,1,3,2,1,0,3,1,0,1,2,0,0,1,1,0,0,1,2,3,1,0,0]
const RELAY_CELL = 11
const SOURCE_CELL = 12
# Episode 3 M4 relay map (Teo's workshop): seven array lamps, one source, a tree of 23 tiles that must all be turned right; the rest are decoys.
const MAP_KINDS = ["tee", "corner", "corner", "straight", "end", "corner", "straight", "end", "tee", "tee", "straight", "none", "straight", "end", "src", "tee", "corner", "end", "tee", "corner", "corner", "end", "corner", "tee", "tee", "tee", "corner", "none", "corner", "straight", "corner", "end", "end", "straight", "none"]
const MAP_SOLUTION = {2:1, 3:1, 4:3, 7:1, 8:0, 9:1, 13:2, 15:1, 16:0, 17:3, 19:1, 20:3, 21:2, 22:0, 23:0, 24:0, 25:0, 26:3, 28:0, 29:1, 30:3, 31:0, 32:0}
const MAP_START = [1, 0, 0, 2, 1, 0, 1, 0, 3, 2, 0, 0, 1, 3, 0, 3, 3, 1, 0, 0, 0, 3, 1, 2, 2, 1, 2, 0, 3, 2, 2, 3, 1, 0, 1]
const MAP_LAMPS = [4, 7, 13, 17, 21, 31, 32]
const LEVELS = {
 "power":{"cols":6,"rows":4,"kinds":ROUTE_KINDS,"start":ROUTE_START,"solution":ROUTE_SOLUTION,"source":SOURCE_CELL,"targets":[RELAY_CELL]},
 "map":{"cols":7,"rows":5,"kinds":MAP_KINDS,"start":MAP_START,"solution":MAP_SOLUTION,"source":14,"targets":MAP_LAMPS}
}
static func level_of(state:Dictionary) -> Dictionary:
 return LEVELS[str(state.get("level","power"))]
static func base_mask(kind:String) -> int:
 match kind:
  "straight": return N|S
  "corner": return N|E
  "tee": return E|S|W
  "src": return E
  "relay": return S
  "end": return N
 return 0
static func rotate_mask(mask:int, turns:int) -> int:
 var m=mask
 for i in range(posmod(turns,4)):
  m=((m<<1)&15)|(m>>3)
 return m
static func route_default(level:String="power") -> Dictionary:
 return {"level":level,"rots":LEVELS[level].start.duplicate(),"hints":0}
static func cell_kind(i:int, level:String="power") -> String:
 return LEVELS[level].kinds[i]
static func is_fixed(kind:String) -> bool:
 return kind=="src" or kind=="relay" or kind=="none"
static func cell_mask(i:int, rots:Array, level:String="power") -> int:
 var k=cell_kind(i,level)
 if is_fixed(k):
  return base_mask(k)
 return rotate_mask(base_mask(k),int(rots[i]))
static func route_rotate(state:Dictionary, i:int) -> Dictionary:
 if is_fixed(cell_kind(i,str(state.get("level","power")))):
  return state
 var s=state.duplicate(true)
 s.rots[i]=(int(s.rots[i])+1)%4
 return s
# cells carrying current: flood from the source through tiles whose open sides meet
static func route_powered(state:Dictionary) -> Array:
 var lv=level_of(state)
 var level=str(state.get("level","power"))
 var rots=state.rots
 var cols=int(lv.cols)
 var rows=int(lv.rows)
 var seen=[int(lv.source)]
 var queue=[int(lv.source)]
 while not queue.is_empty():
  var c=queue.pop_front()
  var x=c%cols
  var y=c/cols
  var m=cell_mask(c,rots,level)
  for side in [[N,0,-1,S],[E,1,0,W],[S,0,1,N],[W,-1,0,E]]:
   if m&side[0]==0: continue
   var nx=x+side[1]
   var ny=y+side[2]
   if nx<0 or nx>=cols or ny<0 or ny>=rows: continue
   var n=ny*cols+nx
   if seen.has(n): continue
   if cell_mask(n,rots,level)&side[3]!=0:
    seen.append(n)
    queue.append(n)
 return seen
static func route_unpowered_targets(state:Dictionary) -> Array:
 var lit=route_powered(state)
 var out=[]
 for t in level_of(state).targets:
  if not lit.has(t): out.append(t)
 return out
static func route_solved(state:Dictionary) -> bool:
 return route_unpowered_targets(state).is_empty()
# the stored solution rotations connect every target (a certificate; the power board is additionally proven by search below)
static func route_certificate(level:String) -> bool:
 var s=route_default(level)
 for cell in LEVELS[level].solution:
  s.rots[cell]=LEVELS[level].solution[cell]
 return route_solved(s)
# is there ANY rotation of the rotatable tiles that connects source to relay? (DFS over tile orientations; tests use this to prove solvability of the power board)
static func route_solvable() -> bool:
 return _dfs(SOURCE_CELL,-1,[SOURCE_CELL])
static func _dfs(c:int, from_side:int, seen:Array) -> bool:
 var x=c%COLS
 var y=c/COLS
 var options=[]
 if c==SOURCE_CELL:
  options=[E]
 else:
  var k=cell_kind(c)
  if k=="relay":
   return from_side==S
  if k=="none": return false
  for r in range(4):
   var m=rotate_mask(base_mask(k),r)
   if m&from_side!=0:
    for side in [N,E,S,W]:
     if side!=from_side and m&side!=0 and not options.has(side): options.append(side)
 for side in options:
  var d=[0,0]
  var back=0
  match side:
   N: d=[0,-1]; back=S
   E: d=[1,0]; back=W
   S: d=[0,1]; back=N
   W: d=[-1,0]; back=E
  var nx=x+d[0]
  var ny=y+d[1]
  if nx<0 or nx>=COLS or ny<0 or ny>=ROWS: continue
  var n=ny*COLS+nx
  if seen.has(n): continue
  if _dfs(n,back,seen+[n]): return true
 return false
# first tile that is not yet right: the power board follows its intended path; the map names the first wrong solution tile in index order
static func route_hint_cell(state:Dictionary) -> int:
 var level=str(state.get("level","power"))
 var rots=state.rots
 if level=="map":
  if route_solved(state): return -1
  var sol=LEVELS["map"].solution
  var keys=sol.keys()
  keys.sort()
  for cell in keys:
   if cell_mask(cell,rots,"map")!=rotate_mask(base_mask(cell_kind(cell,"map")),int(sol[cell])): return cell
  return -1
 for i in range(ROUTE_PATH.size()-1):
  var a=ROUTE_PATH[i]
  var b=ROUTE_PATH[i+1]
  var side=0
  var back=0
  var d=b-a
  if d==1: side=E; back=W
  elif d==-1: side=W; back=E
  elif d==COLS: side=S; back=N
  else: side=N; back=S
  if cell_mask(a,rots)&side==0 or cell_mask(b,rots)&back==0:
   return b if cell_mask(a,rots)&side!=0 else a
 return -1
static func route_hint(state:Dictionary) -> String:
 if str(state.get("level","power"))=="map":
  if int(state.get("hints",0))<=1:
   return "Seven lamps, one current. Every lamp hangs off the same line: follow it out from the source and turn each tile to carry it on."
  return "A tile that the current needs is turned the wrong way. It is marked."
 if int(state.get("hints",0))<=1:
  return "Follow the current from the source. It stops where a tile does not meet its neighbour."
 return "A tile on the way is turned the wrong way. It is marked."
# ---------------------------------------------------------------- sliding rails (the station's sealed archive door)
const RAIL_SIZE = 6
const RAIL_BLOCKS = [[0, 2, 2, "h"], [3, 4, 2, "h"], [5, 3, 2, "v"], [1, 4, 2, "h"], [3, 1, 3, "v"], [3, 0, 3, "h"], [0, 5, 2, "h"]]
static func rail_default() -> Dictionary:
 var b=[]
 for blk in RAIL_BLOCKS: b.append(blk.duplicate())
 return {"blocks":b,"moves":0,"hints":0}
static func rail_cells(blocks:Array) -> Dictionary:
 var o={}
 for i in range(blocks.size()):
  var blk=blocks[i]
  for k in range(int(blk[2])):
   o[Vector2i(int(blk[0])+(k if blk[3]=="h" else 0),int(blk[1])+(k if blk[3]=="v" else 0))]=i
 return o
static func rail_can_move(blocks:Array, i:int, dir:int) -> bool:
 var blk=blocks[i]
 var l=int(blk[2])
 var cell=Vector2i(int(blk[0]),int(blk[1]))
 if blk[3]=="h":
  cell.x=int(blk[0])+(l if dir>0 else -1)
 else:
  cell.y=int(blk[1])+(l if dir>0 else -1)
 if cell.x<0 or cell.y<0 or cell.x>=RAIL_SIZE or cell.y>=RAIL_SIZE:
  return false
 var o=rail_cells(blocks)
 return not o.has(cell)
static func rail_move(state:Dictionary, i:int, dir:int) -> Dictionary:
 if not rail_can_move(state.blocks,i,dir):
  return state
 var s=state.duplicate(true)
 if s.blocks[i][3]=="h":
  s.blocks[i][0]=int(s.blocks[i][0])+dir
 else:
  s.blocks[i][1]=int(s.blocks[i][1])+dir
 s["moves"]=int(s.get("moves",0))+1
 return s
# the key block (0) reaches the right edge
static func rail_solved(state:Dictionary) -> bool:
 return int(state.blocks[0][0])+int(state.blocks[0][2])>=RAIL_SIZE
# breadth-first search over block positions: the shortest list of [block, dir] moves from `state`, or null when unsolvable
static func rail_solve(state:Dictionary) -> Variant:
 var start=state.blocks
 var key=func(b): return str(b)
 var seen={str(start):true}
 var queue=[[start,[]]]
 while not queue.is_empty():
  var cur=queue.pop_front()
  var blocks=cur[0]
  if int(blocks[0][0])+int(blocks[0][2])>=RAIL_SIZE:
   return cur[1]
  for i in range(blocks.size()):
   for dir in [-1,1]:
    if rail_can_move(blocks,i,dir):
     var nb=blocks.duplicate(true)
     if nb[i][3]=="h": nb[i][0]=int(nb[i][0])+dir
     else: nb[i][1]=int(nb[i][1])+dir
     var k=str(nb)
     if not seen.has(k):
      seen[k]=true
      queue.append([nb,cur[1]+[[i,dir]]])
 return null
static func rail_hint(state:Dictionary) -> String:
 if int(state.get("hints",0))<=1:
  return "The gold carriage must slide out of the right edge. Clear the rail in front of it, one block at a time."
 return "The next block to slide is marked."
# which block the optimal solution moves next (hint level 2), or -1
static func rail_hint_block(state:Dictionary) -> int:
 var path:Variant=rail_solve(state)
 if path==null or path.is_empty(): return -1
 return int(path[0][0])
# ---------------------------------------------------------------- memory reconstruction
# each card is unlocked by a clue the player found earlier; the order is oldest -> newest
const MEMORY_CARDS = {
 "records":{"title":"REGISTRY LINE","text":"Filed years before the first awakening.","clue":"records"},
 "terminal":{"title":"DELETED INDEX","text":"Forty files deleted by hand six nights ago.","clue":"terminal"},
 "tone":{"title":"THE LONG TONE","text":"Heard in the market tonight, in Echo's own note.","clue":"tx_3"},
 "bulletin":{"title":"CRASH BULLETIN","text":"Tram forty-one. Dated tomorrow evening.","clue":"tx_2"}
}
const MEMORY_ORDER = ["records","terminal","tone","bulletin"]
static func memory_default() -> Dictionary:
 return {"slots":["","","",""],"hints":0,"checks":0}
static func memory_cards_for(clues:Array) -> Array:
 var out=[]
 for id in MEMORY_ORDER:
  if clues.has(MEMORY_CARDS[id].clue): out.append(id)
 return out
static func memory_tray(state:Dictionary, clues:Array) -> Array:
 var out=[]
 for id in memory_cards_for(clues):
  if not state.slots.has(id): out.append(id)
 return out
# put `card` in slot `i`; whatever was there returns to the tray; a card already placed elsewhere moves
static func memory_place(state:Dictionary, card:String, i:int) -> Dictionary:
 var s=state.duplicate(true)
 for j in range(s.slots.size()):
  if s.slots[j]==card: s.slots[j]=""
 s.slots[i]=card
 return s
static func memory_remove(state:Dictionary, i:int) -> Dictionary:
 var s=state.duplicate(true)
 s.slots[i]=""
 return s
static func memory_score(state:Dictionary) -> int:
 var n=0
 for i in range(MEMORY_ORDER.size()):
  if state.slots[i]==MEMORY_ORDER[i]: n+=1
 return n
static func memory_solved(state:Dictionary) -> bool:
 return memory_score(state)==MEMORY_ORDER.size()
static func memory_feedback(state:Dictionary) -> String:
 var filled=0
 for s in state.slots:
  if s!="": filled+=1
 if filled<MEMORY_ORDER.size(): return "PLACE ALL FOUR FRAGMENTS, THEN CHECK"
 if memory_score(state)==MEMORY_ORDER.size(): return "THE MEMORY HOLDS  /  IN ORDER"
 return "NOT YET  /  THE ORDER IS WRONG"   # no count of correct cards: the owner removed that feedback
static func memory_hint(state:Dictionary) -> String:
 if int(state.get("hints",0))<=1:
  return "Oldest first. Look for the words that say WHEN."
 return "The oldest fragment is the one about the registry."
