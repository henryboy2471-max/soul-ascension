extends Node
var clips={}
var loops={}
var loop_player:AudioStreamPlayer
var loop_kind=""
const STEP_SURFACES = ["wet","wood","metal"]
var step_clips:Dictionary={}
var step_pool:Array=[]
var step_last:Dictionary={}
func _ready() -> void:
 for kind in ["tap","hit","special","win","hurt"]:
  var stream=AudioStreamWAV.new()
  stream.format=AudioStreamWAV.FORMAT_16_BITS
  stream.mix_rate=22050
  var duration=0.10 if kind=="tap" else 0.24
  var samples=PackedByteArray()
  samples.resize(int(22050*duration)*2)
  var freq={"tap":660.0,"hit":160.0,"special":440.0,"win":880.0,"hurt":90.0}[kind]
  for i in range(samples.size()/2):
   var t=float(i)/22050.0
   var envelope=pow(1.0-t/duration,2.0)
   var wave=sin(TAU*(freq*t+180.0*t*t))*0.18*envelope
   samples.encode_s16(i*2,int(wave*32767.0))
  stream.data=samples
  clips[kind]=stream
 clips["step"]=make_step()
 for surface in STEP_SURFACES:
  step_clips[surface]=[]
  for v in range(5):
   step_clips[surface].append(make_footstep(surface,v))
 for i in range(4):
  var sp=AudioStreamPlayer.new()
  sp.volume_db=-7.0
  add_child(sp)
  step_pool.append(sp)
 loops["city"]=make_loop(false)
 loops["realm"]=make_loop(true)
 loop_player=AudioStreamPlayer.new()
 loop_player.volume_db=-9.0
 add_child(loop_player)
func play(kind:String) -> void:
 if not Profile.data.settings.get("sound",true):
  return
 if kind=="step":
  footstep("wet")
  return
 var player=AudioStreamPlayer.new()
 add_child(player)
 player.stream=clips.get(kind,clips.tap)
 player.finished.connect(player.queue_free)
 player.play()
func make_step() -> AudioStreamWAV:
 var stream=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=22050
 var count=int(22050*0.07)
 var samples=PackedByteArray()
 samples.resize(count*2)
 var rng=RandomNumberGenerator.new()
 rng.seed=3
 var low=0.0
 for i in range(count):
  low=low*0.8+rng.randf_range(-1.0,1.0)*0.2
  var envelope=pow(1.0-float(i)/count,3.0)
  samples.encode_s16(i*2,int(low*0.5*envelope*32767.0))
 stream.data=samples
 return stream
# Seamless 4 second ambience: rain hiss plus a low hum for the city, a slow shimmering drone for the Soul Realm.
func make_loop(realm:bool) -> AudioStreamWAV:
 var rate=22050
 var n=rate*4
 var fade=rate/10
 var rng=RandomNumberGenerator.new()
 rng.seed=21 if realm else 17
 var raw=PackedFloat32Array()
 raw.resize(n+fade)
 var low=0.0
 for i in range(n+fade):
  low=low*0.55+rng.randf_range(-1.0,1.0)*0.45
  raw[i]=low
 var stream=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=rate
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_begin=0
 stream.loop_end=n
 var samples=PackedByteArray()
 samples.resize(n*2)
 for i in range(n):
  var noise=raw[i]
  if i<fade:
   var t=float(i)/fade
   noise=raw[i]*t+raw[n+i]*(1.0-t)
  var t_sec=float(i)/rate
  var tone=0.0
  if realm:
   var lfo=0.6+0.4*sin(TAU*0.25*t_sec)
   tone=(sin(TAU*110.0*t_sec)*0.5+sin(TAU*164.0*t_sec)*0.3+sin(TAU*440.0*t_sec)*0.05*lfo)*0.5*lfo
   noise*=0.05
  else:
   tone=(sin(TAU*55.0*t_sec)*0.6+sin(TAU*82.5*t_sec)*0.3)*(0.7+0.3*sin(TAU*0.5*t_sec))*0.5
   noise*=0.22
  samples.encode_s16(i*2,int(clampf((noise+tone)*0.35,-1.0,1.0)*32767.0))
 stream.data=samples
 return stream
func loop(kind:String) -> void:
 if not Profile.data.settings.get("sound",true):
  stop_loop()
  return
 if loop_kind==kind and loop_player.playing:
  return
 loop_kind=kind
 loop_player.stream=loops.get(kind)
 loop_player.play()
func stop_loop() -> void:
 loop_kind=""
 if is_instance_valid(loop_player):
  loop_player.stop()

# Footsteps: a heel thump (low-passed noise + a short body resonance) and a softer toe tap ~70 ms later, with a surface layer (wet-street splash,
# wood knock or metal clink). Five variants per surface, picked at random without immediate repeats, with slight pitch/volume jitter.
func make_footstep(surface:String, variant:int) -> AudioStreamWAV:
 var rate=22050
 var n=int(rate*0.26)
 var rng=RandomNumberGenerator.new()
 rng.seed=100+variant*7+STEP_SURFACES.find(surface)*31
 var buf=PackedFloat32Array()
 buf.resize(n)
 var f_body={"wet":110.0,"wood":170.0,"metal":240.0}[surface]*rng.randf_range(0.9,1.12)
 var toe_at=int(rate*rng.randf_range(0.055,0.085))
 for contact in range(2):
  var start=0 if contact==0 else toe_at
  var amp=1.0 if contact==0 else rng.randf_range(0.35,0.5)
  var low=0.0
  var hp_prev=0.0
  var lp_prev=0.0
  for i in range(n-start):
   var t=float(i)/rate
   var noise=rng.randf_range(-1.0,1.0)
   low=low*0.86+noise*0.14
   var env_thump=exp(-t*52.0)
   var s_i=low*env_thump*0.9+sin(TAU*f_body*t)*exp(-t*38.0)*0.5
   match surface:
    "wet":
     # splash/scuff: high-passed noise with a quick attack and a longer tail
     var hp=noise-hp_prev
     hp_prev=noise*0.6+hp_prev*0.4
     lp_prev=lp_prev*0.55+hp*0.45
     s_i+=lp_prev*minf(1.0,t*320.0)*exp(-t*16.0)*0.55
    "wood":
     s_i+=sin(TAU*f_body*2.4*t)*exp(-t*55.0)*0.28+sin(TAU*f_body*3.7*t)*exp(-t*70.0)*0.16
    "metal":
     s_i+=(sin(TAU*f_body*3.1*t)*0.3+sin(TAU*f_body*5.3*t)*0.18)*exp(-t*30.0)
   buf[start+i]+=s_i*amp*(minf(1.0,t*900.0))
 var stream=AudioStreamWAV.new()
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.mix_rate=rate
 var bytes=PackedByteArray()
 bytes.resize(n*2)
 for i in range(n):
  bytes.encode_s16(i*2,int(clampf(buf[i]*0.42,-1.0,1.0)*32767.0))
 stream.data=bytes
 return stream
func footstep(surface:String="wet", loudness:float=1.0) -> void:
 if not Profile.data.settings.get("sound",true) or step_pool.is_empty() or not step_clips.has(surface):
  return
 var list:Array=step_clips[surface]
 var pick=randi()%list.size()
 if pick==step_last.get(surface,-1):
  pick=(pick+1+randi()%(list.size()-1))%list.size()
 step_last[surface]=pick
 var player:AudioStreamPlayer=null
 for sp in step_pool:
  if not sp.playing:
   player=sp
   break
 if player==null:
  player=step_pool[0]
 player.stream=list[pick]
 player.pitch_scale=randf_range(0.93,1.07)
 player.volume_db=-9.0+linear_to_db(clampf(loudness,0.05,1.5))+randf_range(-1.5,1.0)
 player.play()
