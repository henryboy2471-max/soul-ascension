extends Control
class_name NeonDemo
# SOUL ASCENSION: 2.5D Neon District demonstration. A small, self-contained, NON-CANON playable slice that proves the 2.5D architecture:
# four-direction exploration with depth, collisions, foreground occlusion, enterable interiors, NPC conversations, an investigation, an
# environmental puzzle and a hidden pathway. It never reads or writes saves (Profile) and is not part of the 10-episode story.
# Start: --demo-neon (desktop) or ?demo=neon (web). Placeholder art; only Echo follows an approved design.
signal exit_requested
const SPEAKERS = {
 "ECHO":{"name":"ECHO","color":Color("efce8e"),"portrait":"tex:echo"},
 "IMANI":{"name":"IMANI  /  TRAM MECHANIC","color":Color("4ad0ff"),"portrait":"tex:imani"},
 "KOFI":{"name":"KOFI  /  NOODLE STALL","color":Color("ffb040"),"portrait":"tex:kofi"},
 "ADAEZE":{"name":"MAMA ADAEZE","color":Color("d890ff"),"portrait":"tex:adaeze"},
 "ZURI":{"name":"ZURI","color":Color("ff7ac0"),"portrait":"tex:zuri"},
 "OKOYE":{"name":"OFFICER OKOYE","color":Color("7aa8ff"),"portrait":"tex:okoye"},
 "NGOZI":{"name":"NGOZI  /  NOODLE HOUSE","color":Color("ffb050"),"portrait":"tex:ngozi"},
 "NARRATOR":{"name":"","color":Color("a1a9c2"),"portrait":"none"},
 "SIGNAL":{"name":"UNKNOWN SIGNAL","color":Color("bd95ff"),"portrait":"none"}
}
const OBJECTIVES = [
 "Talk to Imani at the tram repair kiosk",
 "Listen to the NEON DISTRICT tower  (hold ACT)",
 "Find where the combination goes  /  Junction 7",
 "Enter the pulse pattern on the junction boxes",
 "Enter the hidden passage",
 "Follow the passage to the Backroom Arcade",
 "Examine the arcade terminal",
 "Demo complete"
]
const PULSE = ["cyan","gold","violet"]
const BOX_COL = {"cyan":Color("35e6ff"),"gold":Color("ffc060"),"violet":Color("a070ff")}
var stage:Stage25
var street:Stage25
var where="street"
var flags:Dictionary={"talked_imani":false,"clue":false,"talked_kofi":false,"solved":false,"opened":false,"in_passage":false,"terminal":false,"notice":false,"done":false}
var objective=0
var locked=false
var ui:CanvasLayer
var dlg:DialogueBox
var stick:VirtualStick
var act_btn:TouchAction
var obj_label:Label
var prompt_label:Label
var hold_ring:Control
var bar_top:ColorRect
var bar_bot:ColorRect
var fade:ColorRect
var card:Label
var card_sub:Label
var act_edge=false
var act_cool=0.0
var hold_t=0.0
var hold_blocked=false
var seq:Array=[]
var wrong_t=0.0
var junctions:Dictionary={}
var hidden_door:Prop25
var return_pos=Vector2(1115,0.2)
var time=0.0
var perf:Dictionary={}
var frame_ms:Array=[]
var qa_enabled=false
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 build_ui()
 qa_enabled=OS.has_feature("web") and str(JavaScriptBridge.eval("window.location.search",true)).contains("qa=1")
 enter_stage("street",Vector2(380,0.52),"right")
 stage.zoom=1.22
 stage.snap_camera()
 stage.zoom=1.22
 stage.apply_camera()
 intro()
# ------------------------------------------------------------------ UI
func build_ui() -> void:
 ui=CanvasLayer.new()
 ui.layer=10
 add_child(ui)
 bar_top=ColorRect.new()
 bar_top.color=Color(0,0,0,1)
 bar_top.size=Vector2(1280,0)
 ui.add_child(bar_top)
 bar_bot=ColorRect.new()
 bar_bot.color=Color(0,0,0,1)
 bar_bot.size=Vector2(1280,0)
 bar_bot.position=Vector2(0,720)
 ui.add_child(bar_bot)
 var panel=UI.panel(ui,Rect2(24,20,520,64),Color(0.03,0.04,0.1,0.78),Color(0.55,0.4,0.9,0.55))
 UI.label(panel,"OBJECTIVE",Vector2(14,6),13,UI.GOLD)
 obj_label=UI.label(panel,"",Vector2(14,26),21,Color("e6e9f6"),490)
 prompt_label=UI.label(ui,"",Vector2(340,610),24,Color.WHITE,600)
 prompt_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 UI.outline(prompt_label)
 hold_ring=Control.new()
 hold_ring.position=Vector2(590,560)
 hold_ring.size=Vector2(100,100)
 hold_ring.mouse_filter=Control.MOUSE_FILTER_IGNORE
 hold_ring.draw.connect(draw_hold)
 ui.add_child(hold_ring)
 var exit_btn=UI.button(ui,"EXIT DEMO",Rect2(1118,78,132,40),func(): exit_requested.emit())
 exit_btn.focus_mode=Control.FOCUS_NONE
 exit_btn.add_theme_font_size_override("font_size",15)
 stick=VirtualStick.new()
 stick.position=Vector2(36,520)
 stick.size=Vector2(180,180)
 ui.add_child(stick)
 act_btn=TouchAction.new()
 act_btn.title="ACT"
 act_btn.subtitle="E"
 act_btn.position=Vector2(1110,586)
 act_btn.size=Vector2(104,104)
 act_btn.tint=UI.GOLD
 ui.add_child(act_btn)
 act_btn.activated.connect(func(): act_edge=true)
 fade=ColorRect.new()
 fade.color=Color(0,0,0,1)
 fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(fade)
 card=UI.label(ui,"",Vector2(140,290),64,Color.WHITE,1000)
 card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 UI.outline(card,12,Color(0.4,0.15,0.7,0.9))
 card_sub=UI.label(ui,"",Vector2(140,376),22,Color("cdbdff"),1000)
 card_sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 card.modulate.a=0.0
 card_sub.modulate.a=0.0
 set_objective(0)
func draw_hold() -> void:
 if hold_t<=0.0 or stage==null:
  return
 var sp=stage.nearest_spot()
 var need=float(sp.get("hold",1.0)) if not sp.is_empty() else 1.0
 var f=clampf(hold_t/need,0.0,1.0)
 hold_ring.draw_arc(Vector2(50,50),34,0,TAU,48,Color(1,1,1,0.15),6)
 hold_ring.draw_arc(Vector2(50,50),34,-PI/2,-PI/2+TAU*f,48,Color("bd95ff"),6)
func set_objective(i:int) -> void:
 objective=maxi(objective,i) if i>0 else 0
 obj_label.text=OBJECTIVES[objective]
func bars(on:bool, t:float=0.5) -> void:
 var tw=create_tween().set_parallel(true)
 tw.tween_property(bar_top,"size:y",64.0 if on else 0.0,t)
 tw.tween_property(bar_bot,"size:y",64.0 if on else 0.0,t)
 tw.tween_property(bar_bot,"position:y",656.0 if on else 720.0,t)
func fade_to(a:float, t:float=0.45) -> void:
 var tw=create_tween()
 tw.tween_property(fade,"color:a",a,t)
 await tw.finished
func show_card(title:String, sub:String, hold:float=2.0) -> void:
 card.text=title
 card_sub.text=sub
 var tw=create_tween()
 tw.tween_property(card,"modulate:a",1.0,0.6)
 tw.parallel().tween_property(card_sub,"modulate:a",1.0,0.8)
 tw.tween_interval(hold)
 tw.tween_property(card,"modulate:a",0.0,0.7)
 tw.parallel().tween_property(card_sub,"modulate:a",0.0,0.7)
 await tw.finished
# ------------------------------------------------------------------ scenes
func intro() -> void:
 locked=true
 bars(true,0.1)
 await get_tree().create_timer(0.1).timeout
 await fade_to(0.0,1.2)
 show_card("NEON DISTRICT","2.5D DEMONSTRATION  /  NOT PART OF THE EPISODES",1.4)
 await say([{"who":"ECHO","text":"Rain on neon. The whole district hums like it's holding its breath."}])
 bars(false)
 locked=false
func enter_stage(kind:String, at:Vector2, d:String="right") -> void:
 if stage!=null and stage!=street:
  stage.queue_free()
 if stage!=null and stage==street:
  street.visible=false
  street.process_mode=Node.PROCESS_MODE_DISABLED
  if street.rain:
   street.rain.visible=false
 where=kind
 if kind=="street":
  if street!=null:
   stage=street
   street.visible=true
   street.process_mode=Node.PROCESS_MODE_INHERIT
   if street.rain:
    street.rain.visible=true
   street.player.wx=at.x
   street.player.z=at.y
   street.player.set_dir(d)
   street.vel=Vector2.ZERO
   street.snap_camera()
   return
  stage=build_street(at,d)
  street=stage
 elif kind=="noodle":
  stage=build_noodle()
 elif kind=="hidden_alley":
  stage=build_alley()
 elif kind=="arcade":
  stage=build_arcade()
 if kind!="street":
  stage.player.wx=at.x
  stage.player.z=at.y
  stage.player.set_dir(d)
 stage.snap_camera()
func travel(kind:String, at:Vector2, d:String="right", label:String="") -> void:
 locked=true
 await fade_to(1.0,0.35)
 prompt_label.text=""
 enter_stage(kind,at,d)
 await fade_to(0.0,0.5)
 locked=false
 act_cool=0.4
func build_stage_base(kind:String, width:float) -> Stage25:
 var s=Stage25.new()
 add_child(s)
 move_child(s,0)
 s.reduced_motion=false
 s.build(kind,width)
 s.footstep.connect(func(surface): Sound.footstep(surface))
 return s
func wire_player(s:Stage25, id:String, at:Vector2) -> void:
 s.set_player(id,at.x,at.y)
 s.player.footstep.connect(func():
  Sound.footstep(s.surface,0.9)
  s.add_splash(s.player.wx,s.player.z))
func light_signs(s:Stage25) -> void:
 for st in NeonArt.STORES:
  var cx=float(st.x)+float(st.w)*0.5
  var col=Color(st.col)
  var fl=0.0
  if st.get("tower",false):
   fl=0.7
  if st.get("dim",false):
   fl=0.85
  s.add_glow(Vector2(cx,258),float(st.w)*0.75,col,0.16 if not st.get("dim",false) else 0.07,fl)
  s.add_glow(Vector2(cx,462),float(st.w)*1.0,col,0.10,fl*0.6,0.28)
func build_street(at:Vector2, d:String) -> Stage25:
 var s=build_stage_base("street",4800.0)
 wire_player(s,"echo",at)
 light_signs(s)
 var plum=Color("a070ff")
 # --- lamps (back sidewalk) and foreground poles / banners that hide the player when walked behind
 for x in [300,1100,1900,2700,3500,4300]:
  var p=s.add_prop("lamp",float(x),0.10,Vector2(6,3),Color("ffd89a"))
  s.add_glow(Vector2(float(x),Stage25.y_of(0.10)-170.0*Stage25.s_of(0.10)),130,Color("ffd89a"),0.16,0.0)
 for x in [700,1850,3000,4150]:
  var pole=s.add_prop("pole",float(x),0.93,Vector2(10,4),Color("35e6ff"))
  pole.occluder=true
 for x in [1000,2100,3350,4500]:
  var b=s.add_prop("banner",float(x),0.97,Vector2.ZERO,[Color("ff4fb0"),Color("35e6ff"),Color("ffc060"),Color("a070ff")][(x/1000)%4])
  b.occluder=true
 # --- street furniture with collisions
 for v in [[640,"cyan"],[2350,"magenta"],[3920,"gold"]]:
  var c={"cyan":Color("35e6ff"),"magenta":Color("ff4fb0"),"gold":Color("ffc060")}[v[1]]
  s.add_prop("vending",float(v[0]),0.09,Vector2(34,6),c)
  s.add_glow(Vector2(float(v[0]),Stage25.y_of(0.09)-70.0),110,c,0.14)
 for x in [1500,2650,3700]:
  s.add_prop("bench",float(x),0.86,Vector2(56,7),plum)
 for x in [420,1780,3200,4000]:
  s.add_prop("planter",float(x),0.74,Vector2(30,7),Color("ff9ac8"))
 s.add_prop("crate",3020.0,0.14,Vector2(24,6))
 s.add_prop("crate",3050.0,0.30,Vector2(24,6))
 # --- Kofi's stall
 s.add_prop("stall",560.0,0.20,Vector2(124,8))
 var kofi=s.add_actor("kofi",560.0,0.11,"down")
 s.add_spot("kofi",560.0,0.34,"TALK  /  KOFI",150.0,34.0)
 # --- Imani and the tram repair kiosk
 s.add_prop("kiosk",1480.0,0.17,Vector2(60,8),Color("4ad0ff"))
 var imani=s.add_actor("imani",1572.0,0.25,"left")
 s.add_spot("imani",1572.0,0.34,"TALK  /  IMANI",90.0,34.0)
 # --- the flickering NEON DISTRICT tower (investigation)
 s.add_prop("sign_tower",2180.0,0.20,Vector2(30,8),Color("bd7bff"))
 s.add_glow(Vector2(2180,Stage25.y_of(0.20)-160.0),220,Color("bd7bff"),0.22,0.8)
 s.add_spot("tower",2180.0,0.36,"LISTEN  /  NEON DISTRICT TOWER",100.0,34.0,1.4)
 # --- Mama Adaeze on a bench, Zuri by the puddles, Officer Okoye under the awning
 var ad=s.add_actor("adaeze",1500.0,0.80,"right")
 ad.radius=Vector2(14,5)
 s.add_spot("adaeze",1500.0,0.72,"TALK  /  MAMA ADAEZE",90.0,30.0)
 var zu=s.add_actor("zuri",1320.0,0.62,"down")
 s.add_spot("zuri",1320.0,0.56,"TALK  /  ZURI",80.0,30.0)
 var ok=s.add_actor("okoye",2560.0,0.82,"left")
 s.add_spot("okoye",2560.0,0.74,"TALK  /  OFFICER OKOYE",90.0,30.0)
 # --- Noodle House door
 s.add_spot("noodle_door",1115.0,0.06,"ENTER  /  NOODLE HOUSE",60.0,26.0)
 # --- Junction 7: three breaker boxes on the alley wall + the hidden panel
 var order=[["gold",3090.0],["violet",3165.0],["cyan",3240.0]]
 for o in order:
  var j=s.add_prop("junction",o[1],0.08,Vector2(26,5),BOX_COL[o[0]])
  junctions[o[0]]=j
  s.add_spot("junction_"+o[0],o[1],0.17,"PRESS  /  "+o[0].to_upper()+" BREAKER",36.0,26.0)
 hidden_door=s.add_prop("hidden_door",3460.0,0.0,Vector2.ZERO,Color("8a4dff"))
 hidden_door.position.y=NeonArt.Y_BACK
 s.add_spot("hidden",3460.0,0.08,"EXAMINE  /  WALL PANEL",70.0,28.0)
 s.add_spot("tram",4640.0,0.20,"LEAVE THE DISTRICT  /  TRAM 4",70.0,40.0)
 # --- pedestrians: walking, with their own collision and four-direction animation
 s.add_ped("tunde",420.0,0.84,Vector2(260,980),52.0)
 s.add_ped("sade",1700.0,0.90,Vector2(1250,2300),60.0)
 s.add_ped("bayo",2750.0,0.78,Vector2(2400,3300),48.0)
 s.add_ped("ngozi",3850.0,0.88,Vector2(3600,4500),56.0)
 s.add_ped("musa",900.0,0.70,Vector2(700,1400),44.0)
 s.add_ped("tunde",2300.0,0.74,Vector2(1950,2450),40.0)
 s.add_ped("zuri",820.0,0.32,Vector2.ZERO,46.0,"z",Vector2(0.30,0.70))
 s.add_ped("okoye",3480.0,0.70,Vector2.ZERO,42.0,"z",Vector2(0.30,0.70))
 # --- traffic: two lanes, opposite directions
 var cols=[Color("35e6ff"),Color("ff4fb0"),Color("ffc060"),Color("a070ff"),Color("5af0a0")]
 for i in range(6):
  s.add_vehicle(0.45,1,cols[i%5],i%3,float(i)*860.0+120.0)
  s.add_vehicle(0.56,-1,cols[(i+2)%5],(i+1)%3,float(i)*860.0+520.0)
 Sound.loop("city")
 return s
func build_noodle() -> Stage25:
 var s=build_stage_base("noodle",1600.0)
 wire_player(s,"echo",Vector2(220,0.35))
 s.add_prop("doorway",140.0,0.0,Vector2.ZERO,Color("ff7a3d")).position.y=NeonArt.Y_BACK
 s.add_spot("exit",150.0,0.12,"LEAVE  /  BACK TO THE STREET",80.0,40.0)
 s.add_prop("counter",760.0,0.20,Vector2(130,8))
 s.add_actor("ngozi",760.0,0.10,"down")
 s.add_spot("ngozi",760.0,0.34,"TALK  /  NGOZI",150.0,34.0)
 for x in [620,720,820,920]:
  s.add_prop("stool",float(x),0.30,Vector2(10,4))
 s.add_prop("table",1180.0,0.50,Vector2(40,7))
 s.add_prop("table",1360.0,0.72,Vector2(40,7))
 s.add_actor("bayo",1180.0,0.43,"down")
 s.add_prop("terminal",1500.0,0.14,Vector2(30,6),Color("ffb050"))
 s.add_spot("notice",1500.0,0.28,"READ  /  MAINTENANCE NOTICE",80.0,30.0)
 for i in range(5):
  s.add_glow(Vector2(120+i*(1600-240)/4.0,120),150,Color("ff7a3d"),0.2)
 Sound.loop("city")
 return s
func build_alley() -> Stage25:
 var s=build_stage_base("hidden_alley",1700.0)
 wire_player(s,"echo",Vector2(200,0.2))
 s.add_prop("doorway",120.0,0.0,Vector2.ZERO,Color("8a4dff")).position.y=NeonArt.Y_BACK
 s.add_spot("exit_back",130.0,0.12,"GO BACK  /  JUNCTION 7",80.0,40.0)
 s.add_prop("crate",520.0,0.28,Vector2(24,6))
 s.add_prop("crate",560.0,0.52,Vector2(24,6))
 s.add_prop("crate",980.0,0.40,Vector2(24,6))
 s.add_prop("lamp",760.0,0.12,Vector2(6,3),Color("a070ff"))
 s.add_prop("lamp",1280.0,0.12,Vector2(6,3),Color("35e6ff"))
 s.add_prop("pole",1000.0,0.93,Vector2(10,4),Color("a070ff")).occluder=true
 s.add_prop("doorway",1540.0,0.0,Vector2.ZERO,Color("ff4fb0")).position.y=NeonArt.Y_BACK
 s.add_spot("arcade_door",1540.0,0.12,"ENTER  /  BACKROOM ARCADE",80.0,40.0)
 s.add_glow(Vector2(760,250),160,Color("a070ff"),0.22)
 s.add_glow(Vector2(1280,250),160,Color("35e6ff"),0.22)
 s.add_glow(Vector2(1540,300),200,Color("ff4fb0"),0.3)
 Sound.loop("city")
 return s
func build_arcade() -> Stage25:
 var s=build_stage_base("arcade",1500.0)
 wire_player(s,"echo",Vector2(220,0.3))
 s.add_prop("doorway",120.0,0.0,Vector2.ZERO,Color("ff4fb0")).position.y=NeonArt.Y_BACK
 s.add_spot("exit_arc",130.0,0.12,"GO BACK  /  PASSAGE",80.0,40.0)
 var cols=[Color("ff4fb0"),Color("35e6ff"),Color("a070ff"),Color("ffc060"),Color("5af0a0")]
 for i in range(5):
  s.add_prop("cabinet",360.0+i*130.0,0.10,Vector2(32,6),cols[i])
 s.add_prop("terminal",1180.0,0.14,Vector2(36,6),Color("bd95ff"))
 s.add_spot("terminal",1180.0,0.30,"EXAMINE  /  SIGNAL TERMINAL",90.0,30.0,1.0)
 s.add_glow(Vector2(1180,300),200,Color("bd95ff"),0.3)
 Sound.loop("city")
 return s
# ------------------------------------------------------------------ dialogue
func say(lines:Array, focus_on:Vector2=Vector2.ZERO) -> void:
 locked=true
 if stage:
  stage.vel=Vector2.ZERO
  if focus_on!=Vector2.ZERO:
   stage.focus=focus_on
   stage.focus_zoom=1.14
   var tw=create_tween()
   tw.tween_property(stage,"focus_w",1.0,0.5)
 bars(true,0.35)
 dlg=DialogueBox.new()
 dlg.speakers=SPEAKERS
 dlg.setup(lines,"Echo")
 ui.add_child(dlg)
 await dlg.finished
 dlg.queue_free()
 dlg=null
 if stage:
  var tw2=create_tween()
  tw2.tween_property(stage,"focus_w",0.0,0.5)
 bars(false,0.4)
 act_cool=0.5
 locked=false
func focus_point(wx:float, z:float) -> Vector2:
 return Vector2(wx,Stage25.y_of(z)-120.0)
# ------------------------------------------------------------------ interaction logic
func on_spot(sp:Dictionary) -> void:
 var id=sp.id
 match id:
  "imani":
   if not flags.talked_imani:
    flags.talked_imani=true
    set_objective(1)
    await say([
     {"who":"IMANI","text":"Careful with the puddles. The whole grid's leaking tonight. Every sign on this street has been stuttering since sundown."},
     {"who":"ECHO","text":"Stuttering how? Power dips don't usually keep time."},
     {"who":"IMANI","text":"That's the thing. Same rhythm, over and over. Like somebody knocking from inside the wiring."},
     {"who":"IMANI","text":"The big NEON DISTRICT tower in the plaza is loudest. If anyone can hear what it's saying, it's you."},
     {"who":"ECHO","text":"I'll listen."}],focus_point(sp.wx,sp.z))
   elif not flags.clue:
    await say([{"who":"IMANI","text":"Tower's east of here, past the clinic. Put your hand to the glass and listen."}],focus_point(sp.wx,sp.z))
   else:
    await say([{"who":"IMANI","text":"A combination? Then it's for a lock. Maintenance boxes are my department. Ask Kofi where the crew kept theirs."}],focus_point(sp.wx,sp.z))
  "kofi":
   if flags.clue and not flags.talked_kofi:
    flags.talked_kofi=true
    await say([
     {"who":"KOFI","text":"Three colours, in order? Ha. The old crew kept three breaker boxes on the alley wall at Junction 7, east of the Arcade."},
     {"who":"KOFI","text":"Colour-coded, no labels. They said whoever needed them would know the order."},
     {"who":"ECHO","text":"Thank you, Kofi. Keep the broth warm."}],focus_point(sp.wx,sp.z))
    set_objective(3)
   else:
    await say([
     {"who":"KOFI","text":"Hungry? Everybody says no, then smells the broth."},
     {"who":"ECHO","text":"Smells incredible. Quiet night, though."},
     {"who":"KOFI","text":"Quiet isn't the word. Look at those signs. Long, short, long. All night."}],focus_point(sp.wx,sp.z))
  "adaeze":
   await say([
    {"who":"ADAEZE","text":"This street was gardens before the towers came. I still sit here and tune out the rain."},
    {"who":"ADAEZE","text":"If you're chasing that stutter, child, follow the colours. Nothing in this district is only one."}],focus_point(sp.wx,sp.z))
  "zuri":
   await say([
    {"who":"ZURI","text":"Watch this! Triple puddle skip!"},
    {"who":"ZURI","text":"Hey, you hear that humming from the wall past the Arcade? Mom says don't go there. So I don't. Much."}],focus_point(sp.wx,sp.z))
  "okoye":
   await say([
    {"who":"OKOYE","text":"Control says it's a routine outage."},
    {"who":"OKOYE","text":"Routine outages don't blink in three colours. I'd keep that to myself, and I'd keep walking."}],focus_point(sp.wx,sp.z))
  "tower":
   if not flags.clue:
    flags.clue=true
    set_objective(2)
    hidden_door.hint=1.0
    Sound.play("special")
    await say([
     {"who":"NARRATOR","text":"The static folds into a rhythm. Three pulses, each a different colour: CYAN, then GOLD, then VIOLET."},
     {"who":"ECHO","text":"Cyan. Gold. Violet. That isn't damage. It's a combination."}],focus_point(sp.wx,sp.z))
   else:
    await say([{"who":"ECHO","text":"Cyan, gold, violet. Over and over."}],focus_point(sp.wx,sp.z))
  "noodle_door":
   return_pos=Vector2(1115,0.2)
   travel("noodle",Vector2(220,0.35),"right")
  "exit":
   travel("street",return_pos,"down")
  "ngozi":
   await say([
    {"who":"NGOZI","text":"Sit anywhere. The broth is on the house if the lights stay on."},
    {"who":"NGOZI","text":"My grandmother ran this counter through three blackouts. The block always finds its rhythm again."}],focus_point(sp.wx,sp.z))
  "notice":
   flags.notice=true
   await say([
    {"who":"NARRATOR","text":"MAINTENANCE NOTICE  /  Junction 7 breakers reset at 05:00 each day. Restore the order from the tower pulse. Do not guess."}])
  "hidden":
   if flags.opened:
    return_pos=Vector2(3460,0.2)
    flags.in_passage=true
    set_objective(5)
    travel("hidden_alley",Vector2(200,0.2),"right")
   elif flags.clue:
    await say([{"who":"ECHO","text":"A seam in the wall, humming violet. It wants the breakers set first."}])
   else:
    await say([{"who":"ECHO","text":"Just a wall. Though it's warm. Odd for a rainy night."}])
  "exit_back":
   travel("street",Vector2(3460,0.2),"down")
  "arcade_door":
   set_objective(6)
   travel("arcade",Vector2(220,0.3),"right")
  "exit_arc":
   travel("hidden_alley",Vector2(1450,0.2),"left")
  "terminal":
   if not flags.terminal:
    flags.terminal=true
    set_objective(7)
    Sound.play("win")
    await say([
     {"who":"SIGNAL","text":"...if you can hear this, the district is still listening. Hold the line."},
     {"who":"ECHO","text":"Somebody was calling for help through the signs. And they had to hide it in the light."},
     {"who":"NARRATOR","text":"End of the 2.5D demonstration. Thanks for walking the district."}],focus_point(sp.wx,sp.z))
    flags.done=true
    await show_card("DEMO COMPLETE","Four-direction movement  /  depth  /  occlusion  /  interiors  /  puzzle  /  hidden path",2.6)
   else:
    await say([{"who":"ECHO","text":"Whoever sent it, they're still out there."}])
  "tram":
   exit_requested.emit()
  _:
   if id.begins_with("junction_"):
    press_breaker(id.substr(9))
func press_breaker(colour:String) -> void:
 if flags.solved or wrong_t>0.0:
  return
 if not flags.clue:
  say([{"who":"ECHO","text":"Three breakers and no idea of the order. I need to know what the signs were saying."}])
  return
 Sound.play("tap")
 seq.append(colour)
 junctions[colour].state=1
 junctions[colour].queue_redraw()
 if seq.size()<3:
  return
 if seq==PULSE:
  flags.solved=true
  set_objective(4)
  Sound.play("win")
  open_hidden_door()
 else:
  wrong_t=0.9
  seq.clear()
  Sound.play("hurt")
  for k in junctions:
   junctions[k].state=2
func open_hidden_door() -> void:
 locked=true
 var door=Vector2(3460,Stage25.y_of(0.0)-70.0)
 stage.focus=door
 stage.focus_zoom=1.18
 var tw=create_tween()
 tw.tween_property(stage,"focus_w",1.0,0.6)
 bars(true,0.4)
 await get_tree().create_timer(0.7).timeout
 var open=create_tween()
 open.tween_property(hidden_door,"open_amount",1.0,1.4)
 await open.finished
 flags.opened=true
 await get_tree().create_timer(0.5).timeout
 await say([{"who":"ECHO","text":"There it is. A way through the wall. Whoever hid this wanted it found by someone who'd listen."}])
 locked=false
# ------------------------------------------------------------------ frame loop
func keyboard_move() -> Vector2:
 var m=Vector2.ZERO
 if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
  m.x-=1.0
 if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
  m.x+=1.0
 if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
  m.y-=1.0
 if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
  m.y+=1.0
 return m.limit_length(1.0)
var test_move=Vector2.ZERO   # headless tests drive movement through this
func move_input() -> Vector2:
 if test_move!=Vector2.ZERO:
  return test_move
 var m=keyboard_move()
 if stick.direction.length()>0.18:
  m=stick.direction
 return m
func _unhandled_key_input(event:InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_E,KEY_ENTER,KEY_KP_ENTER,KEY_SPACE] and dlg==null:
  act_edge=true
func _process(delta:float) -> void:
 time+=delta
 if stage==null:
  return
 var m=move_input() if not locked else Vector2.ZERO
 stage.tick(delta,m,locked)
 if wrong_t>0.0:
  wrong_t-=delta
  if wrong_t<=0.0:
   for k in junctions:
    junctions[k].state=0
 act_cool=maxf(0.0,act_cool-delta)
 var sp=stage.nearest_spot() if not locked else {}
 update_prompt(sp)
 var held=Input.is_physical_key_pressed(KEY_E) or Input.is_physical_key_pressed(KEY_ENTER) or act_btn.held
 if not sp.is_empty() and act_cool<=0.0:
  var need=float(sp.get("hold",0.0))
  if need>0.0:
   if held and not hold_blocked:
    hold_t+=delta
    if hold_t>=need:
     hold_t=0.0
     hold_blocked=true
     act_edge=false
     on_spot(sp)
   else:
    hold_t=0.0
    if not held:
     hold_blocked=false
    if act_edge:
     act_edge=false
  elif act_edge:
   act_edge=false
   on_spot(sp)
 else:
  hold_t=0.0
  if not held:
   hold_blocked=false
  act_edge=false
 hold_ring.queue_redraw()
 var tm=0.0
 frame_ms.append(delta*1000.0)
 if frame_ms.size()>240:
  frame_ms.pop_front()
 if qa_enabled:
  publish_qa()
func update_prompt(sp:Dictionary) -> void:
 if sp.is_empty():
  prompt_label.text=""
  return
 var verb=("HOLD  " if float(sp.get("hold",0.0))>0.0 else "")+("ACT" if DisplayServer.is_touchscreen_available() else "E")
 prompt_label.text="["+verb+"]  "+str(sp.label)
func qa_state() -> Dictionary:
 var p=stage.player if stage else null
 var sp=stage.nearest_spot() if stage else {}
 return {"scene":"demo","where":where,"px":p.wx if p else 0.0,"pz":p.z if p else 0.0,"dir":p.dir if p else "","cam":stage.cam_c.x if stage else 0.0,"zoom":stage.zoom if stage else 1.0,
  "obj":objective,"locked":locked,"dlg":dlg!=null,"spot":sp.get("id",""),"flags":flags,"seq":seq,"peds":stage.peds.size() if stage else 0,"veh":stage.vehicles.size() if stage else 0}
func publish_qa() -> void:
 JavaScriptBridge.eval("window.__qa="+JSON.stringify(qa_state()))
func perf_snapshot() -> Dictionary:
 var avg=0.0
 for f in frame_ms:
  avg+=f
 avg=avg/maxf(1.0,float(frame_ms.size()))
 return {"fps":Engine.get_frames_per_second(),"avg_frame_ms":avg,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
  "objects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
  "texture_mem_mb":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,"video_mem_mb":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,
  "nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0}
