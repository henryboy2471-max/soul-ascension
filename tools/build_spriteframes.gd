extends SceneTree
# Builds <dir>/frames.tres (SpriteFrames) from <dir>/manifest.json and <dir>/frames/*.png.
# Run after `godot --headless --editor --import --quit`:
#   godot --headless --path . --script res://tools/build_spriteframes.gd -- res://assets/characters/hero
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.is_empty():
  push_error("usage: -- res://assets/characters/<name>")
  quit(2)
  return
 var dir=args[0].trim_suffix("/")
 var parser=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(dir+"/manifest.json"))!=OK:
  push_error("cannot read manifest.json in "+dir)
  quit(2)
  return
 var manifest=parser.data
 var frames=SpriteFrames.new()
 frames.remove_animation("default")
 var built=[]
 for anim in manifest.animations:
  var entry=manifest.animations[anim]
  if entry.get("flagged",false) or not entry.has("frames_out") or entry.frames_out.is_empty():
   print("SKIP (flagged or empty): "+anim)
   continue
  frames.add_animation(anim)
  frames.set_animation_speed(anim,float(entry.fps))
  frames.set_animation_loop(anim,bool(entry.loop))
  for file in entry.frames_out:
   var texture=load(dir+"/frames/"+file)
   if texture==null:
    push_error("missing imported texture "+file+" (run the project import first)")
    quit(2)
    return
   frames.add_frame(anim,texture)
  built.append(anim)
 var err=ResourceSaver.save(frames,dir+"/frames.tres")
 print("BUILT "+dir+"/frames.tres animations="+str(built)+" result="+str(err))
 quit(0 if err==OK else 1)
