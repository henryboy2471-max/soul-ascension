extends RefCounted
class_name MockBilling
# Simulated Google Play Billing + verification server for TEST DATA. It mirrors the real flow so the game-side logic can be built and tested
# without any payment backend: query products -> launch purchase (token + signature) -> server verify -> grant -> acknowledge/consume;
# restore = list unconsumed purchases; refund = a purchase becomes "voided". The real adapter will implement the same methods against
# GodotGooglePlayBilling + a server that calls the Google Play Developer API. This class never touches money or the network.
const IS_MOCK = true
const SECRET = "TEST-ONLY-SECRET"
var purchases:Array=[]
var counter=0
var failures:Array=[]   # queue of skus that should fail (to test errors)
func query_products() -> Array:
 var out=[]
 for p in ShopCatalog.currency_packs():
  out.append(p)
 for sp in ShopCatalog.season_passes():
  out.append({"sku":sp.sku,"name":sp.name,"display_price":sp.display_price,"live":false,"non_consumable":true})
 return out
func _sign(order_id:String, sku:String) -> String:
 return (order_id+"|"+sku+"|"+SECRET).sha256_text()
func launch_purchase(sku:String) -> Dictionary:
 if failures.has(sku):
  failures.erase(sku)
  return {"ok":false,"reason":"USER_CANCELED"}
 var known=not ShopCatalog.pack(sku).is_empty() or not ShopCatalog.pass_by_sku(sku).is_empty()
 if not known:
  return {"ok":false,"reason":"ITEM_UNAVAILABLE"}
 counter+=1
 var order_id="TEST.ORDER.%04d" % counter
 var rec={"order_id":order_id,"sku":sku,"state":"PURCHASED","consumed":false,"signature":_sign(order_id,sku)}
 purchases.append(rec)
 return {"ok":true,"purchase":rec.duplicate(true)}
# What the verification server does: checks the signature and that the order exists and is not voided.
func verify(purchase:Dictionary) -> bool:
 for p in purchases:
  if p.order_id==purchase.get("order_id","") and p.sku==purchase.get("sku","") and p.state!="REFUNDED":
   return purchase.get("signature","")==_sign(p.order_id,p.sku)
 return false
func acknowledge(order_id:String) -> bool:
 for p in purchases:
  if p.order_id==order_id and p.state=="PURCHASED":
   p.state="ACKNOWLEDGED"
   return true
 return false
func consume(order_id:String) -> bool:
 for p in purchases:
  if p.order_id==order_id and p.state=="ACKNOWLEDGED" and not p.consumed:
   p.consumed=true
   return true
 return false
# Restore: purchases the store still reports as owned (non-consumed, not refunded). Consumed crystal packs are not restorable by design.
func owned_purchases() -> Array:
 var out=[]
 for p in purchases:
  if p.state!="REFUNDED" and not p.consumed:
   out.append(p.duplicate(true))
 return out
func simulate_refund(order_id:String) -> bool:
 for p in purchases:
  if p.order_id==order_id and p.state!="REFUNDED":
   p.state="REFUNDED"
   return true
 return false
func voided_purchases() -> Array:
 var out=[]
 for p in purchases:
  if p.state=="REFUNDED":
   out.append(p.duplicate(true))
 return out
