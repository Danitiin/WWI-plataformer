extends Area2D

@export var checkpoint_id: int = 0
var is_activated: bool = false

@onready var sprite = $AnimatedSprite2D

func _ready():
    add_to_group("checkpoints")
    #Conecta una señal para saber si algo choca con el checkpoint
    body_entered.connect(_on_body_entered)
    sprite.play("inactive")

#Si es el player el que choca con el checkpoint, llama activate
func _on_body_entered(body: Node2D):
    if body.is_in_group("player") and not is_activated:
        activate(body)

func activate(player = null):
    is_activated = true

    var level = get_tree().current_scene
    if level and level.has_method("activate_checkpoint"):
        #Guarda la posicion donde esta el checkpoint y al jugador
        level.activate_checkpoint(global_position, player)
    else:
      push_error("ERROR: La escena actual no tiene el método activate_checkpoint")

    change_visual()

func change_visual():
    if sprite and sprite is AnimatedSprite2D:
        sprite.play("active")

#Reinicia el chekpoint
func desactivate():
    is_activated = false

    if sprite and sprite is AnimatedSprite2D:
        sprite.play("inactive")
    elif sprite:
        sprite.modulate = Color(1, 1, 1)