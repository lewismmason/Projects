extends Node

const PORT = 9004 # https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers says this seems safe for now
const MAX_CLIENTS = 2

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var connected_peer_ids : Array = []

# I don't like that I have to copy paste stuff like this enum with this method of dedicated servers.
# A potential fix is to not separate server and client, making clients able to run in "full mode" (client) or a low-cost mode (server)
# where the low cost mode does not run any UI, etc, and only holds game state/moves. TODO after I finish the game with this yuck method for practice...
enum RPS {NONE, ROCK, PAPER, SCISSORS} 
var connected_peer_moves : Array = [] # Array with moves corresponding to users in the connected_peer_ids


func _ready():
	var err = multiplayer_peer.create_server(PORT,MAX_CLIENTS)

	if err != OK: 
		printerr("Failure to create server. Code: " + str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer

	multiplayer_peer.peer_connected.connect(_on_peer_connected)
	multiplayer_peer.peer_disconnected.connect(_on_peer_disconnected)
	print("Server created.")


func _on_peer_connected(new_peer_id : int) -> void:
	print('Player ' + str(new_peer_id) + ' is joining...')
	await get_tree().create_timer(1.).timeout
	self._add_player(new_peer_id)


func _add_player(new_peer_id : int) -> void:
	print('Player ' + str(new_peer_id) + ' joined.')
	connected_peer_ids.append(new_peer_id)
	print('Connected players: ' + str(connected_peer_ids))
	self._update_list()
	connected_peer_moves.append(RPS.NONE)
	$"CanvasLayer/Client Moves".text = str(connected_peer_moves)
	rpc('sync_player_list', connected_peer_ids) # TODO read rpc doc and make sure its safe


func _on_peer_disconnected(leaving_peer_id) -> void:
	await get_tree().create_timer(1.).timeout
	self._remove_player(leaving_peer_id)


func _remove_player(peer_id : int) -> void:
	var peer_id_idx = connected_peer_ids.find(peer_id)
	
	if peer_id_idx != -1:
		connected_peer_ids.remove_at(peer_id_idx)
		connected_peer_moves.remove_at(peer_id_idx)
		$"CanvasLayer/Client Moves".text = str(connected_peer_moves)
	
	print('Player ' + str(peer_id) + ' disconnected.')
	self._update_list()
	rpc('sync_player_list', connected_peer_ids)


func _update_list() -> void: 
	$"CanvasLayer/Connected Clients".text = str(connected_peer_ids)


# Server must have rpc functions, called on client
#region RPC functions

@rpc("authority", "call_remote")
func sync_player_list(connected_peer_ids) -> void:
	print("Function sync_player_list ran on server, nothing occurs.")


@rpc("any_peer", "call_remote")
func move_selected(peer_id : int, peer_move : int) -> void:
	var idx = connected_peer_ids.find(peer_id)

	if idx == -1: 
		printerr("Invalid peer ID called for move_selected.")
		return
	
	if connected_peer_moves.size() < idx:
		printerr("Peer moves array size less than the indix changed.")
		return

	if not RPS.values().has(peer_move):
		printerr("Invalid peer move.")
		return

	connected_peer_moves[idx] = peer_move
	$"CanvasLayer/Client Moves".text = str(connected_peer_moves)

	# If both players have selected a move, see who wins
	if connected_peer_moves.size() != 2: return # only one client connected
	if connected_peer_moves[0] == RPS.NONE or connected_peer_moves[1] == RPS.NONE: return # only one client has done their move
	
	print("Both clients selected a move, determining winner...")
	
	var d = connected_peer_moves[0] - connected_peer_moves[1] # sneaky way to determine winner based on the enum!
	
	if d == 0:
		print("Tie, both players are awarded points.")
		rpc("peer_winner",-1)
	elif d == 1 or d == -2: 
		print("Peer " + str(connected_peer_ids[0]) + " won the round!")
		rpc("peer_winner",connected_peer_ids[0])
	elif d == -1 or d == 2:
		print("Peer " + str(connected_peer_ids[1]) + " won the round!")
		rpc("peer_winner",connected_peer_ids[1])
		


@rpc("authority", "call_local")
func peer_winner(peer_id : int) -> void:
	for i in range(0,connected_peer_moves.size()):
		connected_peer_moves[i] = RPS.NONE # is this a race condition? IE if the client disconnects at exactly this point will this crash?

#endregion
