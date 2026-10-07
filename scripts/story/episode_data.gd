extends RefCounted
class_name EpisodeData
# Episode 1 script. Speaker keys: NARRATOR, PLAYER, MIRA, ENFORCER, SYSTEM.
const SPEAKERS = {
 "NARRATOR":{"name":"","color":Color("a1a9c2"),"portrait":"none"},
 "SYSTEM":{"name":"SKYBRIDGE 09 RELAY","color":Color("6fd7e4"),"portrait":"none"},
 "PLAYER":{"name":"","color":Color("efce8e"),"portrait":"hero"},
 "MIRA":{"name":"MIRA VEY","color":Color("ffd86b"),"portrait":"mira"},
 "ENFORCER":{"name":"MERIDIAN ENFORCER","color":Color("fa6f82"),"portrait":"enforcer"}
}
const TITLE = "A SPARK IN THE STATIC"
const SEASON = "SEASON 01  /  THE FRACTURE"
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
const NEXT_TITLE = "UNDER THE VIOLET RAIN"
const NEXT_NUMBER = "EPISODE 2"
const MURAL = [
 {"who":"NARRATOR","text":"A hand-painted mural: a ring of lanterns around a sleeping city. Beneath it, in careful letters: 'WHEN THE SKY GOES DARK, WE KEEP THE LIGHT.'"},
 {"who":"PLAYER","text":"Lantern Circuit. Mira's people. Hidden in plain sight, just like the rest of us."}
]
