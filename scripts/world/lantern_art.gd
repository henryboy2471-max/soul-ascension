extends WorldArt
class_name LanternArt
# Lantern Quarter (Episode 2): terraced lower district under violet rain. Reuses the district sky/far/mid layers and overrides the
# near facades, wet stone ground, props (depot, radio, three resonators, notice, roof gate, Rain Array) and a heavier violet-rain layer.
const RES_X = [1350.0,1750.0,2150.0]
const DEPOT_X = 470.0
const RADIO_X = 1090.0
const NOTICE_X = 1550.0
const GATE_X = 2420.0
const ARRAY_X = 2600.0
func draw_sky() -> void:
 gradient_rect(Rect2(0,0,width,520),Color(0.035,0.02,0.1),Color(0.36,0.17,0.5))
 for i in range(11):
  var y=30.0+i*40.0
  var x=fmod(i*293.0,width)
  draw_line(Vector2(x-300,y),Vector2(x+340,y+22),Color(0.6,0.35,0.95,0.06),30)
 var centre=Vector2(width*0.5,170)
 for i in range(6):
  draw_arc(centre,250.0+i*6,0,TAU,96,Color(0.62,0.42,1.0,0.05),16-i*2)
 draw_circle(centre,200,Color(0.12,0.06,0.24,0.6))
func draw_near() -> void:
 var rng=RandomNumberGenerator.new()
 rng.seed=71
 var font=ThemeDB.fallback_font
 var signs=["LANTERN QUARTER","TERRACE 3","TEA & REPAIR","LOWER STAIRS","LANTERN CIRCUIT"]
 var x=40.0
 var n=0
 while x<width:
  var w=rng.randf_range(200,320)
  var h=rng.randf_range(250,380)
  draw_rect(Rect2(x,GROUND_TOP+20-h,w,h),Color(0.05,0.04,0.11))
  draw_rect(Rect2(x,GROUND_TOP+20-h,5,h),Color(0.6,0.4,0.95,0.22))
  draw_rect(Rect2(x,GROUND_TOP+20-h,w,6),Color(0.22,0.17,0.4))
  for r in range(int(h/46)):
   for c in range(int(w/46)):
    if rng.randf()<0.22:
     draw_rect(Rect2(x+14+c*46,GROUND_TOP+20-h+20+r*46,22,16),Color(1.0,0.72,0.4,rng.randf_range(0.3,0.65)))
  # hanging lantern strings between the facades
  var sy=GROUND_TOP-150+rng.randf_range(-40,10)
  draw_line(Vector2(x,sy),Vector2(x+w,sy+22),Color(0.35,0.3,0.55,0.7),2)
  for k in range(5):
   var lx=x+20+k*(w-40)/4.0
   var ly=sy+4+(k*(w-40)/4.0)/w*22.0
   draw_circle(Vector2(lx,ly+10),16,Color(1.0,0.7,0.35,0.09))
   draw_circle(Vector2(lx,ly+10),6,Color(1.0,0.78,0.42,0.95))
  var tint=Color(0.75,0.5,1.0) if n%2==0 else Color(1.0,0.72,0.4)
  var sign_y=GROUND_TOP-100+rng.randf_range(-24,16)
  draw_rect(Rect2(x+20,sign_y,w-40,34),Color(tint,0.13))
  draw_rect(Rect2(x+20,sign_y,w-40,34),Color(tint,0.85),false,2)
  draw_string(font,Vector2(x+20,sign_y+25),signs[n%signs.size()],HORIZONTAL_ALIGNMENT_CENTER,w-40,19,tint)
  n+=1
  x+=w+rng.randf_range(70,200)
func draw_ground() -> void:
 draw_rect(Rect2(0,GROUND_TOP,width,260),Color(0.05,0.045,0.1))
 gradient_rect(Rect2(0,GROUND_TOP,width,40),Color(0.2,0.15,0.34),Color(0.1,0.08,0.2))
 draw_line(Vector2(0,GROUND_TOP+40),Vector2(width,GROUND_TOP+40),Color(0.65,0.45,0.95,0.45),2)
 gradient_rect(Rect2(0,GROUND_TOP+41,width,260),Color(0.085,0.065,0.17),Color(0.035,0.03,0.08))
 var rng=RandomNumberGenerator.new()
 rng.seed=83
 # wet flagstones
 for i in range(int(width/70)):
  var sx=i*70.0
  draw_line(Vector2(sx,GROUND_TOP+44),Vector2(sx-30,GROUND_TOP+240),Color(0.5,0.4,0.8,0.08),2)
 for i in range(5):
  draw_line(Vector2(0,GROUND_TOP+70+i*40),Vector2(width,GROUND_TOP+70+i*40),Color(0.5,0.4,0.8,0.06),2)
 # violet and amber puddle reflections
 for i in range(int(width/130)):
  var rx=rng.randf_range(0,width)
  var tint=Color(0.75,0.5,1.0) if i%2==0 else Color(1.0,0.72,0.4)
  draw_line(Vector2(rx,GROUND_TOP+44),Vector2(rx+rng.randf_range(-20,20),GROUND_TOP+230),Color(tint,0.11),rng.randf_range(6,16))
 for i in range(int(width/200)):
  var px=rng.randf_range(0,width)
  var py=rng.randf_range(GROUND_TOP+120,GROUND_TOP+235)
  draw_set_transform(Vector2(px,py),0,Vector2(1,0.18))
  draw_circle(Vector2.ZERO,rng.randf_range(50,120),Color(0.6,0.45,0.95,0.14))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_props() -> void:
 var font=ThemeDB.fallback_font
 var calm=bool(lantern_state.get("calm",false))
 # after the ending the resonators hold a steady, quiet glow instead of pulsing
 var pulse=0.35 if calm else 0.5+0.5*sin(time*3.0)
 var synced=lantern_state.synced
 # Depot 4: a drained tram shed with an open doorway and warm interior light
 var dx=380.0
 draw_rect(Rect2(dx,GROUND_TOP-190,780,210),Color(0.07,0.06,0.15))
 draw_rect(Rect2(dx,GROUND_TOP-190,780,12),Color(0.24,0.18,0.44))
 draw_rect(Rect2(dx,GROUND_TOP-190,780,210),Color(0.6,0.45,0.9,0.4),false,2)
 draw_rect(Rect2(dx+60,GROUND_TOP-150,700,160),Color(0.12,0.08,0.18))
 gradient_rect(Rect2(dx+60,GROUND_TOP-150,700,160),Color(1.0,0.7,0.35,0.0),Color(1.0,0.7,0.35,0.16))
 for i in range(8):
  var lx=dx+100+i*84.0
  draw_line(Vector2(lx,GROUND_TOP-190),Vector2(lx,GROUND_TOP-150),Color(0.4,0.34,0.6,0.7),2)
  draw_circle(Vector2(lx,GROUND_TOP-142),14,Color(1.0,0.72,0.38,0.1+0.05*sin(time*2.0+i)))
  draw_circle(Vector2(lx,GROUND_TOP-142),5,Color(1.0,0.8,0.45,0.9))
 draw_rect(Rect2(dx+8,GROUND_TOP-170,110,26),Color(0.04,0.04,0.1))
 draw_rect(Rect2(dx+8,GROUND_TOP-170,110,26),Color(1.0,0.78,0.42,0.9),false,2)
 draw_string(font,Vector2(dx+8,GROUND_TOP-151),"DEPOT 4",HORIZONTAL_ALIGNMENT_CENTER,110,18,Color(1.0,0.8,0.45))
 # radio unit with a pulsing signal light
 draw_rect(Rect2(RADIO_X-22,GROUND_TOP-62,44,54),Color(0.07,0.08,0.16))
 draw_rect(Rect2(RADIO_X-22,GROUND_TOP-62,44,54),Color(0.5,0.85,0.95,0.6),false,2)
 draw_line(Vector2(RADIO_X+14,GROUND_TOP-62),Vector2(RADIO_X+22,GROUND_TOP-110),Color(0.6,0.6,0.85,0.8),2)
 draw_circle(Vector2(RADIO_X,GROUND_TOP-36),5,Color(0.42,0.9,1.0,0.4+0.5*pulse))
 # three lantern resonators (dim ember until synced, then bright teal-white)
 for i in range(3):
  var rx=RES_X[i]
  var lit=bool(synced[i])
  var core=Color(0.8,1.0,1.0) if lit else Color(1.0,0.55,0.3)
  draw_rect(Rect2(rx-7,GROUND_TOP-150,14,180),Color(0.09,0.09,0.2))
  draw_rect(Rect2(rx-26,GROUND_TOP+8,52,12),Color(0.12,0.12,0.26))
  draw_rect(Rect2(rx-24,GROUND_TOP-190,48,52),Color(0.04,0.05,0.12))
  draw_rect(Rect2(rx-24,GROUND_TOP-190,48,52),Color(core,0.8 if lit else 0.5),false,2)
  var glow=(0.35+0.25*pulse) if lit else 0.12
  for g in range(4):
   draw_circle(Vector2(rx,GROUND_TOP-164),(60-g*13) if lit else (34-g*7),Color(core,glow*0.35+g*0.02))
  draw_circle(Vector2(rx,GROUND_TOP-164),9,Color(core,0.95 if lit else 0.55))
  if lit:
   draw_colored_polygon(PackedVector2Array([Vector2(rx-8,GROUND_TOP-140),Vector2(rx+8,GROUND_TOP-140),Vector2(rx+70,GROUND_TOP+60),Vector2(rx-70,GROUND_TOP+60)]),Color(0.6,0.95,1.0,0.06))
  for k in range(3):
   draw_arc(Vector2(rx,GROUND_TOP-164),22+k*9+(fposmod(time*14.0,9.0) if lit and not calm else 0.0),0,TAU,24,Color(core,0.25-k*0.06),2)
 # Meridian maintenance notice
 draw_rect(Rect2(NOTICE_X-5,GROUND_TOP-30,10,60),Color(0.09,0.1,0.18))
 draw_rect(Rect2(NOTICE_X-58,GROUND_TOP-92,116,66),Color(0.04,0.06,0.13))
 draw_rect(Rect2(NOTICE_X-58,GROUND_TOP-92,116,66),Color(1.0,0.5,0.55,0.8),false,2)
 draw_string(font,Vector2(NOTICE_X-54,GROUND_TOP-70),"MERIDIAN NOTICE",HORIZONTAL_ALIGNMENT_CENTER,108,12,Color(1.0,0.55,0.6))
 draw_string(font,Vector2(NOTICE_X-54,GROUND_TOP-50),"RAIN ARRAY 7",HORIZONTAL_ALIGNMENT_CENTER,108,12,Color(0.9,0.9,1.0))
 draw_string(font,Vector2(NOTICE_X-54,GROUND_TOP-34),"MAINTENANCE",HORIZONTAL_ALIGNMENT_CENTER,108,11,Color(0.7,0.7,0.9))
 # roof gate: a shutter over the stairs; red lock light until all three resonators are synced
 var open=bool(lantern_state.roof_open)
 draw_rect(Rect2(GATE_X-70,GROUND_TOP-170,140,200),Color(0.06,0.06,0.14))
 draw_rect(Rect2(GATE_X-70,GROUND_TOP-170,140,200),Color(0.55,0.45,0.85,0.5),false,2)
 for s in range(6):
  draw_line(Vector2(GATE_X-64+s*24,GROUND_TOP-160+(s if open else 0)*0),Vector2(GATE_X-64+s*24,GROUND_TOP+20),Color(0.3,0.3,0.5,0.0 if open else 0.7),3)
 if not open:
  draw_rect(Rect2(GATE_X-70,GROUND_TOP-170,140,200),Color(0.03,0.03,0.08,0.55))
 draw_circle(Vector2(GATE_X,GROUND_TOP-140),7,Color(0.45,1.0,0.8,0.9) if open else Color(1.0,0.35,0.45,0.5+0.45*pulse))
 draw_string(font,Vector2(GATE_X-66,GROUND_TOP-110),"ROOF ACCESS",HORIZONTAL_ALIGNMENT_CENTER,132,14,Color(0.45,1.0,0.8) if open else Color(1.0,0.5,0.55))
 draw_string(font,Vector2(GATE_X-66,GROUND_TOP-92),"OPEN" if open else "LOCKED",HORIZONTAL_ALIGNMENT_CENTER,132,14,Color(0.45,1.0,0.8) if open else Color(1.0,0.5,0.55))
 # Rain Array 7: roof pylon with dish rings and a console
 var ax=ARRAY_X
 var charged=open
 draw_rect(Rect2(ax-10,GROUND_TOP-330,20,360),Color(0.09,0.08,0.2))
 for k in range(4):
  var ry=GROUND_TOP-300+k*52.0
  draw_arc(Vector2(ax,ry),60-k*8,PI*1.1,PI*1.9,20,Color(0.78,0.55,1.0,0.8),4)
  draw_arc(Vector2(ax,ry),72-k*8+pulse*4.0,PI*1.15,PI*1.85,20,Color(0.78,0.55,1.0,0.25),2)
 draw_rect(Rect2(ax-44,GROUND_TOP-70,88,100),Color(0.07,0.06,0.16))
 draw_rect(Rect2(ax-44,GROUND_TOP-70,88,100),Color(0.7,0.5,1.0,0.6),false,2)
 var screen_color=Color(0.8,0.6,1.0) if charged else Color(0.5,0.3,0.7)
 draw_rect(Rect2(ax-36,GROUND_TOP-58,72,44),Color(screen_color,0.18+0.25*pulse))
 draw_rect(Rect2(ax-36,GROUND_TOP-58,72,44),screen_color,false,2)
 for g in range(3):
  draw_circle(Vector2(ax,GROUND_TOP-36),60-g*14,Color(screen_color,0.04+0.02*pulse))
 draw_broadcast_screens(font)
 if breach_open and breach_scale>0.01:
  var bc=Vector2(ax+10,GROUND_TOP-30)
  var s=breach_scale
  for g in range(6):
   draw_set_transform(bc,0,Vector2(0.6,1))
   draw_circle(Vector2.ZERO,(150-g*18)*s,Color(0.55,0.35,1.0,0.05+g*0.02))
   draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  for r in range(5):
   var radius=(130-r*20)*s
   draw_set_transform(bc,time*(0.6+r*0.25)*(1 if r%2==0 else -1),Vector2(0.6,1))
   draw_arc(Vector2.ZERO,radius,0.2,PI*1.5,40,Color(0.6+r*0.07,0.45,1.0,0.9-r*0.12),4)
   draw_arc(Vector2.ZERO,radius,PI*1.5+0.5,TAU-0.1,24,Color(0.4,0.9,1.0,0.6),2)
   draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  draw_set_transform(bc,0,Vector2(0.6,1))
  draw_circle(Vector2.ZERO,38*s,Color(0.9,0.85,1.0,0.35+0.2*pulse))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_broadcast_screens(font:Font) -> void:
 # Meridian screens on the facades light up with the Amnesty broadcast (ending only; broadcast stays 0 during play).
 var b=float(lantern_state.get("broadcast",0.0))
 if b<=0.01:
  return
 for sx in [1640.0,2230.0]:
  var flick=0.75+0.25*sin(time*23.0+sx)
  draw_rect(Rect2(sx-115,GROUND_TOP-330,230,96),Color(0.05,0.02,0.05,0.9*b))
  draw_rect(Rect2(sx-115,GROUND_TOP-330,230,96),Color(1.0,0.35,0.45,0.9*b*flick),false,3)
  draw_rect(Rect2(sx-115,GROUND_TOP-330,230,96),Color(1.0,0.2,0.3,0.12*b*flick))
  draw_string(font,Vector2(sx-109,GROUND_TOP-296),"RESONANCE AMNESTY",HORIZONTAL_ALIGNMENT_CENTER,218,17,Color(1.0,0.85,0.88,b*flick))
  draw_string(font,Vector2(sx-109,GROUND_TOP-270),"REGISTER  48:00:00",HORIZONTAL_ALIGNMENT_CENTER,218,15,Color(1.0,0.5,0.58,b*flick))
  draw_circle(Vector2(sx,GROUND_TOP-170),150.0*b,Color(1.0,0.3,0.4,0.05*b))
func draw_fore() -> void:
 # heavier violet rain: more streaks, violet tint, two speeds, plus splash ripples on the ground
 var rain=float(lantern_state.get("rain",1.0))
 if not Profile.data.settings.get("reduced_motion",false):
  for i in range(int(90*rain)):
   var x=fmod(i*97.3-time*90+6000,1340)-30
   var y=fmod(i*53.7+time*(620+(i%3)*80)+i*11,780)-30
   draw_line(Vector2(x,y),Vector2(x-9,y+26),Color(0.72,0.55,1.0,(0.2 if i%2==0 else 0.12)*clampf(rain+0.3,0.0,1.0)),1.5)
  for i in range(int(14*rain)):
   var rx=fmod(i*131.0+time*20.0,1280.0)
   var phase=fmod(time*1.6+i*0.37,1.0)
   draw_set_transform(Vector2(rx,590+(i%4)*28),0,Vector2(1,0.25))
   draw_arc(Vector2.ZERO,6.0+phase*18.0,0,TAU,16,Color(0.8,0.65,1.0,0.35*(1.0-phase)),1.5)
   draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 gradient_rect(Rect2(0,0,1280,720),Color(0.35,0.15,0.6,0.07),Color(0.2,0.08,0.4,0.1))
 var dark=Color(0.0,0.0,0.02,0.6)
 var clear=Color(0.0,0.0,0.02,0.0)
 draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(190,0),Vector2(190,720),Vector2(0,720)]),PackedColorArray([dark,clear,clear,dark]))
 draw_polygon(PackedVector2Array([Vector2(1090,0),Vector2(1280,0),Vector2(1280,720),Vector2(1090,720)]),PackedColorArray([clear,dark,dark,clear]))
 draw_polygon(PackedVector2Array([Vector2(0,600),Vector2(1280,600),Vector2(1280,720),Vector2(0,720)]),PackedColorArray([clear,clear,dark,dark]))
