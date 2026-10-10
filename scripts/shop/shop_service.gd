extends RefCounted
class_name ShopService
# Orchestrates ledger + inventory + season pass + billing (design, TEST DATA). PAYMENTS_ENABLED stays false until the owner approves a live
# release: while false, only a billing backend that declares IS_MOCK = true can be used and every product is a non-live test product.
const PAYMENTS_ENABLED = false
var state:Dictionary={"ledger":Ledger.new_state(),"inventory":Inventory.new_state(),"pass":{"xp":0,"premium":false,"order":"","sku":"","claimed_free":[],"claimed_premium":[]}}
var billing
func _init(backend=null) -> void:
 billing=backend
func backend_allowed() -> bool:
 if billing==null:
  return false
 var mock=bool(billing.get("IS_MOCK")) if billing.get("IS_MOCK")!=null else false
 return mock or PAYMENTS_ENABLED
func balance(currency:String) -> int:
 return Ledger.balance(state.ledger,currency)
func earn(currency:String, amount:int, source:String, ref:String="") -> bool:
 return Ledger.earn(state.ledger,currency,amount,source,ref)
# Buy a cosmetic with in-game currency (free route or Soul Crystals). Returns {ok, reason}.
func buy_item(id:String, currency:String) -> Dictionary:
 var it=ShopCatalog.item(id)
 if it.is_empty():
  return {"ok":false,"reason":"UNKNOWN_ITEM"}
 if Inventory.owns(state.inventory,id):
  return {"ok":false,"reason":"ALREADY_OWNED"}
 var price:Dictionary=it.price
 var amount=0
 if price.has(currency):
  amount=int(price[currency])
 elif it.free_route.has(currency):
  amount=int(it.free_route[currency])
 else:
  return {"ok":false,"reason":"WRONG_CURRENCY"}
 if not Ledger.spend(state.ledger,currency,amount,"item:"+id,"buy:"+id):
  return {"ok":false,"reason":"INSUFFICIENT_FUNDS_OR_DEBT"}
 Inventory.grant(state.inventory,id,"currency:"+currency,"buy:"+id)
 if it.category=="bundle":
  for c in it.contents:
   Inventory.grant(state.inventory,c,"bundle:"+id,"buy:"+id)
 return {"ok":true,"reason":""}
# Buy a Soul Crystal pack through billing: purchase -> server verify -> ledger grant -> acknowledge + consume.
func buy_pack(sku:String) -> Dictionary:
 if not backend_allowed():
  return {"ok":false,"reason":"PAYMENTS_DISABLED"}
 var pack=ShopCatalog.pack(sku)
 if pack.is_empty():
  return {"ok":false,"reason":"UNKNOWN_SKU"}
 var res=billing.launch_purchase(sku)
 if not res.ok:
  return {"ok":false,"reason":res.reason}
 var rec=res.purchase
 if not billing.verify(rec):
  return {"ok":false,"reason":"VERIFICATION_FAILED"}
 var amount=int(pack.crystals)+int(pack.get("bonus",0))
 if not Ledger.purchase(state.ledger,"crystals",amount,rec.order_id):
  return {"ok":false,"reason":"DUPLICATE_ORDER"}
 billing.acknowledge(rec.order_id)
 billing.consume(rec.order_id)
 return {"ok":true,"reason":"","order":rec.order_id,"crystals":amount}
func buy_season_pass(sku:String="test.pass.season1") -> Dictionary:
 if not backend_allowed():
  return {"ok":false,"reason":"PAYMENTS_DISABLED"}
 if state.pass.premium:
  return {"ok":false,"reason":"ALREADY_OWNED"}
 if ShopCatalog.pass_by_sku(sku).is_empty():
  return {"ok":false,"reason":"UNKNOWN_SKU"}
 var res=billing.launch_purchase(sku)
 if not res.ok:
  return {"ok":false,"reason":res.reason}
 if not billing.verify(res.purchase):
  return {"ok":false,"reason":"VERIFICATION_FAILED"}
 state.pass.premium=true
 state.pass.order=res.purchase.order_id
 state.pass.sku=sku
 for extra in ShopCatalog.pass_by_sku(sku).extra_items:
  Inventory.grant(state.inventory,extra,"pass:extra","pass:"+str(res.purchase.order_id))
 billing.acknowledge(res.purchase.order_id)
 return {"ok":true,"reason":"","order":res.purchase.order_id}
# New device / reinstall: re-grant the non-consumable season pass the store still reports. Consumed crystal packs are not re-granted.
func restore() -> Dictionary:
 if not backend_allowed():
  return {"ok":false,"restored":[],"reason":"PAYMENTS_DISABLED"}
 var restored=[]
 for p in billing.owned_purchases():
  if not ShopCatalog.pass_by_sku(p.sku).is_empty() and billing.verify(p) and not state.pass.premium:
   state.pass.premium=true
   state.pass.order=p.order_id
   state.pass.sku=p.sku
   for extra in ShopCatalog.pass_by_sku(p.sku).extra_items:
    Inventory.grant(state.inventory,extra,"pass:extra","pass:"+p.order_id)
   restored.append(p.sku)
 return {"ok":true,"restored":restored,"reason":""}
# Apply refunds the store reports (voided purchases): revoke pass benefits and claw back unspent crystals (may create a debt that blocks premium spending).
func process_refunds() -> Dictionary:
 var revoked=[]
 if not backend_allowed():
  return {"revoked":revoked}
 for v in billing.voided_purchases():
  if Ledger.has_ref(state.ledger,"refund:"+v.order_id):
   continue
  if not ShopCatalog.pass_by_sku(v.sku).is_empty():
   if state.pass.order==v.order_id:
    state.pass.premium=false
    state.pass.order=""
    state.pass.sku=""
    state.pass.claimed_premium=[]
    revoked+=Inventory.revoke_by_ref(state.inventory,"pass:"+v.order_id)
    revoked.append(v.sku)
  else:
   var pack=ShopCatalog.pack(v.sku)
   if not pack.is_empty() and Ledger.has_ref(state.ledger,"order:"+v.order_id):
    Ledger.refund(state.ledger,"crystals",int(pack.crystals)+int(pack.get("bonus",0)),v.order_id)
    revoked.append(v.sku)
 return {"revoked":revoked}
# --- season pass progression (xp comes from play, never from spending)
func add_pass_xp(amount:int) -> void:
 state.pass.xp=int(state.pass.xp)+maxi(0,amount)
func pass_tier() -> int:
 var tier=0
 var need=0
 for t in ShopCatalog.season_pass().tiers:
  need+=int(t.xp_needed)
  if int(state.pass.xp)>=need:
   tier=t.tier
 return tier
func claim_tier(tier:int, track:String) -> Dictionary:
 if tier<1 or tier>pass_tier():
  return {"ok":false,"reason":"TIER_NOT_REACHED"}
 if track=="premium" and not state.pass.premium:
  return {"ok":false,"reason":"PASS_REQUIRED"}
 var key="claimed_"+track
 if state.pass[key].has(tier):
  return {"ok":false,"reason":"ALREADY_CLAIMED"}
 var reward=ShopCatalog.season_pass().tiers[tier-1][track]
 for k in reward:
  if k=="item":
   Inventory.grant(state.inventory,reward[k],"pass:"+track,"pass:"+str(state.pass.order) if track=="premium" else "pass:free")
  else:
   Ledger.earn(state.ledger,k,int(reward[k]),"pass:%s:%d" % [track,tier],"pass:%s:%d" % [track,tier])
 state.pass[key].append(tier)
 return {"ok":true,"reason":""}
