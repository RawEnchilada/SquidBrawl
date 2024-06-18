extends Control

@onready var weapon_cooldown_bar = $HBoxContainer/CrossHairAndStats/WeaponCooldownBar
@onready var skill_cooldown_bar = $HBoxContainer/CrossHairAndStats/SkillCooldownBar

func skill_cooldown_changed(cooldown:float):
    skill_cooldown_bar.value = cooldown

func weapon_cooldown_changed(cooldown:float):
    weapon_cooldown_bar.value = cooldown




