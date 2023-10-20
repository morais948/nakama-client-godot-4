extends CharacterBody2D

signal move

@onready var label_name = $name
const SPEED = 300.0

func set_my_name(my_name):
	label_name.text = my_name

func get_input():
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_direction * SPEED

func _physics_process(delta):
	send_position_broadcast()
	get_input()
	move_and_slide()

func send_position_broadcast():
	if velocity.length() > 0:
		var data_msg = {
			'id': Network.session.user_id,
			'position': {
				'x': position.x,
				'y': position.y
			}
		}
		emit_signal('move', data_msg)
