extends RefCounted

var failures: Array[String] = []
var RngService: Variant

func assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)

func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (actual: %s, expected: %s)" % [message, actual, expected])
