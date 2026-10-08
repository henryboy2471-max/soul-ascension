extends RefCounted
class_name UI
const INK=Color("0b1021")
const MUTED=Color("a1a9c2")
const GOLD=Color("efce8e")
const VIOLET=Color("bd95ff")
static func panel(parent:Node, rect:Rect2, color:Color=Color(0.035,0.05,0.105,0.92), border:Color=Color("303650")) -> Panel:
 var node=Panel.new()
 node.position=rect.position
 node.size=rect.size
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style=StyleBoxFlat.new()
 style.bg_color=color
 style.border_color=border
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 node.add_theme_stylebox_override("panel",style)
 parent.add_child(node)
 return node
static func label(parent:Node, words:String, point:Vector2, font_size:int=20, color:Color=Color.WHITE, width:float=0) -> Label:
 var node=Label.new()
 if width>0:
  # Wrap mode and width must be set before the text, or the label first grows to the unwrapped text width.
  node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  node.custom_minimum_size.x=width
 node.text=words
 node.position=point
 node.add_theme_color_override("font_color",color)
 node.add_theme_font_size_override("font_size",font_size)
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(node)
 if width>0:
  node.size.x=width
 return node
static func button(parent:Node, words:String, rect:Rect2, callback:Callable, primary:bool=false) -> Button:
 var node=Button.new()
 node.text=words
 node.position=rect.position
 node.size=rect.size
 node.add_theme_font_size_override("font_size",19)
 node.add_theme_color_override("font_color",INK if primary else Color("e8e9f4"))
 for state in ["normal","hover","pressed","disabled","focus"]:
  var style=StyleBoxFlat.new()
  style.bg_color=GOLD if primary else Color(0.045,0.06,0.12,0.95)
  if state=="hover" or state=="pressed":
   style.bg_color=Color("dec5ff") if primary else Color("292442")
  style.border_color=GOLD if (primary or state=="hover" or state=="pressed") else Color("55526f")
  style.set_border_width_all(1 if state!="focus" else 2)
  style.set_corner_radius_all(5)
  node.add_theme_stylebox_override(state,style)
 node.pressed.connect(func(): Sound.play("tap");callback.call())
 parent.add_child(node)
 return node
static func bar(parent:Node, rect:Rect2, color:Color, maximum:float) -> ProgressBar:
 var node=ProgressBar.new()
 node.position=rect.position
 node.size=rect.size
 node.max_value=maximum
 node.show_percentage=false
 node.add_theme_font_size_override("font_size",1)
 node.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var bg=StyleBoxFlat.new()
 bg.bg_color=Color("171c30")
 bg.set_corner_radius_all(4)
 var fill=StyleBoxFlat.new()
 fill.bg_color=color
 fill.set_corner_radius_all(4)
 node.add_theme_stylebox_override("background",bg)
 node.add_theme_stylebox_override("fill",fill)
 parent.add_child(node)
 node.size=rect.size
 return node
static func hud_bar(parent:Node, rect:Rect2, color:Color, maximum:float) -> HudBar:
 var node=HudBar.new()
 node.position=rect.position
 node.size=rect.size
 node.color=color
 node.max_value=maximum
 node.value=maximum
 parent.add_child(node)
 return node
static func outline(node:Label, size:int=6, color:Color=Color(0.01,0.01,0.05)) -> void:
 node.add_theme_color_override("font_outline_color",color)
 node.add_theme_constant_override("outline_size",size)
class Trim extends Control:
 # Gold (or accent) corner trim and a top rail drawn over a panel: the shared Soul Ascension HUD frame.
 var accent=Color("efce8e")
 var arm=14.0
 func _ready() -> void:
  mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _draw() -> void:
  var r=Rect2(Vector2.ZERO,size)
  draw_line(Vector2(10,0.5),Vector2(size.x-10,0.5),Color(accent,0.55),1)
  for c in [Vector2(0,0),Vector2(size.x,0),Vector2(0,size.y),Vector2(size.x,size.y)]:
   var sx=1.0 if c.x==0 else -1.0
   var sy=1.0 if c.y==0 else -1.0
   draw_line(c+Vector2(0,arm*sy),c,accent,2)
   draw_line(c,c+Vector2(arm*sx,0),accent,2)
static func trim(parent:Node, rect:Rect2, accent:Color=Color("efce8e")) -> Control:
 var node=Trim.new()
 node.position=rect.position
 node.size=rect.size
 node.accent=accent
 parent.add_child(node)
 return node
static func chip(parent:Node, words:String, rect:Rect2, color:Color, font_size:int=12) -> Label:
 # Small filled tag: dark pill, accent border and accent text.
 var back=Panel.new()
 back.position=rect.position
 back.size=rect.size
 back.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var style=StyleBoxFlat.new()
 style.bg_color=Color(color,0.16)
 style.border_color=Color(color,0.8)
 style.set_border_width_all(1)
 style.set_corner_radius_all(10)
 back.add_theme_stylebox_override("panel",style)
 parent.add_child(back)
 var node=label(parent,words,rect.position,font_size,color,rect.size.x)
 node.set_meta("back",back)
 node.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 node.size=rect.size
 return node
static func chip_color(node:Label, color:Color) -> void:
 node.add_theme_color_override("font_color",color)
 var back=node.get_meta("back",null)
 if back!=null:
  var style=back.get_theme_stylebox("panel").duplicate()
  style.bg_color=Color(color,0.16)
  style.border_color=Color(color,0.8)
  back.add_theme_stylebox_override("panel",style)
