extends Node

var time_alive := 0.0
var pressure := 0.0
var best_time := 0.0
var is_game_active := true

# Existing UI
@onready var timer_label: Label = $"../TimerLabel"
@onready var best_label: Label = $"../BestLabel"

# References to your Death Screen
@onready var death_screen: CanvasLayer = $"../DeathScreen"
@onready var final_score_label: Label = $"../DeathScreen/ScoreLabel"


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS 
	death_screen.hide()
	update_best_label()


func _process(delta):
	if not is_game_active:
		# If we are dead, wait for the player to press Dash or Enter/Space to restart
		if Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("ui_accept"):
			restart_game()
		return
		
	time_alive += delta
	pressure = time_alive * time_alive

	if timer_label:
		timer_label.text = "Time: %.2f" % time_alive


func update_best_label():
	if best_label:
		best_label.text = "Best: %.2f" % best_time


func handle_player_death():
	is_game_active = false
	
	# Pause the entire engine (stops physics, movement, and hazards)
	get_tree().paused = true 
	
	if time_alive > best_time:
		best_time = time_alive
		update_best_label()
		
	# Update the final score text and show the UI
	if final_score_label:
		final_score_label.text = "Final Time: %.2f" % time_alive
	death_screen.show()


func restart_game():
	death_screen.hide()
	time_alive = 0.0
	pressure = 0.0
	is_game_active = true
	
	# Unpause the engine
	get_tree().paused = false 
	
	# THE FIX: Delete every single node in the "hazards" group!
	get_tree().call_group("hazards", "queue_free")
	
	# Tell the player to reset
	var player = $"../Player"
	if player:
		player.reset_player()
		player.is_dead = false
