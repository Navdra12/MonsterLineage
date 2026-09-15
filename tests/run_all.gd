extends SceneTree

const SUITE_SCRIPTS: Array[Script] = [
        preload("res://tests/test_rng_service.gd"),
        preload("res://tests/test_localization_and_naming.gd"),
        preload("res://tests/test_genome.gd"),
        preload("res://tests/test_creature_state.gd"),
	preload("res://tests/test_zone_generator.gd"),
	preload("res://tests/test_ui_models.gd"),
	preload("res://tests/test_web_system.gd"),
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
        var locale_service := root.get_node_or_null("LocaleService")
        if locale_service == null:
                printerr("FAIL: LocaleService autoload is unavailable")
                quit(1)
                return
        for suite_script in SUITE_SCRIPTS:
                var suite: Variant = suite_script.new()
                suite.RngService = rng_service
                if _has_property(suite, &"LocaleService"):
                        suite.LocaleService = locale_service
                if _has_property(suite, &"RegisteredSuitePaths"):
                        var suite_paths: Array[String] = []
                        for registered_script: Script in SUITE_SCRIPTS:
                                suite_paths.append(registered_script.resource_path)
                        suite.RegisteredSuitePaths = suite_paths
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

func _has_property(instance: Object, property_name: StringName) -> bool:
        for property: Dictionary in instance.get_property_list():
                if property.name == property_name:
                        return true
        return false
