extends Node

const PORT = 9004 # https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers says this seems safe for now

var multiplayer_peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var _connected_peer_ids = []

enum RPS {NONE, ROCK, PAPER, SCISSORS}
var selected = RPS.NONE


enum PLAYER {PLAYER, OPPONENT, NONE}
var winning = PLAYER.NONE
var player_score = 0
var opponent_score = 0


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
	reset_game()
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
		$CanvasLayer/Score.visible = true
		$CanvasLayer/VBoxContainer/ID.text = str(multiplayer_peer.get_unique_id())
		
	elif multiplayer_peer.get_connection_status() == multiplayer_peer.ConnectionStatus.CONNECTION_DISCONNECTED:
		$CanvasLayer/VBoxContainer/Connect.disabled = false
		$CanvasLayer/VBoxContainer/Connect.modulate = Color(1,1,1)
		$CanvasLayer/VBoxContainer/Disconnect.disabled = true
		$CanvasLayer/VBoxContainer/Disconnect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/ID.text = "Disconnected."
		$CanvasLayer/Gameplay.visible = false
		$CanvasLayer/Score.visible = false

	elif multiplayer_peer.get_connection_status() == multiplayer_peer.ConnectionStatus.CONNECTION_CONNECTING:
		$CanvasLayer/VBoxContainer/Connect.disabled = true
		$CanvasLayer/VBoxContainer/Connect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/Disconnect.disabled = true
		$CanvasLayer/VBoxContainer/Disconnect.modulate = Color(0.5,0.5,0.5)
		$CanvasLayer/VBoxContainer/ID.text = "Connecting..."
		$CanvasLayer/Gameplay.visible = false
		$CanvasLayer/Score.visible = false


func reset_game() -> void:
	#reset score, reset turn, etc
	reset_turn()


func reset_turn() -> void:
	self._select(RPS.NONE)
 

func reset_score() -> void:
	self.opponent_score = 0
	self.player_score = 0
	self._update_score_visual()


func _select(s : int) -> void:
	self.selected = s
	$CanvasLayer/Gameplay/Player/Rock/Rock.disabled = true
	$CanvasLayer/Gameplay/Player/Paper/Paper.disabled = true
	$CanvasLayer/Gameplay/Player/Scissors/Scissors.disabled = true

	match s:
		RPS.ROCK:
			$CanvasLayer/Gameplay/Player/Rock.self_modulate = Color(0.8,1,0.8)
			$CanvasLayer/Gameplay/Player/Paper.modulate = Color(1,1,1,0.3)
			$CanvasLayer/Gameplay/Player/Scissors.modulate = Color(1,1,1,0.3)

		RPS.PAPER:
			$CanvasLayer/Gameplay/Player/Rock.modulate = Color(1,1,1,0.3)
			$CanvasLayer/Gameplay/Player/Paper.self_modulate = Color(0.8,1,0.8)
			$CanvasLayer/Gameplay/Player/Scissors.modulate = Color(1,1,1,0.3)

		RPS.SCISSORS:
			$CanvasLayer/Gameplay/Player/Rock.modulate = Color(1,1,1,0.3)
			$CanvasLayer/Gameplay/Player/Paper.modulate = Color(1,1,1,0.3)
			$CanvasLayer/Gameplay/Player/Scissors.self_modulate = Color(0.8,1,0.8)

		RPS.NONE:
			$CanvasLayer/Gameplay/Player/Rock/Rock.disabled = false
			$CanvasLayer/Gameplay/Player/Rock.modulate = Color(1,1,1,1)
			$CanvasLayer/Gameplay/Player/Rock.self_modulate = Color(1,1,1,1)
			$CanvasLayer/Gameplay/Player/Paper/Paper.disabled = false
			$CanvasLayer/Gameplay/Player/Paper.modulate = Color(1,1,1,1)
			$CanvasLayer/Gameplay/Player/Paper.self_modulate = Color(1,1,1,1)
			$CanvasLayer/Gameplay/Player/Scissors/Scissors.disabled = false
			$CanvasLayer/Gameplay/Player/Scissors.modulate = Color(1,1,1,1)
			$CanvasLayer/Gameplay/Player/Scissors.self_modulate = Color(1,1,1,1)

	if multiplayer_peer.get_connection_status() == multiplayer_peer.ConnectionStatus.CONNECTION_CONNECTED:
		rpc("move_selected", multiplayer.get_unique_id(), s)


func _on_rock_button_up(): self._select(RPS.ROCK)


func _on_paper_button_up(): self._select(RPS.PAPER)


func _on_scissors_button_up(): self._select(RPS.SCISSORS)


func _update_score_visual() -> void:
	$CanvasLayer/Score/Score/Opponent.text = str(opponent_score)
	$CanvasLayer/Score/Score/Player.text = str(player_score)

#region RPC

@rpc("authority", "call_remote")
func sync_player_list(connected_peer_ids) -> void:
	self._connected_peer_ids = connected_peer_ids
	print("Currently connected players: " + str(_connected_peer_ids))


@rpc("any_peer", "call_remote")
func move_selected(peer_id : int, peer_move : int) -> void:
	print('Function move_selected ran on client, nothing occurs.')


@rpc("authority", "call_local")
func peer_winner(peer_id : int) -> void:
	if peer_id == multiplayer.get_unique_id():
		print("Player won the round.")
		player_score += 1 
	elif _connected_peer_ids.has(peer_id): # sneaky way to check if opponent won, depends on previous if check.
		print("Opponent won the round.")
		opponent_score += 1
	elif peer_id == -1:
		print("Tie. Both players are awarded points because thats more fun!")
		player_score += 1 
		opponent_score += 1
	else:
		printerr("Peer winner has an invalid peer_id of " + str(peer_id) + ".") # Should never reach here?

	self._update_score_visual()
	self.reset_turn()
#endregion
