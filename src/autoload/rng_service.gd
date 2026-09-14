extends Node

var _root_seed: int = 1
var _streams: Dictionary = {}

func configure(root_seed: int) -> void:
	_root_seed = root_seed
	_streams.clear()

func stream(stream_id: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_id):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("%s:%s" % [_root_seed, String(stream_id)])
		_streams[stream_id] = rng
	return _streams[stream_id]
