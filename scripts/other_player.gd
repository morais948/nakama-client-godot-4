extends CharacterBody2D

@onready var label_name = $name
const SPEED = 300.0
var target_position = null

func set_my_name(my_name):
	label_name.text = my_name

func _process(delta):
	if target_position:
		position = position.move_toward(target_position, SPEED * delta)

func move_to(target_future):
	target_position = target_future
