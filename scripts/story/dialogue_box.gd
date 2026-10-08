extends Control
class_name DialogueBox
# Bottom-of-screen conversation box. Advance with tap/click, Enter, Space, E or J. SKIP ends the scene.
signal finished
const CHARS_PER_SECOND = 70.0
var lines:Array=[]
var index=-1
var shown=0.0
var typing=false
var player_name="Ascendant"
var name_label:Label
var text_label:Label
var hint:Label
var portrait_frame:Control
var portrait_node:Node
var done=false
var box_panel:Panel
var box_trim:Control
var portrait_ring:Panel
var name_plate:Panel
var counter:Label
var pulse_t=0.0
func setup(list:Array, hero_name:String) -> void:
 lines=list
 player_name=hero_name
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 gui_input.connect(on_gui_input)
 var shade=ColorRect.new()
 shade.color=Color(0.01,0.015,0.04,0.45)
 shade.position=Vector2(0,430)
 shade.size=Vector2(1280,290)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 box_panel=UI.panel(self,Rect2(40,468,1200,208),Color(0.025,0.035,0.08,0.96),Color("6a577c"))
 box_trim=UI.trim(self,Rect2(40,468,1200,208),UI.GOLD)
 portrait_frame=Control.new()
 portrait_frame.position=Vector2(62,486)
 portrait_frame.size=Vector2(172,172)
 portrait_frame.clip_contents=true
 portrait_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(portrait_frame)
 portrait_ring=Panel.new()
 portrait_ring.position=Vector2(60,484)
 portrait_ring.size=Vector2(176,176)
 portrait_ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(portrait_ring)
 name_plate=Panel.new()
 name_plate.position=Vector2(256,484)
 name_plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(name_plate)
 name_label=UI.label(self,"",Vector2(270,487),19,Color.WHITE,700)
 UI.outline(name_label,4)
 text_label=UI.label(self,"",Vector2(262,530),24,Color("e6e9f6"),930)
 hint=UI.label(self,"TAP  /  ENTER",Vector2(1000,644),14,UI.GOLD,200)
 hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 counter=UI.label(self,"",Vector2(262,646),13,Color(UI.MUTED,0.8),200)
 var skip=UI.button(self,"SKIP",Rect2(1118,22,132,46),finish_all)
 skip.focus_mode=Control.FOCUS_NONE
 skip.add_theme_font_size_override("font_size",15)
 next_line()
func on_gui_input(event:InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  advance()
func _unhandled_key_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_E,KEY_J]:
  get_viewport().set_input_as_handled()
  advance()
func _process(delta:float) -> void:
 pulse_t+=delta
 hint.modulate.a=0.6+0.4*sin(pulse_t*5.0) if not typing else 0.0
 if typing and not done:
  shown+=delta*CHARS_PER_SECOND
  text_label.visible_characters=int(shown)
  if shown>=text_label.text.length():
   typing=false
   hint.text="TAP  /  ENTER" if index<lines.size()-1 else "TAP  /  ENTER  TO CONTINUE"
func advance() -> void:
 if done:
  return
 if typing:
  shown=text_label.text.length()
  text_label.visible_characters=-1
  typing=false
  return
 next_line()
func next_line() -> void:
 index+=1
 if index>=lines.size():
  finish_all()
  return
 var line=lines[index]
 var speaker=EpisodeData.SPEAKERS.get(line.who,EpisodeData.SPEAKERS.NARRATOR)
 var display=speaker.name
 if line.who=="PLAYER":
  display=player_name.to_upper()
 name_label.text=display
 name_label.add_theme_color_override("font_color",speaker.color)
 style_for(speaker.color,display!="")
 counter.text=str(index+1)+" / "+str(lines.size())
 text_label.text=line.text
 text_label.visible_characters=0
 shown=0.0
 typing=true
 hint.text=""
 Sound.play("tap")
 set_portrait(speaker.portrait)
func style_for(accent:Color, named:bool) -> void:
 # Speaker accent drives the box border, corner trim, nameplate and portrait ring (Hero gold/blue, Mira gold, Enforcer red).
 var box=box_panel.get_theme_stylebox("panel").duplicate()
 box.border_color=Color(accent,0.65)
 box_panel.add_theme_stylebox_override("panel",box)
 box_trim.accent=accent if named else UI.GOLD
 box_trim.queue_redraw()
 name_plate.visible=named
 name_label.visible=named
 if named:
  var plate=StyleBoxFlat.new()
  plate.bg_color=Color(accent,0.16)
  plate.border_color=Color(accent,0.8)
  plate.set_border_width_all(1)
  plate.set_corner_radius_all(4)
  name_plate.add_theme_stylebox_override("panel",plate)
  name_plate.size=Vector2(maxf(120.0,float(name_label.text.length())*14.5+28.0),32)
 var ring=StyleBoxFlat.new()
 ring.bg_color=Color(0,0,0,0)
 ring.border_color=Color(accent,0.85)
 ring.set_border_width_all(2)
 ring.set_corner_radius_all(6)
 portrait_ring.add_theme_stylebox_override("panel",ring)
 text_label.position.y=534 if named else 510
func set_portrait(kind:String) -> void:
 if is_instance_valid(portrait_node):
  portrait_node.queue_free()
  portrait_node=null
 portrait_frame.visible=kind!="none"
 portrait_ring.visible=kind!="none"
 text_label.position.x=262 if kind!="none" else 70
 name_label.position.x=270 if kind!="none" else 78
 name_plate.position.x=256 if kind!="none" else 64
 counter.position.x=262 if kind!="none" else 70
 text_label.size.x=930 if kind!="none" else 1110
 if kind=="hero":
  var art=TextureRect.new()
  var atlas=AtlasTexture.new()
  atlas.atlas=load("res://assets/echo_key_art.png")
  atlas.region=Rect2(612,24,330,330)
  art.texture=atlas
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_SCALE
  art.size=Vector2(172,172)
  art.mouse_filter=Control.MOUSE_FILTER_IGNORE
  portrait_frame.add_child(art)
  portrait_node=art
 elif kind!="none":
  var bg=ColorRect.new()
  bg.color=Color("141a30")
  bg.size=Vector2(172,172)
  bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
  portrait_frame.add_child(bg)
  var rig=Fighter.new()
  rig.position=Vector2(86,330)
  rig.scale=Vector2(1.9,1.9)
  rig.facing=1
  if kind=="mira":
   rig.look="mira"
   rig.accent=Color("ffd86b")
   rig.hair_color=Color("2b2233")
   rig.skin_color=Color("9a6a52")
   rig.coat_color=Color("2b3350")
   rig.armed=false
   if rig.load_sprite_set("res://assets/characters/mira/frames.tres",155.0,Color("c27bff")):
    # sprite art is a full-body figure: enlarge and lower it so the frame shows face and shoulders
    rig.scale=Vector2(3.1,3.1)
    rig.position=Vector2(86,452)
  elif kind=="enforcer":
   rig.enemy=true
  portrait_frame.add_child(rig)
  portrait_node=bg
  rig.set_meta("portrait_rig",true)
func finish_all() -> void:
 if done:
  return
 done=true
 finished.emit()
