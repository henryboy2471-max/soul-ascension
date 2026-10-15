extends SceneTree
# Home screen redesign: a single primary action (PLAY EPISODE for a fresh save, RESUME EPISODE n for an unfinished episode), real stats, SOON items, no online indicators, legible text.
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
func all_nodes(node:Node, out:Array) -> void:
 out.append(node)
 for c in node.get_children():
  all_nodes(c,out)
func texts(node:Node) -> Array:
 var nodes=[]
 all_nodes(node,nodes)
 var out=[]
 for n in nodes:
  if (n is Label or n is Button) and n.visible and str(n.text)!="":
   out.append(str(n.text))
 return out
func primary_buttons() -> Array:
 # the gold primary buttons on the home screen (their normal style uses the gold fill)
 var nodes=[]
 all_nodes(main.screen,nodes)
 var out=[]
 for n in nodes:
  if n is Button and n.visible:
   var style=n.get_theme_stylebox("normal")
   if style is StyleBoxFlat and style.bg_color.is_equal_approx(Color("efce8e")):
    out.append(n)
 return out
func home(state:Dictionary) -> void:
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 for key in state:
  profile.data[key]=state[key]
 if is_instance_valid(main):
  main.queue_free()
 await process_frame
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 main.show_home()
 await process_frame
func run() -> void:
 profile=root.get_node("Profile")
 # ---- fresh save
 await home({})
 var t=texts(main.screen)
 var prim=primary_buttons()
 check(prim.size()==1 and prim[0].text=="PLAY EPISODE","Fresh save: PLAY EPISODE is the single primary action")
 check(not t.has("RESUME EPISODE 1") and not t.has("SAVED PROGRESS"),"Fresh save: no RESUME button or saved-progress strip")
 check(t.has("EPISODE 1") and t.has("FIRST AWAKENING") and t.has("A spark in the static"),"Episode card shows EPISODE 1 / FIRST AWAKENING and the approved episode name")
 check(t.has("S O U L") and t.has("A S C E N S I O N") and t.has("THE UNBOUND CHRONICLES"),"The approved SOUL ASCENSION logo text is unchanged")
 check(t.has("LV. 1") and t.has("GOLD  500      CRYSTALS  0      ENERGY  60 / 120"),"Level, gold, crystals and energy show the real values")
 var soon_ok=true
 for name in ["SUMMON","SHOP","EVENTS","BATTLE PASS","VIP"]:
  soon_ok=soon_ok and t.has(name+"    /    SOON")
 check(soon_ok,"Summon, Shop, Events, Battle Pass and VIP are all marked SOON")
 var banned=false
 var joined=" | ".join(t).to_lower()
 for word in ["mail","wi-fi","wifi","online now","friends","chat","server"]:
  if joined.contains(word):
   banned=true
   print("  unsupported indicator text: ",word)
 check(not banned,"No mail, Wi-Fi or other online indicators")
 # ---- unfinished episode
 await home({"mission_progress":{"1-1":{"intro":true,"step":1,"px":520.0}},"level":3,"gold":321,"energy":48,"crystals":5})
 t=texts(main.screen)
 prim=primary_buttons()
 check(prim.size()==1 and prim[0].text=="RESUME EPISODE 1","Unfinished episode: RESUME EPISODE 1 is the single primary action")
 check(not t.has("PLAY EPISODE") and t.has("SAVED PROGRESS") and t.has("Objective: Reboot the relay terminal"),"Resume state shows the saved objective and no PLAY EPISODE button")
 check(t.has("LV. 3") and t.has("GOLD  321      CRYSTALS  5      ENERGY  48 / 120"),"Stats follow the actual profile")
 # pressing RESUME starts the episode directly (no modal) and resumes without the intro
 prim[0].pressed.emit()
 await process_frame
 await process_frame
 var ep=main.screen.get_child(0) if main.screen.get_child_count()>0 else null
 check(main.scene_name=="episode" and not is_instance_valid(main.modal),"RESUME starts the episode directly")
 # ---- fresh PLAY opens the mission card
 await home({})
 primary_buttons()[0].pressed.emit()
 await process_frame
 check(is_instance_valid(main.modal),"PLAY EPISODE opens the mission card (controls and BATTLE ONLY stay available)")
 # ---- corrupted progress falls back safely
 await home({"mission_progress":{"1-1":{"intro":true,"step":"banana"}}})
 t=texts(main.screen)
 check(primary_buttons()[0].text=="RESUME EPISODE 1" and t.has("Objective: Find Mira Vey at the tram"),"A corrupted step falls back to the first objective instead of crashing")
 await home({"mission_progress":{"1-1":{"intro":"yes"}}})
 check(primary_buttons()[0].text=="PLAY EPISODE","A non-boolean intro flag is not treated as saved progress")
 # ---- cleared Episode 1 -> Episode 2 is featured; completed episodes never offer RESUME
 await home({"completed":["1-1"],"mission_progress":{"1-1":{"intro":true,"step":2}}})
 t=texts(main.screen)
 check(primary_buttons()[0].text=="PLAY EPISODE" and t.has("EPISODE 2") and t.has("UNDER THE VIOLET RAIN"),"After clearing Episode 1 the home screen features Episode 2 with PLAY EPISODE")
 await home({"completed":["1-1"],"mission_progress":{"1-2":{"intro":true}}})
 check(primary_buttons()[0].text=="RESUME EPISODE 2","An unfinished Episode 2 offers RESUME EPISODE 2")
 # ---- legibility: no text smaller than 14 logical px on the home screen (about 7 px at 667x375)
 await home({"mission_progress":{"1-1":{"intro":true,"step":1}}})
 var nodes=[]
 all_nodes(main,nodes)
 var smallest=999
 var smallest_text=""
 for n in nodes:
  if (n is Label or n is Button) and n.visible and str(n.text)!="":
   var size=n.get_theme_font_size("font_size")
   if size<smallest:
    smallest=size
    smallest_text=str(n.text)
 check(smallest>=13,"Smallest home-screen text is %d px (\"%s\")" % [smallest,smallest_text])
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
