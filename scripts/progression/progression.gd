extends RefCounted
class_name Progression
static func required(level:int) -> int:
 return 100+(level-1)*65
static func grant(profile:Dictionary, amount:int) -> int:
 var before=int(profile.level)
 profile.xp=int(profile.xp)+maxi(0,amount)
 while profile.level < 100 and profile.xp >= required(int(profile.level)):
  profile.xp-=required(int(profile.level))
  profile.level+=1
 if profile.level==100:
  profile.xp=0
 return int(profile.level)-before
