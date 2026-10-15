extends RefCounted
class_name Episode3Data
# Episode 3 (The Relay Keeper) investigation data (M2). Dialogue DRAFTS follow docs/episodes/episode-03/STORY_PLAN.md (official plan, unchanged);
# the wording is Claude's and needs owner review. Everything here is pure data + pure functions so tests can run without a scene:
#   respond(id, clues)  -> what interacting with a spot says and changes (lines, new clue ids, codex ids, toast, unlock)
#   next_step(clues)    -> the current main-quest objective (derived from clues, so it can never disagree with the save)
# `clues` is the saved list mission_progress["1-3"].clues; ids are listed in docs/episodes/episode-03/IMPLEMENTATION.md.
const SPEAKERS = {
 "TEO":{"name":"TEO MARROW  /  RELAY KEEPER","color":Color("e8b878"),"portrait":"none"},
 "ANSELM":{"name":"ANSELM DRAY  /  FORMER REGISTRY CLERK","color":Color("9fb4d8"),"portrait":"none"},
 "PIP":{"name":"PIP","color":Color("ffd86b"),"portrait":"none"},
 "RESIDENT":{"name":"MARKET RESIDENT","color":Color("d8a8c8"),"portrait":"none"},
 "VENDOR":{"name":"STALL KEEPER","color":Color("e8b878"),"portrait":"none"},
 "SIGNAL":{"name":"RELAY VOICE","color":Color("6fd7e4"),"portrait":"none"}
}
const CODEX = [
 {"id":"relay_voices","title":"THE RELAY VOICES","text":"Abandoned towers speak to Lantern Quarter: lullabies, bulletins dated tomorrow, and a tone that matches Echo. Replays, not broadcasts."},
 {"id":"teo","title":"TEO MARROW","text":"The Relay Keeper. Keeps the old relay network alive from a workshop behind the alleyways. Wary of anyone who looks like Meridian."},
 {"id":"anselm","title":"ANSELM DRAY","text":"A former Meridian registry clerk ordered to burn the old registry. He could not. Hides at Meridian Transit Station."},
 {"id":"false_register","title":"THE MISSING REGISTER","text":"Registrations dated years before the first awakening, one line scraped bare. Someone has counted Ascendants for far longer."},
 {"id":"earlier_candidates","title":"EARLIER CANDIDATES","text":"A ledger headed PRE-AWAKENING: a dozen names, each marked RETAINED or LOST. Someone chose people before the Fracture.","secret":true},
 {"id":"relay_journal","title":"A TECHNICIAN'S JOURNAL","text":"\"The towers are not broadcasting. They are remembering. Do not tell the Directorate.\"","secret":true},
 {"id":"pips_trail","title":"PIP'S TRAIL","text":"Lio drew three marks in the alleyways before he went to answer the voices in the central tower. His sister Pip still waits.","secret":true}
]
# clue id -> main-quest requirement order (first missing step is the current objective)
const STEPS = [
 {"id":"tx","text":"Investigate the three unusual transmissions","zone":"market","spots":["signal_1","signal_2","signal_3"],"needs":["tx_1","tx_2","tx_3"]},
 {"id":"terminal","text":"Check the access terminal at the Transit Station","zone":"station","spots":["terminal_a"],"needs":["terminal"]},
 {"id":"anselm","text":"Question Anselm about the missing register","zone":"station","spots":["anselm"],"needs":["anselm_admits"]},
 {"id":"records","text":"Search the station records","zone":"station","spots":["records"],"needs":["records"]},
 {"id":"teo","text":"Find Teo Marrow, the Relay Keeper","zone":"workshop","spots":["teo"],"needs":["teo_met"]},
 {"id":"decode","text":"Decode the transmissions at Teo's decoder","zone":"workshop","spots":["decoder"],"needs":["decoded"]},
 {"id":"board","text":"Assemble the evidence on Teo's board","zone":"workshop","spots":["board"],"needs":["theory"]},
 {"id":"tower","text":"Enter the Central Relay Tower","zone":"workshop","spots":["exit_tower"],"needs":["tower_reached"]}
]
const TOWER_OBJECTIVE = "Climb the Central Relay Tower"
const LOCKED = {
 "shortcut":"LOCKED  /  SOMETHING HERE CAN BE OPENED FROM ANOTHER SIDE",
 "tower":"LOCKED  /  THE WAY TO THE TOWER IS NOT OPEN YET"
}
static func has_all(clues:Array, needs:Array) -> bool:
 for n in needs:
  if not clues.has(n):
   return false
 return true
static func count_of(clues:Array, ids:Array) -> int:
 var n=0
 for i in ids:
  if clues.has(i):
   n+=1
 return n
# the current main-quest step; {} once every step is done. Counter steps report done/total and which spots are still open.
static func next_step(clues:Array) -> Dictionary:
 for s in STEPS:
  if not has_all(clues,s.needs):
   var open=[]
   if s.id=="tx":
    for i in range(3):
     if not clues.has("tx_%d" % (i+1)):
      open.append(s.spots[i])
   else:
    open=s.spots.duplicate()
   return {"id":s.id,"text":s.text,"zone":s.zone,"spots":open,"done":count_of(clues,s.needs),"total":s.needs.size()}
 return {}
static func line(who:String, text:String) -> Dictionary:
 return {"who":who,"text":text}
static func nar(text:String) -> Dictionary:
 return line("NARRATOR",text)
# Result of interacting with spot `id` given the saved clues. Keys: lines (Array), add (clue ids gained), codex (ids), toast, unlock (lock key).
# Pure: the episode applies it. A clue is only gained when the conditions in the dialogue are met, so the order of play can vary.
static func respond(id:String, clues:Array) -> Dictionary:
 var r={"lines":[],"add":[],"codex":[],"toast":"","unlock":""}
 match id:
  "signal_1":
   if clues.has("tx_1"):
    r.lines=[nar("The recording loops: a lullaby, and a promise to be home before the rain.")]
   else:
    r.lines=[nar("The speaker above the stall crackles. Under the static, a woman's voice is humming a lullaby. It stops mid-line."),line("SIGNAL","...leave the lamp on. I'll be home before the rain."),line("MIRA","That frequency has been dead since the strike. Echo, that's a recording... or a person."),line("PLAYER","It sounded like she was talking to me.")]
    r.add=["tx_1"]
  "signal_2":
   if clues.has("tx_2"):
    r.lines=[nar("The bulletin repeats. Tram forty-one. The Skybridge curve. Tomorrow evening.")]
   else:
    r.lines=[line("SIGNAL","Platform nine. Tram forty-one. Brakes failing at the Skybridge curve. Seven injured. Please hold."),line("MIRA","That's an incident bulletin. The timestamp says tomorrow evening."),line("PLAYER","A message about something that hasn't happened yet."),line("MIRA","Then someone is listening to tomorrow, or writing it.")]
    r.add=["tx_2"]
  "signal_3":
   if clues.has("tx_3"):
    r.lines=[nar("The long tone rolls out of the speaker again. The violet rain hums back.")]
   else:
    r.lines=[nar("A single tone, long and low, rolls out of the speaker. The violet in the rain answers it, and your chest hums on the same note."),line("MIRA","Echo? You've gone pale."),line("PLAYER","That's my signature. It's the note I make when I use Aether. Why is it inside a relay tower?"),line("MIRA","I don't know. But I don't think we're the first ones to hear it.")]
    r.add=["tx_3"]
  "witness_a":
   if clues.has("w_a"):
    r.lines=[line("RESIDENT","Hold the lamp. That's what he said. Hold the lamp.")]
   else:
    r.lines=[line("RESIDENT","I heard my husband. Plain as day, from the tower on Ninth. He's been missing since the strike."),line("RESIDENT","He said, 'Hold the lamp.' Nobody believes me."),line("MIRA","We believe you.")]
    r.add=["w_a"]
  "witness_b":
   if clues.has("w_b"):
    r.lines=[line("RESIDENT","Husband? No. A man reading a bulletin. Ask who cordoned the stop before sunrise.")]
   else:
    r.lines=[line("RESIDENT","Husband? That's not what came out of the speaker. It was a man reading a bulletin about a tram crash."),line("RESIDENT","The crash hasn't happened. The wardens were already at the stop before sunrise, setting up cordons."),line("PLAYER","Cordons for a crash that hasn't happened.")]
    r.add=["w_b"]
  "witness_c":
   if clues.has("w_c"):
    r.lines=[line("RESIDENT","I heard nothing. Stop asking.")]
   else:
    r.lines=[line("RESIDENT","I heard nothing. The speakers were dead all night. Meridian came at dawn and took the cable boxes."),line("MIRA","Three people, three different nights."),line("PLAYER","Whatever it is, it isn't only speaking to one person.")]
    r.add=["w_c"]
  "vendor":
   r.lines=[line("VENDOR","Voices from the towers? Everyone's had one this week."),line("VENDOR","If anyone still understands the old relays it's Teo Marrow. Workshop past the alleyways. He doesn't like visitors.")]
  "notice":
   r.lines=[nar("RESONANCE AMNESTY. All Ascendants must register within 48 hours. Unregistered resonance will be suppressed. Director Vaust."),line("MIRA","Your name is already on their list. Keep your head down in the crowd.")]
   r.add=["notice"]
  "journal":
   if clues.has("journal"):
    r.lines=[nar("The water-stained journal. 'The towers are not broadcasting. They are remembering.'")]
   else:
    r.lines=[nar("Behind the stall, wrapped in oilcloth: a technician's journal, the ink running in the damp."),nar("'The towers are not broadcasting. They are remembering. Do not tell the Directorate.'"),line("MIRA","Remembering what?")]
    r.add=["journal"]
    r.codex=["relay_journal"]
    r.toast="HIDDEN CLUE  /  A TECHNICIAN'S JOURNAL"
  "terminal_a":
   if clues.has("terminal"):
    r.lines=[nar("The access log is still lit: DRAY, A. Forty files deleted. Six nights ago.")]
   else:
    r.lines=[nar("The terminal wakes on MERIDIAN TRANSIT / ADMIN ACCESS LOG. The last login, six nights ago, is from a registry workstation: DRAY, A."),nar("The same login deleted forty files and then logged out."),line("MIRA","A registry clerk. Someone deleted forty files and walked away. Find whoever is wearing that name.")]
    r.add=["terminal"]
  "anselm":
   if clues.has("anselm_admits"):
    if clues.has("hidden_registry"):
     r.lines=[line("ANSELM","You found the panel. Then you know there were candidates before any of us. Before the Fracture."),line("ANSELM","Take the third name to someone who can hear what the towers keep.")]
    elif clues.has("records"):
     r.lines=[line("ANSELM","Whoever is on that list has been counted for longer than they have been alive."),line("ANSELM","If there is more, it isn't on a shelf.")]
    else:
     r.lines=[line("ANSELM","East pillar. Look, don't take, and don't say my name where the Directorate listens.")]
   elif clues.has("terminal"):
    r.lines=[line("PLAYER","Dray, A. Six nights ago. Forty files."),line("ANSELM","...You read the log. Then you know I couldn't finish."),line("ANSELM","I was told to burn the old registry. I deleted the index. I couldn't burn the paper."),line("ANSELM","It's on the shelves behind the east pillar. Look, don't take, and don't say my name where the Directorate listens."),line("MIRA","Thank you, Mr. Dray.")]
    r.add=["anselm_admits","anselm_met"]
    r.codex=["anselm"]
   else:
    r.lines=[line("ANSELM","The platforms are closed. Go home."),line("PLAYER","I'm looking for the registry."),line("ANSELM","There is no registry here. Not anymore."),line("MIRA","He's lying badly. Find something he can't talk around. The access terminal, maybe.")]
    r.add=["anselm_met"]
  "records":
   if clues.has("records"):
    r.lines=[nar("The old registry. Entries filed years before the first recorded awakening. One line scraped to bare card.")]
   elif clues.has("anselm_admits"):
    r.lines=[nar("Behind the east pillar, shelves of paper registrations. Ordinary at first. Then the dates: entries filed years before the first recorded awakening."),line("PLAYER","These are Ascendants who shouldn't exist yet."),line("MIRA","Or who have existed longer than anyone admits."),nar("One line has been scraped to bare card. The signature column hums when you hold your hand near it."),line("PLAYER","...Mira. Don't read that line aloud.")]
    r.add=["records","scraped_entry"]
    r.codex=["false_register"]
   else:
    r.lines=[nar("The shelves are stripped bare. The dust has been wiped away recently, in a hurry."),line("MIRA","Someone cleaned this out. Someone here knows where it went.")]
  "registry_hidden":
   if clues.has("hidden_registry"):
    r.lines=[nar("The loose panel. The ledger inside: CANDIDATES, PRE-AWAKENING.")]
   elif clues.has("records"):
    r.lines=[nar("A loose panel behind the shelves. Behind it, a thin ledger: CANDIDATES / PRE-AWAKENING. A dozen names, each marked RETAINED or LOST."),line("MIRA","Earlier candidates. Someone was choosing people before the Fracture.")]
    r.add=["hidden_registry"]
    r.codex=["earlier_candidates"]
    r.toast="HIDDEN CLUE  /  EARLIER CANDIDATES"
   else:
    r.lines=[nar("A bare wall panel.")]
  "archive_door":
   r.lines=[nar("A sealed archive door. Three brackets glow dim where a key pattern should be."),line("MIRA","A resonance lock. We'll need the right pieces to open it. The old registry is a start.")]
  "pip":
   var frags=count_of(clues,["frag_1","frag_2","frag_3"])
   if clues.has("pip_done"):
    r.lines=[line("PIP","Lio drew the tower. I'll wait. You'll find him, right?")]
   elif frags>=3:
    r.lines=[line("PIP","You found all three?"),line("PLAYER","A hand over a lamp. A rooftop. A tower drawn like a spiral."),line("PIP","He went to answer the voices. He thought he could bring people home."),line("PLAYER","I'll find him."),line("PIP","Then take this. It's his lamp glass. It hums when it's near the towers.")]
    r.add=["pip_done"]
    r.codex=["pips_trail"]
    r.toast="OPTIONAL QUEST COMPLETE  /  PIP'S TRAIL"
   elif clues.has("pip_met"):
    r.lines=[line("PIP","Three marks. Faded ones on the walls. You've found %d." % frags)]
   else:
    r.lines=[line("PIP","Are you from the Circuit? ...You hear it too, don't you? The tower talks in my brother's voice. Lio. He walked into the rain and didn't walk out."),line("PIP","He left marks on the walls where he used to hide. Three. If I find them, I find where he went."),line("PLAYER","I'll look."),line("MIRA","We'll look.")]
    r.add=["pip_met"]
  "fragment_1":
   r.lines=[nar("A faded glyph: a child's hand held over a lamp. A boy's laugh drifts out of the wall. 'Pip, catch!'")]
   if not clues.has("frag_1"):
    r.add=["frag_1"]
    r.toast="MEMORY FRAGMENT  /  1 OF 3"
  "fragment_2":
   r.lines=[nar("A second mark: a rooftop and a tram line. The voice in the wall is older now. 'I'll be back before the rain.'")]
   if not clues.has("frag_2"):
    r.add=["frag_2"]
    r.toast="MEMORY FRAGMENT  /  2 OF 3"
  "fragment_3":
   r.lines=[nar("A third mark: the Central Tower drawn as a spiral. 'If I answer it, I can bring them home.'")]
   if not clues.has("frag_3"):
    r.add=["frag_3"]
    r.toast="MEMORY FRAGMENT  /  3 OF 3"
  "lever":
   r.lines=[nar("An old lever grinds into place somewhere nearby. A shortcut opens.")]
  "teo":
   if clues.has("theory"):
    r.lines=[line("TEO","The tower is open to us. Everything else on the network answers me. The Central Relay is the one I can't hear."),line("TEO","Stay close to the wall. The floors above have been dark a long time.")]
   elif clues.has("teo_met"):
    r.lines=[line("TEO","The signals, the Register, the board. Show me on the board when you have them.")]
   else:
    r.lines=[line("TEO","The door was locked for a reason."),line("PLAYER","We heard the towers. We think you can tell us what they're saying."),line("TEO","Meridian sends people with friendly faces."),line("MIRA","I'm Mira Vey. Volt Vanguard. Lantern Circuit."),line("TEO","Vey. Your line keeps half my relays warm. ...Fine. But I don't trust what I can't see. Bring me what the towers say and what the Register hides. Then we talk.")]
    r.add=["teo_met"]
    r.codex=["teo"]
  "decoder":
   if clues.has("decoded"):
    r.lines=[nar("The decoder replays the carrier: three voices, one thread underneath.")]
   elif not clues.has("teo_met"):
    r.lines=[line("TEO","Hands off. Ask first.")]
   elif not has_all(clues,["tx_1","tx_2","tx_3"]):
    r.lines=[nar("The decoder has nothing to read. Transmissions recorded: %d of 3." % count_of(clues,["tx_1","tx_2","tx_3"])),line("MIRA","Your scanner picks them up at the market. We need all three.")]
   else:
    r.lines=[nar("You feed the scanner recordings into the decoder. Three waveforms settle over one another, and a single carrier shows beneath them."),line("TEO","Three voices, one carrier. They aren't broadcasts. They're playback."),line("PLAYER","Playback of what?"),line("TEO","Of someone who was listening when they were recorded.")]
    r.add=["decoded"]
    r.codex=["relay_voices"]
    r.toast="DECODED  /  THE RELAY VOICES"
  "board":
   if clues.has("theory"):
    r.lines=[nar("The evidence board: three transmissions, a deleted index, a registry older than the awakening. Teo's string runs through all of it.")]
   elif has_all(clues,["teo_met","decoded","records"]):
    r.lines=[nar("You pin the pieces up: three transmissions, an index deleted by hand, registry lines older than the awakening. Teo draws string between them."),line("TEO","Seven arrays. They aren't antennas. They are a system for keeping something, and someone has been rewriting what they keep."),line("MIRA","Keeping what?"),line("TEO","Not here. In the Central Relay, where the system answers. I'll open the way.")]
    r.add=["theory"]
    r.unlock="tower"
    r.toast="THEORY ASSEMBLED  /  THE TOWER IS OPEN"
   else:
    var missing=[]
    if not clues.has("teo_met"): missing.append("the Keeper's trust")
    if not clues.has("decoded"): missing.append("the decoded signals")
    if not clues.has("records"): missing.append("the old registry")
    r.lines=[nar("The board has gaps. Still missing: "+", ".join(missing)+"."),line("MIRA","We'll know it fits when the pieces line up.")]
  "relay_map":
   r.lines=[nar("A relay map of the Quarter, seven nodes drawn in chalk. Two are dark, and a torn corner hides the way to the Central Tower.")]
   r.add=["map_seen"]
  "resonator_1","resonator_2","resonator_3":
   r.lines=[nar("A silent resonator. Something is missing from it.")]
  "archive_gate":
   r.lines=[nar("A sealed archive gate. It answers nothing yet.")]
  _:
   r.lines=[nar("Nothing here.")]
 if id.begins_with("signal_") and not r.add.is_empty() and has_all(clues+r.add,["tx_1","tx_2","tx_3"]):
  r.lines.append(line("MIRA","Three transmissions, three different kinds of wrong. Someone at the Transit Station used to sort these relays. Let's start with their terminal."))
 return r
