extends Control
class_name PuzzleScreen
# Episode 3 M3: the resonator puzzle overlay (signal / power / memory). Rules live in PuzzleLogic; this is input + drawing.
# Controls: keyboard (arrows, Enter/Space, H hint, C check, Esc back), mouse and touch (every control is a big Button, or a tap on the board).
# Progress is reported through `changed` after every move (the episode saves it) and `finished(kind, solved)` when the player leaves or solves it.
signal changed(kind:String, state:Dictionary)
signal finished(kind:String, solved:bool)
const PANEL = Rect2(190,50,900,620)
const CYAN = Color("6fd7e4")
const BOARD_ORIGIN = Vector2(230,212)
const CELL = 82.0
var kind="signal"
var state:Dictionary={}
var clues:Array=[]
var canvas:Control
var feedback:Label
var hint_label:Label
var header:Label
var value_labels:Array=[]
var memory_buttons:Array=[]
var action_button:Button
var hint_button:Button
var cursor=0
var selected=""
var time=0.0
var done=false
class Canvas extends Control:
 var host
 func _draw() -> void:
  host.paint(self)
 func _gui_input(event:InputEvent) -> void:
  host.board_input(event)
func setup(k:String, saved:Dictionary, found_clues:Array) -> void:
 kind=k
 clues=found_clues
 var base=PuzzleLogic.signal_default() if k=="signal" else (PuzzleLogic.route_default() if k=="power" else PuzzleLogic.memory_default())
 state=base.duplicate(true)
 for key in saved:
  state[key]=saved[key]
 if k=="power":
  cursor=PuzzleLogic.ROUTE_PATH[1]
 elif k=="memory":
  cursor=0
func _ready() -> void:
 set_anchors_preset(Control.PRESET_FULL_RECT)
 size=Vector2(1280,720)
 mouse_filter=Control.MOUSE_FILTER_STOP
 var dim=ColorRect.new()
 dim.color=Color(0.01,0.01,0.04,0.82)
 dim.size=Vector2(1280,720)
 dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(dim)
 UI.panel(self,PANEL,Color(0.025,0.035,0.075,0.97),Color(UI.VIOLET,0.7))
 UI.trim(self,PANEL,UI.VIOLET)
 canvas=Canvas.new()
 canvas.host=self
 canvas.size=Vector2(1280,720)
 canvas.mouse_filter=Control.MOUSE_FILTER_STOP if kind=="power" else Control.MOUSE_FILTER_IGNORE
 add_child(canvas)
 var titles={"signal":["SIGNAL RESONATOR","Match the live wave to the recorded transmission. Turn FREQUENCY (how many waves) and HEIGHT (how tall), then LOCK."],
  "power":["POWER RESONATOR","The relay is dead. Tap a tile to turn it and send current from the source (left) to the relay lamp (right side). Burnt tiles carry nothing."],
  "memory":["MEMORY RESONATOR","Place the four fragments from the oldest to the newest. Select a fragment, then choose its slot."]}
 UI.chip(self,titles[kind][0],Rect2(230,86,230,28),UI.VIOLET,14)
 UI.label(self,titles[kind][1],Vector2(230,122),17,UI.MUTED,820)
 header=UI.label(self,"",Vector2(230,172),20,UI.GOLD,820)
 feedback=UI.label(self,"",Vector2(230,548),21,Color.WHITE,820)
 hint_label=UI.label(self,"",Vector2(230,578),16,CYAN,820)
 hint_button=UI.button(self,"HINT",Rect2(230,608,170,52),request_hint)
 UI.button(self,"BACK",Rect2(880,608,170,52),func(): leave())
 if kind=="signal":
  value_labels=[UI.label(self,"",Vector2(318,482),30,Color.WHITE,100),UI.label(self,"",Vector2(698,482),30,Color.WHITE,100)]
  UI.label(self,"FREQUENCY",Vector2(230,440),15,UI.MUTED)
  UI.label(self,"HEIGHT",Vector2(610,440),15,UI.MUTED)
  UI.button(self,"<",Rect2(230,470,76,60),func(): nudge(-1,0))
  UI.button(self,">",Rect2(430,470,76,60),func(): nudge(1,0))
  UI.button(self,"<",Rect2(610,470,76,60),func(): nudge(0,-1))
  UI.button(self,">",Rect2(810,470,76,60),func(): nudge(0,1))
  action_button=UI.button(self,"LOCK SIGNAL",Rect2(560,608,260,52),func(): lock_signal(),true)
 elif kind=="power":
  UI.label(self,"Keys: arrows move, Enter turns the tile.",Vector2(860,520),14,UI.MUTED,200)
 else:
  UI.label(self,"OLDEST",Vector2(230,362),15,UI.MUTED)
  UI.label(self,"NEWEST",Vector2(960,362),15,UI.MUTED)
  action_button=UI.button(self,"CHECK ORDER",Rect2(560,608,260,52),func(): check_memory(),true)
  rebuild_memory()
 refresh()
func emit_changed() -> void:
 changed.emit(kind,state.duplicate(true))
func leave() -> void:
 if done and not get_meta("emitted",false):
  set_meta("emitted",true)
  finished.emit(kind,true)
  return
 if not get_meta("emitted",false):
  set_meta("emitted",true)
  finished.emit(kind,is_solved())
func is_solved() -> bool:
 match kind:
  "signal": return PuzzleLogic.signal_solved(state)
  "power": return PuzzleLogic.route_solved(state)
 return PuzzleLogic.memory_solved(state)
func succeed(message:String) -> void:
 if done:
  return
 done=true
 feedback.text=message
 feedback.add_theme_color_override("font_color",Color("9ff0b0"))
 emit_changed()
 await get_tree().create_timer(1.4).timeout
 leave()
func request_hint() -> void:
 if done:
  return
 state["hints"]=int(state.get("hints",0))+1
 refresh()
 emit_changed()
# ---------------------------------------------------------------- signal
func nudge(df:int, da:int) -> void:
 if done:
  return
 state=PuzzleLogic.signal_step(state,df,da)
 refresh()
 emit_changed()
func lock_signal() -> void:
 if done:
  return
 var before=int(state.round)
 state=PuzzleLogic.signal_lock(state)
 refresh()
 emit_changed()
 if PuzzleLogic.signal_solved(state):
  succeed("ALL THREE TRANSMISSIONS RESTORED  /  THE RESONATOR SINGS")
 elif int(state.round)>before:
  feedback.text="LOCKED  /  NEXT TRANSMISSION"
# ---------------------------------------------------------------- power
func board_input(event:InputEvent) -> void:
 if kind!="power" or done:
  return
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var p=event.position-BOARD_ORIGIN
  if p.x<0 or p.y<0 or p.x>=CELL*PuzzleLogic.COLS or p.y>=CELL*PuzzleLogic.ROWS:
   return
  cursor=int(p.y/CELL)*PuzzleLogic.COLS+int(p.x/CELL)
  turn_tile()
func turn_tile() -> void:
 state=PuzzleLogic.route_rotate(state,cursor)
 refresh()
 emit_changed()
 if PuzzleLogic.route_solved(state):
  succeed("POWER RESTORED  /  THE RELAY LAMP BURNS")
# ---------------------------------------------------------------- memory
# A card/slot is a Button (keyboard, mouse and touch all work) with its text on child Labels, so long text wraps inside the card instead of stretching the button.
func card_button(rect:Rect2, title:String, text:String, lit:bool, callback:Callable) -> Button:
 var b=UI.button(self,"",rect,callback,lit)
 var ink=UI.INK if lit else Color("e8e9f4")
 UI.label(b,title,Vector2(12,10),15,ink if lit else UI.GOLD,rect.size.x-24)
 UI.label(b,text,Vector2(12,38),14,ink,rect.size.x-24)
 return b
func rebuild_memory() -> void:
 for b in memory_buttons:
  b.queue_free()
 memory_buttons=[]
 var tray=PuzzleLogic.memory_tray(state,clues)
 for i in range(tray.size()):
  var card=PuzzleLogic.MEMORY_CARDS[tray[i]]
  var id=tray[i]
  memory_buttons.append(card_button(Rect2(230+i*210,214,190,126),card.title,card.text,selected==id,func(): pick_card(id)))
 for i in range(4):
  var held=str(state.slots[i])
  var idx=i
  if held!="":
   var card=PuzzleLogic.MEMORY_CARDS[held]
   memory_buttons.append(card_button(Rect2(230+i*210,388,190,126),card.title,card.text,true,func(): press_slot(idx)))
  else:
   memory_buttons.append(card_button(Rect2(230+i*210,388,190,126),"SLOT %d" % (i+1),"(empty)",false,func(): press_slot(idx)))
func pick_card(id:String) -> void:
 if done:
  return
 selected="" if selected==id else id
 rebuild_memory()
 refresh()
func press_slot(i:int) -> void:
 if done:
  return
 if selected!="":
  state=PuzzleLogic.memory_place(state,selected,i)
  selected=""
 elif str(state.slots[i])!="":
  state=PuzzleLogic.memory_remove(state,i)
 else:
  return
 rebuild_memory()
 refresh()
 emit_changed()
func check_memory() -> void:
 if done:
  return
 state["checks"]=int(state.get("checks",0))+1
 refresh(true)
 emit_changed()
 if PuzzleLogic.memory_solved(state):
  succeed("THE MEMORY HOLDS  /  IN ORDER")
# ---------------------------------------------------------------- shared
func refresh(show_check:bool=false) -> void:
 if kind=="signal":
  var t=PuzzleLogic.signal_target(state)
  header.text="TRANSMISSION %d OF 3  /  %s" % [mini(int(state.round)+1,3),str(t.name)]
  value_labels[0].text=str(int(state.freq))
  value_labels[1].text=str(int(state.amp))
  feedback.text=PuzzleLogic.signal_feedback(state) if not PuzzleLogic.signal_solved(state) else feedback.text
  hint_label.text=PuzzleLogic.signal_hint(state) if int(state.hints)>0 else ""
 elif kind=="power":
  var lit=PuzzleLogic.route_powered(state).size()-1
  header.text="CURRENT REACHES %d TILES" % lit
  feedback.text="The relay is dark." if not PuzzleLogic.route_solved(state) else feedback.text
  hint_label.text=PuzzleLogic.route_hint(state) if int(state.hints)>0 else ""
 else:
  header.text="FRAGMENTS FOUND: %d OF 4" % PuzzleLogic.memory_cards_for(clues).size()
  if show_check or int(state.checks)>0:
   feedback.text=PuzzleLogic.memory_feedback(state) if show_check else feedback.text
  else:
   feedback.text="Select a fragment, then choose its slot. Tap a placed fragment to take it back."
  hint_label.text=PuzzleLogic.memory_hint(state) if int(state.hints)>0 else ""
 if canvas!=null:
  canvas.queue_redraw()
func _process(delta:float) -> void:
 time+=delta
 if canvas!=null and (kind!="memory"):
  canvas.queue_redraw()
func _input(event:InputEvent) -> void:
 if not (event is InputEventKey) or not event.pressed or event.echo:
  return
 var code=event.physical_keycode
 get_viewport().set_input_as_handled()
 if code==KEY_ESCAPE or code==KEY_BACKSPACE:
  leave()
  return
 if code==KEY_H:
  request_hint()
  return
 if done:
  return
 var enter=code==KEY_ENTER or code==KEY_KP_ENTER or code==KEY_SPACE or code==KEY_E
 if kind=="signal":
  match code:
   KEY_LEFT, KEY_A: nudge(-1,0)
   KEY_RIGHT, KEY_D: nudge(1,0)
   KEY_UP, KEY_W: nudge(0,1)
   KEY_DOWN, KEY_S: nudge(0,-1)
  if enter: lock_signal()
 elif kind=="power":
  var x=cursor%PuzzleLogic.COLS
  var y=cursor/PuzzleLogic.COLS
  match code:
   KEY_LEFT, KEY_A: x=maxi(0,x-1)
   KEY_RIGHT, KEY_D: x=mini(PuzzleLogic.COLS-1,x+1)
   KEY_UP, KEY_W: y=maxi(0,y-1)
   KEY_DOWN, KEY_S: y=mini(PuzzleLogic.ROWS-1,y+1)
  cursor=y*PuzzleLogic.COLS+x
  if enter: turn_tile()
  canvas.queue_redraw()
 else:
  var col=cursor%4
  var row=cursor/4
  match code:
   KEY_LEFT, KEY_A: col=maxi(0,col-1)
   KEY_RIGHT, KEY_D: col=mini(3,col+1)
   KEY_UP, KEY_W: row=0
   KEY_DOWN, KEY_S: row=1
   KEY_C: check_memory()
  cursor=row*4+col
  if enter:
   if row==0:
    var tray=PuzzleLogic.memory_tray(state,clues)
    if col<tray.size(): pick_card(tray[col])
   else:
    press_slot(col)
  canvas.queue_redraw()
# ---------------------------------------------------------------- drawing
func paint(c:Control) -> void:
 if kind=="signal":
  paint_signal(c)
 elif kind=="power":
  paint_board(c)
 else:
  paint_memory_cursor(c)
func paint_signal(c:Control) -> void:
 var r=Rect2(230,205,820,215)
 c.draw_rect(r,Color(0.02,0.035,0.07),true)
 c.draw_rect(r,Color(CYAN,0.5),false,2)
 for i in range(1,8):
  c.draw_line(Vector2(r.position.x+r.size.x*i/8.0,r.position.y),Vector2(r.position.x+r.size.x*i/8.0,r.end.y),Color(CYAN,0.08),1)
 c.draw_line(Vector2(r.position.x,r.position.y+r.size.y/2.0),Vector2(r.end.x,r.position.y+r.size.y/2.0),Color(CYAN,0.2),1)
 var t=PuzzleLogic.signal_target(state)
 var half=r.size.y*0.45
 var target_pts=PackedVector2Array()
 var live_pts=PackedVector2Array()
 for i in range(0,241):
  var x=float(i)/240.0
  var px=r.position.x+x*r.size.x
  var mid=r.position.y+r.size.y/2.0
  target_pts.append(Vector2(px,mid-PuzzleLogic.signal_wave(int(t.freq),int(t.amp),x)*half))
  live_pts.append(Vector2(px,mid-PuzzleLogic.signal_wave(int(state.freq),int(state.amp),x+time*0.0)*half))
 c.draw_polyline(target_pts,Color(CYAN,0.55),6,true)
 var locked=PuzzleLogic.signal_distance(state)==0
 c.draw_polyline(live_pts,Color("9ff0b0") if locked else UI.GOLD,3,true)
 c.draw_string(ThemeDB.fallback_font,Vector2(r.position.x+10,r.position.y+22),"RECORDED",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color(CYAN,0.8))
 c.draw_string(ThemeDB.fallback_font,Vector2(r.position.x+100,r.position.y+22),"LIVE",HORIZONTAL_ALIGNMENT_LEFT,-1,13,UI.GOLD)
func paint_board(c:Control) -> void:
 var powered=PuzzleLogic.route_powered(state)
 var hint_cell=PuzzleLogic.route_hint_cell(state) if int(state.get("hints",0))>=2 else -1
 for i in range(PuzzleLogic.COLS*PuzzleLogic.ROWS):
  var x=i%PuzzleLogic.COLS
  var y=i/PuzzleLogic.COLS
  var r=Rect2(BOARD_ORIGIN+Vector2(x*CELL,y*CELL),Vector2(CELL-6,CELL-6))
  var kindname=PuzzleLogic.cell_kind(i)
  c.draw_rect(r,Color(0.04,0.05,0.1),true)
  c.draw_rect(r,Color(0.25,0.28,0.45,0.8),false,1.5)
  var centre=r.position+r.size/2.0
  var live=powered.has(i)
  var col=UI.GOLD if live else Color(0.38,0.42,0.6)
  if kindname=="none":
   c.draw_line(centre-Vector2(22,22),centre+Vector2(22,22),Color("a04050"),4)
   c.draw_line(centre-Vector2(22,-22),centre+Vector2(22,-22),Color("a04050"),4)
  else:
   var mask=PuzzleLogic.cell_mask(i,state.rots)
   for side in [[PuzzleLogic.N,Vector2(0,-1)],[PuzzleLogic.E,Vector2(1,0)],[PuzzleLogic.S,Vector2(0,1)],[PuzzleLogic.W,Vector2(-1,0)]]:
    if mask&side[0]!=0:
     c.draw_line(centre,centre+side[1]*(r.size.x/2.0),col,12)
   c.draw_circle(centre,9,col)
  if kindname=="src":
   c.draw_circle(centre,24,Color(UI.GOLD,0.35+0.2*sin(time*4.0)))
  if kindname=="relay":
   c.draw_circle(centre+Vector2(0,-4),20,Color("fff1b0") if live else Color(0.18,0.2,0.3))
   c.draw_arc(centre+Vector2(0,-4),20,0,TAU,24,Color(UI.GOLD,0.9),2)
  if i==hint_cell:
   c.draw_rect(r.grow(2),Color(1.0,0.4,0.45,0.5+0.4*sin(time*6.0)),false,4)
  if i==cursor:
   c.draw_rect(r.grow(1),Color(CYAN,0.95),false,3)
func paint_memory_cursor(c:Control) -> void:
 var col=cursor%4
 var row=cursor/4
 var r=Rect2(230+col*210-4,(214 if row==0 else 388)-4,198,134)
 c.draw_rect(r,Color(CYAN,0.9),false,3)
