extends Control
class_name Episode
# Episode flow controller. "intro" phase: title card -> opening scene -> explore with objectives -> Soul Realm breach -> battle.
# "ending" phase (after the battle is won): closing scene -> next-episode teaser -> completed.
signal exit_requested
signal completed
var phase="intro"
var request_battle:Callable
var explore:Explore
var step=0
var busy=false
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 if phase=="ending":
  run_ending()
 else:
  run_intro()
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
 await card("EPISODE 1  /  "+EpisodeData.SEASON,EpisodeData.TITLE,"NEON DISTRICT  /  SKYBRIDGE 09",true,3.6)
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
 match n:
  0:
   explore.enabled.mira=true
   explore.set_objective("Find Mira Vey at the tram",560.0)
  1:
   explore.enabled.terminal=true
   explore.set_objective("Reboot the relay terminal",1560.0)
  2:
   explore.open_breach()
   explore.set_objective("Enter the Soul Realm breach",2200.0)
func on_interact(id:String) -> void:
 if busy:
  return
 busy=true
 explore.locked=true
 match id:
  "mira":
   if step==0:
    await say(EpisodeData.MIRA_TALK)
    set_step(1)
   else:
    await say(EpisodeData.MIRA_REPEAT)
  "board":
   await say(EpisodeData.BOARD)
  "mural":
   await say(EpisodeData.MURAL)
  "terminal":
   if step==1:
    explore.set_terminal_done()
    explore.pulse_flash(Color(0.6,0.5,1.0))
    await get_tree().create_timer(0.5).timeout
    await say(EpisodeData.TERMINAL)
    set_step(2)
  "breach":
   if step==2:
    await say(EpisodeData.BREACH)
    await card("SOUL REALM  /  MISSION ZONE 01","THE RESONANT BRIDGE","SURVIVE THE SUPPRESSION CONSTRUCT",false,2.0)
    var ok=false
    if request_battle.is_valid():
     ok=request_battle.call()
    if not ok:
     await say(EpisodeData.NO_ENERGY)
 busy=false
 if is_instance_valid(explore):
  explore.locked=false
func run_ending() -> void:
 var backdrop=make_backdrop()
 await say(EpisodeData.OUTRO)
 backdrop.queue_free()
 await card("NEXT EPISODE",EpisodeData.NEXT_NUMBER+"  /  "+EpisodeData.NEXT_TITLE,"TO BE CONTINUED...",true,4.0)
 completed.emit()
