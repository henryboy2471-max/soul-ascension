extends WorldArt
class_name RelayArt
# Episode 3 zone art (procedural, placeholder level like Lantern Quarter art): violet-rain market, cool-blue station, dark alleys,
# warm-gold workshop interior and the dark relay tower floors. The zone is chosen by RelayArt.zone before an Explore is created;
# RelayArt.found lists spot ids the player has already investigated (their markers go quiet).
static var zone:String="market"
static var found:Array=[]
const PALETTES = {
 "market":{"sky":[Color(0.035,0.02,0.1),Color(0.34,0.16,0.5)],"wall":Color(0.06,0.045,0.13),"accent":Color(1.0,0.72,0.4),"cool":Color(0.7,0.5,1.0),"floor":Color(0.085,0.065,0.17)},
 "station":{"sky":[Color(0.02,0.04,0.1),Color(0.14,0.24,0.42)],"wall":Color(0.05,0.07,0.14),"accent":Color(0.5,0.85,0.95),"cool":Color(0.45,0.7,1.0),"floor":Color(0.07,0.09,0.17)},
 "alleys":{"sky":[Color(0.02,0.015,0.06),Color(0.2,0.1,0.34)],"wall":Color(0.045,0.035,0.1),"accent":Color(0.75,0.5,1.0),"cool":Color(0.6,0.45,0.95),"floor":Color(0.06,0.045,0.12)},
 "workshop":{"sky":[Color(0.1,0.06,0.04),Color(0.3,0.18,0.1)],"wall":Color(0.13,0.09,0.07),"accent":Color(1.0,0.78,0.42),"cool":Color(0.6,0.8,1.0),"floor":Color(0.16,0.11,0.08)},
 "tower_1":{"sky":[Color(0.015,0.015,0.05),Color(0.1,0.08,0.22)],"wall":Color(0.04,0.04,0.1),"accent":Color(0.55,0.9,1.0),"cool":Color(0.6,0.5,1.0),"floor":Color(0.05,0.05,0.12)},
 "tower_2":{"sky":[Color(0.02,0.015,0.05),Color(0.14,0.08,0.24)],"wall":Color(0.045,0.04,0.1),"accent":Color(1.0,0.78,0.42),"cool":Color(0.6,0.5,1.0),"floor":Color(0.05,0.045,0.11)},
 "tower_3":{"sky":[Color(0.02,0.012,0.06),Color(0.18,0.08,0.3)],"wall":Color(0.05,0.035,0.11),"accent":Color(0.85,0.6,1.0),"cool":Color(1.0,0.8,0.5),"floor":Color(0.055,0.04,0.12)}
}
func pal() -> Dictionary:
 return PALETTES.get(zone,PALETTES.market)
func interior() -> bool:
 return zone=="workshop" or zone.begins_with("tower")
func draw_sky() -> void:
 var p=pal()
 gradient_rect(Rect2(0,0,width,520),p.sky[0],p.sky[1])
 if not interior():
  for i in range(9):
   var y=30.0+i*46.0
   var x=fmod(i*311.0,width)
   draw_line(Vector2(x-300,y),Vector2(x+340,y+20),Color(p.cool,0.06),28)
func draw_far() -> void:
 var rng=RandomNumberGenerator.new()
 rng.seed=31+zone.hash()%97
 var p=pal()
 var x=0.0
 while x<width:
  var w=rng.randf_range(90,200)
  var h=rng.randf_range(120,330) if not interior() else rng.randf_range(300,470)
  draw_rect(Rect2(x,GROUND_TOP-h,w,h+20),Color(p.wall,0.8))
  for r in range(int(h/38)):
   for c in range(int(w/34)):
    if rng.randf()<0.14:
     draw_rect(Rect2(x+8+c*34,GROUND_TOP-h+10+r*38,12,10),Color(p.accent,rng.randf_range(0.25,0.6)))
  x+=w+rng.randf_range(10,50)
func draw_mid() -> void:
 var p=pal()
 if interior():
  # tall columns with glowing seams
  var x=40.0
  while x<width:
   draw_rect(Rect2(x,60,34,GROUND_TOP-40),Color(p.wall.lightened(0.05),0.9))
   draw_rect(Rect2(x+14,70,4,GROUND_TOP-60),Color(p.cool,0.35))
   x+=290.0
  for k in range(4):
   draw_line(Vector2(0,150+k*70),Vector2(width,150+k*70),Color(p.cool,0.07),3)
 else:
  var rng=RandomNumberGenerator.new()
  rng.seed=47+zone.hash()%89
  var x=0.0
  while x<width:
   var w=rng.randf_range(160,300)
   var h=rng.randf_range(150,300)
   draw_rect(Rect2(x,GROUND_TOP-h,w,h+10),Color(p.wall,0.95))
   draw_rect(Rect2(x,GROUND_TOP-h,w,5),Color(p.cool,0.25))
   x+=w+rng.randf_range(20,90)
func draw_near() -> void:
 var p=pal()
 var rng=RandomNumberGenerator.new()
 rng.seed=71+zone.hash()%61
 var font=ThemeDB.fallback_font
 match zone:
  "market":
   var x=40.0
   var n=0
   var names=["TEA & REPAIR","LANTERNS","NOODLES","RADIO PARTS","HERBS","TICKETS","SPARKS"]
   while x<width:
    var w=rng.randf_range(210,300)
    var h=rng.randf_range(210,300)
    draw_rect(Rect2(x,GROUND_TOP+20-h,w,h),Color(p.wall))
    draw_rect(Rect2(x,GROUND_TOP+20-h,5,h),Color(p.cool,0.22))
    # striped awning over a lit stall
    var ay=GROUND_TOP-120
    for s in range(6):
     draw_colored_polygon(PackedVector2Array([Vector2(x+10+s*(w-20)/6.0,ay),Vector2(x+10+(s+1)*(w-20)/6.0,ay),Vector2(x+14+(s+1)*(w-28)/6.0,ay+34),Vector2(x+14+s*(w-28)/6.0,ay+34)]),Color(p.accent,0.5) if s%2==0 else Color(0.5,0.25,0.65,0.55))
    draw_rect(Rect2(x+16,ay+34,w-32,56),Color(p.accent,0.1))
    for k in range(5):
     var lx=x+22+k*(w-44)/4.0
     draw_circle(Vector2(lx,ay-12+sin(k*1.7)*6),14,Color(p.accent,0.1))
     draw_circle(Vector2(lx,ay-12+sin(k*1.7)*6),5,Color(1.0,0.82,0.5,0.95))
    draw_string(font,Vector2(x+20,ay-26),names[n%names.size()],HORIZONTAL_ALIGNMENT_CENTER,w-40,17,Color(p.accent,0.9))
    n+=1
    x+=w+rng.randf_range(90,230)
  "station":
   var x=60.0
   while x<width:
    draw_rect(Rect2(x,GROUND_TOP-300,46,320),Color(p.wall.lightened(0.04)))
    draw_rect(Rect2(x+18,GROUND_TOP-296,4,300),Color(p.cool,0.35))
    # departures board
    if int(x/420.0)%2==0:
     draw_rect(Rect2(x+80,GROUND_TOP-270,170,48),Color(0.02,0.03,0.08))
     draw_rect(Rect2(x+80,GROUND_TOP-270,170,48),Color(p.accent,0.7),false,2)
     draw_string(font,Vector2(x+86,GROUND_TOP-240),"SERVICE HALTED",HORIZONTAL_ALIGNMENT_CENTER,158,15,Color(1.0,0.5,0.55))
    x+=420.0
  "alleys":
   var x=0.0
   while x<width:
    var w=rng.randf_range(120,220)
    draw_rect(Rect2(x,GROUND_TOP-380,w,400),Color(p.wall))
    draw_line(Vector2(x+w*0.3,GROUND_TOP-370),Vector2(x+w*0.3,GROUND_TOP+10),Color(0.3,0.26,0.45,0.8),6)   # pipe
    for k in range(3):
     draw_rect(Rect2(x+10,GROUND_TOP-330+k*90,26,34),Color(p.accent,rng.randf_range(0.05,0.3)))
    draw_line(Vector2(x,GROUND_TOP-220),Vector2(x+w+rng.randf_range(40,120),GROUND_TOP-200),Color(0.4,0.35,0.55,0.6),1.5)   # laundry line
    x+=w+rng.randf_range(20,70)
  "workshop":
   var x=50.0
   while x<width:
    draw_rect(Rect2(x,GROUND_TOP-250,220,250),Color(0.1,0.07,0.05))
    for r in range(4):
     draw_rect(Rect2(x+6,GROUND_TOP-240+r*60,208,5),Color(0.35,0.24,0.14))
     for c in range(6):
      draw_rect(Rect2(x+14+c*32,GROUND_TOP-286+r*60+40,22,rng.randf_range(10,34)),Color(rng.randf_range(0.2,0.5),rng.randf_range(0.15,0.3),0.12,0.9))
    x+=420.0
  _:
   var x=100.0
   while x<width:
    # catwalk with railing and hanging cables
    draw_rect(Rect2(x,GROUND_TOP-170,300,10),Color(p.wall.lightened(0.08)))
    for k in range(10):
     draw_line(Vector2(x+k*33,GROUND_TOP-170),Vector2(x+k*33,GROUND_TOP-205),Color(p.cool,0.35),2)
    draw_line(Vector2(x,GROUND_TOP-205),Vector2(x+300,GROUND_TOP-205),Color(p.cool,0.5),2)
    for k in range(3):
     draw_line(Vector2(x+60+k*80,60),Vector2(x+70+k*80,GROUND_TOP-170),Color(p.accent,0.25),3)
    x+=620.0
func draw_ground() -> void:
 var p=pal()
 draw_rect(Rect2(0,GROUND_TOP,width,260),p.floor)
 gradient_rect(Rect2(0,GROUND_TOP,width,40),p.floor.lightened(0.12),p.floor)
 draw_line(Vector2(0,GROUND_TOP+40),Vector2(width,GROUND_TOP+40),Color(p.cool,0.45),2)
 gradient_rect(Rect2(0,GROUND_TOP+41,width,260),p.floor.lightened(0.02),p.floor.darkened(0.55))
 var rng=RandomNumberGenerator.new()
 rng.seed=83+zone.hash()%53
 for i in range(int(width/70)):
  draw_line(Vector2(i*70.0,GROUND_TOP+44),Vector2(i*70.0-30,GROUND_TOP+240),Color(p.cool,0.07),2)
 for i in range(5):
  draw_line(Vector2(0,GROUND_TOP+70+i*40),Vector2(width,GROUND_TOP+70+i*40),Color(p.cool,0.06),2)
 for i in range(int(width/140)):
  var rx=rng.randf_range(0,width)
  draw_line(Vector2(rx,GROUND_TOP+44),Vector2(rx+rng.randf_range(-20,20),GROUND_TOP+230),Color(p.accent if i%2==0 else p.cool,0.1),rng.randf_range(6,16))
 if zone=="station":
  draw_rect(Rect2(0,GROUND_TOP+40,width,6),Color(1.0,0.82,0.3,0.7))   # platform edge line
func marker(x:float, color:Color, pulse:float, quiet:bool) -> void:
 var a=0.25 if quiet else 0.5+0.45*pulse
 draw_circle(Vector2(x,GROUND_TOP-150),(10 if quiet else 16)+pulse*(0 if quiet else 4),Color(color,a*0.25))
 draw_circle(Vector2(x,GROUND_TOP-150),5,Color(color,a))
func draw_props() -> void:
 var p=pal()
 var font=ThemeDB.fallback_font
 var pulse=0.5+0.5*sin(time*3.0)
 for sp in ZoneDefs.zone(zone).get("spots",[]):
  var x=float(sp.x)
  var quiet=found.has(sp.id)
  match str(sp.get("visual","none")):
   "signal":
    # speaker horn on a pole: pulsing signal rings until investigated
    draw_rect(Rect2(x-5,GROUND_TOP-170,10,190),Color(0.2,0.18,0.32))
    draw_colored_polygon(PackedVector2Array([Vector2(x-6,GROUND_TOP-190),Vector2(x+30,GROUND_TOP-210),Vector2(x+30,GROUND_TOP-150),Vector2(x-6,GROUND_TOP-170)]),Color(0.3,0.26,0.45))
    for k in range(3):
     draw_arc(Vector2(x+30,GROUND_TOP-180),16+k*14+(0.0 if quiet else fposmod(time*30.0,14.0)),-0.8,0.8,16,Color(p.cool,(0.2 if quiet else 0.6)-k*0.12),2)
   "board":
    draw_rect(Rect2(x-46,GROUND_TOP-130,92,70),Color(0.04,0.05,0.11))
    draw_rect(Rect2(x-46,GROUND_TOP-130,92,70),Color(p.accent,0.8),false,2)
    for k in range(4):
     draw_line(Vector2(x-38,GROUND_TOP-118+k*14),Vector2(x+38-(k%2)*18,GROUND_TOP-118+k*14),Color(p.accent,0.35),2)
    draw_line(Vector2(x,GROUND_TOP-60),Vector2(x,GROUND_TOP+14),Color(0.3,0.28,0.45),4)
   "journal":
    draw_rect(Rect2(x-20,GROUND_TOP-6,40,22),Color(0.28,0.2,0.14))
    draw_rect(Rect2(x-20,GROUND_TOP-6,40,22),Color(p.accent,0.5),false,1.5)
    if not quiet:
     marker(x,p.accent,pulse,false)
   "terminal":
    draw_rect(Rect2(x-30,GROUND_TOP-90,60,96),Color(0.07,0.08,0.16))
    draw_rect(Rect2(x-30,GROUND_TOP-90,60,96),Color(p.accent,0.6),false,2)
    draw_rect(Rect2(x-22,GROUND_TOP-80,44,34),Color(p.accent,0.15+0.2*pulse*(0.0 if quiet else 1.0)))
   "records":
    for k in range(3):
     draw_rect(Rect2(x-60+k*42,GROUND_TOP-100,36,106),Color(0.08,0.09,0.17))
     draw_rect(Rect2(x-60+k*42,GROUND_TOP-100,36,106),Color(p.cool,0.45),false,1.5)
     for r in range(5):
      draw_line(Vector2(x-56+k*42,GROUND_TOP-86+r*20),Vector2(x-28+k*42,GROUND_TOP-86+r*20),Color(p.cool,0.3),2)
   "door":
    draw_rect(Rect2(x-52,GROUND_TOP-170,104,190),Color(0.06,0.06,0.13))
    draw_rect(Rect2(x-52,GROUND_TOP-170,104,190),Color(1.0,0.4,0.5,0.7),false,2.5)
    draw_circle(Vector2(x,GROUND_TOP-110),9,Color(1.0,0.35,0.45,0.5+0.4*pulse))
    draw_string(font,Vector2(x-48,GROUND_TOP-70),"SEALED",HORIZONTAL_ALIGNMENT_CENTER,96,15,Color(1.0,0.5,0.55))
   "fragment":
    # faded mark on the wall: a ghostly glyph that glows faintly until found
    var g=Color(p.accent,0.18 if quiet else 0.35+0.3*pulse)
    draw_arc(Vector2(x,GROUND_TOP-110),22,0,TAU,24,g,3)
    draw_arc(Vector2(x,GROUND_TOP-110),11,0,TAU,16,g,2)
    draw_line(Vector2(x-30,GROUND_TOP-110),Vector2(x+30,GROUND_TOP-110),g,2)
   "lever":
    draw_rect(Rect2(x-24,GROUND_TOP-60,48,66),Color(0.11,0.1,0.2))
    draw_line(Vector2(x,GROUND_TOP-30),Vector2(x+(26 if quiet else -26),GROUND_TOP-82),Color(0.75,0.7,0.9),6)
    draw_circle(Vector2(x+(26 if quiet else -26),GROUND_TOP-82),8,Color(1.0,0.5,0.4) if not quiet else Color(0.45,1.0,0.8))
   "decoder":
    draw_rect(Rect2(x-50,GROUND_TOP-86,100,92),Color(0.15,0.1,0.07))
    draw_rect(Rect2(x-50,GROUND_TOP-86,100,92),Color(p.accent,0.7),false,2)
    draw_rect(Rect2(x-40,GROUND_TOP-76,80,44),Color(0.03,0.05,0.06))
    for k in range(40):
     var wx=x-38+k*2.0
     draw_line(Vector2(wx,GROUND_TOP-54),Vector2(wx,GROUND_TOP-54+sin(k*0.5+time*4.0)*14.0),Color(0.45,1.0,0.7,0.8),1.5)
   "map":
    draw_rect(Rect2(x-70,GROUND_TOP-30,140,34),Color(0.2,0.14,0.09))
    draw_rect(Rect2(x-62,GROUND_TOP-26,124,26),Color(0.82,0.72,0.5,0.35))
    for k in range(7):
     draw_circle(Vector2(x-54+k*18,GROUND_TOP-13+sin(k*2.0)*5),3.5,Color(p.accent,0.4 if quiet else 0.9))
   "resonator":
    draw_rect(Rect2(x-9,GROUND_TOP-190,18,200),Color(0.1,0.09,0.22))
    for k in range(4):
     draw_arc(Vector2(x,GROUND_TOP-130),30+k*13+(0.0 if quiet else fposmod(time*18.0,13.0)),PI*1.1,PI*1.9,20,Color(p.accent,0.6-k*0.12),3)
    draw_circle(Vector2(x,GROUND_TOP-130),10,Color(p.accent,0.5+0.4*pulse))
   "stairs":
    for k in range(7):
     draw_rect(Rect2(x-50+k*8,GROUND_TOP-20-k*14,100-k*8,14),Color(0.12,0.11,0.24))
     draw_line(Vector2(x-50+k*8,GROUND_TOP-20-k*14),Vector2(x+50,GROUND_TOP-20-k*14),Color(p.cool,0.4),1.5)
   "exit":
    # a lit passage arch with its destination glowing through it
    draw_rect(Rect2(x-34,GROUND_TOP-150,68,170),Color(0.02,0.02,0.06,0.85))
    draw_rect(Rect2(x-34,GROUND_TOP-150,68,170),Color(p.cool,0.55),false,2)
    gradient_rect(Rect2(x-30,GROUND_TOP-146,60,162),Color(p.accent,0.0),Color(p.accent,0.22))
 if zone=="workshop":
  draw_circle(Vector2(width*0.5,GROUND_TOP-260),240,Color(1.0,0.75,0.4,0.05))
func draw_fore() -> void:
 var p=pal()
 if not interior() and not Profile.data.settings.get("reduced_motion",false):
  for i in range(70):
   var x=fmod(i*97.3-time*90+6000,1340)-30
   var y=fmod(i*53.7+time*(620+(i%3)*80)+i*11,780)-30
   draw_line(Vector2(x,y),Vector2(x-9,y+26),Color(0.72,0.55,1.0,0.18 if i%2==0 else 0.1),1.5)
 elif interior() and not Profile.data.settings.get("reduced_motion",false):
  for i in range(26):
   var mx=fmod(i*173.0+time*(6+i%5),1280.0)
   var my=fmod(i*91.0-time*(10+i%4)+720,720.0)
   draw_circle(Vector2(mx,my),1.8,Color(p.accent,0.35))
 gradient_rect(Rect2(0,0,1280,720),Color(p.cool,0.05),Color(p.cool,0.08))
 var dark=Color(0.0,0.0,0.02,0.6)
 var clear=Color(0.0,0.0,0.02,0.0)
 draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(190,0),Vector2(190,720),Vector2(0,720)]),PackedColorArray([dark,clear,clear,dark]))
 draw_polygon(PackedVector2Array([Vector2(1090,0),Vector2(1280,0),Vector2(1280,720),Vector2(1090,720)]),PackedColorArray([clear,dark,dark,clear]))
 draw_polygon(PackedVector2Array([Vector2(0,600),Vector2(1280,600),Vector2(1280,720),Vector2(0,720)]),PackedColorArray([clear,clear,dark,dark]))
