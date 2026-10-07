extends Node
var clips={}
var loops={}
var loop_player:AudioStreamPlayer
var loop_kind=""
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
 loops["city"]=make_loop(false)
 loops["realm"]=make_loop(true)
 loop_player=AudioStreamPlayer.new()
 loop_player.volume_db=-9.0
 add_child(loop_player)
func play(kind:String) -> void:
 if not Profile.data.settings.get("sound",true):
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
