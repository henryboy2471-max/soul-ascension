extends WorldArt
class_name NeonDistrictArt
# Approved 1242c51 scenery: image-only replacement of Episode 1 procedural layers.
# All coordinates below are logical 1280x720 units. Source PNGs are 1.5x.
const ROOT_PATH = "res://assets/environment/neon_district/"
const SCALE_FACTOR = 1.0 / 1.5
const PLATES = {
 "sky": ["plate_sky.png", 0.0],
 "far": ["plate_far.png", 40.0],
 "mid": ["plate_mid.png", 110.0],
 "near": ["plate_near.png", 60.0],
 "ground": ["plate_street.png", 300.0],
 "foreground": ["plate_foreground.png", 580.0],
}
func _ready() -> void:
 if PLATES.has(kind):
  var info: Array = PLATES[kind]
  var path: String = ROOT_PATH + str(info[0])
  if not ResourceLoader.exists(path):
   push_error("Approved Neon District plate missing: " + path)
   return
  var image_sprite := Sprite2D.new()
  image_sprite.centered = false
  image_sprite.texture = load(path)
  image_sprite.position.y = float(info[1])
  image_sprite.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
  add_child(image_sprite)
  return
 if kind == "props":
  hide_procedural_tram = true
  var tram_path := ROOT_PATH + "prop_tram_stalled.png"
  if ResourceLoader.exists(tram_path):
   var tram := Sprite2D.new()
   tram.centered = false
   tram.texture = load(tram_path)
   tram.scale = Vector2(SCALE_FACTOR, SCALE_FACTOR)
   tram.position = Vector2(635.0, 340.0)
   add_child(tram)
  else:
   push_error("Approved stalled tram missing: " + tram_path)
 super._ready()
func _draw() -> void:
 if PLATES.has(kind):
  return
 super._draw()
