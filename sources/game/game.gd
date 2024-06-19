class_name Game
extends Node3D

const PLAYER_SCENE = preload("res://sources/characters/player/player.tscn")


@onready var hud = $CanvasLayer/Hud
@onready var ingame_menu = $CanvasLayer/IngameMenu
@onready var synced_node = $Synced
@onready var island = $Island


func add_player(id:int,player_name:String,player_color:Color):
	var player = PLAYER_SCENE.instantiate()
	var area = SpawnArea.get_spawn_point(id)
	var w = area.get_weapon()
	w.global_position = area.global_position
	synced_node.add_child(w)
	player.global_position = area.global_position
	player.name = str(id)
	synced_node.add_child(player)
	player.rpc("set_player_name", player_name)
	player.rpc("set_player_color", player_color)
	player.rpc("set_id", id)
	player.connect("player_died",Callable(self,"on_player_death"))


func remove_player(id:int):
	synced_node.get_node(str(id)).queue_free()

func _input(event):
	if(!ingame_menu.visible && event.is_action_pressed("pause")):
		ingame_menu.visible = true
		hud.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GameManager.paused = true
	elif(ingame_menu.visible && event.is_action_pressed("pause")):
		ingame_menu.visible = false
		hud.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		GameManager.paused = false
		
func on_player_death(player:Player):
	print_debug("player %s died" % player.id)
	#remove_player(player.id)

func register_projectile(projectile:Bullet):
	projectile.bullet_exploded.connect(Callable(island,"on_bullet_exploded"))
