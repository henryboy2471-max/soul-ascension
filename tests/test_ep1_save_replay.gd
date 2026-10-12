extends SceneTree
# Episode 1 saves, first-clear vs replay rewards, settings persistence and sound gating (headless; sound is checked by state, not by ear).
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
 create_timer(60.0).timeout.connect(func(): print("FAIL: test timed out");quit(2))
func run() -> void:
 var profile=root.get_node("Profile")
 var snd=root.get_node("Sound")
 profile.data=profile.defaults()
 profile.data.onboarded=true
 profile.data.energy=60
 profile.persist()
 var def=MissionDefs.get_def("1-1")
 var first=MissionDefs.reward("1-1",true)
 var replay=MissionDefs.reward("1-1",false)
 check(first.gold>replay.gold and first.xp>replay.xp and replay.gold>0,"Replay rewards are smaller than first-clear rewards but not zero (%d/%d vs %d/%d)" % [first.xp,first.gold,replay.xp,replay.gold])
 # first clear
 var gold0=int(profile.data.gold)
 var energy0=int(profile.data.energy)
 check(profile.begin_run("1-1") and int(profile.data.energy)==energy0-MissionDefs.energy_cost("1-1"),"Starting Episode 1 spends its energy once")
 var r1=profile.finish_run(true)
 check(r1.first and int(profile.data.gold)==gold0+first.gold and profile.data.completed.has("1-1"),"First clear pays first-clear rewards and records completion")
 var saved=profile.backend.read_data()
 check(saved.get("completed",[]).has("1-1") and int(saved.get("gold",0))==gold0+first.gold,"Completion and gold are written to the save")
 # replay
 var gold1=int(profile.data.gold)
 check(profile.begin_run("1-1"),"Episode 1 can be replayed")
 var r2=profile.finish_run(true)
 check(not r2.first and int(profile.data.gold)==gold1+replay.gold and profile.data.completed.count("1-1")==1,"Replay pays replay rewards and does not duplicate completion")
 # defeat: no rewards, run closed
 var gold2=int(profile.data.gold)
 profile.begin_run("1-1")
 var r3=profile.finish_run(false)
 check(int(profile.data.gold)==gold2 and r3.xp==0 and profile.active_run=="","A lost battle pays nothing and closes the run")
 check(profile.finish_run(true).is_empty(),"finish_run with no active run is a no-op (no double rewards)")
 # no energy
 profile.data.energy=0
 check(not profile.begin_run("1-1") and profile.active_run=="","Without energy the run does not start")
 # settings persistence
 profile.data.settings.sound=false
 profile.data.settings.shake=false
 profile.persist()
 var reread=profile.backend.read_data()
 check(reread.settings.sound==false and reread.settings.shake==false,"Settings are saved")
 snd.loop("city")
 check(not snd.loop_player.playing,"Sound off: the ambience loop does not play")
 snd.play("tap")
 snd.footstep("wet")
 check(true,"Sound off: effects and footsteps return without error")
 profile.data.settings.sound=true
 snd.loop("city")
 check(snd.loop_player.playing and snd.loops.has("city") and snd.step_clips.has("wet"),"Sound on: ambience loop plays and footstep clips exist")
 snd.stop_loop()
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
