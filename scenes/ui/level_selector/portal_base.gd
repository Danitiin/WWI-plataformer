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

        #Cargar la escena de loading
        var loading_screen = preload("res://scenes/ui/loading_screens/loading_level.tscn").instantiate()
        get_tree().root.add_child(loading_screen) 

        #Esperar 2 segundos
        await get_tree().create_timer(1.0).timeout

        #Cargar el nivel
        GameManager.load_level(level_id)

        loading_screen.queue_free()