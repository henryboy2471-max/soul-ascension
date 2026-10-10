extends RefCounted
class_name Ledger
# Append-only currency ledger (design + test data). State lives in a plain Dictionary so it can be stored in the save later:
#   {"entries":[{id,ts,kind,currency,amount,source,ref}], "refs":{ref:true}}
# kinds: earn (free), spend, purchase (real-money grant), refund (reversal), restore (re-grant on a new device), grant (admin/test).
# Rules: amounts are signed integers; a ref (idempotency key) can be applied only once; balances never go negative through spend();
# a refund may leave a negative balance (a "debt") which blocks premium spending until repaid.
static func new_state() -> Dictionary:
 return {"entries":[],"refs":{}}
static func balance(state:Dictionary, currency:String) -> int:
 var total=0
 for e in state.entries:
  if e.currency==currency:
   total+=int(e.amount)
 return total
static func has_ref(state:Dictionary, ref:String) -> bool:
 return state.refs.has(ref)
static func _append(state:Dictionary, kind:String, currency:String, amount:int, source:String, ref:String, ts:int) -> bool:
 if ref!="" and state.refs.has(ref):
  return false
 state.entries.append({"id":state.entries.size()+1,"ts":ts,"kind":kind,"currency":currency,"amount":amount,"source":source,"ref":ref})
 if ref!="":
  state.refs[ref]=true
 return true
static func earn(state:Dictionary, currency:String, amount:int, source:String, ref:String="", ts:int=0) -> bool:
 if amount<=0 or not ShopCatalog.CURRENCIES.has(currency):
  return false
 return _append(state,"earn",currency,amount,source,ref,ts)
static func spend(state:Dictionary, currency:String, amount:int, source:String, ref:String="", ts:int=0) -> bool:
 if amount<=0 or not ShopCatalog.CURRENCIES.has(currency):
  return false
 if balance(state,currency)<amount:
  return false
 if debt(state)>0 and ShopCatalog.CURRENCIES[currency].premium:
  return false
 return _append(state,"spend",currency,-amount,source,ref,ts)
static func purchase(state:Dictionary, currency:String, amount:int, order_ref:String, ts:int=0) -> bool:
 # order_ref is the verified store order/purchase token hash; the same order can never grant twice
 if order_ref=="" or amount<=0:
  return false
 return _append(state,"purchase",currency,amount,"store:"+order_ref,"order:"+order_ref,ts)
static func refund(state:Dictionary, currency:String, amount:int, order_ref:String, ts:int=0) -> bool:
 if not has_ref(state,"order:"+order_ref) or amount<=0:
  return false
 return _append(state,"refund",currency,-amount,"refund:"+order_ref,"refund:"+order_ref,ts)
static func restore(state:Dictionary, currency:String, amount:int, order_ref:String, ts:int=0) -> bool:
 # a restore re-grants only if this device's ledger has never seen the order
 if order_ref=="" or amount<=0:
  return false
 return _append(state,"restore",currency,amount,"restore:"+order_ref,"order:"+order_ref,ts)
static func debt(state:Dictionary) -> int:
 var d=0
 for cur in ShopCatalog.CURRENCIES:
  var b=balance(state,cur)
  if b<0:
   d+=-b
 return d
