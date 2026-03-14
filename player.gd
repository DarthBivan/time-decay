extends CharacterBody2D

# =========================
# MOVEMENT & SPRINT
# =========================
var base_max_speed := 360.0
var sprint_multiplier := 1.6 # Sprinting is 60% faster than walking
var base_friction := 900.0
var min_friction := 180.0
var friction_decay_rate := 12.0
var base_acceleration := 1200.0
var min_acceleration := 350.0
var accel_decay_rate := 16.0

# =========================
# DASH (Unified I-Frames)
# =========================
var dash_force := 820.0
var dash_cooldown := 1.2
var dash_timer := 0.0

# We now use ONE timer for the whole dash. While this is > 0, you are invincible.
var dash_state_time := 0.40 
var dash_state_timer := 0.0 

var bounce_iframe_time := 0.30 

# =========================
# STATE
# =========================
var last_move_dir := Vector2.DOWN
var is_dead := false

# =========================
# REFERENCES
# =========================
@onready var body_rect: ColorRect = $ColorRect
@onready var trail: Line2D = $Line2D 
@onready var game_manager = $"../GameManager"

var camera: Camera2D = null

# =========================
# CAMERA SHAKE
# =========================
var shake_time := 0.0
var shake_strength := 0.0


func _ready():
	trail.top_level = true 
	if get_parent().has_node("Camera2D"):
		camera = get_parent().get_node("Camera2D")
	reset_player()


func _physics_process(delta):
	dash_timer -= delta
	dash_state_timer -= delta 
	
	update_camera_shake(delta)

	if is_dead or not game_manager.is_game_active:
		return

	# INPUT
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right"): input_dir.x += 1
	if Input.is_action_pressed("ui_left"): input_dir.x -= 1
	if Input.is_action_pressed("ui_down"): input_dir.y += 1
	if Input.is_action_pressed("ui_up"): input_dir.y -= 1
	input_dir = input_dir.normalized()

	# DASH
	if Input.is_action_just_pressed("dash") and dash_timer <= 0:
		if input_dir != Vector2.ZERO:
			velocity += input_dir * dash_force
		elif velocity.length() > 0:
			velocity += velocity.normalized() * dash_force

		dash_timer = dash_cooldown
		dash_state_timer = dash_state_time 
		
		start_camera_shake(0.08, 2.0)
		dash_flash()

	# CONTROL DECAY
	var current_friction = clampf(
		base_friction - game_manager.pressure * friction_decay_rate * 0.02,
		min_friction,
		base_friction
	)

	var current_accel = clampf(
		base_acceleration - game_manager.pressure * accel_decay_rate * 0.015,
		min_acceleration,
		base_acceleration
	)

	# SPRINT LOGIC
	var active_max_speed = base_max_speed
	if Input.is_action_pressed("sprint") and dash_state_timer <= 0:
		active_max_speed = base_max_speed * sprint_multiplier

	# MOVEMENT & TURNAROUND BOOST
	if input_dir != Vector2.ZERO:
		var applied_accel = current_accel
		
		# If we are moving, and our input is fighting our current direction...
		if velocity.length() > 50.0 and velocity.normalized().dot(input_dir) < 0:
			applied_accel = current_accel * 4.0 # Turn 4x faster!
			
		velocity = velocity.move_toward(input_dir * active_max_speed, applied_accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_friction * delta)
		
	# Keep track of our facing direction
	if velocity.length() > 10.0:
		last_move_dir = velocity.normalized()

	# SPEED CAP & DASH DRAG 
	var dash_cap = base_max_speed * 2.2
	
	if velocity.length() > active_max_speed and dash_state_timer <= 0:
		velocity = velocity.move_toward(velocity.normalized() * active_max_speed, 1800.0 * delta)
		
	if velocity.length() > dash_cap:
		velocity = velocity.normalized() * dash_cap

	move_and_slide()

	# ARENA WALLS 
	var screen_size = get_viewport_rect().size
	var padding = 8.0 

	var hit_left = global_position.x <= padding
	var hit_right = global_position.x >= screen_size.x - padding
	var hit_top = global_position.y <= padding
	var hit_bottom = global_position.y >= screen_size.y - padding

	if hit_left or hit_right or hit_top or hit_bottom:
		if dash_state_timer > 0: 
			var bounced = false
			
			if hit_left: 
				velocity.x = abs(velocity.x)
				bounced = true
			if hit_right: 
				velocity.x = -abs(velocity.x)
				bounced = true
			if hit_top: 
				velocity.y = abs(velocity.y)
				bounced = true
			if hit_bottom: 
				velocity.y = -abs(velocity.y)
				bounced = true
				
			if bounced:
				# Give them a little extra i-frame safety after a wall bounce
				dash_state_timer = max(dash_state_timer, bounce_iframe_time)
		else:
			die()

	global_position.x = clamp(global_position.x, padding, screen_size.x - padding)
	global_position.y = clamp(global_position.y, padding, screen_size.y - padding)

	# TRAIL (Clean Line2D, spawning from the back)
	var player_radius = 20.0 
	var trail_spawn_point = global_position - (last_move_dir * player_radius)
	
	trail.add_point(trail_spawn_point)
	if trail.points.size() > 25:
		trail.remove_point(0)


func dash_flash():
	body_rect.color = Color(0.7, 0.9, 1)
	await get_tree().create_timer(0.08).timeout
	body_rect.color = Color(1,1,1)

func start_camera_shake(time, strength):
	shake_time = time
	shake_strength = strength

func update_camera_shake(delta):
	if not camera: return
	if shake_time > 0:
		shake_time -= delta
		camera.offset = Vector2(randf_range(-1,1), randf_range(-1,1)) * shake_strength
	else:
		camera.offset = Vector2.ZERO

func blink_flash():
	var original_color = body_rect.color
	for i in range(3):
		body_rect.color = Color(1,1,1)
		await get_tree().create_timer(0.04).timeout
		body_rect.color = original_color
		await get_tree().create_timer(0.04).timeout

func die():
	# If we are in the dash state, we are invincible! Ignore the death call.
	if dash_state_timer > 0 or is_dead:
		return

	is_dead = true

	blink_flash()
	start_camera_shake(0.06, 3)

	Engine.time_scale = 0.05
	await get_tree().create_timer(0.05).timeout
	Engine.time_scale = 1.0

	game_manager.handle_player_death()

func reset_player():
	velocity = Vector2.ZERO
	global_position = get_viewport_rect().size / 2
	trail.clear_points()
