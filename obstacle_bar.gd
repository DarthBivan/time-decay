extends CharacterBody2D

var speed: float = 150.0
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# start moving right
	direction = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		# bounce
		direction = direction.bounce(collision.get_normal())
