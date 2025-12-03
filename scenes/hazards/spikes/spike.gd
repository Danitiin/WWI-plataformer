extends Area2D

@export var damage: int = 1
@export var knockback_force: float = 200.0

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
    if body.is_in_group("player"):
        if body.has_method("die"):
            body.die()
            print("Spike mató al player")
