extends RefCounted
class_name WardenLogic
# Episode 3 M4: the Relay Warden encounter as pure rules (no scene, no autoloads), so tests can prove it is fair and deterministic.
# The Warden is not killed: Echo restores three corrupted mechanisms in the order the arena inscription gives. Each correct one interrupts the Warden
# (it is stunned); a wrong one shocks Echo and rouses the Warden. Its attacks are telegraphed for TELEGRAPH seconds on the floor, so they can be read and avoided.
# Positions are world x on the arena strip; zones are [x0, x1] spans. Echo has HP "resonance" points; at 0 the episode reloads the last checkpoint.
const ARENA_W = 2400.0
const PLAYER_MIN = 80.0
const PLAYER_MAX = 2320.0
const SPEED = 300.0           # Explore's walking speed
const REACTION = 0.4          # time a player needs to notice a telegraph (used by the fairness proof, not by the game)
const TELEGRAPH = 1.7
const STRIKE = 0.35
const RECOVER = 1.0
const FIRST_DELAY = 2.5
const STUN = 6.0
const MAX_HP = 5
const INVULN = 1.5
const SLAM_HALF = 120.0
const SWEEP_LEN = 300.0
const PILLAR_W = 180.0
const PILLAR_OFFSET = 400.0
const PATTERNS = ["slam","sweep","pillars","slam","sweep"]
# the mechanisms, in the order the inscription gives (VALVE, then BELL, then SEAL)
const MECHANISMS = {"mech_1":{"name":"SEAL","x":700.0},"mech_2":{"name":"VALVE","x":1250.0},"mech_3":{"name":"BELL","x":1800.0}}
const ORDER = ["mech_2","mech_3","mech_1"]
const WARDEN_MIN = 800.0
const WARDEN_MAX = 2000.0
const WARDEN_SPEED = 70.0
const WARDEN_KEEP = 340.0     # it drifts towards Echo between attacks but keeps this far away, so it never stands on top of the player
static func default_state(restored:Array=[]) -> Dictionary:
 return {"phase":"idle","timer":FIRST_DELAY,"pattern":"","zones":[],"attack_n":0,"x":1700.0,"stun":0.0,"hp":MAX_HP,"inv":0.0,"restored":restored.duplicate(),"done":false}
static func clamp_zone(z:Array) -> Array:
 return [clampf(float(z[0]),0.0,ARENA_W),clampf(float(z[1]),0.0,ARENA_W)]
# the floor zones a pattern covers, given where the Warden and the player stand when it is chosen
static func pattern_zones(pattern:String, warden_x:float, player_x:float) -> Array:
 match pattern:
  "slam": return [clamp_zone([player_x-SLAM_HALF,player_x+SLAM_HALF])]
  "sweep":
   if player_x<warden_x: return [clamp_zone([warden_x-SWEEP_LEN,warden_x])]
   return [clamp_zone([warden_x,warden_x+SWEEP_LEN])]
  "pillars":
   var a=warden_x-PILLAR_OFFSET
   var b=warden_x+PILLAR_OFFSET
   return [clamp_zone([a-PILLAR_W/2.0,a+PILLAR_W/2.0]),clamp_zone([b-PILLAR_W/2.0,b+PILLAR_W/2.0])]
 return []
static func in_zones(zones:Array, x:float) -> bool:
 for z in zones:
  if x>=float(z[0]) and x<=float(z[1]): return true
 return false
# the shortest distance the player must walk from x to stand outside every zone (within the walkable range)
static func safe_distance(zones:Array, x:float) -> float:
 if not in_zones(zones,x):
  return 0.0
 var best=INF
 for cand in [PLAYER_MIN,PLAYER_MAX]:
  if not in_zones(zones,cand): best=minf(best,absf(cand-x))
 for z in zones:
  for edge in [float(z[0])-1.0,float(z[1])+1.0]:
   if edge>=PLAYER_MIN and edge<=PLAYER_MAX and not in_zones(zones,edge):
    best=minf(best,absf(edge-x))
 return best
# how far a player can walk in the time a telegraph is visible, after reacting (a bit under full speed: walking eases up to speed)
static func reach() -> float:
 return (TELEGRAPH-REACTION)*SPEED*0.85
# advance the encounter by dt; returns {"state":..., "events":[...]}. Pure: the input state is not modified.
static func step(state:Dictionary, dt:float, player_x:float) -> Dictionary:
 var s=state.duplicate(true)
 var events=[]
 if bool(s.done) or int(s.hp)<=0:
  return {"state":s,"events":events}
 s.inv=maxf(0.0,float(s.inv)-dt)
 if float(s.stun)>0.0:
  s.stun=maxf(0.0,float(s.stun)-dt)
  s.phase="stunned"
  if float(s.stun)<=0.0:
   s.phase="idle"
   s.timer=1.2
   events.append({"type":"wake"})
  return {"state":s,"events":events}
 # the Warden drifts towards the player between attacks, so standing still never makes the arena safe
 if (s.phase=="idle" or s.phase=="recover") and absf(player_x-float(s.x))>WARDEN_KEEP:
  var dir=signf(player_x-float(s.x))
  s.x=clampf(float(s.x)+dir*WARDEN_SPEED*dt,WARDEN_MIN,WARDEN_MAX)
 s.timer=float(s.timer)-dt
 match str(s.phase):
  "idle", "recover":
   if float(s.timer)<=0.0:
    var pattern=PATTERNS[int(s.attack_n)%PATTERNS.size()]
    s.pattern=pattern
    s.zones=pattern_zones(pattern,float(s.x),player_x)
    s.phase="telegraph"
    s.timer=TELEGRAPH
    events.append({"type":"telegraph","pattern":pattern,"zones":s.zones})
  "telegraph":
   if float(s.timer)<=0.0:
    s.phase="strike"
    s.timer=STRIKE
    events.append({"type":"strike","pattern":s.pattern,"zones":s.zones})
    if in_zones(s.zones,player_x) and float(s.inv)<=0.0:
     s.hp=int(s.hp)-1
     s.inv=INVULN
     events.append({"type":"hit","hp":s.hp})
     if int(s.hp)<=0: events.append({"type":"fail"})
  "strike":
   if float(s.timer)<=0.0:
    s.phase="recover"
    s.timer=RECOVER
    s.zones=[]
    s.attack_n=int(s.attack_n)+1
    events.append({"type":"recover"})
 return {"state":s,"events":events}
# Echo finishes a mechanism. Correct (next in ORDER): it interrupts the Warden; wrong: a feedback shock and the Warden is roused.
static func activate(state:Dictionary, mech:String) -> Dictionary:
 var s=state.duplicate(true)
 var events=[]
 if bool(s.done) or s.restored.has(mech):
  return {"state":s,"events":events}
 if mech==ORDER[s.restored.size()]:
  s.restored.append(mech)
  s.stun=STUN
  s.phase="stunned"
  s.zones=[]
  events.append({"type":"restored","mech":mech,"count":s.restored.size()})
  if s.restored.size()==ORDER.size():
   s.done=true
   s.stun=0.0
   s.phase="done"
   events.append({"type":"restored_all"})
 else:
  events.append({"type":"wrong","mech":mech})
  if float(s.inv)<=0.0:
   s.hp=int(s.hp)-1
   s.inv=INVULN
   events.append({"type":"hit","hp":s.hp})
   if int(s.hp)<=0: events.append({"type":"fail"})
  if s.phase=="idle" or s.phase=="recover":
   s.timer=minf(float(s.timer),0.4)   # roused: the next attack comes quickly
 return {"state":s,"events":events}
# after a failure: back to the last checkpoint with full resonance; restored mechanisms stay restored
static func reset_to_checkpoint(state:Dictionary) -> Dictionary:
 return default_state(state.restored)
# where Echo reappears: the arena entrance, or beside the last restored mechanism
static func checkpoint_x(restored:Array) -> float:
 if restored.is_empty(): return 170.0
 return float(MECHANISMS[restored[restored.size()-1]].x)-140.0
