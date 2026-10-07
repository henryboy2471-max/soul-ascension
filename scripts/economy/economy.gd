extends RefCounted
class_name Economy
const MAX_ENERGY=120
const REGEN_SECONDS=300
static func regenerate(data:Dictionary, now:int) -> void:
 var stamp=int(data.energy_at)
 if now < stamp:
  data.energy_at=now
  return
 if data.energy>=MAX_ENERGY:
  data.energy_at=now
  return
 var ticks=int((now-stamp)/REGEN_SECONDS)
 if ticks>0:
  data.energy=mini(MAX_ENERGY,int(data.energy)+ticks)
  data.energy_at=now if data.energy==MAX_ENERGY else stamp+ticks*REGEN_SECONDS
static func spend(data:Dictionary, currency:String, amount:int) -> bool:
 if currency not in ["gold","crystals","energy"] or amount<0 or int(data.get(currency,0))<amount:
  return false
 data[currency]=int(data[currency])-amount
 return true
