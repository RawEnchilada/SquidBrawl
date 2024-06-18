extends MarginContainer


@onready var player_name_field = $VBoxContainer/PlayerName/LineEdit
@onready var player_color_picker = $VBoxContainer/PlayerColor/ColorPicker
@onready var mouse_sensitivity_slider = $VBoxContainer/MouseSensitivity/HSlider

var previous_ui_scene:Node = null

func _ready():
    player_name_field.text = Settings.user_name
    player_color_picker.color = Settings.user_color
    mouse_sensitivity_slider.set_value_no_signal(Settings.mouse_sensitivity)


func _on_player_name_field_text_changed(new_text):
    Settings.user_name = new_text
    Settings.save_settings()

func _on_player_color_picker_color_changed(new_color):
    Settings.user_color = new_color
    Settings.save_settings()

func _on_mouse_sensitivity_slider_value_changed(new_value):
    Settings.mouse_sensitivity = new_value
    Settings.save_settings()


func _on_back_button_pressed():
    previous_ui_scene.show()
    queue_free()