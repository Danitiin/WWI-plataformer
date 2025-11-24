extends Area3D

@export var level_id: int = -1

func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if level_id < 0:
        print("ERROR: El portal no tiene un ID de nivel válido.")
        return

    if body.is_in_group("player"):
        print("Jugador detectado. Cargando nivel %s..." % level_id)
        GameManager.load_level(level_id)