class_name WebSegment
extends Area2D
## One creature-owned web trap. Restraint is applied to actor-local transient
## modifiers and never changes inherited movement data.

signal triggered(intruder: Node)
signal broken

const CreatureActorData = preload("res://src/creatures/creature_actor.gd")

var owner_id: StringName
var strength: float = 1.0
var adhesion: float = 1.0
var durability: float = 10.0
var armed := true

var _restrained_actors: Dictionary = {}

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func configure(web_owner_id: StringName, web_strength: float, web_adhesion: float) -> void:
	owner_id = web_owner_id
	strength = maxf(web_strength, 0.0)
	adhesion = maxf(web_adhesion, 0.0)
	durability = strength * 10.0
	armed = durability > 0.0

func restraint_multiplier(target_body_size: float) -> float:
	var useful_size := maxf(target_body_size, 0.1)
	return clampf(useful_size / (useful_size + adhesion), 0.15, 1.0)

func try_trigger(body: Node) -> bool:
	if not armed or body == null or not body is CreatureActorData:
		return false
	var actor := body as CreatureActorData
	if actor.state == null or actor.state.creature_id == owner_id:
		return false
	var actor_key := actor.get_instance_id()
	if _restrained_actors.has(actor_key):
		return false
	var body_size := actor.state.genome.get_value(&"body_size") if actor.state.genome != null else 1.0
	actor.apply_movement_restraint(get_instance_id(), restraint_multiplier(body_size))
	_restrained_actors[actor_key] = actor
	triggered.emit(actor)
	return true

func advance_struggle(actor: CreatureActorData, delta_seconds: float) -> void:
	if not armed or actor == null or not _restrained_actors.has(actor.get_instance_id()):
		return
	if delta_seconds <= 0.0 or actor.desired_direction.is_zero_approx() or actor.state == null or actor.state.genome == null:
		return
	var body_size := maxf(actor.state.genome.get_value(&"body_size"), 0.1)
	var move_strength := maxf(actor.state.genome.get_value(&"move_speed"), 0.1)
	var body_strength := 1.0 + maxf(actor.state.genome.get_value(&"chitin"), 0.0) * 0.25
	durability -= delta_seconds * body_size * move_strength * body_strength
	if durability <= 0.0:
		break_web()

func break_web() -> void:
	if not armed:
		return
	armed = false
	durability = 0.0
	_clear_all_restraints()
	set_deferred("monitoring", false)
	broken.emit()
	if is_inside_tree():
		queue_free()

func _physics_process(delta: float) -> void:
	if not armed:
		return
	for actor_key: int in _restrained_actors.keys():
		var actor: Variant = _restrained_actors[actor_key]
		if not is_instance_valid(actor):
			_restrained_actors.erase(actor_key)
			continue
		advance_struggle(actor, delta)
		if not armed:
			return

func _on_body_entered(body: Node) -> void:
	try_trigger(body)

func _on_body_exited(body: Node) -> void:
	if body == null:
		return
	var actor_key := body.get_instance_id()
	if not _restrained_actors.has(actor_key):
		return
	if body is CreatureActorData:
		(body as CreatureActorData).clear_movement_restraint(get_instance_id())
	_restrained_actors.erase(actor_key)

func _clear_all_restraints() -> void:
	for actor: Variant in _restrained_actors.values():
		if is_instance_valid(actor) and actor is CreatureActorData:
			(actor as CreatureActorData).clear_movement_restraint(get_instance_id())
	_restrained_actors.clear()

func _exit_tree() -> void:
	_clear_all_restraints()
