extends Node2D

@onready var kill_area: Area2D = $KillArea
@onready var blade_visual: Sprite2D = $BladeVisual

# =========================
# MOVEMENT (GAMEPLAY)
# =========================
var speed: float = 140.0          # UP/DOWN speed (DO NOT SCALE)
var direction: int = 1            # 1 = down, -1 = up

# =========================
# SPIN (VISUAL ONLY)
# =========================
var base_spin_speed: float = 1.5   # very slow at start
var spin_growth: float = 0.12      # how fast spin ramps up
var max_spin_speed: float = 12.0   # visual cap

# =========================
# LIMITS
# =========================
var min_y: float
var max_y: float

# Reference to player (to read time_alive)
var player: Node = null

func _ready() -> void:
	var viewport := get_viewport_rect()
	
	min_y = 60
	max_y = viewport.size.y - 60

	# Find player
	player = get_parent().get_node("Player")

	# Connect kill signal
	kill_area.body_entered.connect(_on_kill_area_body_entered)

func _process(delta: float) -> void:
	# ---- MOVE UP / DOWN (CONSTANT SPEED) ----
	position.y += speed * direction * delta
	
	if position.y < min_y:
		position.y = min_y
		direction = 1
	elif position.y > max_y:
		position.y = max_y
		direction = -1
	
	# ---- COMPUTE SPIN SPEED FROM TIME ----
	var t: float = 0.0
	if player and "time_alive" in player:
		t = player.time_alive
	
	var spin_speed := base_spin_speed + t * spin_growth
	spin_speed = min(spin_speed, max_spin_speed)
	
	# ---- SPIN VISUAL ONLY ----
	blade_visual.rotation += spin_speed * delta

# =========================
# KILL PLAYER
# =========================
func _on_kill_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.die()
