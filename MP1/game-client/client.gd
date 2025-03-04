extends Node

const PORT = 9004 # https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers says this seems safe for now

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var _connected_peer_ids = []


func _ready():
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_connect_button_up():
	print("Connecting client...")
	var err = multiplayer_peer.create_client("127.0.0.1",PORT)
	
	if err != OK:
		printerr("Failure to create Client. Code: " + str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer
	print("Client connected to server.")
	


func _on_disconnect_button_up():
	multiplayer_peer.close()
	print("Client disconnected from server.")


func _on_server_disconnected() -> void:
	multiplayer_peer.close()
	print("Connection to server lost.")


@rpc func sync_player_list(connected_peer_ids) -> void:
	self._connected_peer_ids = connected_peer_ids
	#multiplayer_peer.get_unique_id()
	print("Currently connected players: " + str(_connected_peer_ids))
