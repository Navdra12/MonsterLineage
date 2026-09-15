class_name CreatureActor
extends CharacterBody2D
## Scene/controller adapter for controller-independent CreatureState data.

signal state_changed(creature_id: StringName)
signal died(creature_id: StringName)
signal entered_food(food_id: StringName)

const CreatureStateData = preload("res://src/creatures/creature_state.gd")
const ZoneStateData = preload("res://src/world/zone_state.gd")
const BodyPlanData = preload("res://src/data/body_plan_def.gd")

const CELL_SIZE := Vector2(16.0, 16.0)
const BASE_MOVE_SPEED := 80.0
const MOVEMENT_ENERGY_COST := 0.75
const STARVATION_CONDITION_LOSS := 0.20
const FOOD_ENERGY_FACTOR := 0.50
const AGE_SPEED_MODIFIERS := {
	&"hatchling": 0.65,
	&"juvenile": 0.85,
	&"adult": 1.0,
}

var state: CreatureStateData
var zone: ZoneStateData
@export var local_input_enabled := true
var desired_direction := Vector2.ZERO

var _body_plan: BodyPlanData
var _death_emitted := false
var _movement_restraints: Dictionary = {}

func bind_state(new_state: CreatureStateData) -> void:
	state = new_state
	_body_plan = _resolve_body_plan() if state != null else null
	_death_emitted = false
	_check_death()

func bind_zone(new_zone: ZoneStateData) -> void:
	zone = new_zone

## Controllers other than local input can supply the same normalized movement intent.
func set_move_direction(direction: Vector2) -> void:
	desired_direction = direction.limit_length(1.0)

func can_enter_cell(cell_type: StringName) -> bool:
	if _body_plan == null:
		return false
	match cell_type:
		&"forest_floor", &"burrow_floor":
			return _has_capability(&"ground_move")
		&"climbable_wall":
			return _has_capability(&"wall_crawl")
		&"small_gap":
			return _body_plan.size_class <= 1 and _has_capability(&"small_gap")
		&"tree_block", &"burrow_wall":
			return false
	return false

func movement_speed() -> float:
	if state == null or state.genome == null:
		return 0.0
	var genome_speed := maxf(state.genome.get_value(&"move_speed"), 0.0)
	var age_modifier := float(AGE_SPEED_MODIFIERS.get(state.age_stage, 1.0))
	return BASE_MOVE_SPEED * genome_speed * age_modifier * _leg_injury_modifier() * _restraint_modifier()

func apply_movement_restraint(source_id: int, multiplier: float) -> void:
	_movement_restraints[source_id] = clampf(multiplier, 0.0, 1.0)

func clear_movement_restraint(source_id: int) -> void:
	_movement_restraints.erase(source_id)

func velocity_for_direction(direction: Vector2, delta: float) -> Vector2:
	if state == null or state.condition <= 0.0:
		return Vector2.ZERO
	var intended_velocity := direction.limit_length(1.0) * movement_speed()
	if zone != null and not intended_velocity.is_zero_approx():
		if not can_enter_cell(_target_cell_type(intended_velocity, delta)):
			return Vector2.ZERO
	return intended_velocity

func advance_survival(delta_seconds: float, is_moving: bool) -> void:
	if state == null or state.genome == null or delta_seconds <= 0.0:
		_check_death()
		return
	var metabolism := maxf(state.genome.get_value(&"metabolism"), 0.0)
	state.needs.tick(delta_seconds, metabolism)
	if is_moving:
		state.needs.energy = clampf(
			state.needs.energy - delta_seconds * metabolism * MOVEMENT_ENERGY_COST,
			0.0,
			100.0
		)
	if state.needs.hunger >= 90.0:
		state.condition = clampf(
			state.condition - delta_seconds * STARVATION_CONDITION_LOSS,
			0.0,
			100.0
		)
	state_changed.emit(state.creature_id)
	_check_death()

func consume_food(food_id: StringName, nutrition: float) -> void:
	if state == null:
		return
	var useful_nutrition := maxf(nutrition, 0.0)
	var context_tags: Array[StringName] = []
	if state.needs.hunger >= 90.0:
		context_tags.append(&"starvation_save")
	state.needs.hunger = clampf(state.needs.hunger - useful_nutrition, 0.0, 100.0)
	state.needs.energy = clampf(
		state.needs.energy + useful_nutrition * FOOD_ENERGY_FACTOR,
		0.0,
		100.0
	)
	state.food_memory.record_food(food_id, useful_nutrition, context_tags)
	entered_food.emit(food_id)
	state_changed.emit(state.creature_id)

func _physics_process(delta: float) -> void:
	if local_input_enabled:
		set_move_direction(Input.get_vector("move_left", "move_right", "move_up", "move_down"))
	var intended_velocity := velocity_for_direction(desired_direction, delta)
	advance_survival(delta, not intended_velocity.is_zero_approx())
	if state == null or state.condition <= 0.0:
		velocity = Vector2.ZERO
		return
	velocity = intended_velocity
	move_and_slide()

func _target_cell_type(intended_velocity: Vector2, delta: float) -> StringName:
	var target_position := global_position + intended_velocity * maxf(delta, 0.0)
	var cell := Vector2i(floori(target_position.x / CELL_SIZE.x), floori(target_position.y / CELL_SIZE.y))
	return zone.cell_at(cell)

func _resolve_body_plan() -> BodyPlanData:
	if state.genome == null or state.genome.body_plan_id.is_empty():
		return null
	var resource_path := "res://content/body_plans/%s.tres" % state.genome.body_plan_id
	if not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as BodyPlanData

func _has_capability(capability: StringName) -> bool:
	return _body_plan != null and _body_plan.movement_capabilities.has(capability)

func _leg_injury_modifier() -> float:
	if state == null or not state.injuries.has_injury(&"legs"):
		return 1.0
	var injury := state.injuries.get_injury(&"legs")
	var severity := float(injury.get(&"severity", 0.0))
	return clampf(1.0 - severity * 0.60, 0.20, 1.0)

func _restraint_modifier() -> float:
	var modifier := 1.0
	for value: float in _movement_restraints.values():
		modifier *= clampf(value, 0.0, 1.0)
	return clampf(modifier, 0.0, 1.0)

func _check_death() -> void:
	if state == null or _death_emitted or state.condition > 0.0:
		return
	_death_emitted = true
	died.emit(state.creature_id)
