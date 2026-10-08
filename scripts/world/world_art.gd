extends Node2D
class_name WorldArt
# Procedural layered district art. Static layers are drawn once and only moved for parallax (cheap on web).
var kind="sky"
var width=1280.0
var time=0.0
var breach_open=false
var breach_scale=0.0
var terminal_done=false
# Lantern Quarter state (read by LanternArt): resonators synced in order [a,b,c], roof gate open.
var lantern_state:Dictionary={"synced":[false,false,false],"roof_open":false}
var bake=true
const GROUND_TOP = 470.0
const STATIC_KINDS = ["sky","far","mid","near","ground"]
const ROWS = {"sky":Vector2(0,520),"far":Vector2(40,520),"mid":Vector2(110,520),"near":Vector2(60,520),"ground":Vector2(470,720)}
func _ready() -> void:
 # Static layers are drawn once into a texture; the parallax then moves one cheap sprite instead of re-rasterizing hundreds of shapes.
 if bake and kind in STATIC_KINDS:
  var rows=ROWS[kind]
  var vp=SubViewport.new()
  vp.size=Vector2i(int(ceil(width)),int(rows.y-rows.x))
  vp.transparent_bg=kind!="sky"
  vp.disable_3d=true
  vp.render_target_update_mode=SubViewport.UPDATE_ONCE
  var painter=get_script().new()
  painter.kind=kind
  painter.width=width
  painter.bake=false
  painter.position.y=-rows.x
  vp.add_child(painter)
  add_child(vp)
  var sprite=Sprite2D.new()
  sprite.centered=false
  sprite.position.y=rows.x
  sprite.texture=vp.get_texture()
  add_child(sprite)
func _process(delta:float) -> void:
 if kind=="props" or kind=="fore":
  if not Profile.data.settings.get("reduced_motion",false):
   time+=delta
  if breach_open:
   breach_scale=minf(1.0,breach_scale+delta*0.9)
  queue_redraw()
func _draw() -> void:
 if bake and kind in STATIC_KINDS:
  return
 match kind:
  "sky": draw_sky()
  "far": draw_far()
  "mid": draw_mid()
  "near": draw_near()
  "ground": draw_ground()
  "props": draw_props()
  "fore": draw_fore()
func gradient_rect(rect:Rect2, top:Color, bottom:Color) -> void:
 draw_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),PackedColorArray([top,top,bottom,bottom]))
func draw_sky() -> void:
 gradient_rect(Rect2(0,0,width,520),Color(0.025,0.03,0.085),Color(0.3,0.15,0.44))
 for i in range(9):
  var y=40.0+i*38.0
  var x=fmod(i*271.0,width)
  draw_line(Vector2(x-260,y),Vector2(x+300,y+18),Color(0.45,0.3,0.8,0.05),26)
 var center=Vector2(width*0.62,150)
 for i in range(5):
  draw_arc(center,230.0+i*5,0,TAU,96,Color(0.55,0.4,0.9,0.06),14-i*2)
 draw_arc(center,226,0,TAU,96,Color(0.78,0.62,1.0,0.5),3)
 for i in range(7):
  var start=i*0.9
  draw_arc(center,248,start,start+0.35,16,Color(0.8,0.65,1.0,0.55),2)
 draw_circle(center,190,Color(0.1,0.07,0.2,0.55))
func draw_far() -> void:
 var rng=RandomNumberGenerator.new()
 rng.seed=11
 var x=-40.0
 while x<width:
  var w=rng.randf_range(60,130)
  var h=rng.randf_range(190,390)
  draw_rect(Rect2(x,GROUND_TOP-h,w,h+40),Color(0.12,0.1,0.26))
  draw_rect(Rect2(x+w-5,GROUND_TOP-h,5,h+40),Color(0.2,0.17,0.4,0.6))
  if rng.randf()<0.45:
   draw_line(Vector2(x+w*0.5,GROUND_TOP-h),Vector2(x+w*0.5,GROUND_TOP-h-rng.randf_range(24,70)),Color(0.55,0.5,0.9,0.7),2)
   draw_circle(Vector2(x+w*0.5,GROUND_TOP-h-4),3,Color(1,0.4,0.55,0.9))
  x+=w+rng.randf_range(8,40)
 gradient_rect(Rect2(0,GROUND_TOP-170,width,210),Color(0.35,0.2,0.55,0.0),Color(0.5,0.28,0.7,0.7))
func draw_mid() -> void:
 var rng=RandomNumberGenerator.new()
 rng.seed=23
 var x=-30.0
 var palette=[Color(0.4,0.85,0.95),Color(0.74,0.55,1.0),Color(1.0,0.75,0.4)]
 while x<width:
  var w=rng.randf_range(90,190)
  var h=rng.randf_range(130,300)
  draw_rect(Rect2(x,GROUND_TOP-h,w,h+40),Color(0.06,0.075,0.17))
  draw_line(Vector2(x,GROUND_TOP-h),Vector2(x+w,GROUND_TOP-h),Color(0.35,0.4,0.7,0.5),2)
  var rows=int(h/22)
  var cols=int(w/20)
  for r in range(rows):
   for c in range(cols):
    if rng.randf()<0.28:
     var tint=palette[rng.randi()%3]
     draw_rect(Rect2(x+8+c*20,GROUND_TOP-h+10+r*22,9,11),Color(tint,rng.randf_range(0.35,0.85)))
  if rng.randf()<0.4:
   var neon=palette[rng.randi()%3]
   var nx=x+w-14
   draw_rect(Rect2(nx-4,GROUND_TOP-h+20,12,rng.randf_range(60,130)),Color(neon,0.14))
   draw_rect(Rect2(nx,GROUND_TOP-h+20,4,rng.randf_range(60,130)),Color(neon,0.9))
  x+=w+rng.randf_range(6,30)
 # elevated skybridge with traffic lights
 draw_rect(Rect2(0,GROUND_TOP-62,width,10),Color(0.07,0.08,0.18))
 draw_line(Vector2(0,GROUND_TOP-62),Vector2(width,GROUND_TOP-62),Color(0.55,0.45,0.9,0.7),2)
 for i in range(int(width/90)):
  draw_circle(Vector2(30+i*90,GROUND_TOP-58),3,Color(0.4,0.9,1.0,0.8))
func draw_near() -> void:
 var rng=RandomNumberGenerator.new()
 rng.seed=37
 var font=ThemeDB.fallback_font
 var signs=["RAMEN","TRAM","SKYBRIDGE 09","CLINIC","NEON DISTRICT","NOODLE","ARCADE"]
 var x=60.0
 var n=0
 while x<width:
  var w=rng.randf_range(190,330)
  var h=rng.randf_range(240,400)
  draw_rect(Rect2(x,GROUND_TOP+20-h,w,h),Color(0.04,0.05,0.11))
  draw_rect(Rect2(x,GROUND_TOP+20-h,5,h),Color(0.4,0.5,0.9,0.25))
  draw_rect(Rect2(x,GROUND_TOP+20-h,w,6),Color(0.2,0.22,0.42))
  for r in range(int(h/46)):
   for c in range(int(w/46)):
    if rng.randf()<0.2:
     draw_rect(Rect2(x+14+c*46,GROUND_TOP+20-h+20+r*46,22,16),Color(1.0,0.82,0.5,rng.randf_range(0.35,0.7)))
  var tint=[Color(0.4,0.9,1.0),Color(0.85,0.5,1.0),Color(1.0,0.45,0.6)][n%3]
  var sign_y=GROUND_TOP-110+rng.randf_range(-30,20)
  draw_rect(Rect2(x+20,sign_y,w-40,36),Color(tint,0.14))
  draw_rect(Rect2(x+20,sign_y,w-40,36),Color(tint,0.9),false,2)
  draw_string(font,Vector2(x+20,sign_y+26),signs[n%signs.size()],HORIZONTAL_ALIGNMENT_CENTER,w-40,20,tint)
  n+=1
  x+=w+rng.randf_range(90,260)
func draw_ground() -> void:
 draw_rect(Rect2(0,GROUND_TOP,width,260),Color(0.045,0.055,0.11))
 gradient_rect(Rect2(0,GROUND_TOP,width,40),Color(0.17,0.17,0.32),Color(0.09,0.1,0.2))
 draw_line(Vector2(0,GROUND_TOP+40),Vector2(width,GROUND_TOP+40),Color(0.5,0.42,0.85,0.45),2)
 gradient_rect(Rect2(0,GROUND_TOP+41,width,260),Color(0.075,0.08,0.16),Color(0.03,0.035,0.08))
 # tram rails and ties
 draw_line(Vector2(0,GROUND_TOP+28),Vector2(width,GROUND_TOP+28),Color(0.6,0.62,0.78,0.55),2)
 draw_line(Vector2(0,GROUND_TOP+34),Vector2(width,GROUND_TOP+34),Color(0.45,0.47,0.62,0.4),2)
 for i in range(int(width/46)):
  draw_line(Vector2(i*46,GROUND_TOP+26),Vector2(i*46+8,GROUND_TOP+36),Color(0.3,0.3,0.45,0.35),3)
 # wet-street neon reflections and puddles
 var rng=RandomNumberGenerator.new()
 rng.seed=51
 for i in range(int(width/110)):
  var rx=rng.randf_range(0,width)
  var tint=[Color(0.4,0.9,1.0),Color(0.85,0.5,1.0),Color(1.0,0.45,0.6)][i%3]
  draw_line(Vector2(rx,GROUND_TOP+44),Vector2(rx+rng.randf_range(-20,20),GROUND_TOP+230),Color(tint,0.11),rng.randf_range(6,18))
 for i in range(int(width/260)):
  var px=rng.randf_range(0,width)
  var py=rng.randf_range(GROUND_TOP+130,GROUND_TOP+235)
  draw_set_transform(Vector2(px,py),0,Vector2(1,0.18))
  draw_circle(Vector2.ZERO,rng.randf_range(50,110),Color(0.45,0.5,0.9,0.12))
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for i in range(int(width/180)):
  draw_line(Vector2(i*180,GROUND_TOP+200),Vector2(i*180+80,GROUND_TOP+200),Color(0.7,0.7,0.9,0.18),3)
func draw_props() -> void:
 var font=ThemeDB.fallback_font
 var pulse=0.5+0.5*sin(time*3.0)
 # lamp posts
 for lx in [260.0,1420.0,1980.0,2400.0]:
  draw_rect(Rect2(lx-4,GROUND_TOP-170,8,200),Color(0.1,0.11,0.2))
  draw_rect(Rect2(lx-4,GROUND_TOP-172,34,8),Color(0.1,0.11,0.2))
  for g in range(4):
   draw_circle(Vector2(lx+24,GROUND_TOP-160),44-g*10,Color(1.0,0.82,0.5,0.045+g*0.025))
  draw_colored_polygon(PackedVector2Array([Vector2(lx+18,GROUND_TOP-156),Vector2(lx+30,GROUND_TOP-156),Vector2(lx+110,GROUND_TOP+60),Vector2(lx-60,GROUND_TOP+60)]),Color(1.0,0.82,0.5,0.045))
 # stalled tram
 var tx=640.0
 draw_rect(Rect2(tx,GROUND_TOP-118,690,134),Color(0.1,0.12,0.24))
 draw_rect(Rect2(tx,GROUND_TOP-118,690,10),Color(0.2,0.22,0.42))
 draw_rect(Rect2(tx,GROUND_TOP-118,690,134),Color(0.45,0.45,0.75,0.5),false,2)
 for i in range(8):
  var wx=tx+24+i*82
  var lit=0.18+0.14*sin(time*2.0+i)
  draw_rect(Rect2(wx,GROUND_TOP-96,60,50),Color(0.04,0.06,0.13))
  draw_rect(Rect2(wx,GROUND_TOP-96,60,50),Color(0.4,0.85,0.95,lit))
 draw_rect(Rect2(tx+20,GROUND_TOP-36,650,6),Color(0.9,0.3,0.4,0.9))
 draw_string(font,Vector2(tx+20,GROUND_TOP-39),"OUT OF SERVICE   -   OUT OF SERVICE   -   OUT OF SERVICE",HORIZONTAL_ALIGNMENT_LEFT,650,13,Color(1.0,0.6,0.65))
 for wx in [tx+60,tx+200,tx+500,tx+630]:
  draw_circle(Vector2(wx,GROUND_TOP+14),11,Color(0.05,0.06,0.12))
  draw_arc(Vector2(wx,GROUND_TOP+14),11,0,TAU,16,Color(0.5,0.5,0.7,0.6),2)
 # tram board
 var bx=1050.0
 draw_rect(Rect2(bx-5,GROUND_TOP-30,10,60),Color(0.09,0.1,0.18))
 draw_rect(Rect2(bx-56,GROUND_TOP-86,112,62),Color(0.04,0.06,0.13))
 draw_rect(Rect2(bx-56,GROUND_TOP-86,112,62),Color(0.4,0.9,1.0,0.8),false,2)
 draw_string(font,Vector2(bx-52,GROUND_TOP-62),"SKYBRIDGE 09",HORIZONTAL_ALIGNMENT_CENTER,104,13,Color(0.4,0.9,1.0))
 draw_string(font,Vector2(bx-52,GROUND_TOP-42),"SERVICE HALTED",HORIZONTAL_ALIGNMENT_CENTER,104,11,Color(1.0,0.6,0.65))
 # relay terminal
 var cx=1560.0
 draw_rect(Rect2(cx-26,GROUND_TOP-86,52,116),Color(0.07,0.08,0.16))
 draw_rect(Rect2(cx-26,GROUND_TOP-86,52,116),Color(0.5,0.5,0.8,0.5),false,2)
 var screen_color=Color(0.35,1.0,0.8) if terminal_done else Color(1.0,0.35,0.45)
 draw_rect(Rect2(cx-20,GROUND_TOP-76,40,34),Color(screen_color,0.2+0.25*pulse))
 draw_rect(Rect2(cx-20,GROUND_TOP-76,40,34),screen_color,false,2)
 for g in range(3):
  draw_circle(Vector2(cx,GROUND_TOP-58),50-g*14,Color(screen_color,0.04+0.02*pulse))
 draw_line(Vector2(cx,GROUND_TOP-86),Vector2(cx,GROUND_TOP-190),Color(0.5,0.5,0.8,0.6),3)
 draw_line(Vector2(cx,GROUND_TOP-190),Vector2(cx+760,GROUND_TOP-170),Color(0.5,0.5,0.8,0.35),2)
 # Lantern Circuit mural
 var mx=1860.0
 draw_rect(Rect2(mx-70,GROUND_TOP-110,140,100),Color(0.05,0.06,0.13))
 draw_rect(Rect2(mx-70,GROUND_TOP-110,140,100),Color(1.0,0.78,0.4,0.5),false,2)
 for i in range(7):
  var a=i*TAU/7.0+time*0.1
  var lp=Vector2(mx,GROUND_TOP-62)+Vector2(cos(a)*34,sin(a)*24)
  draw_circle(lp,9,Color(1.0,0.8,0.4,0.18))
  draw_circle(lp,3.5,Color(1.0,0.82,0.45,0.9))
 draw_arc(Vector2(mx,GROUND_TOP-62),46,0,TAU,40,Color(1.0,0.8,0.4,0.25),2)
 # Soul Realm breach
 if breach_open:
  var bc=Vector2(2200,GROUND_TOP-30)
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
  for i in range(10):
   var a=time*0.8+i*0.63
   var p=bc+Vector2(cos(a)*(80+i*6)*0.6,sin(a*1.3)*(70+i*4))*s
   draw_circle(p,2.5,Color(0.8,0.7,1.0,0.8))
func draw_fore() -> void:
 if not Profile.data.settings.get("reduced_motion",false):
  for i in range(46):
   var x=fmod(i*97.3-time*70+5000,1320)-20
   var y=fmod(i*53.7+time*520,760)-20
   draw_line(Vector2(x,y),Vector2(x-6,y+20),Color(0.65,0.75,1.0,0.16),1)
 var dark=Color(0.0,0.0,0.02,0.6)
 var clear=Color(0.0,0.0,0.02,0.0)
 draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(190,0),Vector2(190,720),Vector2(0,720)]),PackedColorArray([dark,clear,clear,dark]))
 draw_polygon(PackedVector2Array([Vector2(1090,0),Vector2(1280,0),Vector2(1280,720),Vector2(1090,720)]),PackedColorArray([clear,dark,dark,clear]))
 draw_polygon(PackedVector2Array([Vector2(0,600),Vector2(1280,600),Vector2(1280,720),Vector2(0,720)]),PackedColorArray([clear,clear,dark,dark]))
