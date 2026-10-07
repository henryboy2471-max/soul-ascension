extends RefCounted
class_name HeroData
const RARITIES = ["Common", "Rare", "Epic", "Legendary", "Mythic", "Ascended"]
const HEROES = [
 {"id":"echo", "name":"The Unbound", "element":"Echo", "class":"Striker", "rarity":"Common", "lore":"A near-silent Aether signature. An evolution no instrument can measure."},
 {"id":"mira", "name":"Mira Vey", "element":"Volt", "class":"Vanguard", "rarity":"Epic", "lore":"A tram mechanic who learned to catch lightning. Planned starter ally."},
 {"id":"oren", "name":"Oren Vale", "element":"Ember", "class":"Breaker", "rarity":"Legendary", "lore":"A tournament champion bound by a promise he cannot keep."},
 {"id":"sable", "name":"Sable Irix", "element":"Void", "class":"Controller", "rarity":"Mythic", "lore":"A former archivist who remembers futures that never happened."}
]
static func stats(level:int) -> Dictionary:
 return {"health":260+(level-1)*24,"attack":24+(level-1)*3,"defense":8+(level-1)*2,"speed":340,"crit_chance":0.12,"crit_damage":1.6}
static func power(level:int) -> int:
 var s=stats(level)
 return int(s.health*2+s.attack*12+s.defense*8+s.speed)
