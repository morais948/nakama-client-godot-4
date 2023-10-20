extends Node

class_name Util

func _ready():
	randomize()

static func random_integer_between_two_numbers(minimum, maximum):
	return randi() % maximum + minimum

static func random_float_between_two_numbers(minimum, maximum):
	return randf() * (maximum - minimum) + minimum
