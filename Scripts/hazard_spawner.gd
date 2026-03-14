extends Node

@export var blade_scene: PackedScene

# ==========================================
# NEW PACING SETTINGS
# ==========================================
var base_spawn_rate := 12.0 # Wait 12 whole seconds between blades early on
var min_spawn_rate := 2.5   # Absolute endgame limit: 1 blade every 2.5 seconds
var spawn_timer := 3.0      # The VERY FIRST blade drops early (after 3 seconds)

@onready var game_manager = $"../GameManager"

func _process(delta):
	if not game_manager.is_game_active:
		return

	spawn_timer -= delta
	
	if spawn_timer <= 0:
		spawn_blade()
		
		# THE NEW MATH:
		# We divide the pressure by a huge number (0.0002 instead of 0.01).
		# This means it will take a LONG time (like 2+ minutes) before blades start 
		# dropping rapidly. It gives the player time to sweat about their decaying friction.
		var current_rate = max(min_spawn_rate, base_spawn_rate - (game_manager.pressure * 0.0002))
		spawn_timer = current_rate


func spawn_blade():
	if not blade_scene:
		print("ERROR: You forgot to put the blade scene in the Spawner's Inspector slot!")
		return
		
	# 1. Create a fresh copy of the blade
	var blade = blade_scene.instantiate()
	
	# 2. Pick a random X position across the screen to drop it
	var screen_size = get_viewport().get_visible_rect().size
	var padding = 50.0 # Kept slightly further from the walls so they don't glitch on spawn
	var random_x = randf_range(padding, screen_size.x - padding)
	
	# 3. THE VISUAL FIX: Pushed WAY up so it spawns completely off-screen
	var spawn_y = -200.0 
	
	blade.global_position = Vector2(random_x, spawn_y)
	
	# 4. Tag it for the GameManager to clean up later
	blade.add_to_group("hazards") 
	
	# 5. Add the blade to the Main scene
	get_parent().add_child(blade)
