extends MarginContainer

const LOADING_SCENE = preload("res://sources/ui/loading/loading.tscn")
const SETTINGS_SCENE = preload("res://sources/ui/settings/settings.tscn")


@export var main_scene:Node3D = null
@onready var play_game_button = $VBoxContainer/PlayGameButton
@onready var join_game_button = $VBoxContainer/JoinGameButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton


func _ready():
    play_game_button.connect("pressed",Callable(self,"_on_play_game_button_pressed"))
    join_game_button.connect("pressed",Callable(self,"_on_join_game_button_pressed"))
    settings_button.connect("pressed",Callable(self,"_on_settings_button_pressed"))
    quit_button.connect("pressed",Callable(self,"_on_quit_button_pressed"))
    get_tree().paused = false

func _on_play_game_button_pressed():
    var loading = LOADING_SCENE.instantiate()
    $"/root".add_child(loading)
    $"/root".remove_child(main_scene)
    GameManager.host_game(loading)

func _on_join_game_button_pressed():
    var loading = LOADING_SCENE.instantiate()
    $"/root".add_child(loading)
    $"/root".remove_child(main_scene)
    GameManager.join_game(loading)

func _on_settings_button_pressed():
    var settings = SETTINGS_SCENE.instantiate()
    settings.previous_ui_scene = self
    get_parent().add_child(settings)
    hide()

func _on_quit_button_pressed():
    get_tree().quit()
