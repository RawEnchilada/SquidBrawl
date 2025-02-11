extends MarginContainer

signal leave_lobby
signal start_game

@onready var map_name_selector = $VBoxContainer/MapNameSelector
@onready var weapon_type_selector = $VBoxContainer/WeaponTypeSelector
@onready var start_game_button = $VBoxContainer/StartButton
@onready var players_label = $VBoxContainer/PlayersLabel

const MAP_FOLDER = "res://maps/"

func show_lobby():
	visible = true
	
	var maps = []
	var dir = DirAccess.open(MAP_FOLDER)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".map"):
			maps.append(file_name.replace(".map",""))
		file_name = dir.get_next()
	dir.list_dir_end()
	
	map_name_selector.clear()
	for map in maps:
		map_name_selector.add_item(map)
	map_name_selector.select(0)

	weapon_type_selector.clear()
	var weapon_types = Enums.WeaponType.keys()
	for weapon_type in weapon_types:
		weapon_type_selector.add_item(weapon_type)
		
	if(GameManager.is_host()):
		start_game_button.visible = true
	else:
		start_game_button.visible = false
		map_name_selector.disabled = true


func _physics_process(_delta):
	var text = "Connected Players:\n"
	for data in GameManager.players_data:
		text += "  - "+data["name"]+"\n"
	players_label.text = text

func _on_leave_button_pressed():
	emit_signal("leave_lobby")


func _on_start_button_pressed():
	emit_signal("start_game")



func _on_map_name_selector_item_selected(index:int) -> void:
	Settings.map_name = map_name_selector.get_item_text(index)


func _on_weapon_type_selector_item_selected(index:int) -> void:
	GameManager.set_player_weapon_type(GameManager.local_id,Enums.WeaponType[weapon_type_selector.get_item_text(index)])
