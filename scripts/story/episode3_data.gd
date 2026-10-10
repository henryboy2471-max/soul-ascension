extends RefCounted
class_name Episode3Data
# Episode 3 (The Relay Keeper) text data. M1 only carries functional placeholder inspection lines so every interaction can be exercised;
# the official story dialogue (witnesses, Anselm, Teo, Pip, the Warden...) is implemented in M2+ from docs/episodes/episode-03/STORY_PLAN.md.
const PLACEHOLDER = "[M1 placeholder: investigation content arrives in M2.]"
const INSPECT = {
 "notice":[{"who":"NARRATOR","text":"A weathered notice is pinned to the stall pole. "+PLACEHOLDER}],
 "witness_a":[{"who":"NARRATOR","text":"A market resident. "+PLACEHOLDER}],
 "witness_b":[{"who":"NARRATOR","text":"A market resident. "+PLACEHOLDER}],
 "witness_c":[{"who":"NARRATOR","text":"A market resident. "+PLACEHOLDER}],
 "vendor":[{"who":"NARRATOR","text":"A stall keeper. "+PLACEHOLDER}],
 "signal_1":[{"who":"NARRATOR","text":"A speaker hisses with static. "+PLACEHOLDER}],
 "signal_2":[{"who":"NARRATOR","text":"A speaker hisses with static. "+PLACEHOLDER}],
 "signal_3":[{"who":"NARRATOR","text":"A speaker hisses with static. "+PLACEHOLDER}],
 "journal":[{"who":"NARRATOR","text":"A hidden journal. "+PLACEHOLDER}],
 "terminal_a":[{"who":"NARRATOR","text":"An access terminal. "+PLACEHOLDER}],
 "anselm":[{"who":"NARRATOR","text":"A man in a faded registry uniform. "+PLACEHOLDER}],
 "records":[{"who":"NARRATOR","text":"Shelves of records. "+PLACEHOLDER}],
 "archive_door":[{"who":"NARRATOR","text":"A sealed archive door. "+PLACEHOLDER}],
 "pip":[{"who":"NARRATOR","text":"A child lingers in the alley. "+PLACEHOLDER}],
 "fragment_1":[{"who":"NARRATOR","text":"A faded mark on the wall. "+PLACEHOLDER}],
 "fragment_2":[{"who":"NARRATOR","text":"A faded mark on the wall. "+PLACEHOLDER}],
 "fragment_3":[{"who":"NARRATOR","text":"A faded mark on the wall. "+PLACEHOLDER}],
 "lever":[{"who":"NARRATOR","text":"An old lever grinds into place somewhere nearby. A shortcut opens."}],
 "decoder":[{"who":"NARRATOR","text":"Signal-decoding equipment. "+PLACEHOLDER}],
 "teo":[{"who":"NARRATOR","text":"A watchful old keeper. "+PLACEHOLDER}],
 "board":[{"who":"NARRATOR","text":"An evidence board. "+PLACEHOLDER}],
 "relay_map":[{"who":"NARRATOR","text":"A relay map, partly broken. "+PLACEHOLDER}],
 "resonator_1":[{"who":"NARRATOR","text":"A silent resonator. "+PLACEHOLDER}],
 "resonator_2":[{"who":"NARRATOR","text":"A silent resonator. "+PLACEHOLDER}],
 "resonator_3":[{"who":"NARRATOR","text":"A silent resonator. "+PLACEHOLDER}],
 "archive_gate":[{"who":"NARRATOR","text":"A sealed archive gate. "+PLACEHOLDER}]
}
const LOCKED = {
 "shortcut":"LOCKED  /  SOMETHING HERE CAN BE OPENED FROM ANOTHER SIDE",
 "tower":"LOCKED  /  THE WAY TO THE TOWER IS NOT OPEN YET"
}
