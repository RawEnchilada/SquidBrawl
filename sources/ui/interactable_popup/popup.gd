extends Node3D

@onready var label: Label = $SubViewport/MarginContainer/Label
var text = "No hints set, sorry!"

func set_text(new_text: String):
	if (label):
		label.text = new_text
	text = new_text

func _ready():
	label.text = text
