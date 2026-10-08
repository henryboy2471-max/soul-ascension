extends SceneTree
# Automated overflow audit for the Episode 2 flow in logical canvas space. The game stretches this 1280x720 canvas to every window
# (667x375 and 844x390 phones letterbox it), so anything inside the canvas that is not clipped here fits on every phone size.
# Checks: labels/buttons/panels stay inside the canvas, chip text fits its pill, wrapped text fits its panel, buttons never overlap.
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
 create_timer(250.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func alpha_of(node:Node) -> float:
 var a=1.0
 var n=node
 while n!=null:
  if n is CanvasItem:
   a*=n.modulate.a
   if not n.visible: return 0.0
  n=n.get_parent()
 return a
func collect(node:Node, out:Array) -> void:
 if node is Control and node.is_visible_in_tree() and alpha_of(node)>0.05:
  out.append(node)
 for c in node.get_children(): collect(c,out)
# returns a list of human-readable problems for everything currently on screen under `scope`
func audit(scope:Node, skip_names:Array=[]) -> Array:
 var items=[]
 collect(scope,items)
 var issues=[]
 var buttons=[]
 for c in items:
  if c is Label and str(c.text)!="":
   var need=c.get_combined_minimum_size()
   var rect=Rect2(c.global_position,Vector2(maxf(c.size.x,need.x),maxf(c.size.y,need.y)))
   var tag="Label '%s'" % str(c.text).substr(0,28)
   if rect.position.x<-1.0 or rect.position.y<-1.0 or rect.end.x>1281.0 or rect.end.y>721.0:
    if not skip_names.has(c.name): issues.append(tag+" leaves the canvas "+str(rect))
   if c.has_meta("back"):
    var back=c.get_meta("back")
    if need.x>back.size.x+1.0 or need.y>back.size.y+1.0:
     issues.append(tag+" overflows its chip %s vs %s" % [str(need),str(back.size)])
  elif c is Button and c.visible:
   var r=Rect2(c.global_position,c.size)
   if r.position.x<-1.0 or r.position.y<-1.0 or r.end.x>1281.0 or r.end.y>721.0:
    issues.append("Button '%s' leaves the canvas %s" % [c.text,str(r)])
   var need=c.get_minimum_size()
   if need.x>c.size.x+1.0:
    issues.append("Button '%s' text is wider than the button" % c.text)
   buttons.append(c)
 for i in range(buttons.size()):
  for j in range(i+1,buttons.size()):
   var a=Rect2(buttons[i].global_position,buttons[i].size)
   var b=Rect2(buttons[j].global_position,buttons[j].size)
   if a.intersects(b) and buttons[i].get_parent()==buttons[j].get_parent():
    issues.append("Buttons '%s' and '%s' overlap" % [buttons[i].text,buttons[j].text])
 return issues
func fresh(progress:Dictionary={}, level:int=3) -> void:
 if main!=null and is_instance_valid(main):
  main.queue_free()
  await process_frame
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.data.completed=["1-1"]
 profile.data.level=level
 profile.data.codex=["mira","board","mural","terminal","breach","enforcer","violet_rain","sleepers","rain_array","hollow_cantor"]
 profile.active_run=""
 if not progress.is_empty():
  profile.data.mission_progress={"1-2":progress.duplicate(true)}
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
func report(name:String, scope:Node, skip:Array=[]) -> void:
 var issues=audit(scope,skip)
 if not issues.is_empty():
  print("INFO ",name,": ",issues)
 check(issues.is_empty(),"Layout fits the canvas: "+name)
func skip_boxes(ep:Node) -> void:
 for c in ep.get_children():
  if c.has_method("finish_all"): c.finish_all()
  elif c.has_method("finish"): c.finish()
const READY={"intro":true,"depot":true,"mira":true,"notice":true,"resonators":["res_a","res_b","res_c"],"array":true}
func run() -> void:
 root.size=Vector2i(1280,720)
 profile=root.get_node("Profile")
 # menus
 await fresh()
 main.show_home()
 await process_frame
 report("home (Episode 2 featured)",main)
 main.show_missions()
 await process_frame
 report("missions screen",main)
 main.close_modal()
 main.show_mission("1-2")
 await process_frame
 report("Episode 2 mission card",main)
 main.close_modal()
 main.show_codex()
 await process_frame
 report("Codex with 10 entries",main)
 main.close_modal()
 # every Episode 2 dialogue line, in the real dialogue box
 var data=load("res://scripts/story/episode2_data.gd")
 var all_ok=true
 var worst=""
 for name in ["INTRO","DEPOT","MIRA_TALK","MIRA_REPEAT","MEMORY_A","MEMORY_B","MEMORY_C","GATE_UNLOCK","GATE_LOCKED","NOTICE","ARRAY","ENDING_REALM","ENDING_RETURN_A","ENDING_RETURN_B"]:
  var lines=data.get(name)
  for line in lines:
   var box=load("res://scripts/story/dialogue_box.gd").new()
   box.setup([line],"Ascendant")
   main.add_child(box)
   await process_frame
   box.advance()
   await process_frame
   var need=box.text_label.get_combined_minimum_size()
   var bottom=box.text_label.global_position.y+need.y
   var plate_ok=true
   if box.name_plate.visible:
    plate_ok=box.name_label.get_theme_font("font").get_string_size(box.name_label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x<=box.name_plate.size.x-14.0 and box.name_plate.global_position.x+box.name_plate.size.x<=1240.0
   if bottom>box.box_panel.global_position.y+box.box_panel.size.y-4.0 or need.x>box.text_label.size.x+1.0 or not plate_ok:
    all_ok=false
    worst=str(line.text).substr(0,40)
    print("INFO dialogue ",name," ",str(line.who)," need=",need," bottom=",bottom," limit=",box.box_panel.global_position.y+box.box_panel.size.y-4.0," textw=",box.text_label.size.x," plate_ok=",plate_ok)
   box.queue_free()
 check(all_ok,"Every Episode 2 dialogue line fits inside the dialogue box %s" % worst)
 # explore HUD, counter objective, breach prompt
 await fresh({"intro":true,"depot":true,"mira":true,"resonators":["res_a"]})
 main.start_episode("1-2")
 await process_frame
 var ep=main.screen.get_child(0)
 var guard=0
 while ep.explore==null and guard<300:
  skip_boxes(ep)
  await process_frame
  guard+=1
 await create_timer(0.4).timeout
 report("explore HUD with Resonators Synced counter",ep.explore)
 ep.explore.toast("CODEX UPDATED  /  RAIN ARRAY 7")
 await create_timer(0.4).timeout
 report("explore Codex toast",ep.explore)
 await fresh(READY)
 main.start_episode("1-2")
 await process_frame
 ep=main.screen.get_child(0)
 guard=0
 while ep.explore==null and guard<300:
  skip_boxes(ep)
  await process_frame
  guard+=1
 ep.explore.px=2600.0
 await create_timer(0.5).timeout
 ep.on_interact("breach")
 await create_timer(0.4).timeout
 report("breach confirmation",ep)
 for c in ep.get_children():
  if c.has_method("decide"):
   c.armed=0.0
   c.decide(true)
 await create_timer(0.6).timeout
 var battle=main.screen.get_child(0)
 report("battle HUD + resonator whispers",battle)
 battle.skip_whispers()
 battle.intro=0.0
 await create_timer(0.4).timeout
 report("battle HUD: Resonance Shade",battle)
 battle.foe.receive(1000000.0)
 await create_timer(0.9).timeout
 battle.intro=0.0
 report("battle HUD: Hollow Cantor",battle)
 battle.hero.health=battle.hero.max_health*0.4
 battle.foe.health=battle.foe.max_health*0.49
 await create_timer(0.8).timeout
 report("battle HUD: Phase 2 banner + Mira radio line",battle)
 # result screens
 main.current_mission="1-2"
 profile.active_run="1-2"
 main.show_result(true)
 await process_frame
 report("rewards screen (won)",main)
 profile.active_run="1-2"
 main.show_result(false)
 await process_frame
 report("result screen (lost)",main)
 main.show_teaser(MissionDefs.get_def("1-2").ending.teaser)
 await create_timer(2.4).timeout
 report("NEXT EPISODE teaser",main)
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
