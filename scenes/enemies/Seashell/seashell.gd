extends EnemyBase

@export var jump_force: float = -400.0
@export var jump_horizontal_speed: float = 150.0
@export var jump_interval: float = 2.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_timer: Timer = $JumpTimer
@onready var raycast: RayCast2D = $RayCast2D

var direction: int = 1

func _ready():
	super._ready()
	can_walk = false

	if jump_timer:
		jump_timer.wait_time = jump_interval
		jump_timer.timeout.connect(_on_jump_timer_timeout)
		jump_timer.start()
	else:
		print("ERROR: JumpTimer no encontrado!")

	if raycast:
		raycast.target_position = Vector2(15 * direction, 0)

	if sprite:
		sprite.play("idle")
		sprite.flip_h = direction < 0

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0, 500 * delta)

	if raycast:
		if raycast.is_colliding():
			change_direction()

	move_and_slide()

	if is_on_wall():
		change_direction()

func change_direction():
	direction *= -1
	sprite.flip_h = direction > 0
	raycast.target_position = Vector2(15 * direction, 0)

func _on_jump_timer_timeout():
	if is_on_floor():
		# Calcular distancia del salto + margen para deslizamiento
		var jump_distance = jump_horizontal_speed * (2.0 * abs(jump_force) / gravity) * 1.2

		if $FloorCheckRaycast:
			var original_pos = $FloorCheckRaycast.position
			$FloorCheckRaycast.position = Vector2(direction * jump_distance, 0)
			$FloorCheckRaycast.force_raycast_update()

			if not $FloorCheckRaycast.is_colliding():
				change_direction()
				
			$FloorCheckRaycast.position = original_pos
			
		sprite.play("anticipate_jump")
		await get_tree().create_timer(0.2).timeout
		velocity.y = jump_force
		velocity.x = direction * jump_horizontal_speed
		sprite.play("idle")