extends RefCounted
class_name Episode2Data
# Episode 2 (Under the Violet Rain) dialogue. Speaker keys are defined in EpisodeData.SPEAKERS.
const INTRO = [
 {"who":"NARRATOR","text":"By dawn the storm had not ended. It had changed color. Violet rain was falling over Neon District, and every drop hummed."},
 {"who":"NARRATOR","text":"In the Lantern Quarter the lights were still on, but the people were not awake. They stood where they had been standing when the rain began, eyes open, faces turned to the sky."},
 {"who":"PLAYER","text":"The hum is in my teeth. ...It sounds like the thing from the breach."}
]
const DEPOT = [
 {"who":"NARRATOR","text":"Depot 4 was a drained tram shed the Lantern Circuit used as a shelter. Rows of sleepers stood between the old rails, perfectly still, rain-light moving across their faces."},
 {"who":"PLAYER","text":"They're breathing. They're just... not here."}
]
const MIRA_TALK = [
 {"who":"MIRA","text":"You came. Good. Don't touch anyone. They wake badly."},
 {"who":"MIRA","text":"The rain started the moment the breach closed. Every drop carries your signal, Echo, and the second one is answering it."},
 {"who":"PLAYER","text":"Then this is my fault."},
 {"who":"MIRA","text":"It's a leash, not a fault. Somebody on the roof is tuning it. Three lantern resonators on the terrace can shelter the sleepers long enough for us to reach the Rain Array."},
 {"who":"PELL","text":"Depot radio, Pell here. Mira, their pulses are climbing. Whoever you brought, tell them to hurry."},
 {"who":"PELL","text":"Hold each resonator until it syncs. The sleepers will show you something when it does. Don't let it pull you under."},
 {"who":"PLAYER","text":"Three resonators. Then the roof."},
 {"who":"MIRA","text":"I'll keep the depot lit. Go."}
]
const MIRA_REPEAT = [
 {"who":"MIRA","text":"Three resonators on the terrace, then the roof. Hold each one until it syncs."}
]
const MEMORY_A = [
 {"who":"SYSTEM","text":"Resonator synced. A memory surfaces: not yours."},
 {"who":"SLEEPER","text":"It was raining the night I found the tram line. I was lost, and then the lanterns came on, one by one, all the way home."}
]
const MEMORY_B = [
 {"who":"SYSTEM","text":"Resonator synced. A second voice, very close."},
 {"who":"SLEEPER","text":"My brother said the sky would sing again someday. I thought he meant a song. He meant a signal."}
]
const MEMORY_C = [
 {"who":"SYSTEM","text":"Resonator synced. The last voice is the quietest."},
 {"who":"SLEEPER","text":"Don't wake me yet. If I wake, I stop hearing it, and it's the only voice that says my name right."},
 {"who":"PLAYER","text":"They're all hearing the same voice."}
]
const GATE_UNLOCK = [
 {"who":"GATE","text":"Resonators aligned. Roof access released."},
 {"who":"MIRA","text":"The lanterns are holding. Go up. The Rain Array is at the top of the stairs."}
]
const GATE_LOCKED = [
 {"who":"GATE","text":"Roof access locked. Sync all three lantern resonators to release the stairs."}
]
const NOTICE = [
 {"who":"NARRATOR","text":"MERIDIAN MAINTENANCE NOTICE. Rain Array 7: roof relay recalibrated for an 'atmospheric resonance study'. Access restricted to Directorate technicians. Do not interfere with the array during precipitation events."},
 {"who":"PLAYER","text":"An atmospheric study. Sure."}
]
const ARRAY = [
 {"who":"ARRAY","text":"Rain Array 7. Carrier locked on Echo signature."},
 {"who":"MIRA","text":"It's tuned to you. It was never tuned to the rain."},
 {"who":"PLAYER","text":"Then I'll tune it back."},
 {"who":"ARRAY","text":"Resonance channel opening. Soul Realm breach detected."}
]
