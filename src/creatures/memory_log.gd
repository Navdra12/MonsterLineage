class_name MemoryLog
extends RefCounted
## Bounded significant-event memory; low-importance events are forgotten first.

var capacity: int = 32
var entries: Array[Dictionary] = []

func remember(event_id: StringName, importance: float, payload: Dictionary) -> void:
	entries.append({
		&"event_id": event_id,
		&"importance": importance,
		&"payload": payload.duplicate(true),
	})
	_prune_to_capacity()

func has_event(event_id: StringName) -> bool:
	return not get_event(event_id).is_empty()

func get_event(event_id: StringName) -> Dictionary:
	for entry in entries:
		if entry.event_id == event_id:
			return entry
	return {}

func _prune_to_capacity() -> void:
	while entries.size() > maxi(capacity, 0):
		var lowest_index := 0
		for index in range(1, entries.size()):
			if float(entries[index].importance) < float(entries[lowest_index].importance):
				lowest_index = index
		entries.remove_at(lowest_index)
