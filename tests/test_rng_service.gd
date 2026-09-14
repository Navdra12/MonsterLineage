extends "res://tests/test_case.gd"

func run() -> void:
	RngService.configure(123456)
	var a: RandomNumberGenerator = RngService.stream(&"world")
	var first := [a.randi(), a.randi(), a.randi()]

	RngService.configure(123456)
	var b: RandomNumberGenerator = RngService.stream(&"world")
	var second := [b.randi(), b.randi(), b.randi()]

	assert_eq(first, second, "same root seed and stream ID must reproduce sequence")

	RngService.configure(123456)
	var c: RandomNumberGenerator = RngService.stream(&"offspring")
	assert_true(c.randi() != first[0], "different stream IDs must not share the same first value")
