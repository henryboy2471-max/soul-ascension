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
# ---------------------------------------------------------------- power routing
const N = 1
const E = 2
const S = 4
const W = 8
const COLS = 6
const ROWS = 4
# kind per cell, row-major (y*COLS+x). "src" and "relay" are fixed; "none" is a burnt-out tile that carries nothing; everything else rotates.
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
static func base_mask(kind:String) -> int:
 match kind:
  "straight": return N|S
  "corner": return N|E
  "tee": return E|S|W
  "src": return E
  "relay": return S
 return 0
static func rotate_mask(mask:int, turns:int) -> int:
 var m=mask
 for i in range(posmod(turns,4)):
  m=((m<<1)&15)|(m>>3)
 return m
static func route_default() -> Dictionary:
 return {"rots":ROUTE_START.duplicate(),"hints":0}
static func cell_kind(i:int) -> String:
 return ROUTE_KINDS[i]
static func cell_mask(i:int, rots:Array) -> int:
 var k=cell_kind(i)
 if k=="src" or k=="relay" or k=="none":
  return base_mask(k)
 return rotate_mask(base_mask(k),int(rots[i]))
static func route_rotate(state:Dictionary, i:int) -> Dictionary:
 var k=cell_kind(i)
 if k=="src" or k=="relay" or k=="none":
  return state
 var s=state.duplicate(true)
 s.rots[i]=(int(s.rots[i])+1)%4
 return s
# cells carrying current: flood from the source through tiles whose open sides meet
static func route_powered(state:Dictionary) -> Array:
 var rots=state.rots
 var seen=[SOURCE_CELL]
 var queue=[SOURCE_CELL]
 while not queue.is_empty():
  var c=queue.pop_front()
  var x=c%COLS
  var y=c/COLS
  var m=cell_mask(c,rots)
  for side in [[N,0,-1,S],[E,1,0,W],[S,0,1,N],[W,-1,0,E]]:
   if m&side[0]==0: continue
   var nx=x+side[1]
   var ny=y+side[2]
   if nx<0 or nx>=COLS or ny<0 or ny>=ROWS: continue
   var n=ny*COLS+nx
   if seen.has(n): continue
   if cell_mask(n,rots)&side[3]!=0:
    seen.append(n)
    queue.append(n)
 return seen
static func route_solved(state:Dictionary) -> bool:
 return route_powered(state).has(RELAY_CELL)
# is there ANY rotation of the rotatable tiles that connects source to relay? (DFS over tile orientations; tests use this to prove solvability)
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
# first tile on the intended path that does not yet connect to its next tile (hint level 2 pulses it)
static func route_hint_cell(state:Dictionary) -> int:
 var rots=state.rots
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
 if int(state.get("hints",0))<=1:
  return "Follow the current from the source. It stops where a tile does not meet its neighbour."
 return "A tile on the way is turned the wrong way. It is marked."
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
 var n=memory_score(state)
 if n==MEMORY_ORDER.size(): return "THE MEMORY HOLDS  /  IN ORDER"
 return "%d OF 4 IN PLACE  /  THE REST ARE OUT OF ORDER" % n
static func memory_hint(state:Dictionary) -> String:
 if int(state.get("hints",0))<=1:
  return "Oldest first. Look for the words that say WHEN."
 return "The oldest fragment is the one about the registry."
