extends CharacterBody3D

@export var speed: float = 2.0
@onready var animated_sprite_3d = $AnimatedSprite3D

func _physics_process(_delta):
    #Movimiento en la isla del player
    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

    velocity.x = direction.x * speed
    velocity.z = direction.z * speed

    move_and_slide()
    update_animation(input_dir)

func update_animation(input_dir: Vector2):
    #Segun si el player se mueve o no, reproducir run o idle
    if input_dir.length() > 0.1:
        if animated_sprite_3d.animation != "run":
            animated_sprite_3d.play("run")
    else:
        if animated_sprite_3d.animation != "idle":
            animated_sprite_3d.play("idle")

    # Girar el sprite horizontalmente según la dirección
    if input_dir.x > 0.1:
        animated_sprite_3d.flip_h = true
    elif input_dir.x < -0.1:
      animated_sprite_3d.flip_h = false