extends Node

@export
var mouse_sensitivity = 0.35
@export
var user_color = Color.ORANGE
@export
var user_name = "Player"
@export
var ip_address = "127.0.0.1"
@export
var sound_level = 0.5
@export
var chunks = Vector3(6,2,6)

func _ready():
	load_settings()

func _exit_tree():
	save_settings()


func save_settings():
	var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
	file.store_string("{\"mouse_sensitivity\":%s, \"user_color\":\"%s\", \"user_name\":\"%s\", \"ip_address\":\"%s\", \"sound_level\":%s}" % [str(mouse_sensitivity), user_color.to_html(), user_name, ip_address, str(sound_level)])

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
	if json.has("ip_address"):
		ip_address = json["ip_address"]
	if json.has("sound_level"):
		sound_level = json["sound_level"]
