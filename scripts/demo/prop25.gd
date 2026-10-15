extends Node2D
class_name Prop25
# Street props for the 2.5D stage. Origin = ground contact point; the stage places it by (wx, z) and scales it with depth. Drawn procedurally.
var kind="lamp"
var wx=0.0
var z=0.5
var half=Vector2(20,6)      # solid footprint half size (x, z-pixels); zero = walk-through
var col=Color("35e6ff")
var state=0                 # junction: 0 off, 1 lit, 2 wrong flash
var occluder=false          # fades when it hides the player
var open_amount=0.0         # hidden door slide 0..1
var hint=0.0                # hidden-door seam glow
var t=0.0
var animated=false
func _process(delta:float) -> void:
 t+=delta
 if animated or state==2:
  queue_redraw()
func _draw() -> void:
 match kind:
  "lamp": draw_lamp()
  "pole": draw_pole()
  "vending": draw_vending()
  "bench": draw_bench()
  "planter": draw_planter()
  "stall": draw_stall()
  "kiosk": draw_kiosk()
  "junction": draw_junction()
  "sign_tower": draw_sign_tower()
  "hidden_door": draw_hidden_door()
  "banner": draw_banner()
  "crate": draw_crate()
  "stool": draw_stool()
  "counter": draw_counter()
  "cabinet": draw_cabinet()
  "terminal": draw_terminal()
  "table": draw_table()
  "doorway": draw_doorway()
func glow(c:Vector2, r:float, color:Color, a:float=0.25) -> void:
 for i in range(5):
  draw_circle(c,r*(1.0-float(i)/5.0),Color(color,a*float(i+1)/5.0))
func box(rect:Rect2, top:Color, bottom:Color, edge:Color=Color(0.02,0.01,0.08)) -> void:
 NeonArt.gradient(self,rect,top,bottom)
 draw_rect(rect,edge,false,2.0)
func draw_lamp() -> void:
 draw_rect(Rect2(-3,-170,6,170),Color("1a1438"))
 draw_rect(Rect2(-3,-170,2,170),Color(col,0.25))
 draw_rect(Rect2(-18,-176,36,8),Color("1a1438"))
 glow(Vector2(0,-166),58,col,0.35)
 draw_rect(Rect2(-12,-170,24,4),Color(1,1,1,0.9))
 # light pool on the ground (additive-ish)
 draw_set_transform(Vector2(0,0),0,Vector2(1,0.25))
 draw_circle(Vector2.ZERO,70,Color(col,0.07))
 draw_circle(Vector2.ZERO,44,Color(col,0.08))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_pole() -> void:
 draw_rect(Rect2(-9,-330,18,330),Color("120c2c"))
 draw_rect(Rect2(-9,-330,4,330),Color(col,0.35))
 for k in range(6):
  draw_rect(Rect2(-9,-300+k*52,18,4),Color("2b2150"))
 draw_rect(Rect2(-4,-330,2,330),Color(col,0.7))
func draw_vending() -> void:
 box(Rect2(-34,-124,68,124),Color("2a2150"),Color("141030"))
 NeonArt.gradient(self,Rect2(-26,-112,40,76),Color(col,0.9),Color(col.darkened(0.5),0.85))
 for r in range(3):
  for c in range(3):
   draw_rect(Rect2(-23+c*12.5,-108+r*22,9,15),Color(1,1,1,0.28))
 draw_rect(Rect2(18,-100,10,60),Color("0a0720"))
 draw_circle(Vector2(23,-90),2.4,Color(col.lightened(0.4)))
 glow(Vector2(-6,-74),70,col,0.18)
func draw_bench() -> void:
 draw_rect(Rect2(-56,-40,112,8),Color("2b2150"))
 draw_rect(Rect2(-56,-62,112,6),Color("34286a"))
 draw_rect(Rect2(-52,-34,6,34),Color("120c2c"))
 draw_rect(Rect2(46,-34,6,34),Color("120c2c"))
 draw_rect(Rect2(-56,-62,112,2),Color(col,0.5))
func draw_planter() -> void:
 box(Rect2(-30,-30,60,30),Color("2a2150"),Color("151032"))
 for k in range(9):
  var h=40+((k*37)%30)
  draw_line(Vector2(-24+k*6,-30),Vector2(-28+k*7,-30-h),Color("1f6a52") if k%2 else Color("2f9a70"),3.0)
 draw_circle(Vector2(0,-66),7,Color(col,0.9))
func draw_stall() -> void:
 # Kofi's noodle stall: counter, awning, hanging lanterns, steam
 box(Rect2(-120,-70,240,70),Color("3a2430"),Color("1e121e"))
 draw_rect(Rect2(-120,-76,240,8),Color("5a3a44"))
 NeonArt.gradient(self,Rect2(-100,-62,200,42),Color("ff7a3d",0.35),Color("1e121e"))
 for k in range(3):
  draw_rect(Rect2(-84+k*66,-104,40,26),Color("e8e2d0"))
  draw_rect(Rect2(-84+k*66,-104,40,3),Color("c0402a"))
  draw_circle(Vector2(-64+k*66,-110),5,Color("e8e2d0"))
 draw_polygon(PackedVector2Array([Vector2(-136,-196),Vector2(136,-196),Vector2(124,-160),Vector2(-124,-160)]),PackedColorArray([Color("7a2a2a"),Color("7a2a2a"),Color("4a1a22"),Color("4a1a22")]))
 for k in range(10):
  draw_rect(Rect2(-130+k*26,-196,12,36),Color(0,0,0,0.22))
 draw_rect(Rect2(-136,-198,272,4),Color("ffc060"))
 for k in range(3):
  var lx=-80+k*80
  draw_line(Vector2(lx,-160),Vector2(lx,-146),Color(0,0,0,0.6),2.0)
  glow(Vector2(lx,-136),30,Color("ff7a3d"),0.4)
  draw_circle(Vector2(lx,-136),10,Color("ff7a3d"))
 draw_rect(Rect2(-130,-200,6,200),Color("1a1438"))
 draw_rect(Rect2(124,-200,6,200),Color("1a1438"))
 for k in range(4):   # steam from the pot
  var ph=fmod(t*0.7+k*0.27,1.0)
  draw_circle(Vector2(-50+sin(t*2+k)*6,-84-ph*60),8+ph*10,Color(0.9,0.92,1.0,0.16*(1.0-ph)))
func draw_kiosk() -> void:
 box(Rect2(-60,-110,120,110),Color("2f6f86"),Color("17394a"))
 draw_rect(Rect2(-60,-116,120,8),Color("e6c04a"))
 NeonArt.gradient(self,Rect2(-48,-96,60,44),Color("0a0720"),Color("1a1440"))
 for k in range(5):
  draw_rect(Rect2(-44+k*11,-92,8,36),Color(col,0.4+0.1*sin(t*3+k)))
 for k in range(4):   # tool rack
  draw_line(Vector2(26+k*8,-94),Vector2(26+k*8,-56),Color("c0c4d8"),3.0)
 draw_rect(Rect2(-62,-132,124,14),Color("e6c04a"))
 draw_string(ThemeDB.fallback_font,Vector2(-50,-121),"TRAM REPAIR",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("1a1438"))
 glow(Vector2(0,-60),100,Color("4ad0ff"),0.12)
func draw_junction() -> void:
 box(Rect2(-26,-84,52,84),Color("2a2150"),Color("141030"))
 var lit=state==1
 var wrong=state==2
 var c=col if not wrong else Color("ff3040")
 var pulse=0.5+0.5*sin(t*4.0)
 NeonArt.gradient(self,Rect2(-18,-72,36,44),Color(c,(0.95 if lit else (0.9 if wrong else 0.22+0.1*pulse))),Color(c.darkened(0.5),(0.9 if lit or wrong else 0.2)))
 draw_circle(Vector2(0,-50),9,Color(c.lightened(0.3),0.95 if lit else 0.5))
 draw_rect(Rect2(-14,-22,28,8),Color("0a0720"))
 for k in range(3):
  draw_circle(Vector2(-8+k*8,-18),2.2,Color(c,0.9 if lit else 0.3))
 if lit:
  glow(Vector2(0,-50),90,c,0.3)
func draw_sign_tower() -> void:
 draw_rect(Rect2(-26,-300,52,300),Color("120c2c"))
 draw_rect(Rect2(-30,-300,60,14),Color("2b2150"))
 var letters="NEONDISTRICT"
 var font=ThemeDB.fallback_font
 for k in range(letters.length()):
  var flick=sin(t*13.0+k*2.3)*sin(t*5.0+k*0.9)
  var off=flick<-0.55 and (k%3)==int(t*2.0)%3
  var c=Color("bd7bff") if k%2==0 else Color("35e6ff")
  var a=0.18 if off else 1.0
  draw_string_outline(font,Vector2(-9,-282+k*22),letters[k],HORIZONTAL_ALIGNMENT_LEFT,-1,24,7,Color(c,0.35*a))
  draw_string(font,Vector2(-9,-282+k*22),letters[k],HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color(c.lightened(0.5),a))
 glow(Vector2(0,-160),120,Color("bd7bff"),0.18)
 draw_rect(Rect2(-34,-8,68,10),Color("2b2150"))
func draw_hidden_door() -> void:
 # a seam in the wall that only glows once the clue is known; slides aside when opened
 var w=70.0
 var slide=open_amount*w
 draw_rect(Rect2(-w/2,-96,w,96),Color("0a0720"))
 NeonArt.gradient(self,Rect2(-w/2+3,-92,w-6,92),Color("8a4dff",0.25+0.5*open_amount),Color("0a0720",0.9))
 if open_amount<1.0:
  var pa=hint*(0.4+0.3*sin(t*3.0))
  draw_rect(Rect2(-w/2+slide,-96,w,96),Color("1a1240"))
  draw_rect(Rect2(-w/2+slide,-96,w,96),Color(NeonArt.VIOLET,0.35+pa*0.6),false,2.0)
  for k in range(5):
   draw_rect(Rect2(-w/2+slide+4,-86+k*17.0,w-8,2),Color(NeonArt.VIOLET,0.16+pa*0.5))
  draw_circle(Vector2(w/2-10+slide,-46),3,Color(NeonArt.GOLD,0.4+pa))
 if open_amount>0.05:
  glow(Vector2(0,-48),90*open_amount,Color("8a4dff"),0.35)
func draw_banner() -> void:
 # hangs from above the screen; a foreground occluder
 draw_line(Vector2(0,-760),Vector2(0,-430),Color(0,0,0,0.7),2.0)
 NeonArt.gradient(self,Rect2(-24,-430,48,120),Color(col,0.95),Color(col.darkened(0.6),0.9))
 draw_rect(Rect2(-24,-430,48,120),Color(0,0,0,0.5),false,2.0)
 draw_string(ThemeDB.fallback_font,Vector2(-18,-370),"NEON",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color(1,1,1,0.85))
 glow(Vector2(0,-370),70,col,0.18)
func draw_crate() -> void:
 box(Rect2(-24,-34,48,34),Color("3a2c6a"),Color("1c1440"))
 draw_line(Vector2(-24,-34),Vector2(24,0),Color(0,0,0,0.4),2.0)
 draw_line(Vector2(24,-34),Vector2(-24,0),Color(0,0,0,0.4),2.0)
func draw_stool() -> void:
 draw_rect(Rect2(-14,-34,28,8),Color("5a3a44"))
 draw_rect(Rect2(-9,-26,4,26),Color("1e121e"))
 draw_rect(Rect2(5,-26,4,26),Color("1e121e"))
func draw_counter() -> void:
 box(Rect2(-130,-70,260,70),Color("4a2a34"),Color("22121c"))
 draw_rect(Rect2(-134,-76,268,8),Color("7a4a58"))
 NeonArt.gradient(self,Rect2(-120,-62,240,46),Color("ff7a3d",0.25),Color("22121c"))
func draw_cabinet() -> void:
 box(Rect2(-32,-130,64,130),Color("2a2150"),Color("141030"))
 NeonArt.gradient(self,Rect2(-24,-114,48,44),Color(col,0.95),Color(col.darkened(0.6),0.9))
 var blink=0.5+0.5*sin(t*6.0+wx)
 for k in range(4):
  draw_rect(Rect2(-18+k*10,-110+(k%2)*10,6,6),Color(1,1,1,0.4+0.5*blink))
 draw_rect(Rect2(-26,-64,52,14),Color("0a0720"))
 draw_circle(Vector2(-14,-57),4,Color("ff4fb0"))
 draw_circle(Vector2(0,-57),4,Color("35e6ff"))
 glow(Vector2(0,-90),90,col,0.2)
func draw_terminal() -> void:
 box(Rect2(-36,-96,72,96),Color("1a1440"),Color("0a0720"))
 NeonArt.gradient(self,Rect2(-28,-86,56,50),Color(col,0.9),Color(col.darkened(0.6),0.9))
 for k in range(5):
  draw_rect(Rect2(-24,-80+k*9.0,20+((k*13)%24),3),Color(1,1,1,0.5+0.3*sin(t*3+k)))
 glow(Vector2(0,-60),110,col,0.25)
func draw_table() -> void:
 draw_rect(Rect2(-40,-44,80,6),Color("5a3a44"))
 draw_rect(Rect2(-4,-38,8,38),Color("1e121e"))
 draw_circle(Vector2(-14,-48),6,Color("e8e2d0"))
 draw_circle(Vector2(14,-48),6,Color("e8e2d0"))
 draw_circle(Vector2(-14,-50),3,Color("ff7a3d"))
func draw_doorway() -> void:
 var w=84.0
 draw_rect(Rect2(-w/2-6,-120,w+12,120),Color("0a0720"))
 NeonArt.gradient(self,Rect2(-w/2,-114,w,114),Color(col,0.75),Color(col.darkened(0.6),0.9))
 draw_rect(Rect2(-w/2-6,-120,w+12,120),Color(col,0.8),false,3.0)
 glow(Vector2(0,-60),100,col,0.3)
