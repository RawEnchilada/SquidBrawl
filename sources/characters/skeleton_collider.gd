extends Node3D

@export var model_parent:CharacterModel

func skeleton_hit(damage:int):
    model_parent.emit_model_hit(damage)


