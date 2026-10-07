extends SceneTree
# Hero sprite art (assets/characters/hero): frame integrity, foot anchoring, and in-game animation states.
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
func lowest_opaque_row(tex:Texture2D) -> int:
 var img=tex.get_image()
 for y in range(img.get_height()-1,-1,-1):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>0.08:
    return y+1
 return -1
func run() -> void:
 profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 # --- the art itself ---
 var fighter_script=load("res://scripts/combat/fighter.gd")
 var probe=fighter_script.new()
 check(probe.load_sprite_set("res://assets/characters/hero/frames.tres"),"Hero frames.tres loads")
 var frames=probe.sprite_frames
 check(frames.get_frame_count("idle")==6 and frames.get_frame_count("walk")==8 and frames.get_frame_count("hurt")==4 and frames.get_frame_count("defeat")==6,"Reliable animations have the expected frame counts")
 for flagged in ["run","dash","jump","land","attack1","attack2","attack3","skill","finisher"]:
  if frames.has_animation(flagged) and frames.get_frame_count(flagged)>0:
   check(false,"Flagged animation "+flagged+" must not be exported")
 check(not probe.has_animation("attack1") and not probe.has_animation("run") and not probe.has_animation("skill"),"Unreliable animations are not exported (flagged, not invented)")
 var size=frames.get_frame_texture("idle",0).get_size()
 var same_size=true
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/hero/manifest.json"))
 var ground=int(manifest.ground_row)
 var anchored=true
 for anim in ["idle","walk","hurt"]:
  for i in range(frames.get_frame_count(anim)):
   var tex=frames.get_frame_texture(anim,i)
   if tex.get_size()!=size: same_size=false
   if absi(lowest_opaque_row(tex)-ground)>1: anchored=false
 check(same_size,"Every Hero frame shares one canvas size")
 check(anchored,"Idle, walk and hurt frames all stand on the same ground row (no foot jitter)")
 # --- in the district ---
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.start_episode()
 await process_frame
 var ep=main.screen.get_child(0)
 await skip_scenes(ep,func(): return ep.explore!=null)
 var ex=ep.explore
 var hero=ex.player
 check(hero.sprite!=null,"District player uses the Hero sprite")
 await process_frame
 check(hero.current_anim=="idle","Standing still plays idle")
 ex.stick.direction=Vector2(1,0)
 await create_timer(0.3).timeout
 check(hero.current_anim=="walk" and not hero.sprite.flip_h,"Walking right plays walk facing right")
 ex.stick.direction=Vector2(-1,0)
 await create_timer(0.3).timeout
 check(hero.current_anim=="walk" and hero.sprite.flip_h,"Walking left flips the sprite")
 ex.stick.direction=Vector2.ZERO
 await create_timer(0.3).timeout
 check(hero.current_anim=="idle","Stopping returns to idle")
 var x_before=ex.px
 ex.px=60.0
 ex.stick.direction=Vector2(-1,0)
 await create_timer(0.3).timeout
 ex.stick.direction=Vector2.ZERO
 check(ex.px>=80.0 and ex.px<x_before,"Hero stays inside the world bounds")
 # --- Hero Heroes screen ---
 main.show_hero()
 await process_frame
 var shown=false
 for c in main.modal.get_children():
  if c.has_method("attach_frames") and c.sprite!=null:
   shown=true
 check(shown,"Heroes screen shows the Hero sprite")
 main.close_modal()
 # --- in battle ---
 main.start_battle(true)
 await process_frame
 var battle=main.screen.get_child(0)
 battle.intro=0
 var bh=battle.hero
 check(bh.sprite!=null and bh.run_speed_threshold>0.0,"Battle hero uses the Hero sprite")
 battle.stick.direction=Vector2(1,0)
 await create_timer(0.25).timeout
 battle.stick.direction=Vector2.ZERO
 check(bh.current_anim=="walk","Battle movement falls back from run to walk (run is flagged)")
 battle.act("attack")
 await process_frame
 check(bh.swing>0.0 and bh.current_anim in ["idle","walk"],"Attacks fall back to existing frames without errors")
 bh.invincible=0
 bh.receive(10)
 await process_frame
 check(bh.current_anim=="hurt","Taking damage plays hurt")
 await create_timer(0.3).timeout
 bh.invincible=0
 bh.receive(100000)
 await process_frame
 await process_frame
 check(bh.current_anim=="defeat","Dying plays defeat")
 await create_timer(1.2).timeout
 check(main.scene_name=="result","Defeat still ends the battle and reaches the result screen")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
