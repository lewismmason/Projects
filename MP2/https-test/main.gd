extends Node2D


func _ready():
	# Just spawn in the client
	var c = load("res://Client/client.tscn").instantiate()
	self.add_child(c)
