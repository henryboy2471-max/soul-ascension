extends RefCounted
class_name ZoneDefs
# Episode 3 (The Relay Keeper) zone data: five areas, the Central Relay Tower being three connected floors, linked by exits.
# Each zone is one Explore strip (the existing engine is a side-view strip per area, not a seamless open world); areas connect
# through exit spots. Spot kinds: "talk" (press), "channel" (hold). "visual" picks the prop drawn by RelayArt.
# Exits: {id, to, spawn_x (where the player appears in the destination), lock (optional key checked by RelayEpisode)}.
const MARKET = "market"
const STATION = "station"
const ALLEYS = "alleys"
const WORKSHOP = "workshop"
const TOWER_1 = "tower_1"
const TOWER_2 = "tower_2"
const TOWER_3 = "tower_3"
const ARENA = "arena"
const AREAS = {"market":"A","station":"B","alleys":"C","workshop":"D","tower_1":"E","tower_2":"E","tower_3":"E","arena":"E"}
static func zones() -> Dictionary:
 return {
  "market":{
   "name":"LANTERN MARKET","world_w":3400.0,"start_px":170.0,"interior":false,"objective":"Explore Lantern Market","objective_x":1000.0,
   "npcs":[{"id":"witness_a","x":760.0,"hue":0.08},{"id":"witness_b","x":1560.0,"hue":0.55},{"id":"witness_c","x":2380.0,"hue":0.85},{"id":"vendor","x":1230.0,"hue":0.12,"facing":1}],
   "spots":[
    {"id":"exit_alleys","x":70.0,"label":"GO  /  FORGOTTEN ALLEYWAYS","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"alleys","spawn_x":170.0}},
    {"id":"notice","x":520.0,"label":"READ  /  MARKET NOTICE","kind":"talk","range":110.0,"visual":"board"},
    {"id":"witness_a","x":760.0,"label":"TALK  /  WITNESS","kind":"talk","range":120.0,"visual":"none"},
    {"id":"signal_1","x":1000.0,"label":"SCAN  /  SIGNAL DISTURBANCE","kind":"channel","range":120.0,"visual":"signal"},
    {"id":"witness_b","x":1560.0,"label":"TALK  /  WITNESS","kind":"talk","range":120.0,"visual":"none"},
    {"id":"signal_2","x":1900.0,"label":"SCAN  /  SIGNAL DISTURBANCE","kind":"channel","range":120.0,"visual":"signal"},
    {"id":"witness_c","x":2380.0,"label":"TALK  /  WITNESS","kind":"talk","range":120.0,"visual":"none"},
    {"id":"signal_3","x":2800.0,"label":"SCAN  /  SIGNAL DISTURBANCE","kind":"channel","range":120.0,"visual":"signal"},
    {"id":"journal","x":3070.0,"label":"SEARCH  /  BEHIND THE STALL","kind":"talk","range":90.0,"visual":"journal"},
    {"id":"exit_station","x":3330.0,"label":"GO  /  MERIDIAN TRANSIT STATION","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"station","spawn_x":170.0}}
   ]},
  "station":{
   "name":"MERIDIAN TRANSIT STATION","world_w":3000.0,"start_px":170.0,"interior":false,"objective":"Search the transit station","objective_x":1300.0,
   "npcs":[{"id":"anselm","x":1300.0,"hue":0.58,"tint":Color(0.18,0.2,0.28)}],
   "spots":[
    {"id":"exit_market","x":70.0,"label":"GO  /  LANTERN MARKET","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"market","spawn_x":3260.0}},
    {"id":"terminal_a","x":800.0,"label":"ACCESS  /  TERMINAL","kind":"talk","range":110.0,"visual":"terminal"},
    {"id":"anselm","x":1300.0,"label":"TALK  /  FORMER REGISTRY CLERK","kind":"talk","range":130.0,"visual":"none"},
    {"id":"records","x":1750.0,"label":"SEARCH  /  RECORDS","kind":"talk","range":110.0,"visual":"records"},
    {"id":"archive_door","x":2200.0,"label":"EXAMINE  /  ARCHIVE DOOR","kind":"talk","range":120.0,"visual":"door"},
    {"id":"registry_hidden","x":2580.0,"label":"SEARCH  /  LOOSE PANEL","kind":"talk","range":90.0,"visual":"fragment","hidden":true},
    {"id":"exit_alleys_s","x":2930.0,"label":"GO  /  SHORTCUT TO THE ALLEYWAYS","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"alleys","spawn_x":1560.0,"lock":"shortcut"}}
   ]},
  "alleys":{
   "name":"FORGOTTEN ALLEYWAYS","world_w":2400.0,"start_px":170.0,"interior":false,"objective":"Search the alleyways","objective_x":900.0,
   "npcs":[{"id":"pip","x":900.0,"hue":0.14,"scale":0.8,"facing":1}],
   "spots":[
    {"id":"exit_market_a","x":70.0,"label":"GO  /  LANTERN MARKET","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"market","spawn_x":170.0}},
    {"id":"fragment_1","x":560.0,"label":"SEARCH  /  FADED MARK","kind":"talk","range":90.0,"visual":"fragment"},
    {"id":"pip","x":900.0,"label":"TALK  /  CHILD","kind":"talk","range":120.0,"visual":"none"},
    {"id":"fragment_2","x":1250.0,"label":"SEARCH  /  FADED MARK","kind":"talk","range":90.0,"visual":"fragment"},
    {"id":"lever","x":1560.0,"label":"PULL  /  OLD LEVER","kind":"channel","range":110.0,"visual":"lever"},
    {"id":"fragment_3","x":1950.0,"label":"SEARCH  /  FADED MARK","kind":"talk","range":90.0,"visual":"fragment"},
    {"id":"exit_station_a","x":1480.0,"label":"GO  /  SHORTCUT TO THE STATION","kind":"talk","range":90.0,"visual":"exit","exit":{"to":"station","spawn_x":2860.0,"lock":"shortcut"}},
    {"id":"exit_workshop","x":2330.0,"label":"GO  /  TEO'S WORKSHOP","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"workshop","spawn_x":170.0}}
   ]},
  "workshop":{
   "name":"TEO'S WORKSHOP","world_w":1700.0,"start_px":170.0,"interior":true,"objective":"Look around the workshop","objective_x":800.0,
   "npcs":[{"id":"teo","x":800.0,"hue":0.09,"tint":Color(0.3,0.22,0.16),"scale":1.1}],
   "spots":[
    {"id":"exit_alleys_w","x":70.0,"label":"GO  /  FORGOTTEN ALLEYWAYS","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"alleys","spawn_x":2260.0}},
    {"id":"decoder","x":560.0,"label":"EXAMINE  /  SIGNAL DECODER","kind":"talk","range":110.0,"visual":"decoder"},
    {"id":"teo","x":800.0,"label":"TALK  /  RELAY KEEPER","kind":"talk","range":130.0,"visual":"none"},
    {"id":"board","x":1100.0,"label":"EXAMINE  /  EVIDENCE BOARD","kind":"talk","range":120.0,"visual":"board"},
    {"id":"relay_map","x":1400.0,"label":"EXAMINE  /  RELAY MAP","kind":"talk","range":110.0,"visual":"map"},
    {"id":"exit_tower","x":1630.0,"label":"GO  /  CENTRAL RELAY TOWER","kind":"talk","range":100.0,"visual":"exit","exit":{"to":"tower_1","spawn_x":170.0,"lock":"tower"}}
   ]},
  "tower_1":{
   "name":"CENTRAL RELAY TOWER  /  FLOOR 1","world_w":2600.0,"start_px":170.0,"interior":true,"objective":"Climb the Central Relay Tower","objective_x":1300.0,
   "spots":[
    {"id":"exit_down_1","x":70.0,"label":"GO  /  OUT TO THE WORKSHOP","kind":"talk","range":110.0,"visual":"exit","exit":{"to":"workshop","spawn_x":1560.0}},
    {"id":"resonator_1","x":1300.0,"label":"EXAMINE  /  SIGNAL RESONATOR","kind":"talk","range":120.0,"visual":"resonator"},
    {"id":"exit_up_1","x":2530.0,"label":"GO  /  STAIRS UP","kind":"talk","range":100.0,"visual":"stairs","exit":{"to":"tower_2","spawn_x":170.0,"lock":"floor2"}}
   ]},
  "tower_2":{
   "name":"CENTRAL RELAY TOWER  /  FLOOR 2","world_w":2600.0,"start_px":170.0,"interior":true,"objective":"Climb the Central Relay Tower","objective_x":1300.0,
   "spots":[
    {"id":"exit_down_2","x":70.0,"label":"GO  /  STAIRS DOWN","kind":"talk","range":100.0,"visual":"stairs","exit":{"to":"tower_1","spawn_x":2460.0}},
    {"id":"resonator_2","x":1300.0,"label":"EXAMINE  /  POWER RESONATOR","kind":"talk","range":120.0,"visual":"resonator"},
    {"id":"sealed_chamber","x":1950.0,"label":"EXAMINE  /  SEALED CHAMBER","kind":"talk","range":110.0,"visual":"fragment","hidden":true},
    {"id":"exit_up_2","x":2530.0,"label":"GO  /  STAIRS UP","kind":"talk","range":100.0,"visual":"stairs","exit":{"to":"tower_3","spawn_x":170.0,"lock":"floor3"}}
   ]},
  "tower_3":{
   "name":"CENTRAL RELAY TOWER  /  FLOOR 3","world_w":2600.0,"start_px":170.0,"interior":true,"objective":"Reach the top of the tower","objective_x":1300.0,
   "spots":[
    {"id":"exit_down_3","x":70.0,"label":"GO  /  STAIRS DOWN","kind":"talk","range":100.0,"visual":"stairs","exit":{"to":"tower_2","spawn_x":2460.0}},
    {"id":"resonator_3","x":1300.0,"label":"EXAMINE  /  MEMORY RESONATOR","kind":"talk","range":120.0,"visual":"resonator"},
    {"id":"archive_gate","x":2300.0,"label":"EXAMINE  /  SEALED ARCHIVE","kind":"talk","range":120.0,"visual":"door"},
    {"id":"exit_arena","x":2500.0,"label":"GO  /  THE CENTRAL RELAY","kind":"talk","range":100.0,"visual":"exit","exit":{"to":"arena","spawn_x":170.0},"hidden":true}
   ]},
  "arena":{
   "name":"CENTRAL RELAY TOWER  /  THE WARDEN'S CHAMBER","world_w":2400.0,"walk_scale":1.0,"start_px":170.0,"interior":true,"objective":"Wake the three mechanisms in order","objective_x":330.0,
   "npcs":[{"id":"warden","x":1700.0,"hue":0.55,"tint":Color(0.35,0.5,0.72),"scale":1.7,"facing":-1}],
   "spots":[
    {"id":"exit_back","x":70.0,"label":"GO  /  BACK TO THE ARCHIVE GATE","kind":"talk","range":100.0,"visual":"exit","exit":{"to":"tower_3","spawn_x":2380.0}},
    {"id":"inscription","x":330.0,"label":"READ  /  BRASS PLAQUE","kind":"talk","range":110.0,"visual":"board"},
    {"id":"mech_1","x":700.0,"label":"HOLD  /  RESTORE THE SEAL","kind":"channel","range":110.0,"visual":"resonator"},
    {"id":"mech_2","x":1250.0,"label":"HOLD  /  RESTORE THE VALVE","kind":"channel","range":110.0,"visual":"resonator"},
    {"id":"mech_3","x":1800.0,"label":"HOLD  /  RESTORE THE BELL","kind":"channel","range":110.0,"visual":"resonator"},
    {"id":"archive_core","x":2300.0,"label":"EXAMINE  /  THE ARCHIVE CORE","kind":"talk","range":110.0,"visual":"door","hidden":true}
   ]}
 }
static func zone(id:String) -> Dictionary:
 return zones().get(id,{})
static func exits_of(id:String) -> Array:
 var out=[]
 for sp in zone(id).get("spots",[]):
  if sp.has("exit"):
   out.append({"id":sp.id,"x":float(sp.x),"to":sp.exit.to,"spawn_x":float(sp.exit.spawn_x),"lock":str(sp.exit.get("lock",""))})
 return out
# zones reachable from `start` when locked exits are honoured (`open_locks` lists lock keys that are open)
static func reachable(start:String, open_locks:Array=[]) -> Array:
 var seen=[start]
 var queue=[start]
 while not queue.is_empty():
  var z=queue.pop_front()
  for e in exits_of(z):
   if e.lock!="" and not open_locks.has(e.lock):
    continue
   if not seen.has(e.to):
    seen.append(e.to)
    queue.append(e.to)
 return seen
# x of the exit in zone `from` that leads towards zone `to` (locked exits skipped); -1.0 when `to` is not reachable
static func route_x(from:String, to:String, open_locks:Array=[]) -> float:
 if from==to:
  return -1.0
 var first={from:null}
 var queue=[from]
 while not queue.is_empty():
  var z=queue.pop_front()
  for e in exits_of(z):
   if e.lock!="" and not open_locks.has(e.lock):
    continue
   if first.has(e.to):
    continue
   first[e.to]=e if z==from else first[z]
   if e.to==to:
    return float(first[e.to].x)
   queue.append(e.to)
 return -1.0
static func spot_x(zone_id:String, spot_id:String) -> float:
 for sp in zone(zone_id).get("spots",[]):
  if sp.id==spot_id:
   return float(sp.x)
 return -1.0
# Explore config for a zone (art script is supplied by the caller so this file stays free of autoload references)
static func explore_config(id:String, art_script) -> Dictionary:
 var z=zone(id)
 var spots=[]
 var enabled={}
 for sp in z.spots:
  spots.append(sp)
  enabled[sp.id]=not bool(sp.get("hidden",false))   # hidden spots are switched on by the episode once their condition is met
 var cfg={"world_w":float(z.world_w),"start_px":float(z.start_px),"art":art_script,"npcs":z.get("npcs",[]),"companion":true,"no_walkers":bool(z.get("interior",false)),
  "walker_count":2,"spots":spots,"enabled":enabled}
 if z.has("walk_scale"):
  cfg.walk_scale=float(z.walk_scale)   # only the Warden chamber overrides the default exploration pace
 return cfg
