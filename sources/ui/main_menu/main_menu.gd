extends MarginContainer

const LOADING_SCENE = preload("res://sources/ui/loading/loading.tscn")
const SETTINGS_SCENE = preload("res://sources/ui/settings/settings.tscn")

@export var main_scene:Node3D = null
@onready var vbox_container = $VBoxContainer
@onready var play_game_button = $VBoxContainer/PlayGameButton
@onready var ip_address_field = $VBoxContainer/IPAddressField
@onready var join_game_button = $VBoxContainer/JoinGameButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton

@onready var lobby = $Lobby

func _ready():
	play_game_button.connect("pressed",Callable(self,"_on_play_game_button_pressed"))
	ip_address_field.connect("text_changed",Callable(self,"_on_ip_address_field_text_changed"))
	join_game_button.connect("pressed",Callable(self,"_on_join_game_button_pressed"))
	settings_button.connect("pressed",Callable(self,"_on_settings_button_pressed"))
	quit_button.connect("pressed",Callable(self,"_on_quit_button_pressed"))
	ip_address_field.text = Settings.ip_address
	lobby.visible = false
	get_tree().paused = false


func _on_ip_address_field_text_changed(new_text:String):
	Settings.ip_address = new_text
	Settings.save_settings()

func _on_play_game_button_pressed():
	GameManager.host_game()
	lobby.show_lobby()
	vbox_container.visible = false

func _on_join_game_button_pressed():
	GameManager.join_game()
	lobby.show_lobby()
	vbox_container.visible = false

func _on_settings_button_pressed():
	var settings = SETTINGS_SCENE.instantiate()
	settings.previous_ui_scene = self
	get_parent().add_child(settings)
	hide()

func _on_quit_button_pressed():
	get_tree().quit()


func _on_lobby_start_game():
	visible = false
	if(GameManager.is_host()):
		GameManager.restart_game()
	
func _on_lobby_exited():
	GameManager.leave_game()
	lobby.visible = false
	vbox_container.visible = true
