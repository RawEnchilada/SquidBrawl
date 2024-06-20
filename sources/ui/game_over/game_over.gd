extends MarginContainer

var winner_name:String = ""

@onready var winner_label = $VBoxContainer/WinnerLabel
@onready var hbox = $VBoxContainer/HBoxContainer

func _ready():
	if(winner_name != ""):
		winner_label.text = winner_name + " Wins!"
		hbox.visible = false


func _on_restart_button_pressed():
	GameManager.restart_game()

func _on_leave_button_pressed():
	GameManager.leave_game()
