extends SceneTree
# Episode 3 M4: the Warden's rules are fair and deterministic. Pure logic (no scene).
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
# a competent player: stands wherever they like, but walks out of any telegraphed zone as soon as it appears (after the reaction time)
func simulate(start_x:float, seconds:float, dodge:bool) -> Dictionary:
 var s=WardenLogic.default_state()
 var x=start_x
 var hits=0
 var telegraphs=0
 var seen_for=0.0
 var t=0.0
 var dt=1.0/60.0
 while t<seconds:
  var r=WardenLogic.step(s,dt,x)
  s=r.state
  for e in r.events:
   if e.type=="hit": hits+=1
   if e.type=="telegraph": telegraphs+=1; seen_for=0.0
  if s.phase=="telegraph": seen_for+=dt
  if dodge and s.phase=="telegraph" and seen_for>=WardenLogic.REACTION and WardenLogic.in_zones(s.zones,x):
   # walk towards the nearest safe edge at 85% of walking speed
   var best=x
   var bd=INF
   for z in s.zones:
    for edge in [float(z[0])-2.0,float(z[1])+2.0]:
     if edge>=WardenLogic.PLAYER_MIN and edge<=WardenLogic.PLAYER_MAX and not WardenLogic.in_zones(s.zones,edge) and absf(edge-x)<bd:
      bd=absf(edge-x)
      best=edge
   x+=signf(best-x)*minf(absf(best-x),WardenLogic.SPEED*0.85*dt)
  t+=dt
 return {"hits":hits,"telegraphs":telegraphs,"hp":s.hp}
func run() -> void:
 # ---- every telegraph can be read and escaped in time, wherever the player and the Warden stand
 var unfair=0
 var worst=0.0
 for wx in range(int(WardenLogic.WARDEN_MIN),int(WardenLogic.WARDEN_MAX)+1,50):
  for px in range(int(WardenLogic.PLAYER_MIN),int(WardenLogic.PLAYER_MAX)+1,20):
   for pattern in ["slam","sweep","pillars"]:
    var zones=WardenLogic.pattern_zones(pattern,float(wx),float(px))
    var d=WardenLogic.safe_distance(zones,float(px))
    worst=maxf(worst,d)
    if d>WardenLogic.reach(): unfair+=1
 check(unfair==0,"Every pattern, from every Warden and player position, can be escaped within the telegraph time (worst %.0f px, reach %.0f px)" % [worst,WardenLogic.reach()])
 check(WardenLogic.TELEGRAPH>=1.5 and WardenLogic.pattern_zones("slam",1500.0,1000.0)[0][0]==880.0,"The telegraph is at least 1.5 s and a slam is centred where the player stood")
 # ---- a player who reads the telegraphs is never hit; one who stands still is
 var clean=true
 for sx in [150.0,700.0,1250.0,1800.0,2300.0]:
  var r=simulate(sx,60.0,true)
  if r.hits>0 or r.telegraphs<10: clean=false
 check(clean,"A player who walks out of each telegraph takes no damage over 60 s from five starting positions")
 var still=simulate(1500.0,40.0,false)
 check(still.hits>=1 and still.hp<WardenLogic.MAX_HP,"A player who ignores the telegraphs is hit (%d hits in 40 s)" % still.hits)
 # ---- the encounter flow: stun, damage, invulnerability
 var s=WardenLogic.default_state()
 var r=WardenLogic.activate(s,"mech_2")
 check(r.state.restored==["mech_2"] and r.state.phase=="stunned" and r.events[0].type=="restored","The first mechanism in the inscription's order restores and stuns the Warden")
 var stunned=r.state
 var attacked=false
 for i in range(int(WardenLogic.STUN*60.0)-2):
  var q=WardenLogic.step(stunned,1.0/60.0,500.0)
  stunned=q.state
  for e in q.events:
   if e.type=="telegraph" or e.type=="strike": attacked=true
 check(not attacked and stunned.stun>0.0,"A stunned Warden does not attack (for %.0f s)" % WardenLogic.STUN)
 var woke=WardenLogic.step(stunned,1.0,500.0)
 check(woke.events.any(func(e): return e.type=="wake") and woke.state.phase=="idle","The Warden wakes after the stun")
 var wrong=WardenLogic.activate(WardenLogic.default_state(),"mech_1")
 check(wrong.state.hp==WardenLogic.MAX_HP-1 and wrong.state.restored.is_empty() and wrong.events.any(func(e): return e.type=="wrong") and wrong.state.timer<=0.4,"A wrong mechanism shocks Echo, restores nothing and rouses the Warden")
 var twice=WardenLogic.activate(wrong.state,"mech_3")
 check(twice.state.hp==WardenLogic.MAX_HP-1,"Invulnerability stops one mistake costing two points at once")
 var full=WardenLogic.default_state()
 for m in WardenLogic.ORDER: full=WardenLogic.activate(full,m).state
 check(full.done and full.restored==WardenLogic.ORDER and WardenLogic.activate(WardenLogic.default_state(),"mech_2").events.size()==1,"The three mechanisms in order finish the encounter (restored, not destroyed)")
 var fin=WardenLogic.default_state()
 var evs=[]
 for m in WardenLogic.ORDER:
  var a=WardenLogic.activate(fin,m)
  fin=a.state
  evs+=a.events
 check(evs.any(func(e): return e.type=="restored_all") and WardenLogic.step(fin,1.0,0.0).events.is_empty(),"After restoration the Warden stays quiet")
 # ---- failure and checkpoints
 var low=WardenLogic.default_state(["mech_2"])
 low.hp=1
 low.inv=0.0
 var f=WardenLogic.activate(low,"mech_1")
 check(f.events.any(func(e): return e.type=="fail") and f.state.hp<=0,"Running out of resonance fails the attempt")
 var back=WardenLogic.reset_to_checkpoint(f.state)
 check(back.hp==WardenLogic.MAX_HP and back.restored==["mech_2"] and back.phase=="idle" and back.timer>=WardenLogic.FIRST_DELAY-0.01,"A failure resets to the checkpoint with full resonance and keeps restored mechanisms")
 check(WardenLogic.checkpoint_x([])==170.0 and WardenLogic.checkpoint_x(["mech_2"])==WardenLogic.MECHANISMS.mech_2.x-140.0,"Checkpoints: the entrance, then beside the last restored mechanism")
 # ---- deterministic
 var a1=simulate(1000.0,30.0,true)
 var a2=simulate(1000.0,30.0,true)
 check(a1==a2,"The same inputs always give the same fight")
 var order_ok=WardenLogic.ORDER==["mech_2","mech_3","mech_1"] and WardenLogic.MECHANISMS.mech_2.name=="VALVE" and WardenLogic.MECHANISMS.mech_3.name=="BELL" and WardenLogic.MECHANISMS.mech_1.name=="SEAL"
 check(order_ok,"The intended order is VALVE, BELL, SEAL (not left to right)")
 # ---- the Warden keeps its distance instead of standing on top of Echo
 var keep=WardenLogic.default_state()
 for i in range(60*30):
  keep=WardenLogic.step(keep,1.0/60.0,900.0).state
 check(absf(float(keep.x)-900.0)>=WardenLogic.WARDEN_KEEP-2.0 and float(keep.x)<1700.0,"The Warden closes in but stops %.0f px from Echo (it ended %.0f px away)" % [WardenLogic.WARDEN_KEEP,absf(float(keep.x)-900.0)])
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
