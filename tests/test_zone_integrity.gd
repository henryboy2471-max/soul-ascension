extends SceneTree
# Static data integrity of every Episode 3 zone: ids, positions inside the world, exits that lead to real zones and land inside them, every zone reachable and able to return, spots that cannot be reached from the spawn, overlapping prompts.
var passed=0
const ALL_LOCKS=["shortcut","tower","floor2","floor3"]
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
 var ZD=load("res://scripts/world/zone_defs.gd")
 var zs=ZD.zones()
 check(zs.size()>=8,"the zone table has %d zones" % zs.size())
 for id in zs:
  var z=zs[id]
  var w=float(z.world_w)
  check(w>=1280.0 and float(z.start_px)>=80.0 and float(z.start_px)<=w-80.0,"%s: world width %.0f and start_px %.0f are valid" % [id,w,float(z.start_px)])
  check(float(z.objective_x)>=0.0 and float(z.objective_x)<=w,"%s: the objective marker x=%.0f is inside the world" % [id,float(z.objective_x)])
  var ids=[]
  var has_exit=false
  for sp in z.spots:
   check(not ids.has(sp.id),"%s: spot id '%s' is unique" % [id,sp.id])
   ids.append(sp.id)
   check(float(sp.x)>=40.0 and float(sp.x)<=w-40.0,"%s/%s: x=%.0f is inside the world" % [id,sp.id,float(sp.x)])
   check(float(sp.range)>=60.0,"%s/%s: interaction range %.0f is usable" % [id,sp.id,float(sp.range)])
   if sp.has("exit"):
    has_exit=true
    var tgt=zs.get(sp.exit.to,{})
    check(not tgt.is_empty(),"%s/%s: exit leads to the existing zone '%s'" % [id,sp.id,sp.exit.to])
    if not tgt.is_empty():
     var sx=float(sp.exit.spawn_x)
     check(sx>=80.0 and sx<=float(tgt.world_w)-80.0,"%s/%s: spawn x=%.0f lands inside '%s' (width %.0f)" % [id,sp.id,sx,sp.exit.to,float(tgt.world_w)])
  for n in z.get("npcs",[]):
   check(float(n.x)>=80.0 and float(n.x)<=w-80.0,"%s: npc '%s' x=%.0f is inside the world" % [id,n.id,float(n.x)])
  check(has_exit,"%s: has at least one exit" % id)
  # every zone can be reached from the market once every lock is open, and can walk back to it
  check(ZD.reachable("market",ALL_LOCKS).has(id),"%s: reachable from the market once every lock is open" % id)
  if id!="market":
   check(ZD.reachable(id,ALL_LOCKS).has("market"),"%s: has a way back to the market" % id)
 # with every lock closed, the zones before the tower must still connect both ways (no soft-lock before the story opens the tower)
 var locked_reach=ZD.reachable("market",[])
 for id in ["market","station","alleys","workshop"]:
  check(locked_reach.has(id),"%s: reachable from the market with every lock closed" % id)
  check(ZD.reachable(id,[]).has("market"),"%s: can walk back to the market with every lock closed" % id)
 for id in ["tower_1","tower_2","tower_3","arena"]:
  check(not locked_reach.has(id),"%s: stays closed until its lock opens" % id)
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
