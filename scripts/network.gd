extends Node2D

var state = {
	players = {}
}

var start_player = false 

signal start_game
signal update_state
signal ready_player
signal moviment_other_player
signal match_found

var client: NakamaClient
var session: NakamaSession
var socket = null
var room_id = null

#IP padrão
var DEFAULT_HOST = '127.0.0.1'
#IP da maquina na rede local
var PC_HOST = '192.168.0.7'

func _ready():
	client = Nakama.create_client("nakama_godot", PC_HOST, 7350, "http")

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
	var response: NakamaAPI.ApiRpc = await socket.rpc_async("create-match", "")
	var match_id = JSON.parse_string(response.payload).matchId
	await join_room(match_id)
	return match_id

func join_room(match_id):
	var joined_match = await socket.join_match_async(match_id)
	if joined_match.is_exception():
		print("An error occurred: %s" % joined_match)
		return null

	for player in joined_match.presences:
		state.players[player.user_id] = player
		
	room_id = match_id
	get_state_server(joined_match.match_id)
	return joined_match.match_id

func go_match():
	var min_players = 2
	var max_players = 3
	var query = "*"
	var matchmaker_ticket: NakamaRTAPI.MatchmakerTicket = await socket.add_matchmaker_async(query, min_players, max_players)

func _on_matchmaker_matched(p_matched : NakamaRTAPI.MatchmakerMatched):
	await join_room(p_matched.match_id)
	emit_signal("match_found")

func get_state_server(match_id):
	var response: NakamaAPI.ApiRpc = await socket.rpc_async("get-state-match", JSON.stringify({ "matchId": match_id }))
	state = JSON.parse_string(JSON.parse_string(response.payload).label)
	emit_signal("update_state")

func create_socket():
	socket = Nakama.create_socket_from(client)
	var connected: NakamaAsyncResult = await socket.connect_async(session)
	if connected.is_exception():
		print("An error occurred: %s" % connected)
		return
	socket.received_match_presence.connect(self._on_match_presence)
	socket.received_match_state.connect(self._on_match_state)
	socket.received_matchmaker_matched.connect(self._on_matchmaker_matched)

func _on_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		state.players[p.user_id] = p
		get_state_server(room_id)

	for p in p_presence.leaves:
		state.players.erase(p.user_id)
		get_state_server(room_id)

func _on_match_state(p_state: NakamaRTAPI.MatchData):
	match p_state.op_code:
		OP_CODES.READY:
			emit_signal("ready_player", JSON.parse_string(p_state.data).userId)
		OP_CODES.LETS_GO:
			if !start_player:
				start_player = true
				emit_signal('start_game')
		OP_CODES.POSITION_PLAYER:
			var data = JSON.parse_string(p_state.data)
			if data.id != Network.session.user_id:
				emit_signal("moviment_other_player", data)
			

func send_state_room(match_id, new_state, op_code):
	socket.send_match_state_async(match_id, op_code, JSON.stringify(new_state))
