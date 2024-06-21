extends MarginContainer

signal leave_lobby
signal start_game

@onready var start_game_button = $VBoxContainer/StartButton
@onready var players_label = $VBoxContainer/PlayersLabel

func show_lobby():
	visible = true
	if(GameManager.is_host()):
		start_game_button.visible = true
	else:
		start_game_button.visible = false

func _physics_process(_delta):
	var text = "Connected Players:\n"
	for data in GameManager.players_data:
		text += "  - "+data["name"]+"\n"
	players_label.text = text

func _on_leave_button_pressed():
	emit_signal("leave_lobby")


func _on_start_button_pressed():
	emit_signal("start_game")
