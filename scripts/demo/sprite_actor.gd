extends Node2D
class_name SpriteActor
# A 4-direction character for the 2.5D stage: front / back / side strips (idle + 4 walk frames), a soft ground shadow and a wet-street reflection.
# Origin = point on the ground between the feet. wx = world x, z = depth (0 back .. 1 front); the stage sets position and scale from them.
signal footstep
const FRAME_W = 144
const FRAME_H = 288
const BASE_SCALE = 0.86
const VIEWS = {"down":"front","up":"back","left":"side","right":"side"}
static var tex_cache:Dictionary = {}
var char_id="echo"
var wx=0.0
var z=0.5
var dir="down"
var moving=false
var anim_t=0.0
var frame=0
var sprite:Sprite2D
var reflect:Sprite2D
var radius=Vector2(15,6)   # footprint half size in (x, z-pixels)
var tint=Color.WHITE
var life=0.0
static func strip(id:String, view:String) -> Texture2D:
 var key=id+"_"+view
 if not tex_cache.has(key):
  var path="res://assets/demo25d/chars/%s_%s.png" % [id,view]
  if ResourceLoader.exists(path):
   # mipmapped copy so the characters stay clean when scaled down with depth
   var src=load(path)
   var img:Image=src.get_image()
   if img.is_compressed():
    img.decompress()
   img.generate_mipmaps()
   tex_cache[key]=ImageTexture.create_from_image(img)
  else:
   tex_cache[key]=null
 return tex_cache[key]
static func portrait(id:String) -> Texture2D:
 var key=id+"_portrait"
 if not tex_cache.has(key):
  var path="res://assets/demo25d/chars/%s_portrait.png" % id
  tex_cache[key]=load(path) if ResourceLoader.exists(path) else null
 return tex_cache[key]
static func portrait_mip(id:String) -> Texture2D:
 var key=id+"_portrait_mip"
 if not tex_cache.has(key):
  var base=portrait(id)
  if base==null:
   tex_cache[key]=null
  else:
   var img:Image=base.get_image()
   if img.is_compressed():
    img.decompress()
   img.generate_mipmaps()
   tex_cache[key]=ImageTexture.create_from_image(img)
 return tex_cache[key]
func setup(id:String) -> SpriteActor:
 char_id=id
 sprite=Sprite2D.new()
 sprite.hframes=5
 sprite.offset=Vector2(0,-132)
 sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 reflect=Sprite2D.new()
 reflect.hframes=5
 reflect.offset=Vector2(0,-132)
 reflect.scale=Vector2(1,-0.55)
 reflect.modulate=Color(0.55,0.5,1.0,0.2)
 reflect.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 add_child(reflect)
 add_child(sprite)
 set_dir("down")
 return self
func set_dir(d:String) -> void:
 dir=d
 var t=strip(char_id,VIEWS[d])
 sprite.texture=t
 reflect.texture=t
 sprite.flip_h=d=="left"
 reflect.flip_h=d=="left"
func _draw() -> void:
 # soft contact shadow
 draw_set_transform(Vector2.ZERO,0,Vector2(1,0.28))
 for i in range(4):
  draw_circle(Vector2.ZERO,34-i*6,Color(0,0,0,0.10))
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
# advance the walk cycle; emits `footstep` on the two contact frames
func animate(delta:float, is_moving:bool, rate:float=1.0) -> void:
 life+=delta
 moving=is_moving
 var f=0
 if is_moving:
  anim_t+=delta*8.0*rate
  f=1+int(anim_t)%4
 else:
  anim_t=0.0
 if f!=frame:
  frame=f
  if f==2 or f==4:
   footstep.emit()
 sprite.frame=frame
 reflect.frame=frame
 sprite.position.y=0.0 if is_moving else sin(life*2.2)*0.6
func face_toward(px:float, pz:float) -> void:
 var dx=px-wx
 var dz=(pz-z)*264.0
 if absf(dx)>absf(dz)*1.4:
  set_dir("right" if dx>0 else "left")
 else:
  set_dir("down" if dz>0 else "up")
func set_tint(c:Color) -> void:
 tint=c
 sprite.modulate=c
