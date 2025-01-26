extends MarginContainer

const SETTINGS_SCENE = preload("res://sources/ui/settings/settings.tscn")

@onready var settings_button = $VBoxContainer/SettingsButton
@onready var back_to_menu_button = $VBoxContainer/BackToMenuButton
@onready var quit_button = $VBoxContainer/QuitButton

func _ready():
    back_to_menu_button.connect("pressed",Callable(self,"_on_back_to_menu_button_pressed"))
    settings_button.connect("pressed",Callable(self,"_on_settings_button_pressed"))
    quit_button.connect("pressed",Callable(self,"_on_quit_button_pressed"))
    $Control/TextureRect.modulate = Settings.user_color

func _on_settings_button_pressed():
    var settings = SETTINGS_SCENE.instantiate()
    settings.previous_ui_scene = self
    get_parent().add_child(settings)
    hide()

func _on_back_to_menu_button_pressed():
    GameManager.leave_game()

func _on_quit_button_pressed():
    GameManager.leave_game()
    get_tree().quit()

