extends SceneTree
# Hollow Cantor dedicated art (assets/enemies/hollow_cantor): frames, animation set, canvas/anchoring/clipping, distinct silhouette,
# Phase 2 form, and the battle integration (no tint workaround, Shade kept only as a fallback).
var passed=0
var failed=0
func check(ok:bool, name:String) -> void:
 if ok:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  print("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
 create_timer(100.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
# bounding box of pixels above the alpha threshold: Rect2i(x,y,w,h) and the pixel count
func solid(tex:Texture2D, threshold:float=0.35) -> Dictionary:
 var img=tex.get_image()
 var x0=9999
 var x1=-1
 var y0=9999
 var y1=-1
 var count=0
 for y in range(img.get_height()):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>threshold:
    count+=1
    x0=mini(x0,x)
    x1=maxi(x1,x)
    y0=mini(y0,y)
    y1=maxi(y1,y)
 return {"rect":Rect2i(x0,y0,x1-x0+1,y1-y0+1),"count":count}
# smallest distance (px) from any faintly visible pixel (alpha > 0.004) to each canvas edge: [top, left, right, bottom]
func margins(tex:Texture2D) -> Array:
 var img=tex.get_image()
 var w=img.get_width()
 var h=img.get_height()
 var top=h
 var bottom=h
 var left=w
 var right=w
 for y in range(h):
  for x in range(w):
   if img.get_pixel(x,y).a>0.004:
    top=mini(top,y)
    bottom=mini(bottom,h-1-y)
    left=mini(left,x)
    right=mini(right,w-1-x)
 return [top,left,right,bottom]
func solid_bottom_margin(tex:Texture2D) -> int:
 var img=tex.get_image()
 var h=img.get_height()
 var best=h
 for y in range(h):
  for x in range(img.get_width()):
   if img.get_pixel(x,y).a>0.5:
    best=mini(best,h-1-y)
 return best
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var fighter_script=load("res://scripts/combat/fighter.gd")
 var p1=fighter_script.new()
 check(p1.load_sprite_set("res://assets/enemies/hollow_cantor/frames.tres"),"Hollow Cantor frames.tres loads")
 var p2=fighter_script.new()
 check(p2.load_sprite_set("res://assets/enemies/hollow_cantor/phase2/frames.tres"),"Phase 2 frames.tres loads")
 var expect={"idle":[8,8.0,true],"walk":[6,9.0,true],"attack1":[8,20.0,false],"hurt":[2,14.0,false],"defeat":[8,9.0,false]}
 for set_name in ["phase1","phase2"]:
  var f=p1.sprite_frames if set_name=="phase1" else p2.sprite_frames
  var ok=true
  for anim in expect:
   if not f.has_animation(anim) or f.get_frame_count(anim)!=expect[anim][0] or f.get_animation_speed(anim)!=expect[anim][1] or f.get_animation_loop(anim)!=expect[anim][2]:
    ok=false
  check(ok,"%s animation set: idle 8, walk 6, attack1 8, hurt 2, defeat 8 with the expected fps/loop" % set_name)
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemies/hollow_cantor/manifest.json"))
 var size1=p1.sprite_frames.get_frame_texture("idle",0).get_size()
 var size2=p2.sprite_frames.get_frame_texture("idle",0).get_size()
 check(size1.y==size2.y and size1.y==float(manifest.ground_row),"Both forms share the canvas height (so the swap never rescales the character)")
 var worst_top=9999
 var worst_side=9999
 var worst_bottom=9999
 var worst_solid_bottom=9999
 var same=true
 var anchored=true
 for f in [p1.sprite_frames,p2.sprite_frames]:
  var sz=f.get_frame_texture("idle",0).get_size()
  for anim in expect:
   for i in range(f.get_frame_count(anim)):
    var tex=f.get_frame_texture(anim,i)
    if tex.get_size()!=sz: same=false
    var m=margins(tex)
    worst_top=mini(worst_top,m[0])
    worst_side=mini(worst_side,mini(m[1],m[2]))
    worst_bottom=mini(worst_bottom,m[3])
    worst_solid_bottom=mini(worst_solid_bottom,solid_bottom_margin(tex))
    if anim!="defeat" and anim!="hurt":
     if absi(solid(tex)["rect"].end.y-int(sz.y))>20: anchored=false
 check(same,"Every frame in a set shares one canvas size")
 check(worst_top>=24 and worst_side>=24 and worst_bottom>=1 and worst_solid_bottom>=3,"Every frame has safe margins: top >= %d px, sides >= %d px, glow clear of the bottom row (%d), hem >= %d px above it" % [worst_top,worst_side,worst_bottom,worst_solid_bottom])
 check(anchored,"The robe hem hovers just above the ground row in every idle/walk/attack frame (no foot jitter)")
 # silhouette: taller and thinner than the Shade and the Enforcer
 var shade=fighter_script.new()
 shade.load_sprite_set("res://assets/enemies/resonance_shade/frames.tres")
 var enforcer=fighter_script.new()
 enforcer.load_sprite_set("res://assets/enemies/enforcer/frames.tres")
 # mean width of the occupied rows relative to the figure height: the Cantor is a thin vertical figure
 var thin=func(f):
  var tex=f.sprite_frames.get_frame_texture("idle",0)
  var img=tex.get_image()
  var rows=0.0
  var used=0
  for y in range(img.get_height()):
   var n=0
   for x in range(img.get_width()):
    if img.get_pixel(x,y).a>0.35: n+=1
   if n>0:
    rows+=n
    used+=1
  return rows/float(used)/float(used)
 var rc=thin.call(p1)
 check(rc<thin.call(shade)*0.6 and rc<thin.call(enforcer)*0.6,"Silhouette is unnaturally thin and tall compared with the Shade and the Enforcer (%.2f vs %.2f / %.2f)" % [rc,thin.call(shade),thin.call(enforcer)])
 var a1=solid(p1.sprite_frames.get_frame_texture("idle",0))["count"]
 var a2=solid(p2.sprite_frames.get_frame_texture("idle",0))["count"]
 check(a2>a1*1.1,"Phase 2 is the same character intensified: more light, rings and ribbons (%d vs %d opaque pixels)" % [a2,a1])
 check(p1.resolve_animation("attack1")=="attack1" and p1.resolve_animation("hurt")=="hurt" and p1.resolve_animation("defeat")=="defeat" and p1.resolve_animation("run")=="walk","The combat system's animation names resolve to real frames (run falls back to walk)")
 var last=p1.sprite_frames.get_frame_texture("defeat",7)
 check(solid(last,0.1)["count"]<solid(p1.sprite_frames.get_frame_texture("idle",0),0.1)["count"]*0.25,"The last defeat frame is a faint remnant, not a lingering body")
 # --- in battle ---
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 profile.data.completed=["1-1"]
 main.start_battle(true,"1-2")
 await process_frame
 var battle=main.screen.get_child(0)
 battle.intro=0
 battle.skip_whispers()
 battle.foe.receive(1000000.0)
 await create_timer(0.8).timeout
 var cantor=battle.foe
 check(cantor.look=="cantor" and not cantor.temp_art and cantor.sprite.modulate==Color.WHITE and cantor.sprite_frames==p1.sprite_frames.duplicate() or cantor.sprite_frames.resource_path.ends_with("hollow_cantor/frames.tres"),"Hollow Cantor wave uses the dedicated frames with no tint workaround")
 check(cantor.max_health==960.0 and battle.telegraph_radius==150.0 and battle.telegraph_len==1.0 and battle.foe.attack==27.0,"Combat stats and bell-toll timing are unchanged")
 var hero_h=battle.hero.sprite.scale.y*battle.hero.sprite_frames.get_frame_texture("idle",0).get_size().y*battle.hero.scale.y
 var cantor_h=cantor.sprite.scale.y*cantor.sprite_frames.get_frame_texture("idle",0).get_size().y*cantor.scale.y
 check(cantor_h>hero_h*1.35 and cantor_h<hero_h*1.9,"Boss scale: the Cantor stands %.2fx the Hero" % (cantor_h/hero_h))
 # Phase 2 swap keeps health and position, same node
 var node=cantor
 var hp_before=0.49*node.max_health
 node.health=hp_before
 battle.hero.health=battle.hero.max_health*0.6
 await create_timer(1.4).timeout
 check(battle.foe==node and battle.phase==2 and node.boss_form and node.sprite_frames.resource_path.ends_with("phase2/frames.tres") and node.health<=hp_before,"Phase 2 swaps to the intensified frames on the same foe without resetting health")
 var phase2_h=node.sprite.scale.y*node.sprite_frames.get_frame_texture("idle",0).get_size().y
 check(absf(phase2_h-cantor.sprite.scale.y*p1.sprite_frames.get_frame_texture("idle",0).get_size().y)<2.0,"Phase 2 art is drawn at the same world height as Phase 1 (no pop in size)")
 node.receive(1000000.0)
 await create_timer(0.3).timeout
 check(node.dead and node.current_anim=="defeat" and node.sprite.animation=="defeat","Defeat plays the dedicated defeat animation")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
