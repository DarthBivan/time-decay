extends Node2D

var speed := 300.0
var velocity := Vector2.ZERO

# THE I-FRAME TOGGLE
var is_armed := false 

@onready var blade_visual = $BladeVisual

func _ready():
	# Pick a random downward diagonal angle to start dropping in
	var random_angle = randf_range(PI/4, 3*PI/4)
	velocity = Vector2.RIGHT.rotated(random_angle) * speed
	
	# Start the blink sequence!
	arm_blade()

func _physics_process(delta):
	# Move the whole package
	global_position += velocity * delta
	
	# Make the sawblade actually spin!
	if blade_visual:
		blade_visual.rotation += 15.0 * delta
	
	# ==========================================
	# BOUNCE LOGIC
	# ==========================================
	var screen_size = get_viewport_rect().size
	var padding = 40.0 # Adjust this based on your blade's visual size
	
	if global_position.x < padding or global_position.x > screen_size.x - padding:
		velocity.x = -velocity.x
		global_position.x = clamp(global_position.x, padding, screen_size.x - padding)
		
	if global_position.y < padding or global_position.y > screen_size.y - padding:
		velocity.y = -velocity.y
		global_position.y = clamp(global_position.y, padding, screen_size.y - padding)


# ==========================================
# SPAWN I-FRAMES & BLINK
# ==========================================
func arm_blade():
	is_armed = false
	
	# Flash transparent 5 times (takes about 1.5 seconds)
	for i in range(5):
		modulate.a = 0.3 # Ghost mode
		await get_tree().create_timer(0.15).timeout
		modulate.a = 1.0 # Solid mode
		await get_tree().create_timer(0.15).timeout
		
	# The grace period is over. It is now deadly.
	is_armed = true
	modulate.a = 1.0 


# ==========================================
# KILL THE PLAYER
# ==========================================
func _on_kill_area_body_entered(body):
	# If we are still blinking, ignore the collision completely!
	if not is_armed:
		return 
		
	# If it's the player and we are armed, kill them
	if body.name == "Player" and body.has_method("die"):
		body.die()
