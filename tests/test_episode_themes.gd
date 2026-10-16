extends SceneTree
# Per-episode wallpaper and music, quiet footsteps, and no floor circles under walking characters (exploration), with the Music switch in Settings.
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
 create_timer(120.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func wallpaper_of(main) -> String:
 var found=""
 for c in main.screen.get_children():
  if c is TextureRect and c.texture!=null and c.texture.resource_path.contains("wallpaper") or (c is TextureRect and c.texture!=null and c.texture.resource_path.ends_with("echo_key_art.png")):
   found=c.texture.resource_path
   break
 return found
func run() -> void:
 var profile=root.get_node("Profile")
 var sound=root.get_node("Sound")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 # ---- themes: three distinct wallpapers and tracks that exist; unknown ids fall back to Episode 1
 var ids=["1-1","1-2","1-3"]
 var walls=[]
 var tracks=[]
 var ok=true
 for id in ids:
  var t=MissionDefs.theme(id)
  walls.append(t.wallpaper)
  tracks.append(t.music)
  if not ResourceLoader.exists(t.wallpaper) or not ResourceLoader.exists(t.music): ok=false
 check(ok and walls.size()==3 and walls[0]!=walls[1] and walls[1]!=walls[2] and walls[0]!=walls[2] and tracks[0]!=tracks[1] and tracks[1]!=tracks[2],"Episodes 1, 2 and 3 each have their own wallpaper and music track, and the files exist")
 check(walls[0]=="res://assets/echo_key_art.png" and MissionDefs.theme("9-9").wallpaper==walls[0],"Episode 1 keeps the original key art; unknown ids fall back to it")
 var lens_ok=true
 for tr in tracks:
  var st=load(tr)
  if not (st is AudioStreamOggVorbis) or st.get_length()<20.0: lens_ok=false
 check(lens_ok,"Each music track is an Ogg Vorbis loop longer than 20 seconds")
 # ---- the right wallpaper on the right screen
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.show_home()
 await process_frame
 check(wallpaper_of(main)==walls[0],"Fresh save: the home screen shows the Episode 1 wallpaper")
 profile.data.completed=["1-1"]
 main.show_home()
 await process_frame
 check(wallpaper_of(main)==walls[1],"After Episode 1: the home screen shows the Episode 2 wallpaper")
 profile.data.completed=["1-1","1-2"]
 main.show_home()
 await process_frame
 check(main.home_mission()=="1-2" and wallpaper_of(main)==walls[1],"After Episodes 1-2 the featured episode is still 2 (1-3 is not playable) and so is its wallpaper")
 check(MissionDefs.theme("1-3").wallpaper==walls[2] and not MissionDefs.is_playable("1-3"),"Episode 3 has its own wallpaper but is still not playable, so production never shows it on the home screen")
 for id in ["1-1","1-2","1-3"]:
  main.clear_screen()
  main.backdrop(id)
  check(wallpaper_of(main)==MissionDefs.theme(id).wallpaper,"backdrop('%s') draws that episode's wallpaper" % id)
 # the rewards screen of episode 2 uses Episode 2's wallpaper
 profile.data.completed=["1-1"]
 profile.data.energy=60
 check(profile.begin_run("1-2"),"Episode 2 run can be started for the rewards check")
 main.show_result(true)
 await process_frame
 check(main.scene_name=="result" and wallpaper_of(main)==walls[1],"The Episode 2 rewards screen shows the Episode 2 wallpaper")
 # ---- no circles under walking characters in exploration; battle fighters keep theirs
 check(Fighter.new().ground_marker==true,"A fighter (battle) still draws its floor marker by default")
 profile.data.completed=[]
 main.start_episode("1-1")
 await create_timer(1.0).timeout
 var ep=main.screen.get_child(0)
 var n=0
 while ep.explore==null and n<1500:
  for c in ep.get_children():
   if c.has_method("finish_all"): c.finish_all()
   elif c.has_method("finish"): c.finish()
  await process_frame
  n+=1
 var fighters=ep.explore.find_children("*","Fighter",true,false)
 var all_off=fighters.size()>=3
 for f in fighters:
  if f.ground_marker: all_off=false
 check(all_off,"Exploration: player, companion and %d walking characters have no floor circle" % fighters.size())
 # ---- sound levels and the music switch
 check(sound.STEP_DB<=-20.0 and sound.MUSIC_DB<=-18.0,"Footsteps (%.0f dB) and music (%.0f dB) sit well below the effects" % [sound.STEP_DB,sound.MUSIC_DB])
 profile.data.settings.sound=true
 sound.footstep("wet",1.0)
 var quiet=false
 for sp in sound.step_pool:
  if sp.playing and sp.volume_db<=-20.0: quiet=true
 check(quiet,"A footstep plays at its quiet level")
 profile.data.settings["music"]=true
 sound.music_play(tracks[0])
 await process_frame
 check(sound.music_player.playing and sound.music_player.stream is AudioStreamOggVorbis and sound.music_player.stream.loop,"Music on: the Episode 1 track plays as a loop")
 sound.music_play(tracks[1])
 await process_frame
 check(sound.music_player.playing and sound.music_path==tracks[1],"Changing episode theme switches the track")
 profile.data.settings["music"]=false
 sound.music_apply()
 check(not sound.music_player.playing,"Music off: it stops at once")
 sound.music_play(tracks[2])
 check(not sound.music_player.playing,"Music off: new tracks stay silent")
 profile.data.settings["music"]=true
 sound.music_apply()
 sound.loop("realm")
 check(not sound.music_player.playing,"Entering the Soul Realm (battle ambience) stops the music")
 sound.stop_loop()
 sound.stop_music()
 # ---- Settings: the Music switch exists, defaults on, writes its own setting
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 main.show_settings()
 await process_frame
 var checks=[]
 var stack=[main]
 while not stack.is_empty():
  var nd=stack.pop_back()
  if nd is CheckButton and nd.visible: checks.append(nd)
  stack.append_array(nd.get_children())
 var labels=checks.map(func(c): return c.text)
 check(checks.size()==4 and labels.has("Background music") and labels.has("Sound effects"),"Settings lists Sound effects, Background music, Screen shake and Reduced motion")
 var music_switch=checks[labels.find("Background music")]
 check(music_switch.button_pressed==true,"Background music defaults to on")
 music_switch.button_pressed=false
 music_switch.toggled.emit(false)
 check(profile.data.settings.music==false and profile.backend.read_data().settings.music==false and not sound.music_player.playing,"Switching it off is saved and silences the music without touching Sound effects")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
