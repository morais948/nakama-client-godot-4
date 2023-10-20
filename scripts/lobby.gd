extends CanvasLayer

#other_scenes
@onready var world_scene = preload("res://scenes/world.tscn")

#sections
@onready var section_btns_actions = $btns
@onready var section_room = $room
@onready var section_join_room = $join_room
@onready var section_finding_players = $search_players

#actions btns
@onready var btn_create = $btns/create
@onready var btn_join = $btns/join
@onready var btn_match = $btns/match

#room current
@onready var id_room_label = $room/info/id
@onready var player_label = $room/players/label
@onready var btn_copy = $room/info/copy
@onready var btn_ready = $room/info/ready

#join room
@onready var id_room_to_send = $join_room/id_room_to_send
@onready var btn_joined_room = $join_room/send
@onready var btn_back = $join_room/back

#info elemetns
@onready var info_poppup = $info_popup
@onready var label_info = $info_popup/info

#match elements
@onready var tbn_cancel = $search_players/cancel

var my_user_id = null
var min_players = false

func _ready():
	Network.connect("update_state", update_state)
	Network.connect("ready_player", ready_player)
	Network.connect("start_game", start_game)
	Network.connect("match_found", match_found)
	
	btn_copy.connect("button_down", copy_id)
	btn_create.connect("button_down", create_room)
	btn_join.connect("button_down", join_room)
	btn_joined_room.connect("button_down", send_join_room)
	btn_ready.connect("button_down", ready)
	btn_match.connect("button_down", go_match)
	btn_back.connect("button_down", back_from_join)
	tbn_cancel.connect("button_down", cancel_match)

func cancel_match():
	await Network.remove_match()
	show_info("request canceled")
	section_finding_players.hide()
	section_btns_actions.show()

func back_from_join():
	section_join_room.hide()
	section_btns_actions.show()

func match_found():
	id_room_label.text = Network.room_id
	section_finding_players.hide()
	section_room.show()

func go_match():
	section_btns_actions.hide()
	section_finding_players.show()
	await Network.go_match()

func create_room():
	section_btns_actions.hide()
	section_room.show()
	id_room_label.text = await Network.create_room()

func join_room():
	section_btns_actions.hide()
	section_join_room.show()

func send_join_room():
	var response = await Network.join_room(id_room_to_send.text)
	if response:
		id_room_label.text = response
		section_join_room.hide()
		section_room.show()
	else:
		show_info("full match")

func copy_id():
	DisplayServer.clipboard_set(id_room_label.text)

func update_state():
	var labels = get_node("room/players").get_children()
	for label in labels:
		get_node("room/players").remove_child(label)

	var players = Network.state.players
	for id in players:
		var label = Label.new()
		label.horizontal_alignment = true
		label.name = players[id].presence.userId
		if players[id].isReady:
			label.text = players[id].presence.username + '✅'
		else:
			label.text = players[id].presence.username
		get_node("room/players").add_child(label)

func ready():
	await Network.send_state_room(id_room_label.text, "", OP_CODES.SEND_READY)

func ready_player(user_id):
	var labels = get_node("room/players").get_children()
	for label in labels:
		if label.name == user_id:
			label.text = Network.state.players[user_id].presence.username + '✅'

func start_game():
	get_tree().change_scene_to_packed(world_scene)

func show_info(text):
	label_info.text = text
	info_poppup.popup()

