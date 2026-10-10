extends Control
class_name ShopScreen
# SOUL SHOP (design prototype, TEST DATA ONLY): anime-themed chrome / violet / gold storefront. Every purchase goes through ShopService with
# MockBilling: no real money, no network. A permanent banner says so. Opened only from tests/captures until the owner approves integration.
signal closed
const CHROME = Color("c9d3ff")
const CHROME_LO = Color("6b7499")
const VIOLET = Color("7c4dff")
const VIOLET_DK = Color("1a0f3a")
const GOLD = Color("efce8e")
const RARITY = {"common":Color("9fb0d8"),"rare":Color("6fd7e4"),"epic":Color("bd95ff"),"legendary":Color("ffcf6e")}
const TABS = [["FEATURED","featured"],["SOUL CRYSTALS","crystals"],["OUTFITS & SKINS","outfits"],["TRANSFORMATIONS","transformation"],["COMPANIONS","companion"],["BUNDLES","bundle"],["SEASON PASS","pass"]]
var service
var tab="featured"
var selected=""
var content:Control
var detail:Control
var toast_label:Label
var time=0.0
func setup(svc) -> void:
 service=svc
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 if service==null:
  setup(demo_service())
 build()
static func demo_service():
 var svc=ShopService.new(MockBilling.new())
 svc.earn("gold",5200,"test grant")
 svc.earn("shards",2400,"test grant")
 svc.earn("crystals",700,"test grant")
 return svc
func _process(delta:float) -> void:
 time+=delta
 queue_redraw()
func _draw() -> void:
 # deep violet gradient with chrome light streaks and a gold hairline frame
 draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(1280,0),Vector2(1280,720),Vector2(0,720)]),PackedColorArray([Color("120a2a"),Color("1d1040"),Color("0b0620"),Color("0b0620")]))
 for i in range(6):
  var x=-200.0+i*320.0+fmod(time*8.0,320.0)
  draw_polygon(PackedVector2Array([Vector2(x,0),Vector2(x+70,0),Vector2(x-190,720),Vector2(x-260,720)]),PackedColorArray([Color(CHROME,0.0),Color(CHROME,0.05),Color(CHROME,0.0),Color(CHROME,0.0)]))
 for g in range(5):
  draw_circle(Vector2(900,230),380-g*60,Color(VIOLET,0.03+g*0.012))
 draw_rect(Rect2(10,10,1260,700),Color(GOLD,0.55),false,2)
 draw_rect(Rect2(16,16,1248,688),Color(CHROME,0.25),false,1)
func chrome_panel(rect:Rect2, accent:Color=CHROME) -> void:
 UI.panel(self,rect,Color(0.05,0.035,0.12,0.9),Color(accent,0.55))
 UI.trim(self,rect,GOLD)
func build() -> void:
 for c in get_children():
  c.queue_free()
 # header
 var title=UI.label(self,"SOUL SHOP",Vector2(44,26),40,GOLD,400)
 UI.outline(title,8)
 UI.label(self,"CHROME  ·  VIOLET  ·  GOLD",Vector2(48,74),13,Color(CHROME,0.7))
 var warn=UI.chip(self,"TEST DATA  ·  PAYMENTS DISABLED  ·  NO REAL PURCHASES",Rect2(430,32,430,30),Color("ff8597"),13)
 var x=886.0
 for cur in [["crystals","SOUL CRYSTALS",Color("bd95ff")],["shards","ECHO SHARDS",Color("6fd7e4")],["gold","GOLD",GOLD]]:
  UI.chip(self,"%s  %d" % [cur[1],service.balance(cur[0])],Rect2(x,30,128 if cur[0]!="crystals" else 150,32),cur[2],12)
  x+=134 if cur[0]!="crystals" else 156
 UI.button(self,"CLOSE",Rect2(1166,30,86,34),func(): closed.emit())
 # tabs
 var y=112.0
 for t in TABS:
  var b=UI.button(self,t[0],Rect2(34,y,210,46),func(): select_tab(t[1]),tab==t[1])
  y+=54.0
 content=Control.new()
 content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(content)
 detail=Control.new()
 detail.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(detail)
 toast_label=UI.label(self,"",Vector2(280,676),16,GOLD,720)
 toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 fill()
func select_tab(t:String) -> void:
 tab=t
 selected=""
 build()
func listing() -> Array:
 var out=[]
 match tab:
  "featured":
   for i in ShopCatalog.items():
    if i.rarity in ["legendary","epic"] and i.category!="flair":
     out.append({"kind":"item","id":i.id})
  "crystals":
   for p in ShopCatalog.currency_packs():
    out.append({"kind":"pack","id":p.sku})
  "outfits":
   for i in ShopCatalog.items():
    if i.category in ["outfit","skin","hairstyle","flair"]:
     out.append({"kind":"item","id":i.id})
  "transformation","companion","bundle":
   for i in ShopCatalog.items():
    if i.category==tab:
     out.append({"kind":"item","id":i.id})
  "pass":
   for p in ShopCatalog.season_passes():
    out.append({"kind":"pass","id":p.sku})
 return out
func fill() -> void:
 for c in content.get_children():
  c.queue_free()
 var list=listing()
 var cols=3
 for n in range(list.size()):
  var rect=Rect2(270+(n%cols)*232,112+(n/cols)*212,220,200)
  card(list[n],rect)
 if selected=="" and not list.is_empty():
  selected=str(list[0].id)
 show_detail()
func entry_info(e:Dictionary) -> Dictionary:
 match e.kind:
  "item":
   var it=ShopCatalog.item(e.id)
   return {"name":it.name,"rarity":it.rarity,"price":"%d  CRYSTALS" % int(it.price.get("crystals",0)) if it.price.has("crystals") else "%d  GOLD" % int(it.price.gold),"usd":("$%.2f" % float(it.usd)) if it.has("usd") else "FREE ROUTE","owned":Inventory.owns(service.state.inventory,it.id),"tag":str(it.category).to_upper()}
  "pack":
   var p=ShopCatalog.pack(e.id)
   return {"name":p.name,"rarity":"epic","price":"%d  SOUL CRYSTALS" % int(p.crystals),"usd":p.display_price,"owned":false,"tag":"CRYSTALS"}
  _:
   var sp=ShopCatalog.pass_by_sku(e.id)
   return {"name":sp.name,"rarity":"legendary" if "deluxe" in sp.id else "epic","price":"SEASON PASS","usd":sp.display_price,"owned":bool(service.state.pass.premium),"tag":"PASS"}
func card(e:Dictionary, rect:Rect2) -> void:
 var info=entry_info(e)
 var col:Color=RARITY.get(info.rarity,CHROME)
 var is_sel=str(e.id)==selected
 UI.panel(content,rect,Color(0.06,0.04,0.14,0.94),Color(col,0.9 if is_sel else 0.45))
 # preview art: rarity-coloured glow behind a stylised silhouette (placeholder for approved art)
 var art=Control.new()
 art.position=rect.position+Vector2(8,8)
 art.size=Vector2(204,104)
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 art.draw.connect(func():
  art.draw_polygon(PackedVector2Array([Vector2(0,0),Vector2(204,0),Vector2(204,104),Vector2(0,104)]),PackedColorArray([Color(col,0.35),Color(col,0.12),Color(0.03,0.02,0.1),Color(0.03,0.02,0.1)]))
  for g in range(4):
   art.draw_circle(Vector2(102,52),46-g*10,Color(col,0.06+g*0.05))
  match e.kind:
   "pack":
    for k in range(5):
     art.draw_colored_polygon(PackedVector2Array([Vector2(60+k*20,70),Vector2(70+k*20,40-k%2*8),Vector2(80+k*20,70),Vector2(70+k*20,86)]),Color(col,0.9))
   "pass":
    art.draw_arc(Vector2(102,56),34,0,TAU,40,Color(GOLD,0.9),4)
    art.draw_arc(Vector2(102,56),22,0,TAU,40,Color(CHROME,0.8),3)
   _:
    art.draw_circle(Vector2(102,34),16,Color(col,0.85))
    art.draw_colored_polygon(PackedVector2Array([Vector2(70,104),Vector2(80,56),Vector2(124,56),Vector2(134,104)]),Color(col,0.7))
  art.draw_rect(Rect2(0,0,204,104),Color(CHROME,0.35),false,1))
 content.add_child(art)
 UI.chip(content,str(info.tag),Rect2(rect.position.x+12,rect.position.y+12,86,22),col,11)
 UI.label(content,str(info.name),rect.position+Vector2(12,118),15,Color.WHITE,196)
 UI.label(content,str(info.price),rect.position+Vector2(12,160),14,GOLD,196)
 UI.label(content,("OWNED" if info.owned else str(info.usd)),rect.position+Vector2(130,160),13,Color("6fd7e4") if info.owned else CHROME,86)
 var b=Button.new()
 b.flat=true
 b.position=rect.position
 b.size=rect.size
 b.pressed.connect(func():
  selected=str(e.id)
  fill())
 content.add_child(b)
func show_detail() -> void:
 for c in detail.get_children():
  c.queue_free()
 var rect=Rect2(980,112,270,424)
 UI.panel(detail,rect,Color(0.05,0.035,0.12,0.94),Color(GOLD,0.6))
 UI.trim(detail,rect,CHROME)
 var e={}
 for l in listing():
  if str(l.id)==selected:
   e=l
 if e.is_empty():
  return
 var info=entry_info(e)
 UI.label(detail,str(info.name),Vector2(996,128),20,GOLD,238)
 UI.chip(detail,str(info.rarity).to_upper(),Rect2(996,196,100,24),RARITY.get(info.rarity,CHROME),12)
 var text=""
 var buttons=[]
 match e.kind:
  "item":
   var it=ShopCatalog.item(e.id)
   text=str(it.preview)+"\n\nCosmetic only: no stats, no power, no story access."
   if it.has("contents"):
    text+="\nContains: "+", ".join(it.contents.map(func(c): return ShopCatalog.item(c).name))
   if not info.owned:
    if it.price.has("crystals"):
     buttons.append(["BUY  ·  %d CRYSTALS" % int(it.price.crystals),func(): do_buy(e.id,"crystals")])
    if it.free_route.has("shards"):
     buttons.append(["EARN FREE  ·  %d SHARDS" % int(it.free_route.shards),func(): do_buy(e.id,"shards")])
    if it.price.has("gold"):
     buttons.append(["BUY  ·  %d GOLD" % int(it.price.gold),func(): do_buy(e.id,"gold")])
   elif it.category!="bundle":
    buttons.append(["EQUIP",func(): do_equip(e.id)])
  "pack":
   var p=ShopCatalog.pack(e.id)
   text="Soul Crystals are used for cosmetics only. Test purchase: nothing is charged.\n\nNo random rewards. The full story never requires a purchase."
   buttons.append(["TEST PURCHASE  ·  %s" % p.display_price,func(): do_pack(e.id)])
  _:
   var sp=ShopCatalog.pass_by_sku(e.id)
   text="One purchase for Season 1. Cosmetic rewards on a premium track; the free track is always available.\n\nXP comes from playing, never from spending. Does not unlock story or power."
   if not info.owned:
    buttons.append(["TEST PURCHASE  ·  %s" % sp.display_price,func(): do_pass(e.id)])
 UI.label(detail,text,Vector2(996,232),14,Color(CHROME,0.9),238)
 var y=470.0
 for bt in buttons:
  UI.button(detail,bt[0],Rect2(996,y,238,44),bt[1],y==470.0)
  y-=0.0
  y+=50.0 if y<500 else 0.0
func say(msg:String) -> void:
 if is_instance_valid(toast_label):
  toast_label.text=msg
func do_buy(id:String, currency:String) -> void:
 var r=service.buy_item(id,currency)
 say("PURCHASED" if r.ok else "CANNOT BUY  /  "+r.reason)
 build()
func do_equip(id:String) -> void:
 say("EQUIPPED" if Inventory.equip(service.state.inventory,id) else "CANNOT EQUIP")
 fill()
func do_pack(sku:String) -> void:
 var r=service.buy_pack(sku)
 say(("TEST PURCHASE OK  /  +%d CRYSTALS" % int(r.crystals)) if r.ok else "FAILED  /  "+r.reason)
 build()
func do_pass(sku:String) -> void:
 var r=service.buy_season_pass(sku)
 say("TEST PASS ACTIVATED" if r.ok else "FAILED  /  "+r.reason)
 build()
