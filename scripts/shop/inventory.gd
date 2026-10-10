extends RefCounted
class_name Inventory
# Owned cosmetics and equipped loadout (design + test data). State: {"owned":{item_id:{"source":..,"ref":..}}, "equipped":{"echo":{"skin":id,...}}, "companion":id}
static func new_state() -> Dictionary:
 return {"owned":{},"equipped":{},"companion":""}
static func owns(state:Dictionary, id:String) -> bool:
 return state.owned.has(id)
static func grant(state:Dictionary, id:String, source:String, ref:String="") -> bool:
 if ShopCatalog.item(id).is_empty() or state.owned.has(id):
  return false
 state.owned[id]={"source":source,"ref":ref}
 return true
static func revoke_by_ref(state:Dictionary, ref:String) -> Array:
 # refund: remove every item granted by that purchase reference and unequip it
 var removed=[]
 for id in state.owned.keys():
  if state.owned[id].ref==ref:
   state.owned.erase(id)
   removed.append(id)
   for ch in state.equipped:
    for slot in state.equipped[ch].keys():
     if state.equipped[ch][slot]==id:
      state.equipped[ch].erase(slot)
   if state.companion==id:
    state.companion=""
 return removed
static func equip(state:Dictionary, id:String) -> bool:
 if not state.owned.has(id):
  return false
 var it=ShopCatalog.item(id)
 if it.category=="bundle":
  return false
 if it.category=="companion":
  state.companion=id
  return true
 var ch=str(it.character)
 if ch=="any":
  return false
 if not state.equipped.has(ch):
  state.equipped[ch]={}
 state.equipped[ch][str(it.category)]=id
 return true
