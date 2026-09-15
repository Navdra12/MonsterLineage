class_name WebSystem
extends Node2D
## Creature-agnostic composition service for web placement, silk reserves,
## trigger events, and owner vibration memories.

signal web_triggered(owner_id: StringName, intruder_id: StringName, world_position: Vector2)

const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const CreatureActorData = preload("res://src/creatures/creature_actor.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const WebSegmentData = preload("res://src/gameplay/web/web_segment.gd")
const WEB_SEGMENT_SCENE = preload("res://scenes/web_segment.tscn")

const CELL_SIZE := Vector2(16.0, 16.0)
const MAX_PLACEMENT_DISTANCE := 48.0
const FED_HUNGER_LIMIT := 75.0
const SENSORY_RANGE_PIXELS := 96.0
const HIGH_IMPORTANCE := 0.9
const VALID_TERRAIN: Array[StringName] = [
	&"forest_floor", &"burrow_floor", &"climbable_wall", &"small_gap",
]

var _zone: ZoneStateData
var _states: Dictionary = {}
var _actors: Dictionary = {}
var _silk_reserves: Dictionary = {}

func bind_zone(new_zone: ZoneStateData) -> void:
	_zone = new_zone

func register_creature(creature: CreatureStateData, actor: CreatureActorData) -> void:
	if creature == null or actor == null or creature.creature_id.is_empty():
		return
	_states[creature.creature_id] = creature
	_actors[creature.creature_id] = actor
	if not _silk_reserves.has(creature.creature_id):
		_silk_reserves[creature.creature_id] = silk_capacity(creature)

func place_web(owner: CreatureStateData, world_position: Vector2, normal: Vector2) -> WebSegmentData:
	if owner == null or owner.genome == null or _zone == null:
		return null
	var owner_actor: Variant = _actors.get(owner.creature_id)
	if owner_actor == null or not is_instance_valid(owner_actor):
		return null
	if owner_actor.global_position.distance_to(world_position) > MAX_PLACEMENT_DISTANCE:
		return null
	var cell := Vector2i(floori(world_position.x / CELL_SIZE.x), floori(world_position.y / CELL_SIZE.y))
	if not VALID_TERRAIN.has(_zone.cell_at(cell)):
		return null
	var cost := web_cost(owner)
	var reserve := silk_reserve(owner.creature_id)
	if cost <= 0.0 or reserve + 0.00001 < cost:
		return null
	var segment := WEB_SEGMENT_SCENE.instantiate() as WebSegmentData
	segment.configure(
		owner.creature_id,
		owner.genome.get_value(&"web_strength"),
		owner.genome.get_value(&"web_adhesion")
	)
	if not normal.is_zero_approx():
		segment.rotation = normal.angle() + PI * 0.5
	segment.triggered.connect(_on_segment_triggered.bind(segment))
	add_child(segment)
	segment.global_position = world_position
	_silk_reserves[owner.creature_id] = reserve - cost
	return segment

func silk_capacity(owner: CreatureStateData) -> float:
	if owner == null or owner.genome == null:
		return 0.0
	var strength := maxf(owner.genome.get_value(&"web_strength"), 0.0)
	var metabolism := maxf(owner.genome.get_value(&"metabolism"), 0.25)
	return maxf(2.0 + 2.5 * strength / metabolism, 0.0)

func web_cost(owner: CreatureStateData) -> float:
	if owner == null or owner.genome == null:
		return 0.0
	var adhesion := maxf(owner.genome.get_value(&"web_adhesion"), 0.0)
	return 0.75 + adhesion * 0.25

func silk_reserve(creature_id: StringName) -> float:
	return float(_silk_reserves.get(creature_id, 0.0))

func advance_silk(owner: CreatureStateData, delta_seconds: float) -> void:
	if owner == null or owner.genome == null or delta_seconds <= 0.0:
		return
	if owner.needs.hunger > FED_HUNGER_LIMIT or not _silk_reserves.has(owner.creature_id):
		return
	var strength := maxf(owner.genome.get_value(&"web_strength"), 0.0)
	var adhesion := maxf(owner.genome.get_value(&"web_adhesion"), 0.0)
	var metabolism := maxf(owner.genome.get_value(&"metabolism"), 0.25)
	var regeneration_rate := 0.02 * (strength + adhesion) / metabolism
	_silk_reserves[owner.creature_id] = minf(
		silk_reserve(owner.creature_id) + delta_seconds * regeneration_rate,
		silk_capacity(owner)
	)

func _on_segment_triggered(intruder: Node, segment: WebSegmentData) -> void:
	if not intruder is CreatureActorData:
		return
	var intruder_actor := intruder as CreatureActorData
	if intruder_actor.state == null:
		return
	web_triggered.emit(segment.owner_id, intruder_actor.state.creature_id, segment.global_position)
	_remember_vibration(segment, intruder_actor.state.creature_id)

func _remember_vibration(segment: WebSegmentData, intruder_id: StringName) -> void:
	var owner: Variant = _states.get(segment.owner_id)
	var owner_actor: Variant = _actors.get(segment.owner_id)
	if owner == null or owner_actor == null or not is_instance_valid(owner_actor) or owner.genome == null:
		return
	var sensory_range := maxf(owner.genome.get_value(&"sensory_range"), 0.0) * SENSORY_RANGE_PIXELS
	if owner_actor.global_position.distance_to(segment.global_position) > sensory_range:
		return
	owner.memory.remember(&"web_vibration", HIGH_IMPORTANCE, {
		&"world_position": segment.global_position,
		&"intruder_id": intruder_id,
	})
