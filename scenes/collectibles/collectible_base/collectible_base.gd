extends Area2D
class_name Collectible

signal collected(collectible)

@export var collectible_id: int = 0
@export var is_persistent := true
@onready var sprite = $AnimatedSprite2D

func _ready():
    add_to_group("collectibles")
    body_entered.connect(_on_body_entered)

    if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
        sprite.play("idle")

func _on_body_entered(body):
    if body.is_in_group("player") and body.has_method("collect_item"):
        if is_persistent:
            body.collect_item(self)
        else:
            collect()

func collect():
    collected.emit(self)
    # Espacio para implmentar particulas o sonidos que haga el coleccionable
    if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("obtain"):
        sprite.play("obtain")
        await sprite.animation_finished
    queue_free()