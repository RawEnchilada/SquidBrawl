class_name Game
extends Node3D

const PLAYER_SCENE = preload("res://sources/characters/player/player.tscn")
const FREE_CAM_SCENE = preload("res://sources/characters/debug_camera/debug_camera.tscn")


@onready var hud = $CanvasLayer/Hud
@onready var ingame_menu = $CanvasLayer/IngameMenu
@onready var synced_node = $Synced
@onready var island = $Island

# only for the host
var players = []


func add_active_player(id:int,player_name:String,player_color:Color):
	var player = PLAYER_SCENE.instantiate()
	var area = SpawnArea.get_spawn_point(id)
	var w = area.get_weapon()
	w.position = area.global_position
	synced_node.add_child(w)
	player.name = str(id)
	player.position = area.global_position
	synced_node.add_child(player)
	player.rpc("set_player_name", player_name)
	player.rpc("set_player_color", player_color)
	player.rpc("set_id", id)
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
	print("player " + str(player.id) + " died on instance " + str(GameManager.local_id))
	rpc("player_died_remote", player.id, player.global_position)

@rpc("call_local")
func player_died_remote(player_id:int,player_pos:Vector3):
	if(player_id == GameManager.local_id):
		var free_cam = FREE_CAM_SCENE.instantiate()
		add_child(free_cam)
		free_cam.global_position = player_pos
		hud.visible = false
	remove_active_player(player_id)
	if(GameManager.is_host() && players.size() == 1):
		print("game over")
		GameManager.game_over(players[0])


func register_projectile(projectile:Bullet):
	projectile.bullet_exploded.connect(Callable(island,"on_bullet_exploded"))
