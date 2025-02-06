extends Node

const HOST_ID = 1
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

var players_data = []

func host_game():
	peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	add_player_data(local_id,Settings.user_name,Settings.user_color,Enums.WeaponType.BAZOOKA)
	peer.connect("peer_connected",Callable(self,"on_client_connected"))
	peer.connect("peer_disconnected",Callable(self,"remove_player"))

func join_game():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Settings.ip_address, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	local_id = multiplayer.get_unique_id()
	peer.connect("peer_disconnected",Callable(self,"leave_game"))

func on_client_connected(peer_id:int):
	rpc_id(peer_id, "client_send_user_data")

@rpc
func client_send_user_data():
	rpc_id(HOST_ID, "host_receive_user_data", local_id, Settings.user_name, Settings.user_color, Enums.WeaponType.BAZOOKA)

@rpc("any_peer")
func host_receive_user_data(peer_id:int, player_name:String, player_color:Color, weapon_type:Enums.WeaponType):
	add_player_data(peer_id, player_name, player_color, weapon_type)
	rpc("client_receive_all_user_data", JSON.stringify(players_data))

@rpc
func client_receive_all_user_data(json_str:String):
	var json = JSON.parse_string(json_str)
	for data in json:
		var found = false
		for existing_data in players_data:
			if existing_data["id"] == data["id"]:
				found = true
				break
		if !found:
			var color = Color.from_string(data["color"],Color.WHITE)
			add_player_data(data["id"], data["name"], color, data["weapon_type"])
	
func add_player_data(peer_id:int, player_name:String, player_color:Color, weapon_type:Enums.WeaponType):
	players_data.append({
		"id": peer_id,
		"name": player_name,
		"color": player_color.to_html(false),
		"weapon_type": weapon_type
	})

func remove_player(peer_id:int):
	var to_remove = null
	for data in players_data:
		if data["id"] == peer_id:
			to_remove = data
			break
	players_data.erase(to_remove)
	if(game_in_progress != null):
		game_in_progress.remove_active_player(peer_id)

func reset_game():
	if game_in_progress != null:
		game_in_progress.queue_free()
		Bullet.BULLET_COUNT = 0
		BaseWeapon.WEAPON_COUNT = 0
		game_in_progress = null
		print("game node deleted")

func leave_game(_leaving_peer_id = 0):
	if(is_host()):
		peer.disconnect("peer_disconnected",Callable(self,"remove_player"))
	else:
		peer.disconnect("peer_disconnected",Callable(self,"leave_game"))
	peer.close()
	peer = null
	if(game_in_progress != null):
		reset_game()
		get_tree().change_scene_to_file("res://sources/main.tscn")
	game_ended = true
	paused = true
	local_id = -1
	local_player = null
	players_data = []
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	

func init_game(map_name:String):
	game_in_progress = GAME_SCENE.instantiate()
	game_in_progress.map_name = map_name
	var root = get_tree().get_root()
	if(root.has_node("Main")):
		root.remove_child(root.get_node("Main"))
	root.add_child(game_in_progress)
	for data in players_data:
		game_in_progress.add_active_player(data["id"], data["name"], Color.from_string(data["color"],Color.WHITE),data["weapon_type"])
	game_ended = false
	paused = false
	game_in_progress.start()

func create_weapon_in_game(weapontype:Enums.WeaponType, pos:Vector3 = Vector3.ZERO) -> BaseWeapon:
	if game_in_progress == null:
		return
	print_debug("creating weapon ", weapontype)
	var base_path:String = "res://sources/interactables/weapons/"
	var weapon:BaseWeapon = load(base_path + "bazooka.tscn").instantiate()
	match weapontype:
		Enums.WeaponType.MORTAR:
			weapon = load(base_path + "mortar.tscn").instantiate()
		Enums.WeaponType.SPEAR:
			weapon = load(base_path + "direct.tscn").instantiate()
	game_in_progress.synced_node.add_child(weapon)
	weapon.position = pos
	return weapon

func restart_game():
	peer.refuse_new_connections = true
	rpc("restart_game_remote",Settings.map_name)

@rpc("call_local")
func restart_game_remote(map_name:String):
	if(game_in_progress != null):
		reset_game()
		await get_tree().create_timer(1.0).timeout
	init_game(map_name)

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
	game_in_progress.free_authority_nodes()
	local_player = null

func set_player_weapon_type(peer_id:int,weapon_type:Enums.WeaponType):
	rpc("set_player_weapon_type_remote", peer_id, weapon_type)

@rpc("call_local","any_peer")
func set_player_weapon_type_remote(peer_id:int,weapon_type:Enums.WeaponType):
	for data in players_data:
		if data["id"] == peer_id:
			data["weapon_type"] = weapon_type
