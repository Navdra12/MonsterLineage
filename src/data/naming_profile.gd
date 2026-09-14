class_name NamingProfile
extends Resource

@export var profile_id: StringName
@export var onsets: Array[String] = []
@export var nuclei: Array[String] = []
@export var codas: Array[String] = []
@export_range(1, 8, 1) var min_syllables: int = 1
@export_range(1, 8, 1) var max_syllables: int = 2
@export var name_kind_strategies: Dictionary = {}
