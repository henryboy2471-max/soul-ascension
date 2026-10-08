extends RefCounted
class_name EpisodeData
# Episode 1 script. Speaker keys: NARRATOR, PLAYER, MIRA, ENFORCER, SYSTEM.
const SPEAKERS = {
 "NARRATOR":{"name":"","color":Color("a1a9c2"),"portrait":"none"},
 "SYSTEM":{"name":"SKYBRIDGE 09 RELAY","color":Color("6fd7e4"),"portrait":"none"},
 "PLAYER":{"name":"","color":Color("efce8e"),"portrait":"hero"},
 "MIRA":{"name":"MIRA VEY","color":Color("ffd86b"),"portrait":"mira"},
 "ENFORCER":{"name":"MERIDIAN ENFORCER","color":Color("fa6f82"),"portrait":"enforcer"},
 "PELL":{"name":"PELL  /  DEPOT RADIO","color":Color("6fd7e4"),"portrait":"none"},
 "SLEEPER":{"name":"A SLEEPER","color":Color("bd95ff"),"portrait":"none"},
 "GATE":{"name":"ROOF GATE","color":Color("ff8597"),"portrait":"none"},
 "ARRAY":{"name":"RAIN ARRAY 7","color":Color("bd95ff"),"portrait":"none"}
}
const INTRO = [
 {"who":"NARRATOR","text":"Twenty-one years ago, the sky fractured. The light it left behind rewrote what people could become. They called it Aether."},
 {"who":"NARRATOR","text":"Tonight, a storm has shut down the tram network across Neon District. Meridian scanners are sweeping the lower bridges."},
 {"who":"PLAYER","text":"Another dead signal. Another night shift. ...Why does my hand feel warm?"}
]
const MIRA_TALK = [
 {"who":"MIRA","text":"There you are. Keep your head down, the scanners just passed Skybridge 09."},
 {"who":"MIRA","text":"I'm Mira. I keep the trams running, and a few other things Meridian would rather I didn't."},
 {"who":"MIRA","text":"The relay terminal at the end of the platform is dead. If it stays dead, a lot of families lose their power line tonight."},
 {"who":"PLAYER","text":"I'm just a worker. I don't have Aether you can measure."},
 {"who":"MIRA","text":"That's what worries me. Your signal is so quiet it's loud. Hold the console until it syncs, and stay calm. Don't let it flare."}
]
const MIRA_REPEAT = [
 {"who":"MIRA","text":"The relay terminal is at the end of the platform. Hold the console until it syncs. Stay calm."}
]
const BOARD = [
 {"who":"NARRATOR","text":"SKYBRIDGE 09 TRAM BOARD. All services suspended. Meridian Directorate notice: unregistered Aether activity will be suppressed on sight."},
 {"who":"PLAYER","text":"Suppressed. That's one word for it."}
]
const TERMINAL = [
 {"who":"SYSTEM","text":"Relay handshake... unknown resonance detected. Echo signature, class unrated."},
 {"who":"SYSTEM","text":"Resonance exceeds safe threshold. Opening a Soul Realm channel."},
 {"who":"MIRA","text":"That isn't the relay. That's you. Something is tearing open the bridge."},
 {"who":"PLAYER","text":"The air is bending. I can feel it pulling me in."},
 {"who":"MIRA","text":"A breach. A Soul Realm. Meridian will feel it too, so whatever comes out, you have to meet it first."}
]
const BREACH = [
 {"who":"MIRA","text":"I'll hold the platform. Go. And listen to the resonance. Your signal learns from every fight."},
 {"who":"PLAYER","text":"Then let's see what it learns."}
]
const NO_ENERGY = [
 {"who":"NARRATOR","text":"The breach flickers. You need 6 energy to hold the Soul Realm open. Energy recharges over time, even while the game is closed."}
]
const OUTRO = [
 {"who":"ENFORCER","text":"Signal... reclassified. Not harmless. Not harmless."},
 {"who":"MIRA","text":"You did it. The breach is closing. ...What was that light around you?"},
 {"who":"PLAYER","text":"I don't know. But it felt like the whole city was listening."},
 {"who":"SYSTEM","text":"Beyond the atmosphere, a second signal answers. Source unknown. Distance: impossible."},
 {"who":"MIRA","text":"Meridian will come looking for you now. We should move before the rain does."}
]
const MURAL = [
 {"who":"NARRATOR","text":"A hand-painted mural: a ring of lanterns around a sleeping city. Beneath it, in careful letters: 'WHEN THE SKY GOES DARK, WE KEEP THE LIGHT.'"},
 {"who":"PLAYER","text":"Lantern Circuit. Mira's people. Hidden in plain sight, just like the rest of us."}
]
# Codex entries unlocked by exploring. Order is display order.
const CODEX = [
 {"id":"mira","title":"MIRA VEY","text":"Tram mechanic and Volt Vanguard. Keeps an illegal power line alive for displaced families in Neon District and is part of the Lantern Circuit."},
 {"id":"board","title":"MERIDIAN NOTICE","text":"The Directorate suppresses unregistered Aether activity on sight. Public safety rules double as a leash on every Ascendant in the city."},
 {"id":"mural","title":"LANTERN CIRCUIT","text":"A mutual-aid network that hides awakened civilians inside ordinary city services. Their motto: when the sky goes dark, we keep the light."},
 {"id":"terminal","title":"ECHO SIGNAL","text":"An Aether signature so quiet it is almost unreadable. Unlike conventional Aether, Echo learns from the resonance of others without taking their power."},
 {"id":"breach","title":"SOUL REALM","text":"A resonance space torn open by the Echo signal. Memories and fears take shape inside it as constructs. Entering costs energy to hold the channel open."},
 {"id":"enforcer","title":"SOUL-WARPED ENFORCER","text":"A Meridian suppression unit twisted by the Echo resonance. Its last words: Not harmless. Not harmless."},
 {"id":"violet_rain","title":"VIOLET RAIN","text":"A rain that carries a trace of the Echo signal. Every drop hums at the frequency of the second signal and pulls on anyone with an awakened resonance."},
 {"id":"sleepers","title":"THE SLEEPERS","text":"Awakened civilians sheltering in Depot 4 who stand with open eyes while their fears leak out of the Soul Realm. They wake badly. Only the Lantern Circuit knows how to sit with them."},
 {"id":"rain_array","title":"RAIN ARRAY 7","text":"A Meridian roof relay tuned to the Echo signature during an 'atmospheric resonance study'. Whoever holds it can lean on every sleeper in the quarter at once."},
 {"id":"hollow_cantor","title":"HOLLOW CANTOR","text":"A choir of every sleeper's fear given one voice and a bell. It tolls the Echo signal through the rain and feeds on the answer. It rises a second time when its chorus is struck.","secret":true}
]
