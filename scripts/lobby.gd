extends CanvasLayer

#other_scenes
@onready var world_scene = preload("res://scenes/world.tscn")

#sections
@onready var btns_actions = $btns
@onready var room = $room
@onready var join_room = $join_room

#actions btns
@onready var btn_create = $btns/create
@onready var btn_join = $btns/join
@onready var btn_go = $go

#room current
@onready var id_room_label = $room/info/id
@onready var player_label = $room/players/label
@onready var btn_copy = $room/info/copy

#join room
@onready var id_room_to_send = $join_room/id_room_to_send
@onready var btn_joined_room = $join_room/send

var my_user_id = null
var min_players = false

func _ready():
	Network.connect("user_id_loaded", set_user_id)
	Network.connect("update_players_in_room", update_players_in_room)
	Network.connect("quantity_min_player_in_room", set_visible_btn_go)
	Network.connect("canceled_go", set_hide_btn_go)
	Network.connect("go_to_world_scene", go_to_world_scene)
	
	btn_copy.connect("button_down", copy_id)
	
	btn_create.connect("button_down", create_room)
	btn_join.connect("button_down", show_join_room)
	
	btn_joined_room.connect("button_down", joined_room)
	btn_go.connect("button_down", go_to_world)

func go_to_world_scene():
	get_tree().change_scene_to_packed(world_scene)

func go_to_world():
	await Network.send_state_room(id_room_label.text, 'go_to_world_scene', op_codes.go_to_world_scene)
	get_tree().change_scene_to_packed(world_scene)

func set_visible_btn_go():
	btn_go.show()

func set_hide_btn_go():
	btn_go.hide()

func _process(delta):
	if Network.state.players.values().size() >= 2 and !min_players:
		min_players = true
		await Network.send_state_room(id_room_label.text, 'go', op_codes.quantity_min_player_in_room)
		btn_go.show()
	
	if Network.state.players.values().size() < 2:
		min_players = false
		btn_go.hide()

func create_room():
	btns_actions.hide()
	room.show()
	id_room_label.text = await Network.create_room()

func joined_room():
	id_room_label.text = await Network.join_room(id_room_to_send.text)
	join_room.hide()
	update_players_in_room()
	room.show()

func show_join_room():
	btns_actions.hide()
	join_room.show()

func set_user_id(id):
	my_user_id = id

func copy_id():
	DisplayServer.clipboard_set(id_room_label.text)

func update_players_in_room():
	player_label.text = ''
	var players = Network.state.players
	for id in players:
		player_label.text += '\n' + players[id].username
