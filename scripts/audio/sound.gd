extends Node
var clips={}
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
func play(kind:String) -> void:
 if not Profile.data.settings.get("sound",true):
  return
 var player=AudioStreamPlayer.new()
 add_child(player)
 player.stream=clips.get(kind,clips.tap)
 player.finished.connect(player.queue_free)
 player.play()
