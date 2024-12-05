# main.gd
extends Node3D

var balls = []
var ball_scene = preload("res://scenes/ball.tscn")
var balls_left = 10
var game_ready = false
var elapsed_time = 0.0

func _ready():	
	set_globals()
	if not Global.game_started:
		$main_menu.show()
		get_tree().paused = true
		
func set_globals():
	# after each stage is complete 
	# I call a get_tree().reload_current_scene()
	Global.current_ball_size = 2
	Global.infinite_balls = false
	Global.stage_started = false
	# set gravity to normal 
	PhysicsServer3D.area_set_param(get_world_3d().space, 
	PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR, 
	Vector3(0, -1, 0))
	Global.deactivate_all_slots()
	# make sure inputs are setup properly based on platform
	os_specific_inits()	

func os_specific_inits():
	# web build
	if OS.get_name() == "Web":
		var escape_event = InputEventKey.new() 
		escape_event.keycode = KEY_ESCAPE
		var tab_event = InputEventKey.new() 
		tab_event.keycode = KEY_TAB
		InputMap.action_erase_event("ui_cancel",escape_event)
		InputMap.action_add_event("ui_cancel", tab_event)
		$web_shortcuts.show()
		$desktop_shortcuts.hide()
		
func _process(delta):
	elapsed_time+=delta
	if Global.game_started:
		position_camera()
		get_input()
		if Global.stage_started:
			process_balls()
			
func position_camera():
	# this is just an "opening movement" thing so show off the 3D scenery
	if not game_ready:
		if $camera.position.z < 0:
			$camera.position.z += 4
		else:
			game_ready = true
			
func get_input():
	if Input.is_action_just_pressed("ui_cancel"):
		if elapsed_time > 0.1 : toggle_main_menu()
	if Input.is_action_just_pressed("spawn_ball") and game_ready:
		spawn_ball()
	if Input.is_action_just_pressed("settings"):
		if elapsed_time > 0.1 : toggle_settings()

func toggle_main_menu():
	$main_menu.show()
	$main_menu.elapsed_time = 0.0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
		
func spawn_ball():
	# spawning the first ball starts the stage
	if not Global.stage_started:
		Global.stage_started = true
	# check if it's ok to spawn a ball
	if decrement_balls():
		var ball_instance = create_ball_instance()
		setup_ball_collision(ball_instance)
		# position the new ball in respect to the paddle 
		ball_instance.position = $paddle.position + Vector3(0,1,0)
		ball_instance.linear_velocity += Vector3(5,40,0)
		# add the new ball to our list and to the main scene 
		balls.append(ball_instance) 
		add_child(ball_instance)
			
func toggle_settings():	
		$settings_menu.show()
		$settings_menu.elapsed_time = 0.0
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
func process_balls():
	# balls loop
	for ball in balls:
		# Check if the ball has left the screen 
		if ball.position.y < 0:
			balls.erase(ball)
			ball.queue_free()
			# check for game over condition
			if len(balls) == 0 and balls_left == 0:
				game_over()
			break

func game_over():
	$game_over_menu.show()
	set_globals()
	get_tree().paused = true
	Global.stage_started = false	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func restart_stage():
	# called from game_over_menu.gd
	$game_over_menu.hide()
	get_tree().paused = false
	get_tree().reload_current_scene()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
func remove_all_balls():
	for ball in balls:
		ball.queue_free() 
		balls.erase(ball)

func decrement_balls():
	var spare_balls = $stage/spare_balls
	if spare_balls.get_child_count() > 0 and not Global.infinite_balls:
		var spare_ball = spare_balls.get_child(0)
		spare_ball.queue_free()
		balls_left-=1
		if balls_left < 0: balls_left = 0	
		return true
	else:
		if Global.infinite_balls:
			return true 
		else:
			return false

func create_ball_instance():
	var ball_instance = ball_scene.instantiate()
	clear_existing_mesh_instance(ball_instance)
	add_new_mesh_instance(ball_instance)		
	return ball_instance

func clear_existing_mesh_instance(ball_instance):
	if ball_instance.has_node("MeshInstance3D"):
		var mesh_instance = ball_instance.get_node("MeshInstance3D")
		if mesh_instance: mesh_instance.queue_free()
		
func add_new_mesh_instance(ball_instance):
	var new_mesh_instance = ball_instance.ball_models[Global.current_ball_size].instantiate()
	new_mesh_instance.name="MeshInstance3D"
	ball_instance.add_child(new_mesh_instance)
	
func setup_ball_collision(ball_instance):
	# Update collision shape radius 
	if ball_instance.has_node("CollisionShape3D"): 
		var collision_shape = ball_instance.get_node("CollisionShape3D") 
		if collision_shape and collision_shape.shape is SphereShape3D: 
			var sphere_shape = collision_shape.shape as SphereShape3D 
			sphere_shape.radius = Global.current_ball_size / 4.0 - 0.1
		else: 
			print("Error: CollisionShape3D node or SphereShape3D shape not found.")
					
func update_ball_size():
	for ball_instance in balls:
		# print("Updating ball size to " + str(Global.current_ball_size))
		clear_existing_mesh_instance(ball_instance)
		add_new_mesh_instance(ball_instance)
		setup_ball_collision(ball_instance)
