extends RefCounted
class_name BattleSupport
# Reusable battle support helpers (an ally's signal lands on the Hero). Pure rules, no scene access:
# a defeated Hero is never revived and health never exceeds the maximum.
static func heal_amount(hero:Fighter, event:Dictionary) -> int:
 if hero.dead or hero.health<=0.0:
  return 0
 var wanted=float(event.get("heal_fixed",0.0))+float(event.get("heal_pct",0.0))*hero.max_health
 return maxi(0,int(minf(wanted,hero.max_health-hero.health)))
static func apply_heal(hero:Fighter, event:Dictionary) -> int:
 var amount=heal_amount(hero,event)
 if amount>0:
  hero.health=minf(hero.max_health,hero.health+amount)
 return amount
