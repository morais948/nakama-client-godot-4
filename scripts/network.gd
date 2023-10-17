extends Node2D

var state = {
	players = {}
}

signal update_players_in_room
signal quantity_min_player_in_room
signal canceled_go
signal go_to_world_scene

var client: NakamaClient
# Get the System's unique device identifier
var device_id = OS.get_unique_id()
var session: NakamaSession
var socket = null
#var channel: NakamaRTAPI.Channel

#IP padrão
var DEFAULT_HOST = '127.0.0.1'
#IP da maquina na rede local
var PC_HOST = '192.168.1.73'

func _ready():
	client = Nakama.create_client("nakama_godot", DEFAULT_HOST, 7350, "http")

func register_user(email, password, name):
	session = await client.authenticate_email_async(email, password, name, true)
	if session.is_exception():
		print("An error occurred: %s" % session)
		return session.get_exception().message

func login_user(email, password):
	session = await client.authenticate_email_async(email, password, null, false)
	if session.is_exception():
		print("An error occurred: %s" % session)
		return session.get_exception().message

	await create_socket()

func create_room():
	var created_match: NakamaRTAPI.Match = await socket.create_match_async()
	if created_match.is_exception():
		print("An error occurred: %s" % created_match)
		return

	return created_match.match_id

func join_room(match_id):
	var joined_match = await socket.join_match_async(match_id)
	if joined_match.is_exception():
		print("An error occurred: %s" % joined_match)
		return

	for presence in joined_match.presences:
		state.players[presence.user_id] = presence
		emit_signal("update_players_in_room")

	return joined_match.match_id

func create_socket():
	socket = Nakama.create_socket_from(client)
	var connected: NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		print("An error occurred: %s" % connected)
		return
	socket.received_match_presence.connect(self._on_match_presence)
	socket.received_match_state.connect(self._on_match_state)

func _on_match_state(p_state: NakamaRTAPI.MatchData):
	match p_state.op_code:
		op_codes.quantity_min_player_in_room:
			emit_signal("quantity_min_player_in_room")
		op_codes.canceled_go:
			emit_signal("canceled_go")
		op_codes.go_to_world_scene:
			emit_signal("go_to_world_scene")

	print("Received match state with opcode %s, data %s" % [p_state.op_code, JSON.parse_string(p_state.data)])

func _on_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		state.players[p.user_id] = p
		emit_signal("update_players_in_room")

	for p in p_presence.leaves:
		state.players.erase(p.user_id)
		emit_signal("update_players_in_room")

func send_state_room(match_id, new_state, op_code):
	socket.send_match_state_async(match_id, op_code, JSON.stringify(new_state))

func teste():
	pass
