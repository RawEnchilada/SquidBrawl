class_name Game
extends Node3D

const PLAYER_SCENE = preload("res://sources/characters/player/player.tscn")
const FREE_CAM_SCENE = preload("res://sources/characters/debug_camera/debug_camera.tscn")
const EXPLOSION_EFFECT_SCENE = preload("res://sources/interactables/projectile/explosion_effect.tscn")
const SPLASH_EFFECT_SCENE = preload("res://sources/characters/splash_effect.tscn")


@onready var hud = $CanvasLayer/Hud
@onready var ingame_menu = $CanvasLayer/IngameMenu
@onready var synced_node = $Synced
@onready var island = $Island
@onready var spawner = $Spawner as MultiplayerSpawner

var players = []
var map_seed:int = 0

func init_map(map_state = null):
	if(map_state != null):
		island.LoadChunkDataSerialized(map_state)
	island.CreateIsland(map_seed)

func add_active_player(id:int,player_name:String,player_color:Color):
	var player = PLAYER_SCENE.instantiate()
	var area = SpawnArea.get_spawn_point(id)
	if(GameManager.is_host()):
		var w = area.get_weapon(id+map_seed)
		w.position = area.global_position
		synced_node.add_child(w)
	player.name = str(id)
	player.position = area.global_position
	player.player_name = player_name
	player.player_color = player_color
	player.id = id
	synced_node.add_child(player)
	player.set_authority(id)
	player.connect("player_died",Callable(self,"on_player_death"))
	players.append(player)


func remove_active_player(id:int):
	var p = null
	for player in players:
		if(player.id == id):
			p = player
	if(p != null):
		players.erase(p)
		p.queue_free()
			

func _input(event):
	if(!ingame_menu.visible && !GameManager.game_ended && event.is_action_pressed("pause")):
		ingame_menu.visible = true
		hud.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameManager.paused = true
	elif(ingame_menu.visible && !GameManager.game_ended && event.is_action_pressed("pause")):
		ingame_menu.visible = false
		hud.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		GameManager.paused = false
		
func on_player_death(player:Player):
	rpc("player_died_remote", player.id, player.global_position)

@rpc("call_local","any_peer")
func player_died_remote(player_id:int,player_pos:Vector3):
	if(player_id == GameManager.local_id):
		var free_cam = FREE_CAM_SCENE.instantiate()
		add_child(free_cam)
		free_cam.position = player_pos + Vector3.UP
		hud.visible = false
	remove_active_player(player_id)
	if(GameManager.is_host() && players.size() == 1):
		print("game over")
		GameManager.game_over(players[0])
	var splash = SPLASH_EFFECT_SCENE.instantiate()
	splash.position = player_pos + Vector3.UP
	add_child(splash)



@rpc("call_local")
func create_explosion_at_remote(center_position:Vector3,explosion_radius:float):
	var emitter = EXPLOSION_EFFECT_SCENE.instantiate()
	emitter.position = center_position
	emitter.explosion_radius = explosion_radius
	add_child(emitter)
	island.OnBulletExploded(center_position,explosion_radius)

func clear_synced_nodes():
	for node in synced_node.get_children():
		if(node.get_multiplayer_authority() == multiplayer.get_unique_id()):
			node.queue_free()
	
