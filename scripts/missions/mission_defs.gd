extends RefCounted
class_name MissionDefs
# Story mission definitions: the values that used to be hard-coded for Episode 1, extracted verbatim, plus the Episode 2 (1-2) entry.
# Dialogue scripts stay in EpisodeData (content); a definition points at them. Systems (Episode, Explore, Battle, Profile, main)
# read these definitions instead of embedding Episode 1 constants. Episode 1 behaviour is pinned by tests/golden/episode1_trace.json.
static func defs() -> Dictionary:
 return {
  "1-1":{
   "id":"1-1","episode":1,"number":"EPISODE 1","season":"SEASON 01  /  THE FRACTURE",
   "title":"A SPARK IN THE STATIC","title_case":"A spark in the static",
   "location":"NEON DISTRICT / SKYBRIDGE 09","card_location":"NEON DISTRICT  /  SKYBRIDGE 09","region":"NEON DISTRICT",
   "description":"An Aether storm has shut down the tram network. A Meridian enforcer detects your unstable signature. Survive its suppression protocol.",
   "tagline":"Explore, investigate the relay, and survive the Soul Realm.","modal_sub":"STORY 01—01  /  NEON DISTRICT",
   "missions_sub":"CHAPTER 01  /  EPISODE 1 PLAYABLE  /  EPISODE 2 NEXT",
   "energy":6,"playable":true,
   "unlock":{"requires":[]},
   "rewards":{"first":{"xp":120,"gold":250},"replay":{"xp":55,"gold":100}},
   "codex":["mira","board","mural","terminal","breach","enforcer"],
   "intro_card_length":3.6,
   "objectives":[
    {"text":"Find Mira Vey at the tram","x":560.0},
    {"text":"Reboot the relay terminal","x":1560.0},
    {"text":"Enter the Soul Realm breach","x":2200.0}
   ],
   "breach_card":{"kicker":"SOUL REALM  /  MISSION ZONE 01","title":"THE RESONANT BRIDGE","subtitle":"SURVIVE THE SUPPRESSION CONSTRUCT","length":2.0},
   "stage_label":"SOUL REALM  /  RESONANT BRIDGE","battle_stage_label":"01—01  /  SKYBRIDGE 09",
   "waves":[
    {"name":"RESONANCE SHADE","sub":"SOUL REALM ECHO","hp":240.0,"atk":20.0,"def":3.0,"look":"shade","accent":Color("6fd7e4"),"scale":1.0,"boss":false,"card":"RESONANCE SHADE","card_sub":"AN ECHO OF THE SUPPRESSION SCAN  /  CLEAR IT"},
    {"name":"MERIDIAN ENFORCER","sub":"SOUL-WARPED CONSTRUCT","hp":820.0,"atk":28.0,"def":6.0,"look":"warped","accent":Color("c27bff"),"scale":1.2,"boss":true,"card":"SOUL-WARPED ENFORCER","card_sub":"A MERIDIAN CONSTRUCT TWISTED BY YOUR ECHO  /  SURVIVE IT"}
   ],
   "battle_only_waves":[
    {"name":"MERIDIAN ENFORCER","sub":"SUPPRESSION CLASS","hp":650.0,"atk":28.0,"def":6.0,"look":"enforcer","accent":Color(0,0,0,0),"scale":1.0,"boss":false,"card":"MERIDIAN ENFORCER","card_sub":"SUPPRESSION CLASS  /  SKYBRIDGE 09  /  SURVIVE THE SCAN"}
   ],
   "ending":{"lines":EpisodeData.OUTRO,"codex":["enforcer"],"teaser":{"kicker":"NEXT EPISODE","number":"EPISODE 2","title":"UNDER THE VIOLET RAIN","subtitle":"TO BE CONTINUED...","length":4.0}},
   "result":{"won_title":"ASCENSION BEGINS","lost_title":"RISE. TRY AGAIN.","subtitle":"Neon District  /  A spark in the static"}
  },
  # Episode 2 data only (M1). Scenes, objectives and waves arrive in later milestones; "playable" stays false until they exist.
  "1-2":{
   "id":"1-2","episode":2,"number":"EPISODE 2","season":"SEASON 01  /  THE FRACTURE",
   "title":"UNDER THE VIOLET RAIN","title_case":"Under the violet rain",
   "location":"LANTERN QUARTER / DEPOT 4","card_location":"LANTERN QUARTER  /  DEPOT 4","region":"LANTERN QUARTER",
   "description":"A violet rain is falling over the Lantern Quarter and the sleepers are walking toward the sky. Find what is tuning the rain.",
   "tagline":"Follow the rain to its source.","modal_sub":"STORY 01—02  /  LANTERN QUARTER",
   "missions_sub":"CHAPTER 01  /  EPISODE 2 NEXT",
   "energy":6,"playable":false,
   "unlock":{"requires":["1-1"]},
   "rewards":{"first":{"xp":150,"gold":300},"replay":{"xp":65,"gold":120}},
   "codex":["violet_rain","sleepers","rain_array","hollow_cantor"],
   "intro_card_length":3.6,
   "objectives":[],
   "waves":[],"battle_only_waves":[],
   "ending":{"lines":[],"codex":[],"teaser":{"kicker":"NEXT EPISODE","number":"EPISODE 3","title":"THE RELAY KEEPER","subtitle":"TO BE CONTINUED...","length":4.0}},
   "result":{"won_title":"THE RAIN CLEARS","lost_title":"RISE. TRY AGAIN.","subtitle":"Lantern Quarter  /  Under the violet rain"}
  }
 }
static func has_mission(id:String) -> bool:
 return defs().has(id)
static func get_def(id:String) -> Dictionary:
 return defs().get(id,{})
static func is_unlocked(id:String, completed:Array) -> bool:
 var d=get_def(id)
 if d.is_empty():
  return false
 for needed in d.unlock.requires:
  if not completed.has(needed):
   return false
 return true
static func is_playable(id:String) -> bool:
 return bool(get_def(id).get("playable",false))
static func energy_cost(id:String) -> int:
 return int(get_def(id).get("energy",6))
# kind: "first" (first clear) or "replay"
static func reward(id:String, first:bool) -> Dictionary:
 var r=get_def(id).rewards["first" if first else "replay"]
 return {"xp":int(r.xp),"gold":int(r.gold)}
static func waves(id:String, story:bool) -> Array:
 var d=get_def(id)
 return d.waves if story else d.battle_only_waves
static func mission_for_codex(codex_id:String) -> Dictionary:
 for id in defs():
  if defs()[id].codex.has(codex_id):
   return defs()[id]
 return {}
