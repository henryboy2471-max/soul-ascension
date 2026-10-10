extends SceneTree
# Headless checks for the 2.5D Neon District demo: four-direction movement, collisions, depth, occlusion, camera, NPC dialogue, puzzle, interiors,
# sprite coverage, footsteps and save safety. Movement is stepped with a fixed delta (deterministic); only fades/dialogue use real timers.
var passed=0
var failed=0
func check(value:bool, name:String) -> void:
 if value:
  passed+=1
  print("PASS: "+name)
 else:
  failed+=1
  push_error("FAIL: "+name)
func _initialize() -> void:
 call_deferred("run")
func steps(stage, move:Vector2, n:int) -> void:
 for i in range(n):
  stage.tick(0.016,move,false)
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.data.settings.sound=false
 var before=JSON.stringify(profile.data)
 var Stage=load("res://scripts/demo/stage25.gd")
 var demo=load("res://scripts/demo/neon_demo.gd").new()
 root.add_child(demo)
 await process_frame
 # let the opening cinematic play out (title card + one line), then take control
 var waited=0.0
 while demo.intro_running and waited<12.0:
  await create_timer(0.25).timeout
  waited+=0.25
  if demo.dlg!=null:
   demo.dlg.finish_all()
 check(not demo.intro_running and not demo.locked,"opening cinematic finishes and hands over control")
 demo.set_process(false)
 demo.locked=false
 var st=demo.stage
 var p=st.player
 check(st!=null and p!=null,"demo builds a street stage with a player")
 check(st.peds.size()>=8 and st.vehicles.size()>=12,"street has pedestrians and traffic ("+str(st.peds.size())+" peds, "+str(st.vehicles.size())+" vehicles)")
 # --- four-direction movement (ambient pedestrians and traffic are parked far away so the check is deterministic)
 var park_i=0
 for a in st.actors:
  if a!=p and a.has_meta("ped"):
   a.get_meta("ped").pause=1.0e6
   a.wx=-3000.0-park_i*100.0
   park_i+=1
 var saved_top=[]
 for v in st.vehicles:
  saved_top.append(v.top_speed)
  v.top_speed=0.0
  v.speed=0.0
  v.wx=-4000.0
 p.wx=3450.0
 p.z=0.72
 var x0=p.wx
 steps(st,Vector2(1,0),60)
 check(p.wx>x0+100 and p.dir=="right","moves right and faces right")
 x0=p.wx
 steps(st,Vector2(-1,0),60)
 check(p.wx<x0-100 and p.dir=="left","moves left and faces left")
 var z0=p.z
 steps(st,Vector2(0,1),22)
 check(p.z>z0+0.1 and p.dir=="down","moves toward the camera (down) and shows the front view")
 steps(st,Vector2.ZERO,30)
 z0=p.z
 steps(st,Vector2(0,-1),30)
 check(p.z<z0-0.1 and p.dir=="up","moves away (up) and shows the back view")
 # walk cycle advances and loops through frames 1..4
 var frames={}
 for i in range(60):
  st.tick(0.016,Vector2(1,0),false)
  frames[p.frame]=true
 check(frames.has(1) and frames.has(2) and frames.has(3) and frames.has(4),"walk cycle plays all four walk frames")
 steps(st,Vector2.ZERO,80)
 check(p.frame==0 and not p.moving,"returns to idle when input stops")
 # --- depth: perspective and sorting
 check(Stage.y_of(1.0)>Stage.y_of(0.0) and Stage.s_of(1.0)>Stage.s_of(0.0),"screen y and scale grow toward the camera")
 p.z=0.9
 st.tick(0.016,Vector2.ZERO,false)
 var big=p.scale.x
 p.z=0.2
 st.tick(0.016,Vector2.ZERO,false)
 check(big>p.scale.x*1.15,"characters shrink with distance (perspective)")
 check(st.ysort.y_sort_enabled,"world objects are y-sorted")
 # --- collisions
 p.wx=560.0
 p.z=0.33
 steps(st,Vector2(0,-1),80)
 check(p.z>0.2+0.03,"cannot walk through Kofi's stall (z="+str(snapped(p.z,0.001))+")")
 p.wx=60.0
 p.z=0.5
 steps(st,Vector2(-1,0),60)
 check(p.wx>=20.0,"world edge stops the player")
 p.wx=2000.0
 p.z=0.9
 steps(st,Vector2(0,1),60)
 check(p.z<=0.985,"front edge of the plane stops the player")
 # a vehicle in the lane blocks the player and yields to them
 var v=st.vehicles[0]
 v.top_speed=saved_top[0]
 v.speed=v.top_speed
 v.wx=300.0
 p.wx=v.wx+v.dir*220.0
 p.z=v.z
 var sp0=v.speed
 for i in range(60):
  st.tick(0.016,Vector2.ZERO,false)
 check(v.speed<5.0 and absf(p.wx-v.wx)>100.0,"traffic stops before a pedestrian standing in the lane")
 v.top_speed=0.0
 v.speed=0.0
 v.wx=-4000.0
 # --- foreground occlusion
 var pole=null
 for q in st.props:
  if q.occluder and q.kind=="pole":
   pole=q
   break
 p.wx=pole.wx
 p.z=pole.z-0.2
 for i in range(40):
  st.tick(0.016,Vector2.ZERO,false)
 check(pole.modulate.a<0.5,"foreground pole fades when the player is behind it (a="+str(snapped(pole.modulate.a,0.01))+")")
 p.z=pole.z+0.03
 for i in range(60):
  st.tick(0.016,Vector2.ZERO,false)
 check(pole.modulate.a>0.9,"pole is solid again when the player passes in front")
 # --- camera
 p.wx=400.0
 p.z=0.5
 st.snap_camera()
 var c0=st.cam_c.x
 steps(st,Vector2(1,0),160)
 check(st.cam_c.x>c0+200,"camera follows the player")
 p.wx=4700.0
 for i in range(120):
  st.tick(0.016,Vector2.ZERO,false)
 check(st.cam_c.x<=st.world_w-640.0/st.zoom+1.0 and st.cam_c.x>=640.0/st.zoom-1.0,"camera stays inside the world")
 p.z=0.15
 for i in range(120):
  st.tick(0.016,Vector2.ZERO,false)
 var zfar=st.zoom
 p.z=0.95
 for i in range(180):
  st.tick(0.016,Vector2.ZERO,false)
 check(st.zoom>zfar+0.015,"camera pushes in as the player comes toward the screen")
 # --- NPC interaction and the story slice
 p.wx=560.0
 p.z=0.34
 check(st.nearest_spot().get("id","")=="kofi","Kofi is interactable from the front of his stall")
 demo.on_spot(st.spot("kofi"))
 await process_frame
 check(demo.dlg!=null and demo.locked,"talking opens a dialogue and locks movement")
 demo.dlg.finish_all()
 await create_timer(0.9).timeout
 check(demo.dlg==null and not demo.locked,"dialogue closes and returns control")
 demo.on_spot(st.spot("imani"))
 await process_frame
 demo.dlg.finish_all()
 await create_timer(0.9).timeout
 check(demo.flags.talked_imani and demo.objective==1,"Imani advances the mission")
 demo.press_breaker("cyan")
 await process_frame
 check(demo.dlg!=null,"breakers refuse to work before the clue is found")
 demo.dlg.finish_all()
 await create_timer(0.9).timeout
 demo.on_spot(st.spot("tower"))
 await process_frame
 demo.dlg.finish_all()
 await create_timer(0.9).timeout
 check(demo.flags.clue and demo.objective==2,"listening to the tower reveals the pulse pattern")
 demo.press_breaker("gold")
 demo.press_breaker("violet")
 demo.press_breaker("cyan")
 check(not demo.flags.solved and demo.wrong_t>0.0 and demo.seq.is_empty(),"wrong order resets the puzzle")
 await create_timer(1.1).timeout
 demo.wrong_t=0.0
 demo._process(0.016)
 demo.press_breaker("cyan")
 demo.press_breaker("gold")
 demo.press_breaker("violet")
 check(demo.flags.solved,"correct order solves the puzzle")
 await create_timer(4.2).timeout
 check(demo.flags.opened and demo.hidden_door.open_amount>0.99,"hidden pathway opens")
 if demo.dlg!=null:
  demo.dlg.finish_all()
 await create_timer(1.0).timeout
 # --- interiors keep the street alive and return correctly
 var street=demo.stage
 demo.on_spot(street.spot("noodle_door"))
 await create_timer(1.2).timeout
 check(demo.where=="noodle" and demo.stage!=street and not street.visible,"entering the Noodle House swaps to an interior")
 demo.on_spot(demo.stage.spot("exit"))
 await create_timer(1.2).timeout
 check(demo.where=="street" and demo.stage==street and street.visible,"leaving returns to the same street")
 demo.on_spot(street.spot("hidden"))
 await create_timer(1.2).timeout
 check(demo.where=="hidden_alley","hidden panel leads into the passage")
 demo.on_spot(demo.stage.spot("arcade_door"))
 await create_timer(1.2).timeout
 check(demo.where=="arcade","passage leads to the Backroom Arcade")
 # --- art coverage
 var Actor=load("res://scripts/demo/sprite_actor.gd")
 var ok=true
 for id in ["echo","mira","kofi","imani","zuri","okoye","adaeze","tunde","sade","bayo","ngozi","musa"]:
  for view in ["front","back","side"]:
   var t=Actor.strip(id,view)
   ok=ok and t!=null and t.get_width()==5*144 and t.get_height()==288
  ok=ok and Actor.portrait(id)!=null
 check(ok,"all 12 characters have front/back/side walk strips (5 frames) and a portrait")
 # --- sound
 profile.data.settings.sound=true
 var snd=root.get_node("Sound")
 var uniq={}
 for s in snd.STEP_SURFACES:
  var lst=snd.step_clips[s]
  check(lst.size()==5,"5 footstep variants for "+s)
  for c in lst:
   uniq[c.data.size()*1000+c.data[200]]=true
 check(uniq.size()>=10,"footstep variants differ from each other")
 var picks=[]
 for i in range(30):
  snd.footstep("wet")
  picks.append(snd.step_last["wet"])
 var repeats=0
 for i in range(1,picks.size()):
  if picks[i]==picks[i-1]:
   repeats+=1
 check(repeats==0,"footsteps never repeat the same variant twice in a row")
 profile.data.settings.sound=false
 # --- the demo never touches saves
 check(JSON.stringify(profile.data)==before,"demo leaves the profile/save data untouched")
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
