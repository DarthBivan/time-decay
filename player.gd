extends CharacterBody2D

# =========================
# CONSTANT SPEED
# =========================
var max_speed: float = 360.0

# =========================
# FRICTION DECAY
# =========================
var base_friction: float = 900.0
var min_friction: float = 180.0
var friction_decay_rate: float = 12.0

# =========================
# ACCELERATION DECAY
# =========================
var base_acceleration: float = 1200.0
var min_acceleration: float = 350.0
var accel_decay_rate: float = 16.0

# =========================
# GRAVITY DRIFT (DOWN)
# =========================
var gravity_dir: Vector2 = Vector2(0, 1)
var base_gravity_strength: float = 18.0
var gravity_growth: float = 1.1
var max_gravity_strength: float = 95.0

# =========================
# TIME & SCORE
# =========================
var time_alive: float = 0.0
var pressure: float = 0.0
var best_time: float = 0.0

# =========================
# UI REFERENCES
# =========================
@onready var timer_label: Label = get_parent().get_node("TimerLabel")
@onready var best_label: Label = get_parent().get_node("BestLabel")
@onready var camera: Camera2D = get_parent().get_node("Camera2D")

# =========================
# PLAYER VISUAL
# =========================
@onready var body_rect: ColorRect = $ColorRect

# =========================
# SHAKE SETTINGS
# =========================
var shake_time: float = 0.0
var shake_strength: float = 0.0

# =========================
# STATE
# =========================
var is_dead: bool = false

func _ready() -> void:
	reset_run()
	update_best_label()

func _physics_process(delta: float) -> void:
	if is_dead:
		update_camera_shake(delta)
		return
	
	# ---- CAMERA SHAKE UPDATE ----
	update_camera_shake(delta)
	
	# ---- TIME ----
	time_alive += delta
	pressure = time_alive * time_alive
	
	# ---- TIMER UI ----
	if timer_label:
		timer_label.text = "Time: %.2f" % time_alive
	
	# ---- INPUT ----
	var input_dir: Vector2 = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	
	input_dir = input_dir.normalized()
	
	# ---- DECAY ----
	var current_friction: float = clampf(
		base_friction - pressure * friction_decay_rate * 0.02,
		min_friction,
		base_friction
	)
	
	var current_acceleration: float = clampf(
		base_acceleration - pressure * accel_decay_rate * 0.015,
		min_acceleration,
		base_acceleration
	)
	
	# ---- MOVEMENT INPUT ----
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(
			input_dir * max_speed,
			current_acceleration * delta
		)
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			current_friction * delta
		)
	
	# ---- APPLY GRAVITY ----
	var gravity_strength := base_gravity_strength + time_alive * gravity_growth
	gravity_strength = min(gravity_strength, max_gravity_strength)
	
	var gravity_force := gravity_dir * gravity_strength
	velocity += gravity_force * delta
	
	# ---- CAP SPEED ----
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed
	
	move_and_slide()
	
	# ---- COLLISION CHECKS ----
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var other = col.get_collider()
		
		if other is StaticBody2D:
			die()
			return
		
		if other is CharacterBody2D and other != self:
			die()
			return

# =========================
# CAMERA SHAKE
# =========================
func update_camera_shake(delta: float) -> void:
	if shake_time > 0:
		shake_time -= delta
		
		var offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * shake_strength
		
		camera.offset = offset
	else:
		camera.offset = Vector2.ZERO

func start_camera_shake(time: float, strength: float) -> void:
	shake_time = time
	shake_strength = strength

# =========================
# BLINK FLASH
# =========================
func blink_flash():
	if not body_rect:
		return
	
	var original_color = body_rect.color
	
	# Number of blinks
	var blink_count := 5
	# How fast each blink is
	var blink_interval := 0.02
	
	for i in range(blink_count):
		# Flash white (or red)
		body_rect.color = Color(1, 0.2, 0.2)

		
		await get_tree().create_timer(blink_interval).timeout
		
		# Back to normal
		if body_rect:
			body_rect.color = original_color
		
		await get_tree().create_timer(blink_interval).timeout


# =========================
# DEATH
# =========================
func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	
	# VISUAL FEEDBACK
	blink_flash()
	start_camera_shake(0.06, 3.0)
	
	# HIT STOP
	Engine.time_scale = 0.05
	
	get_tree().create_timer(0.05).timeout.connect(_finish_death)

func _finish_death() -> void:
	Engine.time_scale = 1.0
	
	# UPDATE BEST
	if time_alive > best_time:
		best_time = time_alive
		update_best_label()
	
	reset_run()
	is_dead = false

# =========================
# RESET
# =========================
func reset_run() -> void:
	velocity = Vector2.ZERO
	time_alive = 0.0
	pressure = 0.0
	
	var viewport := get_viewport_rect()
	global_position = viewport.size / 2

func update_best_label() -> void:
	if best_label:
		best_label.text = "Best: %.2f" % best_time
