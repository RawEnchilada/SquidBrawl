extends MarginContainer

signal leave_lobby
signal start_game

@onready var chunk_settings_container = $VBoxContainer/HBoxContainer
@onready var spin_box_x = $VBoxContainer/HBoxContainer/SpinBoxX
@onready var spin_box_y = $VBoxContainer/HBoxContainer/SpinBoxY
@onready var spin_box_z = $VBoxContainer/HBoxContainer/SpinBoxZ
@onready var start_game_button = $VBoxContainer/StartButton
@onready var players_label = $VBoxContainer/PlayersLabel

func show_lobby():
	visible = true
	if(GameManager.is_host()):
		start_game_button.visible = true
		chunk_settings_container.visible = true
		spin_box_x.connect("value_changed",Callable(self,"_on_spin_box_x_value_changed"))
		spin_box_y.connect("value_changed",Callable(self,"_on_spin_box_y_value_changed"))
		spin_box_z.connect("value_changed",Callable(self,"_on_spin_box_z_value_changed"))
	else:
		start_game_button.visible = false
		chunk_settings_container.visible = false


func _physics_process(_delta):
	var text = "Connected Players:\n"
	for data in GameManager.players_data:
		text += "  - "+data["name"]+"\n"
	players_label.text = text

func _on_leave_button_pressed():
	emit_signal("leave_lobby")


func _on_start_button_pressed():
	emit_signal("start_game")

func _on_spin_box_x_value_changed(new_value):
	Settings.chunks.x = new_value

func _on_spin_box_y_value_changed(new_value):
	Settings.chunks.y = new_value

func _on_spin_box_z_value_changed(new_value):
	Settings.chunks.z = new_value
