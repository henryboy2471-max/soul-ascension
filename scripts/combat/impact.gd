extends Node2D
var particles:Array=[]
var ring=0.0
var origin=Vector2.ZERO
func burst(point:Vector2, ultimate:bool=false) -> void:
 origin=point
 if ultimate: ring=0.8
 for i in range(36 if ultimate else 14):
  var angle=randf()*TAU
  particles.append({"p":point,"v":Vector2.from_angle(angle)*randf_range(90,330),"life":randf_range(0.2,0.6)})
func _process(delta:float) -> void:
 ring=maxf(0,ring-delta)
 for p in particles:
  p.p+=p.v*delta
  p.v.y+=delta*170
  p.life-=delta
 particles=particles.filter(func(p):return p.life>0)
 queue_redraw()
func _draw() -> void:
 for p in particles:
  draw_line(p.p,p.p-p.v.normalized()*9,Color(0.83,0.67,1,minf(1,p.life*3)),3)
 if ring>0:
  for i in range(3):
   draw_arc(origin,(0.8-ring)*650+i*20,0,TAU,80,Color(0.85,0.72,1,ring*0.8),8-i*2)
