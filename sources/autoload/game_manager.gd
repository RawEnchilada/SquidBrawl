extends Node

const HOST_ID = 1
const ADDRESS = "127.0.0.1"
const PORT = 4200
const GAME_SCENE = preload("res://sources/game/game.tscn")
const GAME_OVER_SCENE = preload("res://sources/ui/game_over/game_over.tscn")

var peer:ENetMultiplayerPeer = null
var game_in_progress:Game = null
var paused = false
var game_ended = false

var local_id = -1
var local_player : Player = null

func is_host() -> bool:
	return local_id == HOST_ID

# Host only
var players_data = []

func host_game(loading_screen:LoadingScreen):
	loading_screen.label.text = "Creating server..."
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	init_game()
	add_player_data(local_id,Settings.user_name,Settings.user_color)
	game_in_progress.add_active_player(local_id,Settings.user_name,Settings.user_color)
	loading_screen.queue_free()
	peer.connect("peer_connected",Callable(self,"ask_for_user_data"))
	peer.connect("peer_disconnected",Callable(self,"remove_player"))


func ask_for_user_data(peer_id:int):
	rpc_id(peer_id, "host_asked_for_user_data")

@rpc
func host_asked_for_user_data():
	rpc_id(1, "client_sent_user_data", local_id, Settings.user_name, Settings.user_color)

@rpc("any_peer")
func client_sent_user_data(peer_id:int, player_name:String, player_color:Color):
	add_player_data(peer_id, player_name, player_color)
	game_in_progress.add_active_player(peer_id, player_name, player_color)

func join_game(loading_screen:LoadingScreen):
	loading_screen.label.text = "Connecting..."
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ADDRESS, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	init_game()
	loading_screen.queue_free()

func add_player_data(peer_id:int, player_name:String, player_color:Color):
	players_data.append({
		"id": peer_id,
		"name": player_name,
		"color": player_color
	})

func remove_player(peer_id:int):
	var to_remove = null
	for data in players_data:
		if data["id"] == peer_id:
			to_remove = data
			break
	players_data.erase(to_remove)
	game_in_progress.remove_active_player(peer_id)

func leave_game():
	if(local_id == HOST_ID):
		rpc("leave_game_remote")
	else:
		leave_game_remote()
	peer.close()
	peer = null

@rpc("call_local")
func leave_game_remote():
	game_ended = true
	paused = true
	game_in_progress.queue_free()
	SpawnArea.spawner_areas.clear()
	game_in_progress = null
	local_id = -1
	local_player = null
	get_tree().change_scene_to_file("res://sources/main.tscn")

func init_game():
	game_in_progress = GAME_SCENE.instantiate()
	get_tree().get_root().add_child(game_in_progress)
	game_ended = false
	paused = false

func restart_game():
	rpc("restart_game_remote")

@rpc("call_local")
func restart_game_remote():
	game_in_progress.queue_free()
	SpawnArea.spawner_areas.clear()
	init_game()
	if(is_host()):
		for data in players_data:
			game_in_progress.add_active_player(data["id"], data["name"], data["color"])

func init_player(player:Player):
	player.connect("weapon_cooldown_changed",Callable(game_in_progress.hud,"weapon_cooldown_changed"))
	player.connect("skill_cooldown_changed",Callable(game_in_progress.hud,"skill_cooldown_changed"))


func game_over(winner:Player):
	if(local_id == HOST_ID):
		rpc("game_over_remote", winner.id, winner.player_name)

@rpc("call_local")
func game_over_remote(winner_id:int, winner_name:String):
	game_ended = true
	paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var player_name = winner_name
	if(local_id == winner_id):
		player_name = ""
	var game_over_ui = GAME_OVER_SCENE.instantiate()
	game_over_ui.winner_name = player_name
	game_in_progress.get_node("CanvasLayer").add_child(game_over_ui)
