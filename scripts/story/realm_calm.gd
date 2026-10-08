extends Node2D
class_name RealmCalm
# Episode 2 ending, part 1: the Soul Realm after the Hollow Cantor falls. The violet rain thins to a drift, the last bell-toll rings
# fade away, and Echo stands in the quiet with Mira's lantern signal beside them (her approved sprite, shown as a soft projection).
var art:SoulRealmArt
var hero:Fighter
var mira:Fighter
var toll_t=-1.0
var glow_t=0.0
func _ready() -> void:
 art=SoulRealmArt.new()
 art.theme_id="rain"
 add_child(art)
 art.set_rain(1.6)
 hero=Fighter.new()
 hero.body=Profile.data.body
 hero.load_sprite_set("res://assets/characters/hero/frames.tres",170.0,Color("4aa3ff"))
 hero.position=Vector2(470,392)
 hero.scale=Vector2(1.1,1.1)
 add_child(hero)
 mira=Fighter.new()
 mira.look="mira"
 mira.armed=false
 mira.facing=-1
 mira.load_sprite_set("res://assets/characters/mira/frames.tres",155.0,Color("c27bff"))
 mira.position=Vector2(800,392)
 mira.scale=Vector2(1.2,1.2)
 mira.modulate=Color(1.0,0.95,0.85,0.0)
 add_child(mira)
func start_calm() -> void:
 # the last bell: three toll rings fading out while the rain thins
 toll_t=0.0
 var tween=create_tween()
 tween.tween_method(func(k): art.set_rain(k),1.6,0.3,3.2)
 tween.parallel().tween_property(mira,"modulate:a",0.85,2.6).set_delay(1.4)
func _process(delta:float) -> void:
 glow_t+=delta
 if toll_t>=0.0:
  toll_t+=delta
 hero.facing=1
 queue_redraw()
func _draw() -> void:
 if toll_t>=0.0 and toll_t<3.6:
  for i in range(3):
   var u=clampf((toll_t-i*0.7)/2.2,0.0,1.0)
   if u>0.0 and u<1.0:
    draw_arc(Vector2(800,300),30.0+u*420.0,0,TAU,64,Color(0.9,0.85,1.0,0.5*(1.0-u)),3.0+3.0*(1.0-u))
 # Mira's lantern light: a warm halo behind the projection
 var a=clampf((toll_t-1.4)/2.0,0.0,1.0)*(0.18+0.04*sin(glow_t*2.0))
 draw_circle(Vector2(800,320),120.0,Color(1.0,0.8,0.45,a))
 draw_circle(Vector2(800,320),70.0,Color(1.0,0.9,0.6,a*0.8))
