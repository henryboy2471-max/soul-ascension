extends SceneTree
# Mira sprite art (assets/characters/mira): frame integrity, foot anchoring, district NPC, portrait, scale vs the Hero.
var passed=0
var failed=0
var main
var profile
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(90.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func skip_scenes(ep:Node, until_call:Callable, max_frames:int=900) -> bool:
 var frames=0
 while frames<max_frames:
  if until_call.call():
   return true
  if is_instance_valid(ep):
   for c in ep.get_children():
    if c.has_method("finish_all"):
     c.finish_all()
    elif c.has_method("finish"):
     c.finish()
  await process_frame
  frames+=1
 return until_call.call()
# Returns [top_row, bottom_row_exclusive] of pixels with alpha above the threshold (solid figure, ignores faint glow).
func solid_extent(tex:Texture2D, threshold:float=0.6) -> Vector2i:
 var img=tex.get_image()
 var top=-1
 var bottom=-1
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>threshold:
    if top<0: top=y
    bottom=y+1
    break
 return Vector2i(top,bottom)
func median(values:Array) -> float:
 var v=values.duplicate()
 v.sort()
 return float(v[v.size()/2])
func displayed_height(f) -> float:
 var heights=[]
 for i in range(f.sprite_frames.get_frame_count("idle")):
  var e=solid_extent(f.sprite_frames.get_frame_texture("idle",i))
  heights.append(e.y-e.x)
 return median(heights)*f.sprite.scale.y*f.scale.y
func run() -> void:
 profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 var fighter_script=load("res://scripts/combat/fighter.gd")
 var probe=fighter_script.new()
 check(probe.load_sprite_set("res://assets/characters/mira/frames.tres"),"Mira frames.tres loads")
 var frames=probe.sprite_frames
 check(frames.get_frame_count("idle")==16 and frames.get_frame_count("run")==15 and frames.get_frame_count("dash")==6,"Imported animations have the expected frame counts")
 var leaked=false
 for flagged in ["walk","jump","land","hurt","defeat","attack1","attack2","attack3","skill","finisher"]:
  if frames.has_animation(flagged) and frames.get_frame_count(flagged)>0:
   leaked=true
 check(not leaked,"Flagged animations are not exported (flagged, not invented)")
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/mira/manifest.json"))
 var ground=int(manifest.ground_row)
 var size=frames.get_frame_texture("idle",0).get_size()
 var same_size=true
 var anchored=true
 for anim in ["idle","run","dash"]:
  for i in range(frames.get_frame_count(anim)):
   var tex=frames.get_frame_texture(anim,i)
   if tex.get_size()!=size: same_size=false
   if absi(solid_extent(tex).y-ground)>1: anchored=false
 check(same_size,"Every Mira frame shares one canvas size")
 check(anchored,"All idle, run and dash frames stand on the same ground row (no foot jitter)")
 check(probe.resolve_animation("walk")=="run" and probe.resolve_animation("attack1")=="idle" and probe.resolve_animation("hurt")=="idle" and probe.resolve_animation("defeat")=="idle","Missing animations fall back to run/idle")
 # --- district NPC ---
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_episode()
 await process_frame
 var ep=main.screen.get_child(0)
 await skip_scenes(ep,func(): return ep.explore!=null)
 var ex=ep.explore
 var npc=ex.npc
 var hero=ex.player
 check(npc.sprite!=null,"District Mira uses the sprite art")
 await process_frame
 check(npc.current_anim=="idle","Mira idles in the district")
 ex.px=100.0
 await create_timer(0.2).timeout
 var left_flip=npc.sprite.flip_h
 ex.px=900.0
 await create_timer(0.2).timeout
 check(left_flip and not npc.sprite.flip_h,"Mira turns to face the Hero")
 # --- scale next to the Hero ---
 var hero_h=displayed_height(hero)
 var mira_h=displayed_height(npc)
 var ratio=mira_h/hero_h
 print("INFO: displayed standing height in the district  hero=%.1f px  mira=%.1f px  ratio=%.3f" % [hero_h,mira_h,ratio])
 check(ratio>=0.90 and ratio<=1.0,"Mira stands 0-10% shorter than the Hero in the district")
 check(absf(hero_h-mira_h)<=20.0,"Neither character is noticeably larger (within 20 px)")
 # --- dialogue portrait ---
 ex.px=540.0
 await create_timer(0.55).timeout
 ex.act_edge=true
 await process_frame
 await process_frame
 var box=null
 for c in ep.get_children():
  if c.has_method("finish_all"):
   box=c
 check(box!=null,"Talking to Mira opens the dialogue")
 var portrait_ok=false
 if box!=null:
  await create_timer(0.2).timeout
  for c in box.portrait_frame.get_children():
   if c.has_method("attach_frames") and c.sprite!=null and c.look=="mira":
    portrait_ok=true
 check(portrait_ok,"Mira's dialogue portrait shows the sprite art")
 await skip_scenes(ep,func(): return not ep.busy)
 check(ep.step==1 and profile.data.codex.has("mira"),"The conversation still advances the objective and unlocks the Codex")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
