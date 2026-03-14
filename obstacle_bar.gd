extends Node2D

@onready var kill_area: Area2D = $KillArea

var speed: float = 150.0
var direction: Vector2 = Vector2(1, 1).normalized()

func _ready():
	kill_area.body_entered.connect(_on_body_entered)


func _process(delta):
	position += direction * speed * delta

	var viewport_size := get_viewport_rect().size

	# Bounce off screen edges safely (checks direction to prevent getting stuck)
	if position.x < 40 and direction.x < 0:
		direction.x *= -1
	elif position.x > viewport_size.x - 40 and direction.x > 0:
		direction.x *= -1

	if position.y < 40 and direction.y < 0:
		direction.y *= -1
	elif position.y > viewport_size.y - 40 and direction.y > 0:
		direction.y *= -1


func _on_body_entered(body):
	if body.has_method("die"):
		body.die()
