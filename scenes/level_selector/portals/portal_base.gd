extends Area3D

@export var level_id: int = -1

func _ready():
    #detectamos si algo entra en el area del portal
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if level_id < 0:
        print("ERROR: El portal no tiene un ID de nivel válido.")
        return

    # Si lo que entra es el player
    if body.is_in_group("player"):
        #Quitar el sonido para que no se oiga la musica durante las pantallas de carga
        AudioServer.set_bus_mute(0, true)

        #Cargar la escena de loading
        var loading_screen = preload("res://scenes/ui/loading_screens/loading_level.tscn").instantiate()
        get_tree().root.add_child(loading_screen) 

        #Esperar 2 segundos
        await get_tree().create_timer(1.0).timeout

        #Volver a poner el sonido
        AudioServer.set_bus_mute(0, false)

        await get_tree().process_frame

        #Cargamos el nivel y cambiamos la escena para mostrar el nivel
        GameManager.load_level(level_id)

        loading_screen.queue_free()