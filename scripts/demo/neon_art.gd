extends RefCounted
class_name NeonArt
# Procedural art for the 2.5D Neon District demonstration (PLACEHOLDER art, original). Everything here is drawn once into baked textures
# (see Stage25.bake) so the per-frame cost is a handful of sprites. Coordinates: x = world x, y = screen y at camera zoom 1.
const BG = Color("070817")
const VIOLET = Color("8a4dff")
const CYAN = Color("35e6ff")
const MAGENTA = Color("ff4fb0")
const GOLD = Color("ffc060")
const WARM = Color("ffd89a")
const Y_BACK = 392.0    # back edge of the walkable plane (building base line)
const Y_FRONT = 656.0   # front edge of the walkable plane
# Street-level shop fronts, left to right. door = enterable building. Names are placeholder shop signs.
const STORES = [
 {"x":40,"w":330,"h":250,"name":"RAMEN ROW","col":"ff4fb0"},
 {"x":380,"w":300,"h":210,"name":"NOODLE","col":"ffc060"},
 {"x":690,"w":250,"h":270,"name":"TRAM PARTS","col":"35e6ff"},
 {"x":950,"w":330,"h":235,"name":"NOODLE HOUSE","col":"ff7a3d","door":"noodle"},
 {"x":1290,"w":360,"h":290,"name":"CLINIC 24","col":"5af0a0"},
 {"x":1660,"w":300,"h":230,"name":"SKYBRIDGE 09","col":"35e6ff"},
 {"x":1970,"w":420,"h":310,"name":"NEON DISTRICT","col":"bd7bff","tower":true},
 {"x":2400,"w":320,"h":240,"name":"ARCADE","col":"ff4fb0"},
 {"x":2730,"w":300,"h":260,"name":"DATA  DEN","col":"35e6ff"},
 {"x":3040,"w":240,"h":250,"name":"JUNCTION 7","col":"ffc060","dim":true},
 {"x":3290,"w":340,"h":230,"name":"","col":"8a4dff","hidden":true},
 {"x":3640,"w":300,"h":280,"name":"LANTERN SUPPLY","col":"ffc060"},
 {"x":3950,"w":420,"h":255,"name":"MERIDIAN NOODLES","col":"ff4fb0"},
 {"x":4380,"w":400,"h":270,"name":"EXIT  /  TRAM 4","col":"35e6ff"},
]
static func rng_for(seed:int) -> RandomNumberGenerator:
 var r=RandomNumberGenerator.new()
 r.seed=seed
 return r
static func gradient(c:CanvasItem, rect:Rect2, top:Color, bottom:Color) -> void:
 c.draw_polygon(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),PackedColorArray([top,top,bottom,bottom]))
static func glow_rect(c:CanvasItem, rect:Rect2, col:Color, spread:float=10.0, strength:float=0.2) -> void:
 for i in range(5):
  var g=spread*(1.0-float(i)/5.0)
  c.draw_rect(rect.grow(g),Color(col,strength*(float(i)+1.0)/5.0*0.6),true)
 c.draw_rect(rect,Color(col,0.95),true)
 c.draw_rect(rect.grow(-rect.size.x*0.3 if rect.size.x<rect.size.y else 0.0),Color(1,1,1,0.55),true)
# ------------------------------------------------------------------ sky (fixed to the screen)
static func sky(c:CanvasItem, w:float, h:float) -> void:
 gradient(c,Rect2(0,0,w,h*0.62),Color("060616"),Color("1a1040"))
 gradient(c,Rect2(0,h*0.62,w,h*0.38),Color("1a1040"),Color("46206e"))
 # distant broken halo ring (matches the Echo key art skyline) and cloud bands
 for k in range(8):
  c.draw_arc(Vector2(w*0.66,150),210+k*3,PI*1.05,PI*1.95,60,Color(0.55,0.32,1.0,0.05+0.012*k),2.0+k)
 c.draw_arc(Vector2(w*0.66,150),213,PI*1.05,PI*1.9,64,Color(0.75,0.55,1.0,0.55),2.0)
 var r=rng_for(11)
 for i in range(16):
  var y=r.randf_range(20,300)
  c.draw_rect(Rect2(r.randf_range(-200,w),y,r.randf_range(300,800),r.randf_range(10,36)),Color(0.35,0.2,0.6,r.randf_range(0.04,0.1)))
# ------------------------------------------------------------------ far skyline, three silhouette bands (parallax)
static func far(c:CanvasItem, w:float, h:float) -> void:
 var bands=[{"y":330.0,"col":Color("1b1546"),"win":0.18,"hmin":90,"hmax":230,"wmin":40,"wmax":90,"seed":3},
  {"y":356.0,"col":Color("120f33"),"win":0.28,"hmin":110,"hmax":290,"wmin":50,"wmax":110,"seed":4},
  {"y":380.0,"col":Color("0b0a22"),"win":0.4,"hmin":140,"hmax":340,"wmin":60,"wmax":130,"seed":5}]
 for b in bands:
  var r=rng_for(b.seed)
  var x=-20.0
  while x<w:
   var bw=r.randf_range(b.wmin,b.wmax)
   var bh=r.randf_range(b.hmin,b.hmax)
   var top=b.y-bh
   c.draw_rect(Rect2(x,top,bw,bh+60),b.col)
   if r.randf()<0.4:
    c.draw_rect(Rect2(x+bw*0.4,top-r.randf_range(14,40),bw*0.12,40),b.col)
   if r.randf()<0.3:
    c.draw_rect(Rect2(x+bw*0.1,top-8,bw*0.8,8),b.col)
   # lit windows
   var cols=int(bw/9.0)
   for ix in range(cols):
    for iy in range(int(bh/12.0)):
     if r.randf()<b.win*0.35:
      var wc=WARM if r.randf()<0.55 else (CYAN if r.randf()<0.6 else MAGENTA)
      c.draw_rect(Rect2(x+4+ix*9.0,top+6+iy*12.0,4,5),Color(wc,r.randf_range(0.25,0.8)))
   if r.randf()<0.35:
    var ncol=[VIOLET,CYAN,MAGENTA][r.randi()%3]
    c.draw_rect(Rect2(x+bw*0.08,top+10,3,bh*0.6),Color(ncol,0.2))
    c.draw_rect(Rect2(x+bw*0.08+0.5,top+10,2,bh*0.6),Color(ncol,0.85))
   x+=bw+r.randf_range(-8,10)
  # atmospheric haze after each band
  gradient(c,Rect2(0,b.y-90,w,150),Color(0.45,0.2,0.7,0.0),Color(0.45,0.2,0.7,0.16))
 # skybridge arc
 c.draw_rect(Rect2(0,300,w,5),Color("2a1d5a"))
 for i in range(int(w/110)):
  c.draw_rect(Rect2(i*110.0+50,305,4,62),Color("2a1d5a"))
# ------------------------------------------------------------------ street-level facade strip (scroll 1.0), baked in chunks
static func facade(c:CanvasItem, x0:float, x1:float) -> void:
 var base=Y_BACK
 var r0=rng_for(77)
 # continuous back wall tone behind the shop fronts
 gradient(c,Rect2(x0,base-360,x1-x0,360),Color("0e0c26"),Color("191238"))
 for s in STORES:
  var sx=float(s.x)
  if sx+float(s.w)<x0 or sx>x1:
   continue
  var sw=float(s.w)
  var sh=float(s.h)
  var col=Color(s.col)
  var r=rng_for(int(sx)+5)
  var top=base-sh
  var tone=Color("171233").lerp(Color("241a4a"),r.randf())
  if s.get("dim",false):
   tone=Color("0f0c24")
  # building mass with a slight vertical gradient
  gradient(c,Rect2(sx,top,sw,sh),tone.lightened(0.05),tone.darkened(0.25))
  c.draw_rect(Rect2(sx,top,6,sh),Color(0,0,0,0.35))
  c.draw_rect(Rect2(sx+sw-6,top,6,sh),Color(0,0,0,0.25))
  # upper floors: window rows with warm / cyan interior light
  var rows=int((sh-96.0)/34.0)
  for iy in range(rows):
   var cols=int((sw-30.0)/46.0)
   for ix in range(cols):
    var wx=sx+18.0+ix*46.0
    var wy=top+16.0+iy*34.0
    var lit=r.randf()<0.62
    var wcol=WARM if r.randf()<0.6 else CYAN.lerp(Color.WHITE,0.3)
    c.draw_rect(Rect2(wx,wy,30,20),Color("07061a"))
    if lit:
     gradient(c,Rect2(wx+2,wy+2,26,16),Color(wcol,0.9),Color(wcol.darkened(0.35),0.9))
     if r.randf()<0.3:
      c.draw_rect(Rect2(wx+2,wy+9,26,2),Color(0.1,0.05,0.2,0.7))
    c.draw_rect(Rect2(wx-2,wy+20,34,3),Color("2b2150"))
  # roof details: AC units, antenna, water tank
  for k in range(2):
   c.draw_rect(Rect2(sx+20+k*(sw*0.5),top-12,34,12),Color("231a48"))
  if r.randf()<0.6:
   c.draw_rect(Rect2(sx+sw*0.7,top-46,3,46),Color("231a48"))
   c.draw_circle(Vector2(sx+sw*0.7+1.5,top-48),3,Color(MAGENTA,0.9))
  # vertical neon blade sign
  var bx=sx+sw-30
  glow_rect(c,Rect2(bx,top+30,5,sh*0.45),col,12.0,0.35)
  # ---- shop front (ground floor)
  var fy=base-92.0
  c.draw_rect(Rect2(sx,fy,sw,92),Color("0b0920"))
  var door_w=64.0
  var door_x=sx+sw*0.5-door_w/2
  var has_door=s.has("door")
  # display windows glowing from within
  for k in range(2):
   var wx2=sx+14.0+k*(sw-14.0)/2.0
   var ww=(sw-14.0)/2.0-(door_w/2+12.0 if k==0 else 0.0)
   if k==0:
    ww=door_x-sx-22.0
   else:
    wx2=door_x+door_w+8.0
    ww=sx+sw-wx2-14.0
   if ww<20:
    continue
   var wc=Color(s.col).lerp(WARM,0.55)
   gradient(c,Rect2(wx2,fy+14,ww,64),Color(wc,0.85),Color(wc.darkened(0.45),0.7))
   for m in range(3):
    c.draw_rect(Rect2(wx2+8+m*(ww/3.0),fy+34,ww/3.0-14,3),Color(0.08,0.04,0.15,0.55))
   c.draw_rect(Rect2(wx2,fy+14,ww,64),Color(0.02,0.0,0.08,0.0),false,2.0)
   c.draw_rect(Rect2(wx2,fy+13,ww,3),Color(0.02,0.02,0.1,0.9))
  # door
  if not s.get("hidden",false):
   c.draw_rect(Rect2(door_x,fy+12,door_w,80),Color("100b28"))
   var dcol=Color(s.col) if has_door else Color("2a2150")
   if has_door:
    gradient(c,Rect2(door_x+4,fy+16,door_w-8,76),Color(dcol.lightened(0.3),0.95),Color(dcol.darkened(0.4),0.95))
    c.draw_rect(Rect2(door_x+door_w/2-1,fy+16,2,76),Color(0.05,0.02,0.1,0.8))
   else:
    gradient(c,Rect2(door_x+4,fy+16,door_w-8,76),Color("1c1540"),Color("120d2c"))
    c.draw_circle(Vector2(door_x+door_w-12,fy+58),2.2,Color(GOLD,0.8))
  else:
   # the hidden panel: a plain wall that hums faintly (opened later by the puzzle)
   c.draw_rect(Rect2(door_x-6,fy+8,door_w+12,86),Color("0f0b26"))
   for k in range(6):
    c.draw_rect(Rect2(door_x-2,fy+14+k*13,door_w+4,2),Color(VIOLET,0.14))
   c.draw_rect(Rect2(door_x+door_w/2-0.8,fy+8,1.6,86),Color(VIOLET,0.22))
  # awning (striped) over the windows
  var ay=fy-6.0
  c.draw_polygon(PackedVector2Array([Vector2(sx-6,ay),Vector2(sx+sw+6,ay),Vector2(sx+sw-2,ay+22),Vector2(sx+2,ay+22)]),PackedColorArray([col.darkened(0.25),col.darkened(0.25),col.darkened(0.55),col.darkened(0.55)]))
  for k in range(int(sw/22.0)):
   c.draw_rect(Rect2(sx+k*22.0+2,ay,10,22),Color(0,0,0,0.25))
  c.draw_rect(Rect2(sx-6,ay,sw+12,3),Color(col,0.9))
  # sign board with the shop name
  if s.name!="":
   var font=ThemeDB.fallback_font
   var fs=int(clampf(sw/float(s.name.length())*1.35,18,34))
   var tw=font.get_string_size(s.name,HORIZONTAL_ALIGNMENT_LEFT,-1,fs).x
   var sgx=sx+sw*0.5-tw/2-14
   var sgy=fy-62.0
   glow_rect(c,Rect2(sgx,sgy,tw+28,36),Color(col,0.28),14.0,0.25)
   c.draw_rect(Rect2(sgx,sgy,tw+28,36),Color("0a0720"))
   c.draw_rect(Rect2(sgx,sgy,tw+28,36),Color(col,0.9),false,2.0)
   c.draw_string_outline(font,Vector2(sgx+14,sgy+27),s.name,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,8,Color(col,0.35))
   c.draw_string(font,Vector2(sgx+14,sgy+27),s.name,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color(col.lightened(0.55)))
  # pipes, cables and a fire escape for depth
  c.draw_rect(Rect2(sx+8,top+10,5,sh-60),Color("2b2150"))
  for k in range(3):
   c.draw_line(Vector2(sx,top+40+k*14),Vector2(sx+sw,top+54+k*18),Color(0.05,0.03,0.12,0.8),2.0)
  if r.randf()<0.5:
   var fx=sx+sw*0.2
   for k in range(3):
    c.draw_rect(Rect2(fx,top+60+k*52,60,4),Color("3a2c6a"))
    c.draw_line(Vector2(fx,top+64+k*52),Vector2(fx+60,top+112+k*52),Color("2b2150"),2.0)
 # street-level light spill on the wall base
 gradient(c,Rect2(x0,base-18,x1-x0,18),Color(0,0,0,0.0),Color(0,0,0,0.5))
# ------------------------------------------------------------------ ground plane (scroll 1.0), baked in chunks
static func ground(c:CanvasItem, x0:float, x1:float) -> void:
 var y0=Y_BACK
 var yf=Y_FRONT
 var w=x1-x0
 # near sidewalk / road / back sidewalk bands
 var back_end=y0+(yf-y0)*0.36
 var road_end=y0+(yf-y0)*0.64
 gradient(c,Rect2(x0,y0,w,back_end-y0),Color("201a44"),Color("2c2458"))
 gradient(c,Rect2(x0,back_end,w,road_end-back_end),Color("120f2a"),Color("17133a"))
 gradient(c,Rect2(x0,road_end,w,yf-road_end),Color("261e50"),Color("34286a"))
 gradient(c,Rect2(x0,yf,w,720-yf),Color("120d2c"),Color("0a0720"))
 # curbs with a neon edge, paving rows spaced wider toward the camera (perspective cue)
 c.draw_rect(Rect2(x0,back_end-3,w,5),Color("3b2f78"))
 c.draw_rect(Rect2(x0,back_end+2,w,2),Color(CYAN,0.35))
 c.draw_rect(Rect2(x0,road_end-1,w,5),Color("3b2f78"))
 c.draw_rect(Rect2(x0,road_end+3,w,2),Color(MAGENTA,0.3))
 var yy=y0
 var step=7.0
 while yy<back_end:
  c.draw_line(Vector2(x0,yy),Vector2(x1,yy),Color(0.0,0.0,0.0,0.22),1.0)
  yy+=step
  step*=1.18
 yy=road_end+6
 step=9.0
 while yy<yf:
  c.draw_line(Vector2(x0,yy),Vector2(x1,yy),Color(0.0,0.0,0.0,0.22),1.0)
  yy+=step
  step*=1.2
 var r=rng_for(31)
 var xx=x0-fmod(x0,64.0)
 while xx<x1:
  c.draw_line(Vector2(xx,y0),Vector2(xx,back_end),Color(0,0,0,0.18),1.0)
  c.draw_line(Vector2(xx-(xx-640.0)*0.0,road_end+4),Vector2(xx,yf),Color(0,0,0,0.18),1.0)
  xx+=64.0
 # lane markings + crosswalks
 var mid=(back_end+road_end)/2.0
 var dx=x0-fmod(x0,140.0)
 while dx<x1:
  c.draw_rect(Rect2(dx,mid-1.5,64,3),Color(GOLD,0.55))
  dx+=140.0
 for cx in [820.0,2200.0,3480.0,4500.0]:
  if cx>x0-120 and cx<x1+120:
   for k in range(9):
    c.draw_rect(Rect2(cx-64+k*16.0,back_end+6,9,road_end-back_end-12),Color(0.9,0.92,1.0,0.22))
 # wet street: puddles with the shop-sign colours reflected as vertical streaks (static; the animated shimmer is added by the stage)
 for s in STORES:
  var sx=float(s.x)+float(s.w)*0.5
  if sx<x0-80 or sx>x1+80:
   continue
  var col=Color(s.col)
  var n=3
  for k in range(n):
   var px=sx+r.randf_range(-120,120)
   var py=r.randf_range(back_end+10,road_end-6)
   var pw=r.randf_range(50,120)
   c.draw_set_transform(Vector2(px,py),0,Vector2(1,0.2))
   c.draw_circle(Vector2.ZERO,pw*0.5,Color(0.04,0.03,0.12,0.7))
   c.draw_circle(Vector2.ZERO,pw*0.42,Color(col,0.12))
   c.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  # reflected neon column across the road and sidewalk
  for k in range(7):
   var ry=y0+30+k*(yf-y0-30)/7.0
   var len=r.randf_range(8,22)+k*2.0
   c.draw_rect(Rect2(sx-5+r.randf_range(-3,3),ry,r.randf_range(3,7),len),Color(col,0.08+0.02*k))
 # drains, manholes and floor lights
 for k in range(int(w/220.0)):
  var gx=x0+80+k*220.0+r.randf_range(-30,30)
  c.draw_rect(Rect2(gx,road_end+14,34,5),Color("07061a"))
  c.draw_rect(Rect2(gx+2,road_end+15,30,1),Color(CYAN,0.25))
 gradient(c,Rect2(x0,y0,w,26),Color(0,0,0,0.5),Color(0,0,0,0.0))
# ------------------------------------------------------------------ interiors (baked back wall + floor)
static func interior(c:CanvasItem, w:float, kind:String) -> void:
 var base=Y_BACK
 var wall_top=Color("1a1238")
 var wall_bot=Color("26194f")
 var floor_top=Color("2a1d4e")
 var floor_bot=Color("140d30")
 var accent=Color("ff7a3d") if kind=="noodle" else (Color("ff4fb0") if kind=="arcade" else Color("35e6ff"))
 gradient(c,Rect2(0,0,w,base),wall_top,wall_bot)
 gradient(c,Rect2(0,base,w,720-base),floor_top,floor_bot)
 var r=rng_for(91)
 if kind=="noodle":
  for k in range(int(w/120.0)):   # wooden slats + paper lanterns
   c.draw_rect(Rect2(k*120.0+10,60,100,300),Color(0.28,0.16,0.2,0.5))
   c.draw_rect(Rect2(k*120.0+58,60,3,300),Color(0,0,0,0.3))
  for k in range(9):
   var lx=120+k*(w-240)/8.0
   c.draw_line(Vector2(lx,0),Vector2(lx,96+r.randf_range(0,24)),Color(0,0,0,0.6),2.0)
   for g in range(5):
    c.draw_circle(Vector2(lx,120+r.randf_range(0,24)),44-g*6,Color(1.0,0.45,0.2,0.05))
   c.draw_circle(Vector2(lx,120),22,Color("ff7a3d"))
   c.draw_circle(Vector2(lx-5,114),8,Color(1,0.85,0.6,0.7))
  c.draw_rect(Rect2(0,base-6,w,10),Color("3a2430"))
 elif kind=="arcade":
  for k in range(int(w/180.0)):   # neon wall stripes + posters
   var colr=[VIOLET,CYAN,MAGENTA][k%3]
   glow_rect(c,Rect2(60+k*180.0,70,6,260),colr,16,0.3)
   c.draw_rect(Rect2(90+k*180.0,110,70,100),Color("0a0720"))
   gradient(c,Rect2(94+k*180.0,114,62,92),Color(colr,0.65),Color(colr.darkened(0.6),0.6))
  c.draw_rect(Rect2(0,base-6,w,10),Color("2a1a4a"))
 else:
  for k in range(int(w/90.0)):   # alley brick wall with pipes
   for j in range(9):
    c.draw_rect(Rect2(k*90.0+(45 if j%2 else 0),40+j*34,86,30),Color(0.16+r.randf()*0.05,0.1,0.22+r.randf()*0.05,1))
  for k in range(5):
   c.draw_rect(Rect2(120+k*(w-240)/4.0,0,10,base),Color("2b2150"))
  glow_rect(c,Rect2(0,120,w,4),VIOLET,18,0.3)
 # floor sheen strips + baseboard glow
 for k in range(14):
  var fy=base+8+k*k*1.6
  if fy<720:
   c.draw_line(Vector2(0,fy),Vector2(w,fy),Color(0,0,0,0.16),1.0)
 gradient(c,Rect2(0,base,w,18),Color(accent,0.28),Color(accent,0.0))
 gradient(c,Rect2(0,0,w,70),Color(0,0,0,0.5),Color(0,0,0,0.0))
