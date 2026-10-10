extends Control
var screen:Control
var modal:Control
var currency_label:Label
var notice:Label
var scene_name="home"
var current_mission="1-1"
# The mission the home screen advertises: the first unlocked playable mission that is not cleared yet (Episode 1 on a fresh save).
func home_mission() -> String:
 var featured="1-1"
 for id in ["1-1","1-2"]:
  if MissionDefs.is_playable(id) and MissionDefs.is_unlocked(id,Profile.data.completed):
   featured=id
   if not Profile.data.completed.has(id):
    return id
 return featured
var rotate_overlay:Control
var orientation_timer=0.0
func _process(delta:float) -> void:
 orientation_timer-=delta
 if orientation_timer<=0.0:
  orientation_timer=0.4
  var size=get_window().size
  set_portrait_hint(size.y>size.x)
# Phones held upright get a rotate prompt (the game is landscape-only).
func set_portrait_hint(portrait:bool) -> void:
 if portrait and rotate_overlay==null:
  rotate_overlay=Control.new()
  rotate_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  rotate_overlay.mouse_filter=Control.MOUSE_FILTER_STOP
  rotate_overlay.z_index=100
  var dim=ColorRect.new()
  dim.color=Color(0.012,0.016,0.04,0.97)
  dim.size=Vector2(1280,720)
  dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
  rotate_overlay.add_child(dim)
  var title=UI.label(rotate_overlay,"ROTATE YOUR DEVICE",Vector2(140,290),54,Color.WHITE,1000)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var sub=UI.label(rotate_overlay,"Soul Ascension plays in landscape",Vector2(140,370),24,UI.GOLD,1000)
  sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  add_child(rotate_overlay)
 elif not portrait and rotate_overlay!=null:
  rotate_overlay.queue_free()
  rotate_overlay=null
func _ready() -> void:
 Profile.changed.connect(refresh_profile)
 show_home()
 if demo_requested():
  call_deferred("start_neon_demo")
  return
 if not Profile.data.onboarded and not OS.get_cmdline_user_args().has("--capture-home"):
  onboarding()
 if OS.get_cmdline_user_args().has("--capture-home"):
  capture("home")
 elif OS.get_cmdline_user_args().has("--capture-battle"):
  if modal: modal.queue_free();modal=null
  start_battle()
  capture("battle")
# The 2.5D Neon District demonstration is a separate, non-canon sandbox: it never touches saves or episode progress.
# Start it with the command-line flag --demo-neon, or on the web with ?demo=neon.
func demo_requested() -> bool:
 if OS.get_cmdline_user_args().has("--demo-neon"):
  return true
 if OS.has_feature("web"):
  var q=JavaScriptBridge.eval("window.location.search",true)
  return q is String and q.contains("demo=neon")
 return false
func start_neon_demo() -> void:
 close_modal()
 clear_screen()
 scene_name="neon_demo"
 var demo=NeonDemo.new()
 demo.exit_requested.connect(show_home)
 screen.add_child(demo)
func capture(kind:String) -> void:
 await get_tree().create_timer(1.0).timeout
 var img=get_viewport().get_texture().get_image()
 img.save_png("user://"+kind+".png")
 print("CAPTURE: "+ProjectSettings.globalize_path("user://"+kind+".png"))
 get_tree().quit()
func clear_screen() -> void:
 if is_instance_valid(screen):
  # Keep the old screen in the tree (hidden, inert) until it is freed at frame end; removing it early made running tweens complain.
  screen.hide()
  screen.process_mode=Node.PROCESS_MODE_DISABLED
  screen.queue_free()
 screen=Control.new()
 screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(screen)
 currency_label=null
 notice=null
func backdrop() -> void:
 var texture=TextureRect.new()
 texture.texture=load("res://assets/echo_key_art.png")
 texture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 texture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 texture.size=Vector2(1280,630)
 texture.position=Vector2(0,87)
 texture.mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture.pivot_offset=Vector2(640,315)
 screen.add_child(texture)
 if not Profile.data.settings.get("reduced_motion",false):
  var drift=texture.create_tween().set_loops()
  drift.tween_property(texture,"scale",Vector2(1.035,1.035),9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  drift.tween_property(texture,"scale",Vector2(1.0,1.0),9.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 var shade=ColorRect.new()
 shade.size=Vector2(1280,720)
 shade.color=Color(0.015,0.022,0.065,0.25)
 shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
 screen.add_child(shade)
 for edge in [[120.0,false],[930.0,true]]:
  var fade=TextureRect.new()
  var gradient=Gradient.new()
  gradient.colors=PackedColorArray([Color(0.025,0.035,0.07,0.0),Color(0.025,0.035,0.07,1.0)] if edge[1] else [Color(0.025,0.035,0.07,1.0),Color(0.025,0.035,0.07,0.0)])
  var gradient_texture=GradientTexture2D.new()
  gradient_texture.gradient=gradient
  gradient_texture.fill_from=Vector2(0,0)
  gradient_texture.fill_to=Vector2(1,0)
  fade.texture=gradient_texture
  fade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  fade.position=Vector2(edge[0],87)
  fade.size=Vector2(220,630)
  fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
  screen.add_child(fade)
 screen.add_child(load("res://scripts/ui/atmosphere.gd").new())
func show_home() -> void:
 scene_name="home"
 Sound.stop_loop()
 clear_screen()
 backdrop()
 UI.panel(screen,Rect2(0,0,1280,104),Color(0.025,0.035,0.07,0.90),Color("242b41"))
 var rail=ColorRect.new()
 rail.color=Color(UI.GOLD,0.5)
 rail.position=Vector2(0,103)
 rail.size=Vector2(1280,1)
 rail.mouse_filter=Control.MOUSE_FILTER_IGNORE
 screen.add_child(rail)
 UI.label(screen,"S O U L",Vector2(31,19),22,Color.WHITE)
 UI.label(screen,"A S C E N S I O N",Vector2(30,46),17,UI.GOLD)
 UI.label(screen,"THE UNBOUND CHRONICLES",Vector2(31,76),13,UI.MUTED)
 UI.panel(screen,Rect2(242,23,287,59),Color(0.035,0.05,0.11,0.7))
 UI.label(screen,"LV. "+str(Profile.data.level),Vector2(256,34),24,UI.GOLD)
 UI.label(screen,Profile.data.name,Vector2(340,28),18)
 UI.label(screen,"POWER  "+str(HeroData.power(int(Profile.data.level))),Vector2(340,53),14,UI.MUTED)
 currency_label=UI.label(screen,"",Vector2(566,38),19,Color("e7def6"))
 UI.button(screen,"SETTINGS",Rect2(1106,24,150,58),show_settings)
 refresh_profile()
 UI.label(screen,"SEASON 01  /  THE FRACTURE",Vector2(32,131),13,UI.GOLD)
 UI.label(screen,"Your power.
Without limits.",Vector2(30,160),39,Color.WHITE)
 UI.label(screen,"One quiet spark.
An entire world listening.",Vector2(32,282),17,Color("c2c5d8"))
 UI.panel(screen,Rect2(30,342,292,153),Color(0.025,0.035,0.08,0.92),Color(UI.GOLD,0.4))
 UI.trim(screen,Rect2(30,342,292,153),UI.GOLD)
 UI.label(screen,"STORY  /  CHAPTER 01",Vector2(47,358),14,UI.VIOLET)
 var home_def=MissionDefs.get_def(home_mission())
 var replay=MissionDefs.reward(home_def.id,false)
 UI.label(screen,home_def.region,Vector2(47,382),25)
 UI.label(screen,home_def.number+"   "+home_def.title_case,Vector2(47,422),15,UI.MUTED)
 UI.label(screen,("INVESTIGATE  ·  NO ENERGY COST" if home_def.get("flow","district")=="lantern" else "EXPLORE FREE  ·  %d ENERGY FOR THE BOSS" % home_def.energy) if not Profile.data.completed.has(home_def.id) else "CLEARED  ·  REPLAY +%d XP  ·  +%d GOLD" % [replay.xp,replay.gold],Vector2(47,462),14,UI.GOLD)
 UI.button(screen,"PLAY "+home_def.number,Rect2(30,510,292,79),show_mission,true)
 UI.button(screen,"MISSIONS",Rect2(30,604,139,66),show_missions)
 UI.button(screen,"UPGRADE",Rect2(183,604,139,66),show_upgrade)
 UI.panel(screen,Rect2(996,132,260,93),Color(0.025,0.035,0.08,0.92),Color(UI.GOLD,0.4))
 UI.trim(screen,Rect2(996,132,260,93),UI.GOLD)
 UI.label(screen,"NOW PLAYING",Vector2(1013,147),14,UI.GOLD)
 UI.label(screen,"EPISODE 1  /  FIRST AWAKENING",Vector2(1013,173),13)
 UI.label(screen,"Plays offline  ·  no purchases",Vector2(1013,199),14,UI.MUTED)
 UI.button(screen,"HEROES    /    01",Rect2(996,244,260,65),show_hero)
 UI.button(screen,"SUMMON    /    SOON",Rect2(996,320,260,65),func(): planned("SUMMON","Coming soon: hero banners with published odds, rarity guarantees and summon history. Nothing can be summoned yet."))
 UI.button(screen,"SHOP    /    SOON",Rect2(996,396,260,65),func(): planned("SHOP","Coming soon: clearly itemized power packs and Crystal purchases. There are no paid items in this version."))
 UI.button(screen,"EVENTS    /    SOON",Rect2(996,472,260,65),func(): planned("EVENTS","Coming soon: seasonal stories, rotating challenges and limited bosses. There are no active offers or countdown timers."))
 UI.button(screen,"BATTLE PASS",Rect2(996,548,260,65),func(): planned("BATTLE PASS","Coming soon: free and premium reward tracks. There is nothing to claim yet."))
 UI.button(screen,"VIP",Rect2(996,624,260,46),func(): planned("VIP 0—15","Coming soon: purchase-based VIP progression with clear benefits. You are VIP 0. No purchases can be made in this version."))
 UI.panel(screen,Rect2(434,569,412,99),Color(0.025,0.035,0.075,0.85),Color("77618c"))
 UI.trim(screen,Rect2(434,569,412,99),UI.VIOLET)
 UI.label(screen,"E C H O   /   S T R I K E R",Vector2(459,582),13,UI.VIOLET)
 UI.label(screen,"THE UNBOUND",Vector2(457,605),28)
 UI.label(screen,"BASE FORM     •     EVOLUTION UNKNOWN",Vector2(459,644),13,UI.MUTED)
 notice=UI.label(screen,"Progress is saved on this device.",Vector2(31,692),13,UI.MUTED)
 refresh_profile()
func refresh_profile() -> void:
 if is_instance_valid(currency_label):
  currency_label.text="GOLD  "+str(Profile.data.gold)+"      CRYSTALS  "+str(Profile.data.crystals)+"      ENERGY  "+str(Profile.data.energy)+" / 120"
 if is_instance_valid(notice) and not Profile.save_ok:
  notice.text="SAVE FAILED — keep the game open and check device storage."
  notice.modulate=Color("ff7188")
func new_modal(title:String, subtitle:String="") -> Control:
 close_modal()
 modal=Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var dim=ColorRect.new()
 dim.size=Vector2(1280,720)
 dim.color=Color(0.01,0.015,0.035,0.86)
 modal.add_child(dim)
 UI.panel(modal,Rect2(255,74,770,576),Color("0d1427"),Color("6a577c"))
 UI.trim(modal,Rect2(255,74,770,576),UI.GOLD)
 UI.label(modal,title,Vector2(291,102),31,Color.WHITE,685)
 UI.label(modal,subtitle,Vector2(293,150),14,UI.VIOLET,680)
 UI.button(modal,"CLOSE",Rect2(835,568,153,58),close_modal)
 return modal
func close_modal() -> void:
 if is_instance_valid(modal):
  # Closed from inside one of its own button callbacks, so keep it in the tree (hidden, inert) until frame end.
  modal.hide()
  modal.process_mode=Node.PROCESS_MODE_DISABLED
  modal.queue_free()
 modal=null
func planned(title:String, copy:String, sub:String="COMING SOON", footer:String="Episode 1 is the playable story right now.") -> void:
 var node=new_modal(title,sub)
 UI.label(node,copy,Vector2(294,232),24,UI.MUTED,674)
 if footer!="":
  UI.label(node,footer,Vector2(294,476),17,UI.GOLD,658)
func show_mission(id:String="") -> void:
 var mission=MissionDefs.get_def(id if id!="" else home_mission())
 var node=new_modal(mission.title,mission.modal_sub)
 UI.label(node,mission.description,Vector2(294,208),23,Color("cbd0e2"),677)
 UI.label(node,mission.tagline,Vector2(294,334),23,UI.GOLD)
 UI.label(node,"Explore: WASD / arrows / left stick, E to act
Strike: J   Heavy: K   Dodge: Space   Block: hold L
Pulse: Q   Rift: E   Mend: R   Ultimate: F
On a phone, use the matching touch buttons.",Vector2(294,383),17,UI.MUTED,690)
 UI.button(node,"BEGIN "+mission.number,Rect2(294,551,348,75),func(): start_episode(mission.id),true)
 if not mission.battle_only_waves.is_empty():
  UI.button(node,"BATTLE ONLY",Rect2(656,568,170,58),func(): start_battle(false,mission.id))
func start_episode(mission_id:String="1-1") -> void:
 close_modal()
 if not MissionDefs.is_unlocked(mission_id,Profile.data.completed) or not MissionDefs.is_playable(mission_id):
  # A locked (or unfinished) episode never starts; the player stays on the menu.
  var locked=MissionDefs.get_def(mission_id)
  planned("EPISODE LOCKED","Clear the previous episode to unlock "+str(locked.get("number","this episode")).capitalize()+": "+str(locked.get("title_case","")),"LOCKED","")
  return
 current_mission=mission_id
 if MissionDefs.get_def(mission_id).get("flow","district")=="lantern" and Profile.begin_ending(mission_id):
  # The boss was already beaten and paid for but the ending never finished (reload): resume the ending, no energy, no fight.
  show_lantern_ending()
  return
 clear_screen()
 scene_name="episode"
 var episode=LanternEpisode.new() if MissionDefs.get_def(mission_id).get("flow","district")=="lantern" else Episode.new()
 episode.mission_id=mission_id
 episode.request_battle=func(): return start_battle(true,mission_id)
 episode.exit_requested.connect(show_home)
 screen.add_child(episode)
func on_battle_finished(won:bool, from_episode:bool) -> void:
 if won and from_episode and MissionDefs.get_def(current_mission).get("flow","district")=="lantern":
  Profile.mark_battle_won(current_mission)
  show_lantern_ending()
 elif won and from_episode:
  show_ending()
 else:
  show_result(won)
func show_lantern_ending() -> void:
 # Episode 2 ending: calm Soul Realm -> Lantern Quarter aftermath. The mission is completed (and paid) only when it finishes.
 Sound.stop_loop()
 clear_screen()
 scene_name="ending"
 var episode=LanternEpisode.new()
 episode.mission_id=current_mission
 episode.phase="ending"
 episode.completed.connect(func(): show_result(true))
 screen.add_child(episode)
func show_ending() -> void:
 clear_screen()
 scene_name="ending"
 var episode=Episode.new()
 episode.mission_id=current_mission
 episode.phase="ending"
 episode.completed.connect(func(): show_result(true))
 screen.add_child(episode)
func start_battle(from_episode:bool=false, mission_id:String="1-1") -> bool:
 if not Profile.begin_run(mission_id):
  if not from_episode or MissionDefs.get_def(mission_id).get("flow","district")=="lantern":
   # Standalone battles and Episode 2's breach show the normal recharge screen; Episode 1's own breach keeps its in-scene line.
   var cost=MissionDefs.energy_cost(mission_id)
   planned("ENERGY RECHARGING","Missions require %d energy. One energy regenerates every five minutes, including while the game is closed. Paid refills are not available." % cost,"MISSIONS  /  %d ENERGY" % cost,"")
  return false
 current_mission=mission_id
 close_modal()
 clear_screen()
 scene_name="battle"
 var battle=Battle.new()
 battle.mission_id=mission_id
 battle.boss_mode=from_episode
 screen.add_child(battle)
 battle.finished.connect(on_battle_finished.bind(from_episode))
 battle.retreat.connect(func(): show_result(false))
 return true
func show_teaser(teaser:Dictionary) -> void:
 # NEXT EPISODE card after the rewards, then back to the menu.
 clear_screen()
 scene_name="teaser"
 var card=TitleCard.new()
 card.setup(teaser.kicker,teaser.number+"  /  "+teaser.title,teaser.subtitle,true,float(teaser.length))
 screen.add_child(card)
 card.done.connect(show_home)
func show_result(won:bool) -> void:
 Sound.stop_loop()
 var reward=Profile.finish_run(won)
 if reward.is_empty(): return
 clear_screen()
 scene_name="result"
 backdrop()
 var tone=UI.GOLD if won else UI.VIOLET
 UI.panel(screen,Rect2(283,84,714,552),Color(0.025,0.035,0.075,0.96),Color(tone,0.7))
 UI.trim(screen,Rect2(283,84,714,552),tone)
 UI.chip(screen,"MISSION COMPLETE" if won else "SIGNAL LOST",Rect2(325,120,190,26),tone,13)
 var texts=MissionDefs.get_def(reward.id).result
 UI.label(screen,texts.won_title if won else texts.lost_title,Vector2(324,160),44)
 UI.label(screen,texts.subtitle,Vector2(326,226),19,UI.MUTED)
 var rule=ColorRect.new()
 rule.color=Color(tone,0.35)
 rule.position=Vector2(326,268)
 rule.size=Vector2(620,1)
 screen.add_child(rule)
 if won:
  for tile in [["XP","+"+str(reward.xp),Color("bd95ff"),326],["GOLD","+"+str(reward.gold),UI.GOLD,646]]:
   UI.panel(screen,Rect2(tile[3],286,300,90),Color(0.04,0.05,0.11,0.95),Color(tile[2],0.6))
   UI.label(screen,tile[0],Vector2(tile[3]+18,298),13,tile[2])
   UI.label(screen,tile[1],Vector2(tile[3]+18,320),40,Color.WHITE)
 else:
  UI.label(screen,"No rewards earned. Energy was used on entry.",Vector2(326,300),24,UI.GOLD,620)
 UI.label(screen,"LEVEL "+str(Profile.data.level),Vector2(326,396),25)
 if reward.levels>0:
  UI.chip(screen,"LEVEL UP",Rect2(456,399,104,26),UI.GOLD,13)
 var xp=UI.hud_bar(screen,Rect2(326,436,620,18),UI.VIOLET,Progression.required(int(Profile.data.level)))
 xp.value=Profile.data.xp
 xp.ghost=Profile.data.xp
 xp.readout=str(Profile.data.xp)+" / "+str(Progression.required(int(Profile.data.level)))+" XP"
 xp.readout_size=13
 UI.label(screen,"Progress saved locally" if Profile.save_ok else "Save failed — check device storage",Vector2(326,484),15,UI.MUTED if Profile.save_ok else Color("ff7188"))
 var teaser=MissionDefs.get_def(reward.id).ending.teaser
 if won and MissionDefs.get_def(reward.id).get("flow","district")=="lantern":
  UI.chip(screen,"CODEX  /  HOLLOW CANTOR",Rect2(584,399,214,26),UI.VIOLET,13)
  UI.button(screen,"NEXT EPISODE",Rect2(325,535,280,65),func(): show_teaser(teaser),true)
 else:
  UI.button(screen,"HOME",Rect2(325,535,280,65),show_home)
 if MissionDefs.get_def(reward.id).battle_only_waves.is_empty():
  # Story-only missions have no standalone battle: return to the open breach (the energy is charged again on entry).
  UI.button(screen,"RETURN TO THE BREACH  /  %d ENERGY" % MissionDefs.energy_cost(reward.id),Rect2(630,535,316,65),func(): start_episode(reward.id),not won)
 else:
  UI.button(screen,"REPLAY BATTLE  /  6 ENERGY",Rect2(630,535,316,65),func(): start_battle(false,reward.id),true)
func show_hero() -> void:
 var node=new_modal("THE UNBOUND","OWNED  /  COMMON  /  ECHO STRIKER")
 var rig=Fighter.new()
 rig.body=Profile.data.body
 rig.load_sprite_set("res://assets/characters/hero/frames.tres",170.0,Color("4aa3ff"))
 rig.position=Vector2(401,414)
 rig.scale=Vector2(1.3,1.3)
 node.add_child(rig)
 var stats=HeroData.stats(int(Profile.data.level))
 UI.label(node,"LEVEL "+str(Profile.data.level)+"   /   POWER "+str(HeroData.power(int(Profile.data.level))),Vector2(530,205),22,UI.GOLD)
 UI.label(node,"Health     "+str(stats.health)+"
Attack     "+str(stats.attack)+"
Defense    "+str(stats.defense)+"
Speed      "+str(stats.speed)+"
Critical   12% / 160%",Vector2(530,250),22,Color("cbd0e2"))
 UI.label(node,"A quiet Aether signature with limitless evolutionary potential.",Vector2(294,464),19,UI.MUTED,680)
 UI.label(node,"Gear, stars and transformations arrive in later episodes.",Vector2(294,520),14,UI.MUTED,680)
 UI.button(node,"TURN",Rect2(294,568,110,58),func(): rig.facing*=-1)
 UI.button(node,"AETHER POSE",Rect2(416,568,210,58),func(): rig.swing=1.0;rig.invincible=1.0;Sound.play("special"))
 UI.button(node,"CODEX",Rect2(638,568,170,58),show_codex)
func show_codex() -> void:
 # Entries that belong to a locked episode stay hidden, so a fresh save shows only the Episode 1 entries.
 var entries=[]
 for entry in EpisodeData.CODEX:
  var source=MissionDefs.mission_for_codex(entry.id)
  if entry.get("secret",false) and not Profile.data.codex.has(entry.id):
   continue
  if source.is_empty() or MissionDefs.is_unlocked(source.id,Profile.data.completed):
   entries.append(entry)
 var node=new_modal("CODEX","STORY AND WORLD ENTRIES  /  "+str(Profile.data.codex.size())+" OF "+str(entries.size())+" FOUND")
 var wide=entries.size()>6
 for i in range(entries.size()):
  var entry=entries[i]
  var found=Profile.data.codex.has(entry.id)
  var rows=4 if entries.size()>9 else 3
  var col=i/rows
  var row=i%rows
  var x=294+col*(236 if wide else 350)
  var y=200+row*(92 if rows==4 else 118)
  var width=224 if wide else 330
  UI.label(node,entry.title if found else "UNDISCOVERED",Vector2(x,y),17,UI.GOLD if found else Color("68738c"),width)
  var source=MissionDefs.mission_for_codex(entry.id)
  UI.label(node,entry.text if found else "Explore Episode %d to uncover this entry." % int(source.get("episode",1)),Vector2(x,y+26),13,Color("cbd0e2") if found else Color("68738c"),width)
func show_upgrade() -> void:
 var node=new_modal("GROW YOUR AETHER","LEVELS INCREASE YOUR COMBAT STATS")
 UI.label(node,"Level "+str(Profile.data.level)+"   →   "+str(mini(100,Profile.data.level+1)),Vector2(294,221),37,UI.GOLD)
 UI.label(node,"Earn XP by completing the first story mission. Every level adds 24 health, 3 attack and 2 defense.",Vector2(294,292),24,UI.MUTED,666)
 var xp=UI.bar(node,Rect2(294,407,660,17),UI.VIOLET,Progression.required(int(Profile.data.level)))
 xp.value=Profile.data.xp
 UI.label(node,str(Profile.data.xp)+" / "+str(Progression.required(int(Profile.data.level)))+" XP",Vector2(294,441),20)
 UI.label(node,"Gear and skill material upgrades arrive in later episodes.",Vector2(294,500),17,UI.MUTED,674)
func show_missions() -> void:
 var chapter=MissionDefs.get_def("1-1")
 var sub=chapter.missions_sub
 if MissionDefs.is_playable("1-2") and MissionDefs.is_unlocked("1-2",Profile.data.completed):
  sub="CHAPTER 01  /  EPISODES 1 AND 2 PLAYABLE"
 var node=new_modal(chapter.region,sub)
 var story=MissionData.story()
 for i in range(10):
  var mission=story[i]
  var col=i/5
  var row=i%5
  var title=mission.id+"  "+mission.title
  UI.label(node,title,Vector2(294+col*350,208+row*63),16,Color.WHITE if i==0 else UI.MUTED,320)
  UI.label(node,mission_status(mission.id),Vector2(294+col*350,233+row*63),13,UI.GOLD if i==0 else Color("68738c"))
 UI.button(node,"PLAY EPISODE 1",Rect2(294,568,240,58),func(): show_mission("1-1"),true)
 if MissionDefs.is_playable("1-2") and MissionDefs.is_unlocked("1-2",Profile.data.completed):
  UI.button(node,"PLAY EPISODE 2",Rect2(544,568,240,58),func(): show_mission("1-2"),true)
func mission_status(id:String) -> String:
 var d=MissionDefs.get_def(id)
 if d.is_empty():
  return "PLANNED"
 if Profile.data.completed.has(id):
  return "CLEARED · REPLAY AVAILABLE"
 if d.playable and MissionDefs.is_unlocked(id,Profile.data.completed):
  return d.number+" · PLAYABLE"
 return d.number+" · UP NEXT"
func show_settings() -> void:
 var node=new_modal("SETTINGS","SAVED ON THIS DEVICE")
 var options=[["sound","Sound effects"],["shake","Screen shake"],["reduced_motion","Reduced background motion"]]
 for i in range(options.size()):
  var key=options[i][0]
  var check=CheckButton.new()
  check.text=options[i][1]
  check.position=Vector2(294,211+i*79)
  check.size=Vector2(648,64)
  check.add_theme_font_size_override("font_size",23)
  check.button_pressed=Profile.data.settings.get(key,false)
  node.add_child(check)
  check.toggled.connect(func(value): Profile.data.settings[key]=value;Profile.persist())
 UI.label(node,"Saved on this device with a backup copy.
No analytics, ads or payment services are connected.",Vector2(294,478),17,UI.MUTED,676)
func onboarding() -> void:
 var node=new_modal("YOUR SIGNAL HAS AWAKENED","SOUL ASCENSION  /  THE FIRST FRACTURE")
 # The onboarding panel cannot be dismissed before choosing an identity.
 for child in node.get_children():
  if child is Button: child.queue_free()
 UI.label(node,"Aether changed the world. Yours barely registers.
Tonight, the city will learn what that means.",Vector2(294,198),23,Color("cbd0e2"),680)
 UI.label(node,"CHOOSE YOUR NAME",Vector2(294,306),14,UI.GOLD)
 var field=LineEdit.new()
 field.position=Vector2(294,334)
 field.size=Vector2(652,56)
 field.max_length=18
 field.text="Ascendant"
 field.add_theme_font_size_override("font_size",24)
 node.add_child(field)
 UI.button(node,"BEGIN YOUR AWAKENING",Rect2(294,440,652,80),func():
  var chosen=field.text.strip_edges()
  Profile.data.name="Ascendant" if chosen.is_empty() else chosen
  Profile.data.body="male"
  Profile.data.onboarded=true
  Profile.persist()
  show_home()
  show_mission()
 ,true)
