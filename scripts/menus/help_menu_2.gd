extends Node3D
class_name HelpMenu2

var active 

func _ready() -> void:
	active = false	
	
func _process(_delta: float) -> void:
	if active:
		$grower_model.rotate(Vector3(1.0,0.0,0.0),0.015)
		$shrinker_model.rotate(Vector3(1.0,0.0,0.0),0.02)
		
		if Input.is_action_just_pressed("menu_1"):
			active = false
			var camera = Global.get_main().get_node("camera")
			var help_menu = Global.get_main().get_node("help_menu")
			camera.lerping = true
			camera.target_position = Vector3(0,45,0)
			help_menu.active = true