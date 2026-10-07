extends Node2D
var particles:Array=[]
var slashes:Array=[]
var ring=0.0
var origin=Vector2.ZERO
func burst(point:Vector2, ultimate:bool=false) -> void:
 origin=point
 if ultimate: ring=0.8
 var tilt=randf_range(-0.9,0.9)
 slashes.append({"p":point,"life":0.2,"a":tilt,"big":ultimate})
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
 for s in slashes:
  s.life-=delta
 slashes=slashes.filter(func(s):return s.life>0)
 queue_redraw()
func _draw() -> void:
 for s in slashes:
  var t=s.life/0.2
  var dir=Vector2.from_angle(s.a-0.6)
  var length=(150.0 if s.big else 90.0)*(1.2-t*0.5)
  draw_line(s.p-dir*length,s.p+dir*length,Color(0.8,0.7,1.0,t*0.35),14*t+2)
  draw_line(s.p-dir*length*0.8,s.p+dir*length*0.8,Color(1,1,1,t),3)
 for p in particles:
  draw_line(p.p,p.p-p.v.normalized()*9,Color(0.83,0.67,1,minf(1,p.life*3)),3)
 if ring>0:
  for i in range(3):
   draw_arc(origin,(0.8-ring)*650+i*20,0,TAU,80,Color(0.85,0.72,1,ring*0.8),8-i*2)
