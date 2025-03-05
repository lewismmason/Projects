extends Node

const PORT = 9004 # https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers says this seems safe for now

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var _connected_peer_ids = []


func _ready():
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_server_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	update_connection_button_status()


func _on_connect_button_up():
	print("Connecting client...")
	var err = multiplayer_peer.create_client("127.0.0.1",PORT)

	if err != OK:
		printerr("Failure to create Client. Code: " + str(err))
		return

	multiplayer.multiplayer_peer = multiplayer_peer
	update_connection_button_status()
	$ConnectionTimeOut.start()


func _on_disconnect_button_up():
	multiplayer_peer.close()
	update_connection_button_status()
	print("Client disconnected from server.")


func _on_server_disconnected() -> void:
	multiplayer_peer.close()
	update_connection_button_status()
	print("Connection to server lost.")


func _on_server_connected() -> void:
	update_connection_button_status()


func _on_connection_time_out_timeout():
	print("Connection timeout triggered.")
	multiplayer_peer.close()


func _on_connection_failed() -> void:
	print("Connection to server failed.")
	update_connection_button_status()
	$CanvasLayer/VBoxContainer/ID.text = "Failed."


func update_connection_button_status() -> void:
	$ConnectionTimeOut.stop() # We stop the timer here...
	
	if multiplayer_peer.get_connection_status() == multiplayer_peer.ConnectionStatus.CONNECTION_CONNECTED:
		$CanvasLayer/VBoxContainer/Connect.disabled = true
		$CanvasLayer/VBoxContainer/Connect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/Disconnect.disabled = false
		$CanvasLayer/VBoxContainer/Disconnect.modulate = Color(1,1,1)
		$CanvasLayer/Gameplay.visible = true
		$CanvasLayer/VBoxContainer/ID.text = str(multiplayer_peer.get_unique_id())
		
	elif multiplayer_peer.get_connection_status() == multiplayer_peer.ConnectionStatus.CONNECTION_DISCONNECTED:
		$CanvasLayer/VBoxContainer/Connect.disabled = false
		$CanvasLayer/VBoxContainer/Connect.modulate = Color(1,1,1)
		$CanvasLayer/VBoxContainer/Disconnect.disabled = true
		$CanvasLayer/VBoxContainer/Disconnect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/ID.text = "Disconnected."
		$CanvasLayer/Gameplay.visible = false
		
	elif multiplayer_peer.get_connection_status() == multiplayer_peer.ConnectionStatus.CONNECTION_CONNECTING:
		$CanvasLayer/VBoxContainer/Connect.disabled = true
		$CanvasLayer/VBoxContainer/Connect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/Disconnect.disabled = true
		$CanvasLayer/VBoxContainer/Disconnect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/ID.text = "Connecting..."
		$CanvasLayer/Gameplay.visible = false


#region RPC
@rpc 
func sync_player_list(connected_peer_ids) -> void:
	self._connected_peer_ids = connected_peer_ids
	#multiplayer_peer.get_unique_id()
	print("Currently connected players: " + str(_connected_peer_ids))
#endregion
