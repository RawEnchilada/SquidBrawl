extends Area3D

const popup_scene = preload("res://sources/ui/interactable_popup/popup.tscn")

var closest_interactable = null
var ignore_body = null


func on_interactable_entered(body:BaseWeapon):
	if(closest_interactable == null):
		set_interactable(body)
	elif(body.global_position.distance_to(global_position) < closest_interactable.global_position.distance_to(global_position)):
		remove_interactable()
		set_interactable(body)



func on_interactable_exited(body:BaseWeapon):
	if(body == closest_interactable):
		remove_interactable()


func set_interactable(body:BaseWeapon):
	if(body != ignore_body):
		closest_interactable = body
		var popup = popup_scene.instantiate()
		popup.set_text(closest_interactable.get_interaction_hint())
		closest_interactable.add_child(popup)

func remove_interactable():
	if(closest_interactable.has_node("Popup")):
		closest_interactable.remove_child(closest_interactable.get_node("Popup"))
	closest_interactable = null


func on_weapon_equipped(weapon:BaseWeapon):
	ignore_body = weapon