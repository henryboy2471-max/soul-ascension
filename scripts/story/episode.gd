extends Control
class_name Episode
# Episode flow controller. "intro" phase: title card -> opening scene -> explore with objectives -> Soul Realm breach -> battle.
# "ending" phase (after the battle is won): closing scene -> next-episode teaser -> completed.
signal exit_requested
signal completed
var phase="intro"
var mission_id="1-1"
var mission:Dictionary={}
var request_battle:Callable
var explore:Explore
var step=0
var busy=false
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
 await card(mission.number+"  /  "+mission.season,mission.title,mission.card_location,true,mission.intro_card_length)
 var backdrop=make_backdrop()
 await say(EpisodeData.INTRO)
 backdrop.queue_free()
 begin_explore()
func begin_explore() -> void:
 explore=Explore.new()
 add_child(explore)
 explore.interact.connect(on_interact)
 explore.exit_requested.connect(func(): exit_requested.emit())
 set_step(0)
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
   explore.open_breach()
 explore.set_objective(objective.text,objective.x)
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
  explore.act_block=0.45
  explore.locked=false
func run_ending() -> void:
 var ending=mission.ending
 for id in ending.codex:
  Profile.unlock_codex(id)
 var backdrop=make_backdrop()
 await say(ending.lines)
 backdrop.queue_free()
 var teaser=ending.teaser
 await card(teaser.kicker,teaser.number+"  /  "+teaser.title,teaser.subtitle,true,teaser.length)
 completed.emit()
