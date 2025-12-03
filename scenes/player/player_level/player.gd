extends CharacterBody2D

#Señales
signal health_changed(new_health: int, max_health: int)
signal player_damaged(damage: int)
signal player_died

# Movimiento básico del player
@export_group("Movimiento")
@export var speed: float = 100.0
@export var acceleration: float = 250.0
@export var friction: float = 800.0
@export_group("Movimiento aereo")
@export var air_acceleration: float = 500.0
@export var air_friction: float = 100.0
@export var air_turn_acceleration: float = 1200.0

const max_gravity_multiplier: float = 0.4
const anticipation_duration: float = 0.08
const landing_duration: float = 0.15

#Salto
@export_group("Salto")
@export var jump_velocity: float = -350.0
@export var gravity: float = 980.0
#Animaciones antes y despues del salto
var is_landing: bool = false
var is_anticipating: bool = false
var was_in_air: bool = false
var jump_was_pressed: bool = false

# Giro en el aire
@export_group("Spin")
@export var spin_duration: float = 0.25
@export var spin_boost: float = -100.0
@export var spin_gravity_multiplier: float = 0.4
@export var spin_horizontal_boost: float = 1.1

var is_spinning: bool = false
var spin_timer: float = 0.0
var can_spin: bool = false
var spin_rotation: float = 0.0

# Coyote Time y Jump Buffer
@export_group("Controles Avanzados")
@export var coyote_time_duration: float = 0.15
@export var jump_buffer_duration: float = 0.15

var coyote_time_timer: float = 0.0
var jump_buffer_timer: float = 0.0

#Corner Correction
@export_group("Corner Correction")
@export var corner_correction_enabled: bool = true
@export var corner_correction_amount: int = 8

# Habilidades de los niveles
var abilities: Array[AbilityBase] = []
var current_ability_index: int = 0
var ability_in_control: bool = false

#Habilidades desbloqueadas temporalmente en este nivel
var unlocked_abilities: Dictionary = {}

#Sistema de vida
@export_group("Sistema de vida")
@export var max_health: int = 3
@export var invincibility_duration: float = 1.5
@export var knockback_force: float = 300.0

var current_health: int = 3
var is_invincible: bool = false
var is_dead: bool = false
var is_hit: bool = false

#Sistema de ataque
@export_group("Sistema de ataque")
@export var stomp_bounce_force: float = -250.0
@export var stomp_damage: int = 1

#Camara look-ahead
@export_group("Camara")
@export var camera_look_ahead: float = 60.0
@export var camera_smooth_speed: float = 0.5
@export var camera_move_threshold: float = 10.0

#Sprite del player
@onready var animated_sprite : AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_box: Area2D = $HurtBox

@onready var camera: Camera2D = $Camera2D

func _ready():
	#Inicializa la vida y emite una señal para el hud
	add_to_group("player")
	current_health = max_health
	health_changed.emit(current_health, max_health)
	load_level_ability()

	#Si hay hurt_box
	if hurt_box:
		#Conecta la señal para saber con que choca
		hurt_box.body_entered.connect(_on_hurt_box_body_entered)

func load_level_ability():
	#Coge las habilidades
	var level_ability_names = GameManager.get_level_abilities()
	#limpia las habilidades desbloqueadas
	unlocked_abilities.clear()
	
	#Carga las habilidades del nivel (bloqueadas hasta recoger su poción)
	for ability_name in level_ability_names:
		unlocked_abilities[ability_name] = false
		add_ability(ability_name)

func add_ability(ability_name: String):
	#Busca la habilidad
	var ability_path = "res://scenes/player/abilities/" + ability_name + "/" + ability_name + ".tscn"
	if not ResourceLoader.exists(ability_path):
		push_error("No hay habilidad: %s" % ability_name)
		return

	#Carga el archivo como un PackedScene (escena en memoria para instanciarla luego)
	var ability_scene = load(ability_path) as PackedScene
	if not ability_scene:
		push_error("No se pudo cargar la escena de habilidad: %s" % ability_path)
		return

	#Instancia la escena como AbilityBase
	var ability = ability_scene.instantiate() as AbilityBase
	if not ability:
		push_error("No se pudo instanciar la habilidad: %s" % ability_path)
		return
	
	#Añade la habilidad al player como hija
	add_child(ability)
	ability.putAbility(self)
	abilities.append(ability)
	

func _physics_process(delta: float):
	check_landing()
	handle_gravity(delta)
	update_timers(delta)
	handle_jump()
	handle_abilities(delta)
	handle_horizontal_movement(delta)
	attempt_corner_correction()
	update_animation()
	update_camera_offset(delta)
	update_spin_visual(delta)
	move_and_slide()

# Aplicar gravedad
func handle_gravity(delta: float):
	#Si hay una habilidad usandose no aplica gravedad
	if ability_in_control:
		return

	if is_on_floor():
		velocity.y = 0.0
		return

	#Reduce la gravedad si el player esta haciendo un spin
	var gravity_multiplier = spin_gravity_multiplier if is_spinning else 1.0
	velocity.y += gravity * gravity_multiplier * delta
	
	#Limita la velocidad de caida
	velocity.y = min(velocity.y, gravity * max_gravity_multiplier)

# Actualizar temporizadores
func update_timers(delta: float):
	coyote_time_timer = max(0.0, coyote_time_timer - delta)
	jump_buffer_timer = max(0.0, jump_buffer_timer - delta)
	
	#Duración del spin
	if spin_timer > 0.0:
		spin_timer -= delta
		if spin_timer <= 0.0:
			end_spin()
	
	# Coyote Time y estado cuando el player esta en el suelo
	if is_on_floor():
		coyote_time_timer = coyote_time_duration
		can_spin = false
		if is_spinning:
			end_spin()

func handle_jump():
	# Comprobar si hay que saltar
	var can_jump = is_on_floor() or coyote_time_timer > 0.0
	"""
	Si el jugador presiono saltar antes de tocar el suelo, (para que el jugador no se fruste
	porque pulso saltar muy poco tiempo antes de tocar el suelo y el player no salto) puede
	saltar, no esta haciendo animacion de anticipar y si no salto ya con esa pulsación
	"""
	if jump_buffer_timer > 0.0 and can_jump and not is_anticipating and not jump_was_pressed:
		perform_jump()

func perform_jump():
	#Velocidad de salto, resetea timers y habilita spin
	velocity.y = jump_velocity
	coyote_time_timer = 0.0
	jump_buffer_timer = 0.0
	can_spin = true
	jump_was_pressed = true

	if has_node("JumpSound"):
		$JumpSound.play()

	#Activa la animacion de anticipation
	is_anticipating = true
	get_tree().create_timer(anticipation_duration).timeout.connect(func():is_anticipating = false)

#Detecta cuando aterriza el player para activar la animación de aterrizaje
func check_landing():
	var is_in_air = not is_on_floor()
	
	if was_in_air and not is_in_air and not is_landing:
		is_landing = true
		get_tree().create_timer(landing_duration).timeout.connect(func():is_landing = false)

	was_in_air = is_in_air

func start_spin():
	#Inicia el spin
	is_spinning = true
	can_spin = false
	spin_timer = spin_duration
	spin_rotation = 0.0

	#Pequeño impulso hacia arriba
	velocity.y = spin_boost

	#Si el player se mueve durante el spin
	if abs(velocity.x) > 10:
		#Agrega una pequeña aceleración al moviento horizontal
		velocity.x *= spin_horizontal_boost

#Termina el spin y devuelve el sprite a su posición normal
func end_spin():
	is_spinning = false
	animated_sprite.scale.x = 1.0
	animated_sprite.rotation = 0.0

func update_spin_visual(delta: float):
	if not is_spinning:
		return

	#A que velocidad tiene que girar
	var spin_speed = (PI * 1.0) / spin_duration
	spin_rotation += spin_speed * delta

	#Se "aplasta" el sprite del player para que cuando haga spin
	#de la sensación de que esta girando como un papel
	var effect_paper_mario = abs(cos(spin_rotation))
	animated_sprite.scale.x = lerp(0.1, 1.0, effect_paper_mario)

	#Si el sprite mira a la izquierda, lo invierte
	if animated_sprite.flip_h:
		animated_sprite.scale.x = -abs(animated_sprite.scale.x)

# Movimiento horizontal
func handle_horizontal_movement(delta: float):
	if ability_in_control:
		return

	var direction = Input.get_axis("ui_left", "ui_right")

	var accel: float = acceleration
	var fric: float = friction

	#El player en el aire usa distintos valores
	if not is_on_floor():
		"""
		Mayor aceleración al cambiar de dirección en el aire, si no pasara esto seria
		muy tedioso cambiar de direccion en el aire aparte de lento ya que el jugador
		tiene que cancelar la velocidad hacia la que esta yendo y luego empezar a
		acelerar hacia la que quiere ir, con una mayor aceleración al cambiar de direccion
		se siente mas fluido el movimiento en el aire
		"""
		if direction != 0 and velocity.x != 0 and sign(direction) != sign(velocity.x):
			accel = air_turn_acceleration
		else:
			accel = air_acceleration

		fric = air_friction

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, fric * delta)

# Corner Correction
func attempt_corner_correction():
	if not corner_correction_enabled:
		return
	
	# Solo intentar corrección cuando está subiendo
	if velocity.y >= 0:
		return
	
	var dt = get_physics_process_delta_time()
	var motion = Vector2(0, velocity.y * dt)
	
	# Ver si hay colision verticalmente
	if test_move(global_transform, motion):
		for i in range(1, corner_correction_amount + 1):
			for direction in [-1.0, 1.0]:
				var offset = Vector2(i * direction, 0)
				if not test_move(global_transform.translated(offset), motion):
					# Aplicar la corrección
					global_position.x += i * direction

					if velocity.x * direction < 0:
						velocity.x = 0
					
					return

#Cambiar animación
func update_animation():
	if velocity.x != 0 and not ability_in_control and not is_spinning:
		animated_sprite.flip_h = velocity.x > 0
	
	var new_animation = ""
	var ability_animation = ""
	#Coge la animacion de la habilidad activa (si existe)
	if not abilities.is_empty():
		ability_animation = abilities[current_ability_index].get_animation_name()

	#Elige la animación correcta segun el estado del player
	if is_hit:
		new_animation = "hit"
	elif ability_animation != "":
		new_animation = ability_animation
	elif is_spinning:
		new_animation = "spin"
	elif is_landing:
		new_animation = "ground"
	elif is_anticipating:
		new_animation = "anticipation"
	elif is_on_floor():
		if abs(velocity.x) > 5:
			new_animation = "run"
		else:
			new_animation = "idle"
	else:
		if velocity.y < 0:
			new_animation = "jump"
		else:
			new_animation = "fall"

	#Cambia si es distinta a la anterior
	if animated_sprite.animation != new_animation:
		animated_sprite.play(new_animation)
	
# Gestión de habilidades
func handle_abilities(delta: float):
	if abilities.is_empty():
		ability_in_control = false
		return

	var selected_ability = abilities[current_ability_index]

	#Ver si está desbloqueada
	if not unlocked_abilities.get(selected_ability.name, false):
		ability_in_control = false
		return

	#La habilidad "toma el control" de movimiento
	#Como en dash que no podemos movernos verticalmente
	ability_in_control = selected_ability.physics_update(delta)

func _unhandled_input(event):
	#Si se pulsa el boton de saltar
	if event.is_action_pressed("ui_accept"):
		var can_jump = is_on_floor() or coyote_time_timer > 0.0
		#Si puede saltar
		if can_jump:
			jump_buffer_timer = jump_buffer_duration
			jump_was_pressed = false
		#Mientras esta en el aire si puede hacer un spin
		elif can_spin and not is_on_floor() and not is_spinning and not ability_in_control:
			start_spin()
			
	if event.is_action_released("ui_accept"):
		jump_was_pressed = false

	if not abilities.is_empty() and event.is_action_pressed("ability_action"):
		var selected_ability = abilities[current_ability_index]

		#Ver si esta desbloqueada
		if unlocked_abilities.get(selected_ability.name, false):
			selected_ability.activate()

#Devuelve la habilidad actual
func get_current_ability() -> AbilityBase:
	if abilities.is_empty():
		return null
	return abilities[current_ability_index]

#Comprueba si el player tiene una habilidad especifica
func has_ability(ability_name: String) -> bool:
	for ability in abilities:
		if ability.name == ability_name:
			return true
	return false

func collect_item(collectible: Collectible):
	var collectible_id = collectible.collectible_id

	print("RECOGIENDO COLECCIONABLE")
	print("Collectible ID: ", collectible_id)
	print("Ya está en PlayerData? ", PlayerData.is_collectible_collected(GameManager.current_level, collectible_id))

	if PlayerData.is_collectible_collected(GameManager.current_level, collectible_id):
		print("YA ESTABA GUARDADO PERMANENTEMENTE, ignorando")
		return

	print("Ya está en temp_collected_items? ", collectible_id in GameManager.temp_collected_items)

	if collectible_id not in GameManager.temp_collected_items:
		GameManager.temp_collected_items.append(collectible_id)
		print("AÑADIDO a temp_collected_items")

	print("temp_collected_items ahora: ", GameManager.temp_collected_items)

	# Llamar al método collect() del coleccionable para que se destruya
	if collectible.has_method("collect"):
		collectible.collect()

#Si el player mira a la derecha = 1 si mira a la izquierda = -1
func get_facing_direction() -> int:
	return 1 if animated_sprite.flip_h else -1

func take_damage(damage: int, knockback_direction: Vector2 = Vector2.ZERO):
	#Si el player esta muerto o es invencible no recibe daño
	if is_dead or is_invincible:
		return

	#Reduce en 1 la vida
	current_health -= damage
	current_health = max(current_health, 0)

	print("Player recibio daño. Vida: ", current_health, "/", max_health)

	#Le dice al hud que al player le cambio la vida
	player_damaged.emit(damage)
	health_changed.emit(current_health, max_health)

	#Animacion de golpeo
	is_hit = true
	animated_sprite.play("hit")

	#Si el player se mueve retrocede en la direccion opuesta al enemigo
	if knockback_direction != Vector2.ZERO:
		velocity = knockback_direction.normalized() * knockback_force

	_activate_invincibility()

	#El player ya no esta siendo golpeado despues de 0.4 segundos
	get_tree().create_timer(0.4).timeout.connect(func():
		is_hit = false
	)

	#Si la vida llega a 0 el player muere
	if current_health <= 0:
		die()
	else:
		#Si no el player vuelve a reproducir la animacion idle
		get_tree().create_timer(0.4).timeout.connect(func():
			if not is_dead:
				animated_sprite.play("idle")
		)

"""
Cuando el player es golpeado activa invencibilidad durante 1.5 segundos
y el sprite del player parpadea para indicar al jugador que no le pueden
hacer daño durante ese parpadeo
"""
func _activate_invincibility():
	is_invincible = true

	_start_blink_effect()

	var timer := get_tree().create_timer(invincibility_duration)
	timer.timeout.connect(_on_invincibility_timeout)

	print("Invencibilidad activada por ", invincibility_duration, " segundos")

func _start_blink_effect():
	#El sprite del player aparece y desaparece 5 veces
	var blink_count = 5
	var blink_duration = invincibility_duration / (blink_count * 2)

	for i in range(blink_count):
		if not is_inside_tree():
			return

		await get_tree().create_timer(blink_duration).timeout

		if not is_inside_tree():
			return
		
		#El sprite del player se vuelve semi-transparente
		animated_sprite.modulate.a = 0.3
		
		if not is_inside_tree():
			return
			
		await get_tree().create_timer(blink_duration).timeout
		
		if not is_inside_tree():
			return

		#Devuelve el sprite a ser visible por completo
		animated_sprite.modulate.a = 1.0

#Desactiva la invencibilidad
func _on_invincibility_timeout():
	is_invincible = false
	animated_sprite.modulate.a = 1.0
	print("Invencibilidad desactivada")

func die():
	if is_dead:
		return

	#Emite la señal de que el player murio
	is_dead = true
	player_died.emit()

	print("Player muerto")

	#Desactiva los controles para que no se pueda mover
	set_physics_process(false)

	#Reproduce 2 animaciones de muerte
	animated_sprite.play("dead_hit")

	await get_tree().create_timer(0.8).timeout

	animated_sprite.play("dead_ground")

	await get_tree().create_timer(0.5).timeout

	var level = get_tree().current_scene
	#Si el nivel puede reaparecer al player lo hace
	if level and level.has_method("respawn_player"):
		level.respawn_player()
	else:
		#Si no, recarga la escena
		get_tree().reload_current_scene()

func respawn(spawn_position: Vector2):
	#Resetear estados
	is_dead = false
	is_hit = false
	is_invincible = false
	is_landing = false
	is_anticipating = false
	is_spinning = false
	ability_in_control = false

	#Resetear las habilidades
	for ability in abilities:
		if "dash_timer" in ability:
			ability.dash_timer = 0.0
		if "is_gliding" in ability:
			ability.is_gliding = false
			ability.cooldown_timer = 0.0
		if "has_double_jumped" in ability:
			ability.has_double_jumped = false
		if "cooldown_timer" in ability:
			ability.cooldown_timer = 0.0

	#Resetear vida
	current_health = max_health
	health_changed.emit(current_health, max_health)

	#Ponerlo en el spawn
	global_position = spawn_position
	velocity = Vector2.ZERO

	#Resetear fisica
	set_physics_process(true)

	#Resetear player
	animated_sprite.modulate.a = 1.0
	animated_sprite.scale.x = 1.0
	animated_sprite.rotation = 0.0
	animated_sprite.play("idle")

	print("Player respawn en: ", spawn_position)

func _on_hurt_box_body_entered(body: Node2D):
	#Solo reacciona a los enemigos
	if not body.is_in_group("enemies"):
		return
		
	if is_invincible or is_dead:
		return

	#Detecta si el player esta cayendo sobre un enemigo
	var is_falling_on_enemy = (velocity.y > 0 or is_spinning) and global_position.y < body.global_position.y
	
	#Si el player cae sobre un enemigo
	if is_falling_on_enemy:
		#Daña al enemigo
		stomp_enemy(body)
	else:
		"""
		Si no, significa que esta colisionando de otra manera
		que no es sobre el enemigo, por lo tanto el player
		tiene que recibir daño
		"""
		var knockback_dir := global_position - body.global_position
		take_damage(1, knockback_dir)
		print("Colisión con enemigo: ", body.name)
		
func stomp_enemy(enemy: Node2D):
	#El player daña al enemigo si este puede recibir daño
	if enemy.has_method("take_damage"):
		enemy.take_damage(stomp_damage)
		print("¡Saltaste sobre ", enemy.name, "!")

	#El player rebota hacia arriba despues de saltar sobre un enemigo
	velocity.y = stomp_bounce_force
	
	#Como el player "toco algo de suelo" puede volver a hacer spin
	can_spin = true
	if is_spinning:
		end_spin()

func update_camera_offset(delta: float):
	if not camera:
		return

	#Solo mover camara si el jugador se mueve
	if abs(velocity.x) > camera_move_threshold:
		var target_offset_x = camera_look_ahead if animated_sprite.flip_h else -camera_look_ahead
		camera.offset.x = lerp(camera.offset.x, target_offset_x, camera_smooth_speed * delta)
	# Si está quieto, mantener la vista de la cámara

#Gestión de habilidades temporales
func unlock_temp_ability(ability_name: String):
	if unlocked_abilities.has(ability_name):
		unlocked_abilities[ability_name] = true
		print("Habilidad desbloqueada: ", ability_name)

#Bloquea todas las habilidades
func clear_temp_abilities():
	for key in unlocked_abilities.keys():
		unlocked_abilities[key] = false
	print("Habilidades bloqueadas")

#Devuelve una copia del estado de las habilidades
func get_unlocked_abilities() -> Dictionary:
	return unlocked_abilities.duplicate()

#Restaura el estado de las habilidades
func restore_unlocked_abilities(abilities_state: Dictionary):
	unlocked_abilities = abilities_state.duplicate()