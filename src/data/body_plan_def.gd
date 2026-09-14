class_name BodyPlanDef
extends Resource
## Shared anatomical template. Numeric traits modify structures; they do not
## grant missing parts or movement capabilities. Treat authored definitions as read-only.

@export var id: StringName
@export var display_key: StringName
@export var base_parts: Array[StringName] = []
@export var movement_capabilities: Array[StringName] = []
## Prototype traversal uses <= 1 for small gaps.
@export var size_class: int = 1
