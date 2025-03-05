extends Node

const PORT = 9004 # https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers says this seems safe for now
const MAX_CLIENTS = 2

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var connected_peer_ids = []

func _ready():
	var err = multiplayer_peer.create_server(PORT,MAX_CLIENTS)

	if err != OK: 
		printerr("Failure to create server. Code: " + str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer

	#multiplayer_peer.set_bind_ip("127.0.0.1")
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
	rpc('sync_player_list', connected_peer_ids) # TODO read rpc doc and make sure its safe


func _on_peer_disconnected(leaving_peer_id) -> void:
	await get_tree().create_timer(1.).timeout
	self._remove_player(leaving_peer_id)


func _remove_player(peer_id : int) -> void:
	var peer_id_idx = connected_peer_ids.find(peer_id)
	
	if peer_id_idx != -1:
		connected_peer_ids.remove_at(peer_id_idx)
	
	print('Player ' + str(peer_id) + ' disconnected.')
	self._update_list()
	rpc('sync_player_list', connected_peer_ids)


func _update_list() -> void: 
	$"CanvasLayer/Connected Clients".text = str(connected_peer_ids)


# Server must have rpc functions, called on client
@rpc func sync_player_list(connected_peer_ids) -> void:
	pass
