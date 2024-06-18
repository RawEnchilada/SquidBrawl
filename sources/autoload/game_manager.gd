extends Node

const HOST_ID = 1
const ADDRESS = "127.0.0.1"
const PORT = 4200
const GAME_SCENE = preload("res://sources/game/game.tscn")

var peer:ENetMultiplayerPeer = null
var game_in_progress:Game = null
var paused = false

var local_id = -1
var local_player : Player = null

func host_game(loading_screen:LoadingScreen):
	loading_screen.label.text = "Creating server..."
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	game_in_progress = GAME_SCENE.instantiate()
	get_tree().get_root().add_child(game_in_progress)
	game_in_progress.add_player(local_id,Settings.user_name,Settings.user_color)
	loading_screen.queue_free()
	peer.connect("peer_connected",Callable(self,"ask_for_user_data"))
	peer.connect("peer_disconnected",Callable(game_in_progress,"remove_player"))


func ask_for_user_data(peer_id:int):
	rpc_id(peer_id, "host_asked_for_user_data")

@rpc
func host_asked_for_user_data():
	rpc_id(1, "client_sent_user_data", Settings.user_name, Settings.user_color)

@rpc("any_peer")
func client_sent_user_data(player_name:String, player_color:Color):
	game_in_progress.add_player(local_id, player_name, player_color)

func join_game(loading_screen:LoadingScreen):
	loading_screen.label.text = "Connecting..."
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ADDRESS, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	game_in_progress = GAME_SCENE.instantiate()
	get_tree().get_root().add_child(game_in_progress)
	loading_screen.queue_free()


func end_game():
	local_id = -1
	local_player = null
	peer.close()
	peer = null
	game_in_progress.queue_free()
	game_in_progress = null


func init_player(player:Player):
	player.connect("weapon_cooldown_changed",Callable(game_in_progress.hud,"weapon_cooldown_changed"))
	player.connect("skill_cooldown_changed",Callable(game_in_progress.hud,"skill_cooldown_changed"))