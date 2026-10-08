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
# --- Ending (M4). Realm: the Cantor has fallen and the Soul Realm calms. Return: the Lantern Quarter, rain settling, breach closing.
const ENDING_REALM = [
 {"who":"NARRATOR","text":"The bell stops. The rain does not fall so much as settle, and the Soul Realm goes very still."},
 {"who":"MIRA","text":"Echo. Say something. Your signal went quiet and I thought..."},
 {"who":"PLAYER","text":"I'm here. It wasn't a monster, Mira. It sounded like all of them at once: every sleeper, one voice, one bell."},
 {"who":"MIRA","text":"The resonators held. Three lanterns, still lit. They didn't stop it. They gave the sleepers somewhere to stand while you cut it loose."},
 {"who":"PLAYER","text":"Somebody wrote that chorus. Somebody taught the Soul Realm what to sing."},
 {"who":"MIRA","text":"Rain Array 7. Think about the number. Seven means six more. This was never just the Lantern Quarter."},
 {"who":"PLAYER","text":"Then we follow the signal. All of it."},
 {"who":"MIRA","text":"Come home first. The breach won't stay open for long, and the sleepers are going to wake up wanting to know who is still humming."}
]
const ENDING_RETURN_A = [
 {"who":"NARRATOR","text":"The breach folds shut behind them like an eyelid. The rain settles to a thin violet mist. It is still falling."},
 {"who":"SLEEPER","text":"...The voice stopped. Why does it feel like it's still listening?"},
 {"who":"PELL","text":"Depot 4 to Mira. Pulses are back to normal, every one of them. But the Meridian screens across the quarter just came alive."}
]
const ENDING_RETURN_B = [
 {"who":"VAUST","text":"Citizens of Neon District. A Resonance Amnesty is now in effect. Register within forty-eight hours. Unregistered resonance will be suppressed."},
 {"who":"REGISTRY","text":"1 ASCENDANT FLAGGED  /  SIGNATURE: ECHO."},
 {"who":"MIRA","text":"...They have your name already."},
 {"who":"PLAYER","text":"Then they've been listening a lot longer than the rain."}
]
