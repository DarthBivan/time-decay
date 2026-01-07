extends CharacterBody2D

# =========================
# CONSTANT SPEED
# =========================
var max_speed: float = 360.0

# =========================
# FRICTION DECAY
# =========================
var base_friction: float = 900.0
var min_friction: float = 150.0
var friction_decay_rate: float = 15.0

# =========================
# ACCELERATION DECAY
# =========================
var base_acceleration: float = 1200.0
var min_acceleration: float = 300.0
var accel_decay_rate: float = 20.0

# =========================
# TIME & PRESSURE
# =========================
var time_alive: float = 0.0
var pressure: float = 0.0
var best_time: float = 0.0

# =========================
# SCREEN
# =========================
var screen_rect: Rect2

# =========================
# PLAYER SIZE (HALF)
# =========================
var half_size: Vector2 = Vector2(10, 10) # adjust if you change square size

# =========================
# UI REFERENCES
# =========================
@onready var timer_label: Label = get_parent().get_node("TimerLabel")
@onready var best_label: Label = get_parent().get_node("BestLabel")

func _ready() -> void:
	screen_rect = get_viewport_rect()
	reset_run()
	update_best_label()

func _physics_process(delta: float) -> void:
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
	
	# ---- MOVEMENT ----
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
	
	move_and_slide()
	
	# ---- EDGE = DEATH ----
	if not is_fully_inside_screen():
		on_death()

# =========================
# STRICT EDGE CHECK
# =========================
func is_fully_inside_screen() -> bool:
	var pos := global_position
	
	if pos.x - half_size.x < screen_rect.position.x:
		return false
	if pos.y - half_size.y < screen_rect.position.y:
		return false
	if pos.x + half_size.x > screen_rect.position.x + screen_rect.size.x:
		return false
	if pos.y + half_size.y > screen_rect.position.y + screen_rect.size.y:
		return false
	
	return true

# =========================
# DEATH / RESET LOGIC
# =========================
func on_death() -> void:
	# update best time
	if time_alive > best_time:
		best_time = time_alive
		update_best_label()
	
	# start new run
	reset_run()

func reset_run() -> void:
	velocity = Vector2.ZERO
	global_position = screen_rect.size / 2
	time_alive = 0.0
	pressure = 0.0

func update_best_label() -> void:
	if best_label:
		best_label.text = "Best: %.2f" % best_time
