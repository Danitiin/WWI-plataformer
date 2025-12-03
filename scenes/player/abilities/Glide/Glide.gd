extends AbilityBase
class_name Glide

@export_group("Fisica del planeo")
@export var glide_gravity: float = 40.0
@export var glide_max_fall_speed: float = 45.0
@export var horizontal_boost: float = 0.0
@export var horizontal_control: float = 0.9
@export var horizontal_friction: float = 0.98

@export_group("Tiempo y transicion")
@export var max_glide_duration: float = 5.0
@export var transition_time: float = 0.15
@export var reactivation_cooldown: float = 0.3  #Cooldown para evitar spam

var is_gliding: bool = false
var glide_timer: float = 0.0
var transition_timer: float = 0.0
var is_transitioning: bool = false
var initial_direction: int = 1
var cooldown_timer: float = 0.0

func physics_update(delta: float) -> bool:
	#Actualizar cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	#Solo actualizar en el aire y cayendo
	if not can_glide():
		if is_gliding:
			stop_glide()
		return false

	#Verificar input (mantener presionado)
	var want_to_glide = Input.is_action_pressed("ability_action")

	#Si el jugador quiere planear, no lo hace y no tiene cooldown
	if want_to_glide and not is_gliding and cooldown_timer <= 0:
		start_glide()
	#Si no quiere planear y esta planeando
	elif not want_to_glide and is_gliding:
		stop_glide()

	#Actualizar estado de planeo
	if is_gliding:
		update_glide(delta)
		return true

	return false

func can_glide() -> bool:
	#Condiciones para poder planear
	if player.is_on_floor(): #Si esta en el suelo
		return false
	if player.velocity.y < 0: #Si va hacia arriba
		return false
	if player.is_spinning:  #No planear durante spin
		return false
	return true

func start_glide():
	is_gliding = true
	is_transitioning = true
	transition_timer = transition_time
	glide_timer = 0.0

	#Guarda la direccion a la que mira el player e impulsa al player horizontalmente
	initial_direction = player.get_facing_direction()
	player.velocity.x += initial_direction * horizontal_boost

	print("Iniciando planeo")

func update_glide(delta: float):
	#Va incrementando planeo timer cada frame
	glide_timer += delta

	#Si el player lleva 5 segundos o mas para de planear
	if glide_timer >= max_glide_duration:
		stop_glide()
		return

	var gravity_multiplier = 1.0
	#Si transiciona (transicion de gravedad normal a la de planear)
	if is_transitioning:
		transition_timer -= delta
		#Si termina de transicionar
		if transition_timer <= 0:
			#Para y deja solo la velocidad de planeo
			is_transitioning = false
			gravity_multiplier = 0.0
		else:
			#Calcula el progreso de la transición
			var t = 1.0 - (transition_timer / transition_time)
			#Reduce el multiplicador de gravedad gradualmente
			gravity_multiplier = lerp(1.0, 0.0, t)
	else:
		gravity_multiplier = 0.0

	#Calcula la diferencia entre las 2 gravedades y segun el multplicador la reduce
	var current_gravity = glide_gravity + (player.gravity - glide_gravity) * gravity_multiplier
	player.velocity.y += current_gravity * delta

	#Limitar velocidad de caida
	player.velocity.y = min(player.velocity.y, glide_max_fall_speed)

	# El player se puede mover horizontalmente mientras planea
	var direction = Input.get_axis("ui_left", "ui_right")

	#Si el player se mueve horizontalmente
	if direction != 0.0:
		#90% de control aereo
		var glide_acceleration = player.air_acceleration * horizontal_control
		#El player acelera gradualmente hacia la direccion que este pulsando
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * player.speed,
			glide_acceleration * delta
		)
	else:
		player.velocity.x *= horizontal_friction

#Quita el planeo
func stop_glide():
	if not is_gliding:
		return

	is_gliding = false
	is_transitioning = false
	cooldown_timer = reactivation_cooldown
	print("Fin del planeo")

func get_animation_name() -> String:
	if is_gliding:
		return "glide"
	return ""