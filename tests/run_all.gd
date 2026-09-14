extends SceneTree

const SUITE_SCRIPTS: Array[Script] = [
	preload("res://tests/test_rng_service.gd"),
	preload("res://tests/test_genome.gd"),
]

func _initialize() -> void:
	_run()

func _run() -> void:
	var failures: Array[String] = []
	var rng_service := root.get_node_or_null("RngService")
	if rng_service == null:
		printerr("FAIL: RngService autoload is unavailable")
		quit(1)
		return

	for suite_script in SUITE_SCRIPTS:
		var suite: Variant = suite_script.new()
		suite.RngService = rng_service
		suite.run()
		for failure in suite.failures:
			failures.append("%s: %s" % [suite_script.resource_path, failure])

	if failures.is_empty():
		print("PASS: %d suite(s)" % SUITE_SCRIPTS.size())
		quit(0)
		return

	for failure in failures:
		printerr("FAIL: %s" % failure)
	printerr("FAILED: %d assertion(s)" % failures.size())
	quit(1)
