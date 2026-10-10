extends RefCounted
class_name ShopCatalog
# MONETIZATION DESIGN - TEST DATA ONLY. Nothing here is a live product: every entry has "live": false, prices are TEST placeholders, and
# no payment backend is connected (see PAYMENTS_ENABLED in ShopService). Design rules, enforced by validate() and tests/test_shop_design.gd:
#  - cosmetics only (skins, outfits, hairstyles, transformations, companions, UI/profile flair): NO stats, power, energy, XP or story gating;
#  - the full 10-episode story is never behind a purchase;
#  - every cosmetic has a free route (earnable) or is part of the free season-pass track, except pure premium-only collaborations (none in test data);
#  - no randomized paid items (no gacha/loot boxes), every price is shown up front.
const CURRENCIES = {
 "gold":{"name":"Gold","premium":false,"earn":"missions, exploration"},
 "shards":{"name":"Echo Shards","premium":false,"earn":"exploration discoveries, optional quests, season-pass free track"},
 "crystals":{"name":"Soul Crystals","premium":true,"earn":"purchase (small amounts also earnable in the pass)"}
}
const CATEGORIES = ["skin","outfit","hairstyle","transformation","companion","flair","bundle"]
const FORBIDDEN_FIELDS = ["stats","power","attack","defense","hp","xp_boost","energy","unlock_episode","skip_story","damage"]
const RARITIES = ["common","rare","epic","legendary"]
# PLANNING PRICES (owner-proposed, NOT approved live products). Soul Crystal packs: total crystals and display price in USD.
const CRYSTAL_RATE = 60   # planning rate: 60 Soul Crystals ~ 1 USD of cosmetic value (the 600-crystal / $9.99 pack); bigger packs give more
const PRICE_POINTS = [5.99,7.99,9.99,14.99,19.99,24.99,29.99]   # approved planning cosmetic prices (USD)
static func currency_packs() -> Array:
 # Consumable Soul Crystal packs. SKUs are TEST ids; real SKUs are created only after owner approval.
 return [
  {"sku":"test.crystals.150","name":"Handful of Soul Crystals","crystals":150,"usd":2.99,"display_price":"TEST $2.99","live":false},
  {"sku":"test.crystals.600","name":"Pouch of Soul Crystals","crystals":600,"usd":9.99,"display_price":"TEST $9.99","live":false},
  {"sku":"test.crystals.1400","name":"Satchel of Soul Crystals","crystals":1400,"usd":19.99,"display_price":"TEST $19.99","live":false},
  {"sku":"test.crystals.3000","name":"Chest of Soul Crystals","crystals":3000,"usd":39.99,"display_price":"TEST $39.99","live":false},
  {"sku":"test.crystals.6500","name":"Vault of Soul Crystals","crystals":6500,"usd":79.99,"display_price":"TEST $79.99","live":false},
  {"sku":"test.crystals.10000","name":"Soul Hoard","crystals":10000,"usd":99.99,"display_price":"TEST $99.99","live":false}
 ]
static func crystal_price(usd:float) -> int:
 return int(round(usd*CRYSTAL_RATE))
static func _it(id:String, name:String, category:String, character:String, rarity:String, usd:float, shards:int, preview:String, extra:Dictionary={}) -> Dictionary:
 var d={"id":id,"name":name,"category":category,"character":character,"rarity":rarity,"usd":usd,"price":{"crystals":crystal_price(usd)},"free_route":{"shards":shards},"preview":preview,"live":false}
 d.merge(extra)
 return d
static func items() -> Array:
 return [
  _it("outfit_echo_lantern","Echo  /  Lantern Circuit Coat","outfit","echo","rare",5.99,1100,"Amber lantern fittings and a brass collar"),
  _it("outfit_mira_workshop","Mira  /  Tram Mechanic","outfit","mira","rare",5.99,1100,"Work coat, goggles, tool belt"),
  _it("hair_echo_windswept","Echo  /  Windswept","hairstyle","echo","common",5.99,1100,"Longer swept hair with a violet tint"),
  _it("skin_echo_midnight","Echo  /  Midnight Resonance","skin","echo","epic",9.99,1900,"Deep-indigo coat, silver trim, violet rim light"),
  _it("skin_mira_gilded","Mira  /  Gilded Volt","skin","mira","epic",9.99,1900,"Gold-forward armor, brighter violet cape"),
  _it("transform_echo_dawn","Echo  /  Dawn Resonance (Soul Realm form)","transformation","echo","legendary",19.99,3600,"Cosmetic alternate Soul Realm aura and Phase look; identical stats"),
  _it("outfit_echo_anim_aurora","Echo  /  Aurora Coat (animated)","outfit","echo","legendary",24.99,4500,"Exclusive animated outfit: flowing light panels and drifting motes",{"animated":true}),
  _it("companion_lantern_wisp","Lantern Wisp","companion","any","rare",7.99,1500,"A small lantern spirit that follows you; cosmetic only"),
  _it("companion_bell_moth","Bell Moth","companion","any","epic",9.99,1900,"A glowing moth with a tiny chiming bell; cosmetic only"),
  _it("companion_resonance_fox","Resonance Fox","companion","any","legendary",14.99,2700,"An ember-and-violet spirit fox with a trailing glow; cosmetic only"),
  {"id":"flair_frame_violet","name":"Violet Rain Portrait Frame","category":"flair","character":"any","rarity":"common","price":{"gold":2500},"free_route":{"gold":2500},"preview":"Dialogue portrait frame","live":false},
  {"id":"bundle_echo_midnight_set","name":"Echo  /  Midnight Collection (bundle)","category":"bundle","character":"echo","rarity":"epic","usd":29.99,"price":{"crystals":crystal_price(29.99)},"free_route":{"shards":5400},
   "contents":["skin_echo_midnight","hair_echo_windswept","companion_bell_moth"],"preview":"Midnight skin + Windswept hair + Bell Moth, fixed contents (no randomness)","live":false}
 ]
# Season passes (planning prices, TEST skus): one-time purchases for the whole Season 1; cosmetic rewards only; XP comes from play, not spending.
# Deluxe adds extra cosmetics and a profile frame; neither pass sells story access, power, energy or XP boosts.
static func season_passes() -> Array:
 return [
  {"id":"pass_season1","name":"Season 1 Pass  /  The Fracture","sku":"test.pass.season1","usd":14.99,"display_price":"TEST $14.99","live":false,"covers_story":false,"extra_items":[]},
  {"id":"pass_season1_deluxe","name":"Deluxe Season 1 Pass","sku":"test.pass.season1.deluxe","usd":24.99,"display_price":"TEST $24.99","live":false,"covers_story":false,"extra_items":["outfit_echo_anim_aurora"]}
 ]
static func season_pass() -> Dictionary:
 var tiers=[]
 for t in range(1,11):
  var free_reward={"shards":50*t} if t%2==1 else {"gold":400*t}
  var premium_reward={"item":"flair_frame_violet"} if t==1 else ({"item":"companion_lantern_wisp"} if t==5 else ({"item":"skin_echo_midnight"} if t==10 else {"crystals":20}))
  tiers.append({"tier":t,"xp_needed":100*t,"free":free_reward,"premium":premium_reward})
 var base=season_passes()[0].duplicate(true)
 base["tiers"]=tiers
 return base
static func pass_by_sku(sku:String) -> Dictionary:
 for p in season_passes():
  if p.sku==sku:
   return p
 return {}
static func item(id:String) -> Dictionary:
 for i in items():
  if i.id==id:
   return i
 return {}
static func pack(sku:String) -> Dictionary:
 for p in currency_packs():
  if p.sku==sku:
   return p
 return {}
# Returns a list of problems (empty = valid). Used by tests and as a release gate.
static func validate() -> Array:
 var problems=[]
 var seen={}
 for i in items():
  if seen.has(i.id):
   problems.append("duplicate id "+i.id)
  seen[i.id]=true
  if not CATEGORIES.has(i.category):
   problems.append("%s: category %s is not a cosmetic category" % [i.id,i.category])
  if not RARITIES.has(i.rarity):
   problems.append("%s: bad rarity" % i.id)
  for f in FORBIDDEN_FIELDS:
   if i.has(f):
    problems.append("%s: forbidden gameplay field %s" % [i.id,f])
  if bool(i.get("live",false)):
   problems.append("%s: live items are not allowed in test data" % i.id)
  if not (i.has("price") and i.price is Dictionary and not i.price.is_empty()):
   problems.append("%s: missing price" % i.id)
  for cur in i.get("price",{}):
   if not CURRENCIES.has(cur):
    problems.append("%s: unknown currency %s" % [i.id,cur])
  if not i.has("free_route"):
   problems.append("%s: no free route" % i.id)
  if i.has("usd") and not PRICE_POINTS.has(float(i.usd)):
   problems.append("%s: usd %.2f is not an approved planning price point" % [i.id,float(i.usd)])
  if i.category=="bundle":
   for c in i.contents:
    if item(c).is_empty():
     problems.append("%s: bundle contains unknown item %s" % [i.id,c])
 for p in currency_packs():
  if bool(p.get("live",false)) or not str(p.sku).begins_with("test."):
   problems.append("%s: pack must be a non-live test sku" % p.sku)
 for sp in season_passes():
  if bool(sp.live) or bool(sp.covers_story):
   problems.append("%s must be non-live and must not cover story access" % sp.id)
  for x in sp.extra_items:
   if item(x).is_empty():
    problems.append("%s: unknown extra item %s" % [sp.id,x])
 var sp=season_pass()
 for t in sp.tiers:
  for track in ["free","premium"]:
   for k in t[track]:
    if not (k in ["shards","gold","crystals","item"]):
     problems.append("pass tier %d: unsupported reward %s" % [t.tier,k])
    if k=="item" and item(t[track][k]).is_empty():
     problems.append("pass tier %d: unknown item %s" % [t.tier,t[track][k]])
 return problems
