extends Node

@export
var mouse_sensitivity = 0.35
@export
var user_color = Color.ORANGE
@export
var user_name = "Player"

func _ready():
	load_settings()

func _exit_tree():
	save_settings()


func save_settings():
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string("{\"mouse_sensitivity\":%s, \"user_color\":\"%s\", \"user_name\":\"%s\"}" % [str(mouse_sensitivity), user_color.to_html(), user_name])

func load_settings():
	var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
	if not file:
		return
	var json = JSON.parse_string(file.get_as_text())
	if json.has("mouse_sensitivity"):
		mouse_sensitivity = json["mouse_sensitivity"]
	if json.has("user_color"):
		user_color = Color.from_string(json["user_color"], Color.BLACK)
	if json.has("user_name"):
		user_name = json["user_name"]
