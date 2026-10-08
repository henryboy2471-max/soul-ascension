extends Episode
class_name LanternEpisode
# Episode 2 flow (Lantern Quarter): title card -> opening scene -> Depot 4 -> Mira (and Pell on the radio) -> three lantern resonators
# in any order (counter objective) -> roof gate -> Rain Array -> breach opens. Progress is saved per step so returning to the mission
# restores it. M2 ends at the breach-opening transition (the Soul Realm battle arrives in M3).
const RES_IDS = ["res_a","res_b","res_c"]
const RES_X = LanternArt.RES_X
const MEMORIES = {"res_a":Episode2Data.MEMORY_A,"res_b":Episode2Data.MEMORY_B,"res_c":Episode2Data.MEMORY_C}
var synced:Array=[]
var progress:Dictionary={}
func load_progress() -> void:
 progress=Profile.mission_progress(mission_id).duplicate(true)
 progress.erase("combat_run")
 progress.erase("battle_won")
 synced=[]
 for id in progress.get("resonators",[]):
  if RES_IDS.has(id) and not synced.has(id):
   synced.append(id)
func save_progress() -> void:
 # Only this scene's own keys are written; keys owned by the battle (combat_run, battle_won) are kept as the profile holds them.
 progress["resonators"]=synced.duplicate()
 var stored=Profile.mission_progress(mission_id).duplicate(true)
 for key in progress:
  stored[key]=progress[key]
 Profile.set_mission_progress(mission_id,stored)
func run_intro() -> void:
 load_progress()
 if progress.get("intro",false):
  # returning to the mission: skip the cinematic, restore the district state
  begin_explore()
  return
 await card(mission.number+"  /  "+mission.season,mission.title,mission.card_location,true,mission.intro_card_length)
 var backdrop=make_backdrop()
 await say(Episode2Data.INTRO)
 backdrop.queue_free()
 progress["intro"]=true
 save_progress()
 begin_explore()
func lantern_config() -> Dictionary:
 var sleepers=[]
 for i in range(6):
  sleepers.append({"x":560.0+i*86.0,"facing":1 if i%2==0 else -1})
 return {
  "world_w":2760.0,"start_px":140.0,"art":LanternArt,"npc_x":980.0,"walker_count":2,"sleepers":sleepers,"gate_x":LanternArt.GATE_X,
  "spots":[
   {"id":"depot","x":LanternArt.DEPOT_X,"label":"ENTER  /  DEPOT 4","kind":"talk","range":130.0},
   {"id":"mira","x":980.0,"label":"TALK  /  MIRA VEY","kind":"talk","range":130.0},
   {"id":"res_a","x":RES_X[0],"label":"HOLD  /  SYNC RESONATOR","kind":"channel","range":120.0},
   {"id":"res_b","x":RES_X[1],"label":"HOLD  /  SYNC RESONATOR","kind":"channel","range":120.0},
   {"id":"res_c","x":RES_X[2],"label":"HOLD  /  SYNC RESONATOR","kind":"channel","range":120.0},
   {"id":"notice","x":LanternArt.NOTICE_X,"label":"READ  /  MERIDIAN NOTICE","kind":"talk","range":110.0},
   {"id":"gate","x":LanternArt.GATE_X,"label":"READ  /  ROOF GATE","kind":"talk","range":130.0},
   {"id":"array","x":LanternArt.ARRAY_X,"label":"HOLD  /  SYNC RAIN ARRAY","kind":"channel","range":130.0},
   {"id":"breach","x":LanternArt.ARRAY_X,"label":breach_label(),"kind":"talk","range":130.0}
  ],
  "enabled":{"depot":false,"mira":false,"res_a":false,"res_b":false,"res_c":false,"notice":true,"gate":false,"array":false,"breach":false}
 }
func stored_progress() -> Dictionary:
 return Profile.mission_progress(mission_id)
func breach_label() -> String:
 var stored=stored_progress()
 if stored.get("battle_won",false):
  return "THE BREACH  /  QUIET"
 if stored.get("combat_run",false):
  return "RESUME  /  THE BREACH  ·  ENERGY PAID"
 return "ENTER  /  THE BREACH  ·  %d ENERGY" % MissionDefs.energy_cost(mission_id)
func begin_explore() -> void:
 explore=Explore.new()
 explore.config=lantern_config()
 add_child(explore)
 explore.interact.connect(on_interact)
 explore.exit_requested.connect(func(): exit_requested.emit())
 for i in range(3):
  explore.props.lantern_state.synced[i]=synced.has(RES_IDS[i])
 if progress.get("array",false):
  explore.props.breach_open=true
  explore.props.breach_scale=1.0
 var target=0
 if progress.get("depot",false):
  target=1
 if progress.get("mira",false):
  target=2
 if synced.size()>=3:
  target=3
  if progress.get("array",false):
   target=4
 set_step(target)
func objective_text(n:int) -> String:
 var text=str(mission.objectives[n].text)
 return text % synced.size() if n==2 else text
func unsynced_xs() -> Array:
 var xs=[]
 for i in range(3):
  if not synced.has(RES_IDS[i]):
   xs.append(RES_X[i])
 return xs
func set_step(n:int) -> void:
 step=n
 for id in ["depot","mira","gate","array","breach"]+RES_IDS:
  explore.enabled[id]=false
 explore.clear_counter()
 match n:
  0:
   explore.enabled.depot=true
   explore.set_gate_locked(true)
   explore.set_objective(objective_text(0),float(mission.objectives[0].x))
  1:
   explore.enabled.mira=true
   explore.set_gate_locked(true)
   explore.set_objective(objective_text(1),float(mission.objectives[1].x))
  2:
   for i in range(3):
    explore.enabled[RES_IDS[i]]=not synced.has(RES_IDS[i])
   explore.enabled.gate=true
   explore.set_gate_locked(true)
   explore.props.lantern_state.roof_open=false
   explore.set_counter_objective(objective_text(2),unsynced_xs(),synced.size(),3)
  3:
   explore.set_gate_locked(false)
   explore.props.lantern_state.roof_open=true
   explore.enabled.array=true
   explore.set_objective(objective_text(3),float(mission.objectives[3].x))
  4:
   explore.set_gate_locked(false)
   explore.props.lantern_state.roof_open=true
   explore.props.breach_open=true
   explore.props.breach_scale=1.0
   explore.enabled.breach=true
   explore.set_objective(objective_text(4),float(mission.objectives[4].x))
func on_interact(id:String) -> void:
 if busy:
  return
 busy=true
 explore.locked=true
 match id:
  "depot":
   if step==0:
    await say(Episode2Data.DEPOT)
    unlock("sleepers")
    progress["depot"]=true
    save_progress()
    set_step(1)
  "mira":
   if step==1:
    await say(Episode2Data.MIRA_TALK)
    unlock("violet_rain")
    progress["mira"]=true
    save_progress()
    set_step(2)
   elif step>=2:
    await say(Episode2Data.MIRA_REPEAT)
  "notice":
   await say(Episode2Data.NOTICE)
   unlock("rain_array")
   progress["notice"]=true
   save_progress()
  "gate":
   if step<3:
    await say(Episode2Data.GATE_LOCKED)
  "array":
   if step==3:
    await run_array()
  "breach":
   if step==4:
    await enter_breach()
  _:
   if RES_IDS.has(id) and step==2 and not synced.has(id):
    await sync_resonator(id)
 busy=false
 if is_instance_valid(explore):
  explore.act_block=0.45
  explore.locked=false
func sync_resonator(id:String) -> void:
 # Counted exactly once per resonator: the id joins `synced` before any scene plays, and the spot is disabled.
 synced.append(id)
 explore.enabled[id]=false
 explore.props.lantern_state.synced[RES_IDS.find(id)]=true
 var count=synced.size()
 # the counter shows 1/3, 2/3 and 3/3; the roof gate releases exactly at 3/3
 explore.set_counter_objective(objective_text(2),unsynced_xs(),count,3)
 if count>=3:
  explore.set_gate_locked(false)
  explore.props.lantern_state.roof_open=true
  explore.enabled.gate=false
  explore.enabled.array=true
 save_progress()
 explore.pulse_flash(Color(0.6,0.95,1.0))
 await get_tree().create_timer(0.5).timeout
 await say(MEMORIES[id])
 explore.toast("RESONATOR SYNCED  /  %d of 3" % count)
 if count>=3:
  explore.pulse_flash(Color(0.75,0.6,1.0))
  await say(Episode2Data.GATE_UNLOCK)
  set_step(3)
func run_array() -> void:
 explore.pulse_flash(Color(0.75,0.6,1.0))
 await say(Episode2Data.ARRAY)
 unlock("rain_array")
 explore.props.breach_open=true
 await get_tree().create_timer(1.4).timeout
 progress["array"]=true
 save_progress()
 var breach=mission.breach_card
 await card(breach.kicker,breach.title,breach.subtitle,false,breach.length)
 # The breach stays open: exploration is free, and the player decides when to step through.
 set_step(4)
func enter_breach() -> void:
 var stored=stored_progress()
 if stored.get("battle_won",false):
  await say(Episode2Data.BREACH_QUIET)
  return
 Economy.regenerate(Profile.data,int(Time.get_unix_time_from_system()))
 var prompt=BreachPrompt.new()
 prompt.setup(MissionDefs.energy_cost(mission_id),int(Profile.data.energy),bool(stored.get("combat_run",false)))
 add_child(prompt)
 var go=await prompt.decided
 prompt.queue_free()
 if not go:
  return
 # Energy is charged inside request_battle (Profile.begin_run) and only on success. When energy is short the shared recharge
 # screen opens over this scene and nothing here changes: resonators, the open breach and the saved progress stay intact.
 if request_battle.is_valid():
  request_battle.call()
