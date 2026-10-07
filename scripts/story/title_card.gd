extends Control
class_name TitleCard
# Full-screen cinematic card: slow push-in on the key art (optional), letterbox bars, fading text. Tap/Enter skips.
signal done
var kicker=""
var title=""
var subtitle=""
var use_art=true
var duration=3.4
var finished_flag=false
var art:TextureRect
func setup(k:String, t:String, s:String, with_art:bool=true, length:float=3.4) -> void:
 kicker=k
 title=t
 subtitle=s
 use_art=with_art
 duration=length
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: finish())
 var base=ColorRect.new()
 base.color=Color(0.012,0.016,0.04)
 base.size=Vector2(1280,720)
 base.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(base)
 if use_art:
  art=TextureRect.new()
  art.texture=load("res://assets/echo_key_art.png")
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_SCALE
  art.size=Vector2(1280,853)
  art.position=Vector2(0,20)
  art.pivot_offset=Vector2(640,250)
  art.modulate=Color(0.85,0.85,0.95,0)
  art.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(art)
  var tween=create_tween().set_parallel(true)
  tween.tween_property(art,"scale",Vector2(1.07,1.07),duration)
  tween.tween_property(art,"modulate:a",1.0,0.7)
 for edge in [[0.0,true],[680.0,false]]:
  var bar=ColorRect.new()
  bar.color=Color.BLACK
  bar.size=Vector2(1280,40)
  bar.position=Vector2(0,-40 if edge[1] else 720)
  bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(bar)
  create_tween().tween_property(bar,"position:y",edge[0],0.5)
 var shade=ColorRect.new()
 shade.color=Color(0,0,0,0.38)
 shade.position=Vector2(0,420)
 shade.size=Vector2(1280,300)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 var texts=Control.new()
 texts.modulate.a=0
 texts.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(texts)
 UI.label(texts,kicker,Vector2(90,500),16,UI.GOLD,1100)
 UI.label(texts,title,Vector2(88,528),56,Color.WHITE,1100)
 UI.label(texts,subtitle,Vector2(90,610),19,Color("c2c5d8"),1100)
 var text_tween=create_tween()
 text_tween.tween_interval(0.6)
 text_tween.tween_property(texts,"modulate:a",1.0,0.6)
 UI.label(self,"TAP TO SKIP",Vector2(1090,688),11,UI.MUTED,160).horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 get_tree().create_timer(duration).timeout.connect(finish)
func _unhandled_key_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_SPACE,KEY_E,KEY_J]:
  get_viewport().set_input_as_handled()
  finish()
func finish() -> void:
 if finished_flag:
  return
 finished_flag=true
 done.emit()
