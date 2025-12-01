extends CharacterBody2D
class_name EnemyBase

#Señales
signal enemy_dead

#Sistema de vida
@export var max_health: int = 1
@export var speed: float = 150.0
var current_health: int = 1
var is_dying: bool = false

var move_direction = 1
var can_walk = true

@onready var animated_sprite = $AnimatedSprite2D
@onready var wall_raycast = $RayCast2D
@onready var collision_shape = $CollisionShape2D
@onready var floor_raycast = $FloorRayCast

func _ready():
	current_health = max_health
	add_to_group("enemies")

func _physics_process(delta):
		
	if animated_sprite:
		animated_sprite.flip_h = move_direction > 0

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	if can_walk:
		velocity.x = move_direction * speed

	move_and_slide()

	if wall_raycast.is_colliding():
		move_direction *= -1
		wall_raycast.target_position.x *= -1
		floor_raycast.target_position.x *= -1

	if can_walk and is_on_floor() and floor_raycast and not floor_raycast.is_colliding():
		move_direction *= -1
		wall_raycast.target_position.x *= -1
		floor_raycast.target_position.x *= -1

func take_damage(damage: int):
	if is_dying:
		return

	current_health -= damage
	current_health = max(current_health, 0)

	print(name, " recibio daño " , current_health, "/", max_health)

	if current_health <= 0:
		die()

func die():
	if is_dying:
		return

	is_dying = true
	enemy_dead.emit()

	print(name, " murio")

	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	set_physics_process(false)

	if animated_sprite and animated_sprite.sprite_frames.has_animation("dead"):
		animated_sprite.play("dead")
		#Espera la a animacion de muerte
		await animated_sprite.animation_finished

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	queue_free()
