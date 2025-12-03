extends EnemyBase

@export var jump_force: float = -400.0
@export var jump_horizontal_speed: float = 150.0
@export var jump_interval: float = 2.0
@export var gravity: float = 980.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_timer: Timer = $JumpTimer
@onready var raycast: RayCast2D = $RayCast2D
@onready var floor_check_raycast: RayCast2D = $FloorCheckRaycast

var direction: int = 1

func _ready():
	super._ready()
	"""
	seashell es un enemigo que se mueve saltando, por lo que no puede caminar
	asi se lo indicamos a enemyBase
	"""
	can_walk = false

	if jump_timer:
		jump_timer.wait_time = jump_interval
		jump_timer.timeout.connect(_on_jump_timer_timeout)
		jump_timer.start()
	else:
		print("ERROR: JumpTimer no encontrado!")

	#Raycast a 15 px en la direccion que mira seashell para que detecte paredes
	if raycast:
		raycast.target_position = Vector2(15 * direction, 0)

	if sprite:
		sprite.play("idle")
		sprite.flip_h = direction < 0

func _physics_process(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		#desacelera a seashell cuando cae gradualmente, por eso se desliza al aterrizar
		velocity.x = move_toward(velocity.x, 0, 500 * delta)

	#raycast detecta algo y cambia de direccion
	if raycast:
		if raycast.is_colliding():
			change_direction()

	move_and_slide()

	if is_on_wall():
		change_direction()

#cambia la direccion de seashell, tambien cambia el sprite y su raycast
func change_direction():
	direction *= -1
	sprite.flip_h = direction > 0
	raycast.target_position = Vector2(15 * direction, 0)

func _on_jump_timer_timeout():
	if is_on_floor():
		"""
		Se calcula la distancia del salto mas el deslizamiento despues de caer
		con abs hacemos que el valor sea positivo, en godot el eje y positivo
		va hacia abajo y el negativo hacia arriba, si no se pone abs el calculo
		se haria mal
		"""
		var jump_distance = jump_horizontal_speed * (2.0 * abs(jump_force) / gravity) * 1.2

		if floor_check_raycast:
			var original_pos = floor_check_raycast.position
			#movemos el raycast que detecta el suelo a donde caeria seashell si saltase
			floor_check_raycast.position = Vector2(direction * jump_distance, 0)
			#se fuerza la actualizacion del raycast
			floor_check_raycast.force_raycast_update()

			#si seashell se va a caer, cambia de direccion
			if not floor_check_raycast.is_colliding():
				change_direction()
			
			floor_check_raycast.position = original_pos
			
		#animacion de saltar y ejecucion del sato
		sprite.play("anticipate_jump")
		await get_tree().create_timer(0.2).timeout
		velocity.y = jump_force
		velocity.x = direction * jump_horizontal_speed
		sprite.play("idle")