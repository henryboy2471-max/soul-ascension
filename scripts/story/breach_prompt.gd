extends Control
class_name BreachPrompt
# Confirmation shown at the open Rain Array breach. Nothing is charged until the player confirms (energy is spent by Profile.begin_run).
signal decided(go:bool)
var cost=6
var energy=0
var paid=false
var armed=0.35
var done=false
func setup(energy_cost:int, current_energy:int, already_paid:bool) -> void:
 cost=energy_cost
 energy=current_energy
 paid=already_paid
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var dim=ColorRect.new()
 dim.color=Color(0.01,0.0,0.04,0.7)
 dim.size=Vector2(1280,720)
 dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(dim)
 UI.panel(self,Rect2(300,190,680,300),Color(0.025,0.035,0.08,0.97),Color(UI.GOLD,0.7))
 UI.trim(self,Rect2(300,190,680,300),UI.GOLD)
 UI.chip(self,"SOUL REALM  /  THE SLEEPERS' STAIR",Rect2(336,218,330,26),UI.VIOLET,13)
 UI.label(self,"THE BREACH IS OPEN",Vector2(336,256),38)
 var copy="Energy for this run is already paid. Step through to resume." if paid else "Stepping through costs %d energy. Explore as long as you like first: nothing is spent until you enter." % cost
 UI.label(self,copy,Vector2(338,314),20,Color("cbd0e2"),600)
 UI.label(self,"ENERGY  %d" % energy,Vector2(338,388),20,UI.GOLD)
 var enter=UI.button(self,"ENTER THE BREACH",Rect2(336,424,300,52),func(): decide(true),true)
 enter.name="EnterButton"
 var wait=UI.button(self,"NOT YET",Rect2(656,424,200,52),func(): decide(false))
 wait.name="NotYetButton"
 enter.focus_mode=Control.FOCUS_NONE
 wait.focus_mode=Control.FOCUS_NONE
func _process(delta:float) -> void:
 armed=maxf(0.0,armed-delta)
func _unhandled_key_input(event:InputEvent) -> void:
 if armed>0.0 or not event is InputEventKey or not event.pressed or event.echo:
  return
 if event.physical_keycode in [KEY_ENTER,KEY_KP_ENTER,KEY_E]:
  decide(true)
 elif event.physical_keycode==KEY_ESCAPE:
  decide(false)
func decide(go:bool) -> void:
 if done or armed>0.0:
  return
 done=true
 decided.emit(go)
