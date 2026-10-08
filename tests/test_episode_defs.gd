extends SceneTree
# M1 regression: Episode 1 is unchanged after its hard-coded values moved into MissionDefs, and mission 1-2 (unlock + rewards) works as data.
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
 create_timer(150.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func run() -> void:
 var profile=root.get_node("Profile")
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 # --- Episode 1 trace must equal the trace recorded from the locked commit 80f54c3 ---
 var golden=JSON.parse_string(FileAccess.get_file_as_string("res://tests/golden/episode1_trace.json"))
 var tracer=load("res://tests/support/episode1_trace.gd").new()
 var trace=await tracer.run(root,main)
 var first_diff=-1
 for i in range(mini(trace.size(),golden.size())):
  if trace[i]!=golden[i]:
   first_diff=i
   break
 if first_diff>=0:
  print("INFO: first difference at event %d\n  golden: %s\n  now:    %s" % [first_diff,str(golden[first_diff]).substr(0,300),str(trace[first_diff]).substr(0,300)])
 check(trace.size()==golden.size() and first_diff<0,"Episode 1 story order, dialogue, objectives, cards, waves, Phase 2, ending, teaser and menu texts match the locked commit (%d events)" % golden.size())
 var joined="\n".join(trace)
 check(joined.contains("EPISODE 2  /  UNDER THE VIOLET RAIN | TO BE CONTINUED..."),"The ending still shows the Episode 2 teaser card")
 check(joined.contains("+120 | GOLD | +250") and joined.contains("REWARD gold=750"),"First clear pays 120 XP / 250 gold")
 check(joined.contains("REPLAY-REWARD gold+=100 xp+=55 completed=[\"1-1\"]"),"Replay pays 55 XP / 100 gold and does not repeat the first clear")
 main.queue_free()
 await process_frame
 # --- definitions ---
 var d=MissionDefs.get_def("1-1")
 check(d.rewards.first.xp==120 and d.rewards.first.gold==250 and d.rewards.replay.xp==55 and d.rewards.replay.gold==100 and d.energy==6,"1-1 reward and energy data")
 check(d.objectives.map(func(o): return o.text)==["Find Mira Vey at the tram","Reboot the relay terminal","Enter the Soul Realm breach"],"1-1 objectives keep their order")
 check(d.waves.size()==2 and d.waves[0].look=="shade" and d.waves[1].look=="warped" and d.waves[1].boss and d.battle_only_waves.size()==1,"1-1 wave definitions: Shade, boss Enforcer, plus the battle-only wave")
 check(d.ending.lines==EpisodeData.OUTRO and d.ending.teaser.title=="UNDER THE VIOLET RAIN","1-1 ending lines and teaser")
 check(d.codex==["mira","board","mural","terminal","breach","enforcer"],"1-1 Codex ids")
 # --- mission 1-2: unlock condition and reward data ---
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.settings.sound=false
 var m2=MissionDefs.get_def("1-2")
 check(not m2.is_empty() and m2.title=="UNDER THE VIOLET RAIN" and m2.unlock.requires==["1-1"] and not m2.playable,"1-2 is defined, requires 1-1 and has no scenes yet (not playable)")
 check(m2.rewards.first.xp==150 and m2.rewards.first.gold==300 and m2.rewards.replay.xp==65 and m2.rewards.replay.gold==120,"1-2 reward data")
 check(not MissionDefs.is_unlocked("1-2",profile.data.completed) and MissionDefs.is_unlocked("1-1",profile.data.completed),"1-2 is locked on a fresh save, 1-1 is open")
 var energy0=int(profile.data.energy)
 check(not profile.begin_run("1-2") and int(profile.data.energy)==energy0 and profile.active_run=="","A locked mission cannot be started and costs no energy")
 check(not profile.begin_run("9-9") and not MissionDefs.has_mission("9-9"),"An unknown mission id is rejected")
 profile.begin_run("1-1")
 profile.finish_run(true)
 check(MissionDefs.is_unlocked("1-2",profile.data.completed),"Clearing 1-1 unlocks 1-2")
 profile.data.energy=60
 var gold0=int(profile.data.gold)
 check(profile.begin_run("1-2") and int(profile.data.energy)==54,"1-2 starts once unlocked and spends 6 energy")
 var first=profile.finish_run(true)
 check(first.id=="1-2" and first.first and first.xp==150 and first.gold==300 and int(profile.data.gold)==gold0+300,"1-2 first clear pays 150 XP / 300 gold")
 profile.data.energy=60
 profile.begin_run("1-2")
 var replay=profile.finish_run(true)
 check(not replay.first and replay.xp==65 and replay.gold==120,"1-2 replay pays 65 XP / 120 gold")
 check(profile.data.completed==["1-1","1-2"],"Both missions are recorded once each")
 profile.data.energy=60
 profile.begin_run("1-1")
 var again=profile.finish_run(true)
 check(not again.first and again.xp==55 and again.gold==100,"1-1 rewards are unaffected by 1-2")
 check(profile.backend.write_data(profile.data) and profile.backend.read_data().completed==["1-1","1-2"],"A save containing 1-2 writes and reads back (no save-format change)")
 # --- UI reads the data: 1-2 shows as the next episode but is not offered ---
 profile.data.completed=["1-1"]
 main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 check(main.home_mission()=="1-1" and main.mission_status("1-1")=="CLEARED · REPLAY AVAILABLE" and main.mission_status("1-2")=="EPISODE 2 · UP NEXT" and main.mission_status("1-3")=="PLANNED","Missions screen status: 1-1 cleared, 1-2 up next, 1-3 planned")
 var story=MissionData.story()
 check(story.size()==10 and story[0].title=="A spark in the static" and story[1].title=="Under the violet rain" and story[2].title=="The relay keeper","The mission list keeps its titles")
 main.queue_free()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
