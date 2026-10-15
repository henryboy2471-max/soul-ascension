extends Node2D
class_name Stage25
# 2.5D stage (one "set" of the demo: the street or an interior). A 2D scene with real depth cues:
#  - walkable plane = world x (px) + depth z (0 back .. 1 front); screen y and character scale are functions of z (perspective)
#  - everything on the plane lives in one y-sorted container; props that hide the player fade out (foreground occlusion)
#  - parallax layers (sky, skyline, facade, ground, foreground) + a camera that follows, looks ahead, shifts and zooms with depth
#  - static art is baked once into textures; only a few sprites move each frame
signal footstep(surface)
const DEPTH = 264.0
const Y_BACK = 392.0
const Y_FRONT = 656.0
const S_BACK = 0.74
const S_FRONT = 1.0
const WALK_SPEED = Vector2(235.0,150.0)   # px/s along x and along depth (in z-pixels)
const FOOT = Vector2(14.0,6.0)
const CHUNK = 1600
var world_w=4800.0
var interior=""
var surface="wet"
var cam_c=Vector2(640,360)
var zoom=1.0
var focus=Vector2.ZERO
var focus_w=0.0
var focus_zoom=1.0
var cam_lock=false
var far_layer:Node2D
var cam_root:Node2D
var ysort:Node2D
var glow_layer:Node2D
var ripples:Node2D
var fore_layer:Node2D
var rain:CanvasLayer
var player:SpriteActor
var actors:Array=[]
var peds:Array=[]
var props:Array=[]
var vehicles:Array=[]
var spots:Array=[]
var glows:Array=[]
var vel=Vector2.ZERO
var look=0.0
var time=0.0
var reduced_motion=false
var splash_list:Array=[]
var bake_count=0
class Painter extends Node2D:
 var fn:Callable
 func _draw() -> void:
  fn.call(self)
class RippleLayer extends Node2D:
 var stage
 func _process(_d:float) -> void:
  queue_redraw()
 func _draw() -> void:
  stage.draw_ripples(self)
static func y_of(z:float) -> float:
 return lerpf(Y_BACK,Y_FRONT,z)
static func s_of(z:float) -> float:
 return lerpf(S_BACK,S_FRONT,z)
# ------------------------------------------------------------------ building the set
func build(kind:String, width:float) -> void:
 interior="" if kind=="street" else kind
 world_w=width
 surface="wet" if kind=="street" else ("metal" if kind=="hidden_alley" else "wood")
 y_sort_enabled=false
 far_layer=Node2D.new()
 add_child(far_layer)
 cam_root=Node2D.new()
 add_child(cam_root)
 var mat=CanvasItemMaterial.new()
 mat.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
 if kind=="street":
  var sky=bake(Vector2i(1280,720),func(c): NeonArt.sky(c,1280.0,720.0),Vector2.ZERO,false,self)
  move_child(sky,0)
  var fw=int(1280.0+(world_w-1280.0)*0.22+260.0)
  var far=bake(Vector2i(fw,400),func(c): NeonArt.far(c,float(fw),400.0),Vector2(-130,0),true,far_layer)
  far.position.x=-130
  var x0=0
  while x0<int(world_w):
   var x1=mini(x0+CHUNK,int(world_w))
   var a=float(x0)
   var b=float(x1)
   bake(Vector2i(x1-x0,392-32),func(c): NeonArt.facade(c,a,b),Vector2(a,32),true,cam_root)
   bake(Vector2i(x1-x0,720-392),func(c): NeonArt.ground(c,a,b),Vector2(a,392),true,cam_root)
   x0=x1
 else:
  var w=width
  bake(Vector2i(int(w),720),func(c): NeonArt.interior(c,w,kind),Vector2.ZERO,false,cam_root)
 ysort=Node2D.new()
 ysort.y_sort_enabled=true
 cam_root.add_child(ysort)
 glow_layer=Node2D.new()
 glow_layer.material=mat
 glow_layer.z_index=20
 cam_root.add_child(glow_layer)
 ripples=RippleLayer.new()
 ripples.stage=self
 ripples.z_index=2
 cam_root.add_child(ripples)
 fore_layer=Node2D.new()
 fore_layer.z_index=30
 add_child(fore_layer)
 if kind=="street":
  add_rain()
  add_fore_bokeh()
func bake(size:Vector2i, fn:Callable, at:Vector2, transparent:bool, parent:Node) -> Sprite2D:
 # Static art is drawn once into a texture; afterwards it is a single sprite (one draw call per chunk).
 var vp=SubViewport.new()
 vp.size=size
 vp.transparent_bg=transparent
 vp.disable_3d=true
 vp.render_target_update_mode=SubViewport.UPDATE_ONCE
 var painter=Painter.new()
 painter.fn=fn
 painter.position=-at
 vp.add_child(painter)
 parent.add_child(vp)
 var sp=Sprite2D.new()
 sp.centered=false
 sp.position=at
 sp.texture=vp.get_texture()
 parent.add_child(sp)
 bake_count+=1
 return sp
func add_rain() -> void:
 rain=CanvasLayer.new()
 rain.layer=4
 add_child(rain)
 var img=Image.create(3,34,false,Image.FORMAT_RGBA8)
 for y in range(34):
  var a=sin(PI*float(y)/33.0)
  for x in range(3):
   img.set_pixel(x,y,Color(0.75,0.82,1.0,a*(0.9 if x==1 else 0.35)))
 var tex=ImageTexture.create_from_image(img)
 for layer in [{"n":110,"v":780.0,"s":0.7,"a":0.30,"life":1.1},{"n":46,"v":1250.0,"s":1.25,"a":0.5,"life":0.75}]:
  var p=CPUParticles2D.new()
  p.texture=tex
  p.amount=layer.n
  p.lifetime=layer.life
  p.preprocess=layer.life
  p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE
  p.emission_rect_extents=Vector2(820,6)
  p.position=Vector2(640,-30)
  p.direction=Vector2(-0.16,1.0)
  p.spread=2.0
  p.gravity=Vector2.ZERO
  p.initial_velocity_min=layer.v*0.92
  p.initial_velocity_max=layer.v*1.08
  p.scale_amount_min=layer.s
  p.scale_amount_max=layer.s*1.15
  p.color=Color(1,1,1,layer.a)
  p.rotation=0.16
  p.local_coords=true
  p.fixed_fps=0
  rain.add_child(p)
func add_fore_bokeh() -> void:
 # out-of-focus foreground shapes (parallax 1.4) for depth: a dark pole and soft neon bokeh in front of everything
 var r=NeonArt.rng_for(5)
 var lay=Node2D.new()
 lay.name="bokeh"
 fore_layer.add_child(lay)
 var painter=Painter.new()
 painter.fn=func(c):
  for i in range(14):
   var x=r.randf_range(0,world_w*1.2)
   var col=[NeonArt.VIOLET,NeonArt.CYAN,NeonArt.MAGENTA,NeonArt.GOLD][r.randi()%4]
   c.draw_circle(Vector2(x,r.randf_range(560,700)),r.randf_range(14,34),Color(col,0.10))
 lay.add_child(painter)
# ------------------------------------------------------------------ content helpers
func glow_tex() -> Texture2D:
 if not has_meta("glow_tex"):
  var g=GradientTexture2D.new()
  var grad=Gradient.new()
  grad.set_color(0,Color(1,1,1,1))
  grad.set_color(1,Color(1,1,1,0))
  g.gradient=grad
  g.fill=GradientTexture2D.FILL_RADIAL
  g.fill_from=Vector2(0.5,0.5)
  g.fill_to=Vector2(1.0,0.5)
  g.width=128
  g.height=128
  set_meta("glow_tex",g)
 return get_meta("glow_tex")
func add_glow(pos:Vector2, radius:float, col:Color, alpha:float, flicker:float=0.0, squash:float=1.0) -> void:
 var s=Sprite2D.new()
 s.texture=glow_tex()
 s.position=pos
 s.scale=Vector2(radius/64.0,radius/64.0*squash)
 s.modulate=Color(col,alpha)
 glow_layer.add_child(s)
 glows.append({"node":s,"a":alpha,"flick":flicker,"ph":randf()*10.0})
func add_actor(id:String, wx:float, z:float, d:String="down") -> SpriteActor:
 var a=SpriteActor.new()
 a.setup(id)
 a.wx=wx
 a.z=z
 a.set_dir(d)
 ysort.add_child(a)
 actors.append(a)
 place(a)
 return a
func add_prop(kind:String, wx:float, z:float, half:Vector2=Vector2.ZERO, col:Color=Color("35e6ff")) -> Prop25:
 var p=Prop25.new()
 p.kind=kind
 p.wx=wx
 p.z=z
 p.half=half
 p.col=col
 p.animated=kind in ["stall","sign_tower","kiosk","cabinet","terminal","junction","hidden_door"]
 ysort.add_child(p)
 props.append(p)
 place(p)
 return p
func add_vehicle(lane:float, d:int, col:Color, kind:int, x:float) -> Vehicle25:
 var v=Vehicle25.new()
 v.setup(lane,d,col,kind)
 v.wx=x
 ysort.add_child(v)
 vehicles.append(v)
 place(v)
 return v
func add_spot(id:String, wx:float, z:float, label:String, rx:float=70.0, rz:float=40.0, hold:float=0.0) -> Dictionary:
 var s={"id":id,"wx":wx,"z":z,"label":label,"rx":rx,"rz":rz,"hold":hold,"enabled":true}
 spots.append(s)
 return s
func spot(id:String) -> Dictionary:
 for s in spots:
  if s.id==id:
   return s
 return {}
func set_player(id:String, wx:float, z:float) -> SpriteActor:
 player=add_actor(id,wx,z,"right")
 player.radius=FOOT
 return player
func add_ped(id:String, wx:float, z:float, range_x:Vector2, speed:float, mode:String="x", range_z:Vector2=Vector2.ZERO) -> SpriteActor:
 var a=add_actor(id,wx,z,"right")
 a.set_meta("ped",{"min":range_x.x,"max":range_x.y,"speed":speed,"dir":1.0 if randf()<0.5 else -1.0,"pause":randf()*2.0,"mode":mode,"zmin":range_z.x,"zmax":range_z.y})
 peds.append(a)
 return a
func place(n:Node2D) -> void:
 var zz=n.z
 n.position=Vector2(n.wx,y_of(zz))
 var k=s_of(zz)
 if n is SpriteActor:
  k*=SpriteActor.BASE_SCALE*(1.0 if n.char_id!="zuri" else 1.0)
 n.scale=Vector2(k,k)
# ------------------------------------------------------------------ collisions (world x, depth in z-pixels)
func rect_of(n) -> Rect2:
 var h=n.half if n is Prop25 or n is Vehicle25 else n.radius
 return Rect2(n.wx-h.x,n.z*DEPTH-h.y,h.x*2.0,h.y*2.0)
func blocked(wx:float, z:float, ignore=null, half:Vector2=FOOT) -> bool:
 if wx<half.x+10.0 or wx>world_w-half.x-10.0 or z<0.02 or z>0.985:
  return true
 var r=Rect2(wx-half.x,z*DEPTH-half.y,half.x*2.0,half.y*2.0)
 for p in props:
  if p.half!=Vector2.ZERO and p!=ignore and rect_of(p).intersects(r):
   return true
 for v in vehicles:
  if v!=ignore and rect_of(v).intersects(r):
   return true
 for a in actors:
  if a!=ignore and rect_of(a).intersects(r):
   return true
 return false
func move_actor(a:SpriteActor, delta_px:Vector2) -> bool:
 # axis-separated movement so the actor slides along walls and props
 var moved=false
 var nx=a.wx+delta_px.x
 if not blocked(nx,a.z,a,a.radius):
  a.wx=nx
  moved=true
 var nz=a.z+delta_px.y/DEPTH
 if not blocked(a.wx,nz,a,a.radius):
  a.z=nz
  moved=true
 return moved
# ------------------------------------------------------------------ per frame
func tick(delta:float, move:Vector2, locked:bool) -> void:
 time+=delta
 # --- player
 if player:
  var target=Vector2.ZERO if locked else Vector2(move.x*WALK_SPEED.x,move.y*WALK_SPEED.y)
  vel=vel.move_toward(target,1500.0*delta if target!=Vector2.ZERO else 1900.0*delta)
  var before=Vector2(player.wx,player.z)
  if vel.length()>1.0:
   move_actor(player,vel*delta)
  var actual=Vector2(player.wx,player.z)-before
  var moving=vel.length()>26.0 and actual.length()>0.0
  if moving and not locked:
   var m=target if target!=Vector2.ZERO else vel
   var nd=("right" if m.x>0 else "left") if absf(m.x)*1.0>=absf(m.y)*1.35 else ("down" if m.y>0 else "up")
   if nd!=player.dir:
    player.set_dir(nd)
  player.animate(delta,moving,clampf(vel.length()/WALK_SPEED.x,0.6,1.1))
  place(player)
  if absf(vel.x)>30.0:
   look=lerpf(look,signf(vel.x)*80.0,1.0-exp(-delta*2.2))
 # --- NPCs
 for a in actors:
  if a==player:
   continue
  if a.has_meta("ped"):
   tick_ped(a,delta)
  else:
   a.animate(delta,false)
  place(a)
 # --- vehicles
 for v in vehicles:
  tick_vehicle(v,delta)
 # --- props that hide the player fade out
 for p in props:
  if p.occluder:
   var hide=player!=null and player.z<p.z-0.01 and absf(player.wx-p.wx)<p.half.x+60.0
   p.modulate.a=lerpf(p.modulate.a,0.3 if hide else 1.0,1.0-exp(-delta*9.0))
  place(p)
 # --- lights
 for g in glows:
  if g.flick>0.0:
   var f=sin(time*17.0+g.ph)*sin(time*5.3+g.ph*1.7)
   var k=1.0-g.flick*(1.0 if f<-0.45 else 0.0)-g.flick*0.12*f
   g.node.modulate.a=g.a*maxf(k,0.08)
 for i in range(splash_list.size()-1,-1,-1):
  splash_list[i].t+=delta
  if splash_list[i].t>0.7:
   splash_list.remove_at(i)
 update_camera(delta)
func tick_ped(a:SpriteActor, delta:float) -> void:
 var d=a.get_meta("ped")
 if d.pause>0.0:
  d.pause-=delta
  a.animate(delta,false)
  return
 var step=d.speed*delta*d.dir
 var moved=false
 if d.mode=="x":
  var before=a.wx
  moved=move_actor(a,Vector2(step,0))
  if not moved or a.wx<d.min or a.wx>d.max:
   d.dir=-d.dir
   d.pause=randf_range(0.6,2.4)
   a.set_dir("right" if d.dir>0 else "left")
  else:
   a.set_dir("right" if d.dir>0 else "left")
 else:
  moved=move_actor(a,Vector2(0,step))
  if not moved or a.z<d.zmin or a.z>d.zmax:
   d.dir=-d.dir
   d.pause=randf_range(1.0,3.0)
  a.set_dir("down" if d.dir>0 else "up")
 a.animate(delta,moved,0.8)
func tick_vehicle(v:Vehicle25, delta:float) -> void:
 # yield to anyone standing in the lane ahead (crosswalk behaviour), then drive on and wrap around the street
 var want=v.top_speed
 var look=70.0+v.speed*v.speed/420.0   # braking distance at 260 px/s^2 plus a margin
 var ahead=Rect2(v.wx+(95.0 if v.dir>0 else -95.0-look),v.z*DEPTH-26.0,look,52.0)
 for a in actors:
  if ahead.intersects(rect_of(a)):
   want=0.0
   break
 v.speed=move_toward(v.speed,want,260.0*delta)
 v.wx+=v.dir*v.speed*delta
 if v.dir>0 and v.wx>world_w+260.0:
  v.wx=-260.0
 elif v.dir<0 and v.wx<-260.0:
  v.wx=world_w+260.0
 v.scale=Vector2(v.dir*s_of(v.z),s_of(v.z))
 v.position=Vector2(v.wx,y_of(v.z))
func update_camera(delta:float) -> void:
 if player==null or cam_lock:
  apply_camera()
  return
 var tx=player.wx+look
 var ty=360.0+(0.5-player.z)*34.0
 var tz=lerpf(1.0,1.045,player.z)
 if focus_w>0.0:
  tx=lerpf(tx,focus.x,focus_w)
  ty=lerpf(ty,focus.y,focus_w)
  tz=lerpf(tz,focus_zoom,focus_w)
 var k=1.0-exp(-delta*4.5)
 cam_c.x=lerpf(cam_c.x,tx,k)
 cam_c.y=lerpf(cam_c.y,ty,k)
 zoom=lerpf(zoom,tz,k)
 apply_camera()
func apply_camera() -> void:
 var half=640.0/zoom
 cam_c.x=clampf(cam_c.x,half,maxf(half,world_w-half))
 cam_root.scale=Vector2(zoom,zoom)
 cam_root.position=Vector2(640,360)-cam_c*zoom
 if far_layer:
  far_layer.position=Vector2(-(cam_c.x-640.0)*0.22,-(cam_c.y-360.0)*0.1)
 if fore_layer:
  fore_layer.position=Vector2(-(cam_c.x-640.0)*1.4,-(cam_c.y-360.0)*0.4)
func snap_camera() -> void:
 if player:
  cam_c=Vector2(player.wx,360.0+(0.5-player.z)*34.0)
  zoom=lerpf(1.0,1.045,player.z)
  apply_camera()
# ------------------------------------------------------------------ interaction
func nearest_spot() -> Dictionary:
 var best={}
 var bd=1e9
 if player==null:
  return best
 for s in spots:
  if not s.enabled:
   continue
  var dx=absf(player.wx-s.wx)
  var dz=absf(player.z-s.z)*DEPTH
  if dx<=s.rx and dz<=s.rz:
   var d=dx+dz*0.8
   if d<bd:
    bd=d
    best=s
 return best
# ------------------------------------------------------------------ wet-street ripples (drawn each frame; small count)
func add_splash(wx:float, z:float) -> void:
 if surface=="wet":
  splash_list.append({"x":wx,"y":y_of(z),"t":0.0,"k":s_of(z)})
func draw_ripples(c:CanvasItem) -> void:
 if surface!="wet" or reduced_motion:
  return
 var left=cam_c.x-700.0
 var r=NeonArt.rng_for(9)
 for i in range(14):
  var rx=left+fmod(r.randf()*1400.0+i*53.0,1400.0)
  var ry=lerpf(NeonArt.Y_BACK+30.0,NeonArt.Y_FRONT,r.randf())
  var ph=fmod(time*0.9+r.randf()*3.0,1.0)
  var k=s_of((ry-Y_BACK)/DEPTH)
  c.draw_set_transform(Vector2(rx,ry),0,Vector2(1,0.28))
  c.draw_arc(Vector2.ZERO,(4.0+ph*20.0)*k,0,TAU,16,Color(0.8,0.85,1.0,0.22*(1.0-ph)),1.2)
 for s in splash_list:
  var ph=s.t/0.7
  c.draw_set_transform(Vector2(s.x,s.y),0,Vector2(1,0.3))
  c.draw_arc(Vector2.ZERO,(6.0+ph*30.0)*s.k,0,TAU,18,Color(0.85,0.9,1.0,0.5*(1.0-ph)),1.6)
 c.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
