extends RefCounted
class_name MissionData
# The two missions with a full definition (1-1, 1-2) take their values from MissionDefs; the rest are placeholders in the list.
const STORY = [
 {"id":"1-1"},
 {"id":"1-2"},
 {"id":"1-3","title":"The relay keeper","playable":false},
 {"id":"1-4","title":"A debt to lightning","playable":false},
 {"id":"1-5","title":"Glasshound pursuit","playable":false},
 {"id":"1-6","title":"A city beneath the city","playable":false},
 {"id":"1-7","title":"The Null surgeon","playable":false},
 {"id":"1-8","title":"A friend's frequency","playable":false},
 {"id":"1-9","title":"Break the broadcast","playable":false},
 {"id":"1-10","title":"Director Vaust","playable":false}
]
static func story() -> Array:
 var list=[]
 for entry in STORY:
  if MissionDefs.has_mission(entry.id):
   var d=MissionDefs.get_def(entry.id)
   list.append({"id":d.id,"title":d.title_case,"location":d.location,"description":d.description,"energy":d.energy,"playable":d.playable})
  else:
   list.append(entry)
 return list
