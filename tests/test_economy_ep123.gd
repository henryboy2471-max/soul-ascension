extends SceneTree
# Economy assessment pins (docs/episodes/episode-03/ECONOMY_ASSESSMENT.md): Episode 3's PROVISIONAL rewards against Episodes 1-2 on the intended path. Pure data, no autoloads.
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
 var ids=["1-1","1-2","1-3"]
 var first=[]
 var replay=[]
 for id in ids:
  first.append(MissionDefs.reward(id,true))
  replay.append(MissionDefs.reward(id,false))
 check(first[0].xp==120 and first[0].gold==250 and first[1].xp==150 and first[1].gold==300 and first[2].xp==180 and first[2].gold==340,"First-clear rewards are 120/250, 150/300 and (provisional) 180/340")
 check(replay[0].xp==55 and replay[1].xp==65 and replay[2].xp==80 and replay[0].gold==100 and replay[1].gold==120 and replay[2].gold==150,"Replay rewards are 55/100, 65/120 and (provisional) 80/150")
 check(first[0].xp<first[1].xp and first[1].xp<first[2].xp and first[0].gold<first[1].gold and first[1].gold<first[2].gold,"Rewards rise with each episode")
 check(first[1].xp-first[0].xp==first[2].xp-first[1].xp,"XP steps up by the same 30 each episode")
 var ratios_ok=true
 for i in range(3):
  var rx=float(replay[i].xp)/float(first[i].xp)
  var rg=float(replay[i].gold)/float(first[i].gold)
  if rx<0.40 or rx>0.50 or rg<0.38 or rg>0.46: ratios_ok=false
 check(ratios_ok,"Replay pays 40-50% of the first-clear XP and 38-46% of the gold in every episode (Episode 3: 44% and 44%)")
 check(bool(MissionDefs.get_def("1-3").rewards.get("provisional",false)) and not MissionDefs.get_def("1-1").rewards.has("provisional") and not MissionDefs.get_def("1-2").rewards.has("provisional"),"Only Episode 3's rewards are flagged provisional")
 # the intended path: clear 1-1, 1-2, 1-3 in order on a fresh profile
 var p={"level":1,"xp":0}
 var gold=500
 var levels=[]
 for i in range(3):
  Progression.grant(p,int(first[i].xp))
  gold+=int(first[i].gold)
  levels.append([int(p.level),int(p.xp)])
 check(levels[0]==[2,20] and levels[1]==[3,5] and levels[2]==[3,185],"On the intended path the levels are 2 (20 XP) after 1-1, 3 (5 XP) after 1-2, and still 3 (185 of 230 XP) after 1-3: Episode 3 does not itself level the player up")
 check(gold==1390,"Gold after all three first clears is 500 + 250 + 300 + 340 = 1390")
 check(Progression.required(3)==230 and Progression.required(4)==295,"XP to level: 230 at level 3, 295 at level 4")
 var q={"level":3,"xp":185}
 Progression.grant(q,int(replay[2].xp)*2)
 check(int(q.level)==4 and int(q.xp)==115,"Two Episode 3 replays (160 XP) from 185/230 reach level 4 with 115 XP")
 # energy: the boss battles of 1-1 and 1-2 cost 6; the Episode 3 run costs nothing, so its replay is not limited by energy
 check(MissionDefs.energy_cost("1-1")==6 and MissionDefs.energy_cost("1-2")==6 and MissionDefs.energy_cost("1-3")==0,"Energy: 1-1 and 1-2 cost 6, 1-3 costs 0 (its replay is not energy-gated)")
 var d={"energy":120,"energy_at":0}
 check(Economy.REGEN_SECONDS==300 and Economy.MAX_ENERGY==120,"Energy regenerates 1 per 300 s up to 120")
 print("RESULT: %d passed, %d failed" % [passed,failed])
 quit(1 if failed>0 else 0)
