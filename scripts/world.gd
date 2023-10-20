extends Panel

@onready var player_preload = preload("res://scenes/player.tscn")
@onready var other_player_preload = preload("res://scenes/other_player.tscn")

func _ready():
	Network.connect("moviment_other_player", moviment_other_player)
#	Network.connect("update_players_in_room",update_players_in_room)
	instance_my_player()
	instance_other_players()
	pass

func moviment_other_player(data):
	var other_players = get_node("other_players").get_children()
	for player in other_players:
		if player.name == data.id:
			player.move_to(Vector2(data.position.x, data.position.y))

func instance_my_player():
	var player = player_preload.instantiate()
	var player_session_data = Network.state.players[Network.session.user_id]
	player.position.x = player_session_data['position']['x']
	player.position.y = player_session_data['position']['y']
	
	if Network.session:
		player.name = Network.session.user_id
	else:
		player.name = 'player'

	player.connect('move', send_position_player)
	add_child(player)
	player.set_my_name(Network.session.username)

func send_position_player(data):
	await Network.send_state_room(Network.room_id, data, OP_CODES.SEND_POSITION_PLAYER)

func instance_other_players():
	var other_players = Network.state.players
	var my_id = Network.session.user_id
	
	for id in other_players:
		if id != my_id:
			var p = other_player_preload.instantiate()
			p.position.x = other_players[id]['position']['x']
			p.position.y = other_players[id]['position']['y']
			p.name = other_players[id]['presence'].userId
			get_node("other_players").add_child(p)
			p.set_my_name(other_players[id]['presence'].username)

func move_other_player(data_string):
	var data = JSON.parse_string(JSON.parse_string(data_string))
	var other_player = get_node("other_players/" + data['id'])
	other_player.move_to(Vector2(int(data['position']['x']), int(data['position']['y'])))

func update_players_in_room():
	var players_removed = get_node("other_players").get_children()
	for player in players_removed:
		get_node("other_players").remove_child(player)
	
	instance_other_players()
