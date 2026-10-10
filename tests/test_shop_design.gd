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
 check(ShopCatalog.validate().is_empty(),"catalog validates: "+str(ShopCatalog.validate()))
 var packs=ShopCatalog.currency_packs()
 var want=[[150,2.99],[600,9.99],[1400,19.99],[3000,39.99],[6500,79.99],[10000,99.99]]
 var ok=packs.size()==6
 for i in range(mini(packs.size(),6)):
  ok=ok and int(packs[i].crystals)==want[i][0] and absf(float(packs[i].usd)-want[i][1])<0.001 and packs[i].live==false
 check(ok,"approved planning crystal packs, all non-live")
 var all_nonlive=true
 for it in ShopCatalog.items():
  all_nonlive=all_nonlive and it.live==false
 check(all_nonlive,"every catalog item is non-live")
 var s=ShopService.new(null)
 check(s.buy_pack("test.crystals.150").reason=="PAYMENTS_DISABLED","no backend: purchase refused")
 var s2=ShopService.new(MockBilling.new())
 var r=s2.buy_pack("test.crystals.600")
 check(r.ok and s2.balance("crystals")==600,"mock purchase credits crystals")
 check(Ledger.balance(s2.state.ledger,"gold")==0,"purchased crystals do not touch earned currencies")
 var order=r.order
 check(not Ledger.purchase(s2.state.ledger,"crystals",600,order),"duplicate order id rejected")
 check(s2.earn("gold",50,"mission:1-1","m11") and s2.balance("gold")==50,"earn credits gold once")
 check(not s2.earn("gold",50,"mission:1-1","m11"),"duplicate earn ref rejected")
 var rf=s2.billing.simulate_refund(order)
 var pr=s2.process_refunds()
 check(rf and pr.revoked.size()==1 and s2.balance("crystals")==0,"refund claws back crystals")
 check(s2.process_refunds().revoked.is_empty(),"refund processed once")
 var s3=ShopService.new(MockBilling.new())
 s3.buy_pack("test.crystals.150")
 var any=""
 for it in ShopCatalog.items():
  if it.category!="bundle" and it.price.has("crystals") and int(it.price.crystals)>s3.balance("crystals"):
   any=it.id
   break
 check(any!="" and not s3.buy_item(any,"crystals").ok,"cannot buy beyond balance")
 print("RESULT passed=%d failed=%d" % [passed,failed])
 quit(1 if failed>0 else 0)
