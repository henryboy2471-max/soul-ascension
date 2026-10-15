extends Control
class_name Episode
# Episode flow controller. "intro" phase: title card -> opening scene -> explore with objectives -> Soul Realm breach -> battle.
# "ending" phase (after the battle is won): closing scene -> completed (the rewards screen offers NEXT EPISODE -> teaser).
signal exit_requested
signal completed
var phase="intro"
var mission_id="1-1"
var mission:Dictionary={}
var request_battle:Callable
var explore:Explore
var step=0
var busy=false
var saved:Dictionary={}   # validated resume state of this district-flow mission: intro (bool), step (int), px (float)
func _ready() -> void:
 mission=MissionDefs.get_def(mission_id)
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 if phase=="ending":
  run_ending()
 else:
  run_intro()
func unlock(id:String) -> void:
 if Profile.unlock_codex(id) and is_instance_valid(explore):
  for entry in EpisodeData.CODEX:
   if entry.id==id:
    explore.toast("CODEX UPDATED  /  "+entry.title)
func hero_name() -> String:
 return str(Profile.data.name)
func say(lines:Array) -> void:
 var box=DialogueBox.new()
 box.setup(lines,hero_name())
 add_child(box)
 await box.finished
 box.queue_free()
func card(kicker:String, title:String, subtitle:String, with_art:bool=true, length:float=3.4) -> void:
 var c=TitleCard.new()
 c.setup(kicker,title,subtitle,with_art,length)
 add_child(c)
 await c.done
 c.queue_free()
func make_backdrop() -> TextureRect:
 var art=TextureRect.new()
 art.texture=load("res://assets/echo_key_art.png")
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_SCALE
 art.size=Vector2(1280,853)
 art.position=Vector2(0,20)
 art.modulate=Color(0.5,0.5,0.62)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(art)
 return art
func run_intro() -> void:
 load_saved()
 if saved.has("intro"):
  # returning to the mission (reload or EXIT): skip the cinematic and restore the district state
  begin_explore()
  return
 await card(mission.number+"  /  "+mission.season,mission.title,mission.card_location,true,mission.intro_card_length)
 var backdrop=make_backdrop()
 await say(EpisodeData.INTRO)
 backdrop.queue_free()
 store_state(true,0,-1.0)
 begin_explore()
# Reads the saved resume state defensively: any value that is missing, of the wrong type, out of range or not finite is ignored (never trusted, never fatal).
func load_saved() -> void:
 saved={}
 var raw=Profile.mission_progress(mission_id)
 var st=raw.get("step",null)
 if (st is int or st is float) and is_finite(float(st)) and float(st)==floorf(float(st)) and int(st)>=0 and int(st)<mission.objectives.size():
  saved["step"]=int(st)
 if raw.get("intro",false) is bool and raw.get("intro",false) or saved.has("step"):
  saved["intro"]=true
 var x=raw.get("px",null)
 if (x is int or x is float) and is_finite(float(x)) and float(x)>=80.0 and float(x)<=Explore.WORLD_W-80.0:
  saved["px"]=float(x)
func store_state(intro:bool, at_step:int, at_x:float) -> void:
 var stored=Profile.mission_progress(mission_id).duplicate(true)
 stored["intro"]=intro
 if at_step>=0:
  stored["step"]=at_step
 if at_x>=0.0:
  stored["px"]=snappedf(at_x,1.0)
 Profile.set_mission_progress(mission_id,stored)
func persist_state() -> void:
 if is_instance_valid(explore):
  store_state(true,step,explore.px)
func begin_explore() -> void:
 load_saved()
 explore=Explore.new()
 if saved.has("px"):
  explore.config={"start_px":saved.px}
 var resume_step=int(saved.get("step",0))
 if resume_step>=1:
  explore.enabled.mira=true
 add_child(explore)
 explore.interact.connect(on_interact)
 explore.exit_requested.connect(func():
  persist_state()
  exit_requested.emit())
 if resume_step>=2:
  explore.set_terminal_done()
 set_step(resume_step)
 if Profile.flag(Profile.mission_progress(mission_id),"combat_run"):
  # the energy for this attempt is already paid (closed or reloaded during the fight): say so, and the breach will not charge again
  for spot in explore.spots:
   if spot.id=="breach":
    spot.label="RESUME  /  SOUL REALM BREACH  ·  ENERGY PAID"
func set_step(n:int) -> void:
 step=n
 # Objective text and waypoint come from the mission definition; what each step unlocks stays here (Episode 1 flow).
 var objective=mission.objectives[n]
 match n:
  0:
   explore.enabled.mira=true
  1:
   explore.enabled.terminal=true
  2:
   explore.enabled.terminal=false   # relay is rebooted; no dead 'HOLD' prompt left behind
   explore.open_breach()
 explore.set_objective(objective.text,objective.x)
 persist_state()
func on_interact(id:String) -> void:
 if busy:
  return
 busy=true
 explore.locked=true
 match id:
  "mira":
   if step==0:
    await say(EpisodeData.MIRA_TALK)
    unlock("mira")
    set_step(1)
   else:
    await say(EpisodeData.MIRA_REPEAT)
  "board":
   await say(EpisodeData.BOARD)
   unlock("board")
  "mural":
   await say(EpisodeData.MURAL)
   unlock("mural")
  "terminal":
   if step==1:
    explore.set_terminal_done()
    explore.pulse_flash(Color(0.6,0.5,1.0))
    await get_tree().create_timer(0.5).timeout
    await say(EpisodeData.TERMINAL)
    unlock("terminal")
    set_step(2)
  "breach":
   if step==2:
    await say(EpisodeData.BREACH)
    unlock("breach")
    var breach=mission.breach_card
    await card(breach.kicker,breach.title,breach.subtitle,false,breach.length)
    var ok=false
    if request_battle.is_valid():
     ok=request_battle.call()
    if not ok:
     await say(EpisodeData.NO_ENERGY)
 busy=false
 if is_instance_valid(explore):
  persist_state()
  explore.act_block=0.45
  explore.locked=false
func run_ending() -> void:
 var ending=mission.ending
 for id in ending.codex:
  Profile.unlock_codex(id)
 var backdrop=make_backdrop()
 await say(ending.lines)
 backdrop.queue_free()
 completed.emit()
