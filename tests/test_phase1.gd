extends SceneTree
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
func run() -> void:
 var profile=root.get_node("Profile")
 profile.data=profile.defaults()
 profile.active_run=""
 profile.data.settings.sound=false
 var sample=profile.defaults()
 check(Progression.grant(sample,120)==1 and sample.level==2 and sample.xp==20,"XP levels and carries remainder")
 check(Progression.grant(sample,400)==2 and sample.level==4 and sample.xp==25,"Multiple levels in one grant")
 var wallet=profile.defaults()
 check(not Economy.spend(wallet,"gold",-5) and wallet.gold==500,"Reject negative spend")
 check(not Economy.spend(wallet,"crystals",1) and wallet.crystals==0,"Reject overdraft")
 wallet.energy=50
 wallet.energy_at=1000
 Economy.regenerate(wallet,1901)
 check(wallet.energy==53 and wallet.energy_at==1900,"Energy offline regeneration keeps remainder")
 Economy.regenerate(wallet,999999)
 check(wallet.energy==120,"Energy regeneration cap")
 wallet.energy=40
 wallet.energy_at=5000
 Economy.regenerate(wallet,2000)
 check(wallet.energy==40 and wallet.energy_at==2000,"Backward clock does not grant energy")
 var storage=LocalSave.new()
 var path="user://isolated_test.json"
 for suffix in ["",".bak",".tmp"]:
  DirAccess.remove_absolute(path+suffix)
 check(storage.write_data(sample,path),"Atomic local save")
 check(storage.read_data(path).level==4,"Save/load round trip")
 sample.level=5
 storage.write_data(sample,path)
 var broken=FileAccess.open(path,FileAccess.WRITE)
 broken.store_string("corrupted")
 broken.close()
 check(storage.read_data(path).level==4,"Corrupt primary recovers backup")
 check(profile.begin_run("1-1") and profile.data.energy==54,"Mission entry spends energy once")
 check(not profile.begin_run("1-1") and profile.data.energy==54,"Reject concurrent mission")
 var reward=profile.finish_run(true)
 check(reward.xp==120 and reward.gold==250 and profile.data.level==2,"First clear rewards and level up")
 check(profile.finish_run(true).is_empty() and profile.data.gold==750,"Cannot duplicate settlement")
 profile.begin_run("1-1")
 reward=profile.finish_run(true)
 check(reward.xp==55 and reward.gold==100,"Replay uses repeat rewards")
 profile.begin_run("1-1")
 reward=profile.finish_run(false)
 check(reward.xp==0 and reward.gold==0,"Loss awards no rewards")
 profile.data.energy=0
 check(not profile.begin_run("1-1"),"Mission rejects insufficient energy")
 profile.data.energy=60
 var main=load("res://scenes/main.tscn").instantiate()
 root.add_child(main)
 await process_frame
 main.close_modal()
 for method in ["show_hero","show_upgrade","show_missions","show_settings","show_mission"]:
  main.call(method)
  await process_frame
  check(is_instance_valid(main.modal),"Screen opens: "+method)
  main.close_modal()
 main.start_battle()
 await process_frame
 var battle=main.screen.get_child(0)
 battle.intro=0
 battle.set_process(false)
 battle.foe.set_process(false)
 battle.hero.set_process(false)
 battle.hero.position=Vector2(500,450)
 battle.foe.position=Vector2(600,450)
 var start_hp=battle.foe.health
 battle.act("attack")
 check(battle.foe.health<start_hp and battle.combo==1,"Basic attack deals damage and starts combo")
 start_hp=battle.foe.health
 battle.act("attack")
 check(battle.foe.health==start_hp,"Attack cooldown prevents immediate repeat")
 battle.hero.blocking=true
 start_hp=battle.hero.health
 battle.hero.receive(28)
 check(start_hp-battle.hero.health<=6,"Block reduces incoming damage")
 battle.act("dodge")
 start_hp=battle.hero.health
 battle.hero.receive(28)
 check(battle.hero.health==start_hp,"Dodge grants invulnerability")
 battle.hero.position=Vector2(500,450)
 battle.act("pulse")
 check(battle.foe.stun>0 and battle.energy<100,"Special uses energy and staggers")
 battle.hero.health=100
 battle.act("mend")
 check(battle.hero.health==170,"Mend restores health")
 battle.ultimate=100
 battle.act("ultimate")
 check(battle.ultimate==0 and battle.ultimate_title.text!="","Ultimate consumes charge and animates")
 # Simultaneous touch IDs: movement and attack must be independent.
 var touch=InputEventScreenTouch.new()
 touch.index=1;touch.pressed=true;touch.position=Vector2(168,605)
 battle.stick._input(touch)
 touch=InputEventScreenTouch.new()
 touch.index=2;touch.pressed=true;touch.position=Vector2(1095,660)
 battle.controls.attack._input(touch)
 check(battle.stick.direction.length()>0 and battle.controls.attack.held,"Multitouch movement and attack")
 touch.pressed=false
 battle.controls.attack._input(touch)
 check(not battle.controls.attack.held and battle.stick.direction.length()>0,"Release attack preserves movement touch")
 battle.foe.health=1
 battle.foe.invincible=0
 battle.foe.receive(10000)
 await create_timer(0.9).timeout
 check(main.scene_name=="result" and profile.active_run=="","Victory reaches result and settles mission")
 main.show_home()
 main.start_battle()
 await process_frame
 battle=main.screen.get_child(0)
 battle.hero.invincible=0
 battle.hero.receive(10000)
 await create_timer(0.9).timeout
 check(main.scene_name=="result" and profile.active_run=="","Defeat reaches result and settles mission")
 check(profile.backend.read_data().level==profile.data.level,"Progression survives save reload")
 main.queue_free()
 for suffix in ["",".bak",".tmp"]:
  DirAccess.remove_absolute(path+suffix)
 print("RESULT: %d passed / %d failed" % [passed,failed])
 quit(1 if failed else 0)
