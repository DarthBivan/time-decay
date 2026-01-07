extends Node2D

@onready var kill_area: Area2D = $KillArea
@onready var blade_visual: Sprite2D = $BladeVisual

# =========================
# MOVEMENT
# =========================
var speed: float = 140.0
var direction: int = 1   # 1 = down, -1 = up

# Visual spin
var spin_speed: float = 8.0

var min_y: float
var max_y: float

func _ready() -> void:
	var viewport := get_viewport_rect()
	
	min_y = 60
	max_y = viewport.size.y - 60

	# Connect kill signal
	kill_area.body_entered.connect(_on_kill_area_body_entered)

func _process(delta: float) -> void:
	# ---- MOVE UP / DOWN (SCRIPTED, NO PHYSICS) ----
	position.y += speed * direction * delta
	
	if position.y < min_y:
		position.y = min_y
		direction = 1
	elif position.y > max_y:
		position.y = max_y
		direction = -1
	
	# ---- SPIN VISUAL ONLY ----
	blade_visual.rotation += spin_speed * delta

# =========================
# KILL PLAYER
# =========================
func _on_kill_area_body_entered(body: Node) -> void:
	if body.name == "Player":
		body.die()
