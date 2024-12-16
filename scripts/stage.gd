# stage.gd
extends StaticBody3D
class_name Stage

var current_blocks
var block_scene_paths = []
var ticks = 0

func _ready():
	add_scene_paths()
	load_stage()
	if not Global.show_background_3d:
		$background_3d.hide()
		
func start_rsg():
	$rsg_timer.start()
	$ready_set_go_label.show()
	
func _on_rsg_timer_timeout():
	ticks+=1
	if ticks == 1:
		$ready_set_go_label.text = "SET!"
	elif ticks==2:
		$ready_set_go_label.text = "GO!!!"
	else:
		var main_scene = get_tree().root.get_child(2)
		main_scene.game_ready = true 
		$rsg_timer.stop()
		$ready_set_go_label.hide()
		
func add_scene_paths():
	for i in range(Global.total_stages):
		block_scene_paths.append("res://scenes/stage_blocks/blocks_" + str(i) + ".tscn")
		
func load_blocks():
	# Remove previous stage's blocks  
	if current_blocks: 
		current_blocks.queue_free()
	var scene_path = block_scene_paths[Global.current_stage] 
	var new_blocks_scene = load(scene_path) 
	current_blocks = new_blocks_scene.instantiate() 
	add_child(current_blocks)

func load_stage():
	Global.load_times()
	load_blocks()
	$stage_label.text = "Stage " + str(Global.current_stage)	
	if Global.current_stage > 0 : set_best_time_labels()

func set_best_time_labels():
	var best_stage_time = Global.stage_times_dict[Global.current_stage]
	$best_stage_time_label.text = "Best Stage Time " + Global.format_time(best_stage_time)
	var best_total_time = Global.total_times_dict[Global.current_stage]
	$best_total_time_label.text = "Best Total Time " + Global.format_time(best_total_time)
	
func all_stages_cleared():
	cleanup_stage()	
	$all_stages_cleared_menu.show()
		
func stage_cleared():
	cleanup_stage()
	$stage_cleared_menu.show()
	if Global.current_stage > 0 : $stage_cleared_menu.update_labels()
	
func cleanup_stage():
	var replay_timer = GlobalAudioServer.get_node("replay_timer")
	replay_timer.stop()
	Global.stage_time = $time_label.elapsed_time
	Global.accumlated_time = $total_time_label.elapsed_time
	Global.stage_started = false
	var main_scene = get_tree().root.get_child(2)
	main_scene.remove_all_balls()
	clear_flow_arrows()
	clear_metal_blocks()
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func clear_flow_arrows():	
	for child in current_blocks.get_children():
		if child.is_in_group("FlowArrows"):
			child.queue_free()
			
func clear_metal_blocks():
	for child in current_blocks.get_children():
		if child is BlockMetal:
			child.queue_free()
				
func _process(_delta):	
	var count = get_breakable_count()
	# check if stage had been cleared 
	$blocks_left_label.text = "Blocks Left " + str(count)
	if count == 0:
		stage_cleared()
				
func load_next_stage():
	Global.current_stage += 1 
	if Global.current_stage == Global.total_stages:
		all_stages_cleared()
	else:
		get_tree().paused = false
		get_tree().reload_current_scene()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func get_breakable_count():
	var all_blocks = current_blocks.get_children()
	var breakable_count = 0
	for block in all_blocks:
		if block.is_in_group("BreakableBlocks"):
			breakable_count+=1
	return breakable_count
