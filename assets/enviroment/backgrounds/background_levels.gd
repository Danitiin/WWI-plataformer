extends Node2D

var camera: Camera2D
var player: CharacterBody2D

@export var x_offset: float = -250.0
#Sprite del agua animada
@onready var water = $AnimatedSprite2D


@export_group("Movimiento progresivo del agua")
@export var start_x: float = 0.0
@export var end_x: float = 8000.0
@export var water_start_pos: float = 600.0
@export var water_end_pos: float = -400.0

@export_group("Movimiento de nubes")
@export var clouds_speed: float = 15.0
@export var clouds_wrap_distance: float = 1200.0
@export var extra_offset: float = 400.0

@onready var clouds1: TileMapLayer = $Clouds
@onready var clouds2: TileMapLayer = $Clouds2

var clouds_container_1: Node2D
var clouds_container_2: Node2D

func _ready():
    #inicia la animacion del agua
    if water:
        water.play("idle")

    await get_tree().process_frame

    player = get_tree().get_first_node_in_group("player")
    if not player:
        print("No se encontró el player")
        return

    if player:
        camera = player.get_node_or_null("Camera2D")

    if not camera:
        print("No se encontró la cámara del player")

    setup_infinite_clouds()

func _process(delta):
    if not camera or not player:
        return

    #el fondo sigue a la camara horizontalmente y verticalmente no se mueve porque esta 0
    global_position.x = camera.get_screen_center_position().x + x_offset
    global_position.y = 0

    """
    Calculamos el progreso del jugador (cuanto avanza) / (distancia total) esto nos dice
    la proporpocion del nivel completada.
    Con "clamp" nos aseguramos que los valores que obtenemos no se pasen de 0.0 y 1.0
    """
    var player_x = player.global_position.x
    var progress = clamp((player_x - start_x) / (end_x - start_x), 0.0, 1.0)

    """
    Segun el progreso del jugador movemos el sprite del reflejo animado del agua.
    lerp calcula la distancia total entre punto a (water_start_pos) y punto b (water_end_pos)
    la distancia total se multiplica.
    lerp hace que la transición se sienta suave porque hace transiciones graduales
    """
    if water:
        water.position.x = lerp(water_start_pos, water_end_pos, progress)

    move_clouds(delta)

func setup_infinite_clouds():
    if not clouds1 or not clouds2:
        return

    #Creamos un contenedor para guardar todas las nubes y poder moverlas juntas
    clouds_container_1 = Node2D.new()
    clouds_container_1.name = "CloudsContainer1"
    add_child(clouds_container_1)

    #Se guarda la posicion de las nubes
    var clouds1_pos = clouds1.position
    var clouds2_pos = clouds2.position

    #Quitamos las nubes para añadirlas al contenedor
    remove_child(clouds1)
    remove_child(clouds2)

    #Metemos las nubes dentro del contenedor y hacemos que
    clouds_container_1.add_child(clouds1)
    clouds_container_1.add_child(clouds2)

    clouds1.position = clouds1_pos
    clouds2.position = clouds2_pos

    #Contenedor 2 vacio
    clouds_container_2 = Node2D.new()
    clouds_container_2.name = "CloudsContainer2"
    add_child(clouds_container_2)
    
    #Copiamos las nubes
    var clouds1_duplicate = clouds1.duplicate()
    var clouds2_duplicate = clouds2.duplicate()

    clouds_container_2.add_child(clouds1_duplicate)
    clouds_container_2.add_child(clouds2_duplicate)

    #Se pone el contenedor 2 al final del contenedor 1
    clouds_container_2.position.x = clouds_wrap_distance

    print("Sistema de nubes infinitas configurado")

func move_clouds(delta: float):
    if not clouds_container_1 or not clouds_container_2:
        return

    #Mover ambos contenedores hacia la izquierda
    clouds_container_1.position.x -= clouds_speed * delta
    clouds_container_2.position.x -= clouds_speed * delta

    #Limite donde los contenedores se tienen que cambiar de sitio
    var wrap_limit = -clouds_wrap_distance - extra_offset

    #Cuando el contenedor1 pasa el limite, se cambia por el 2, y lo mismo con el 2
    if clouds_container_1.position.x <= wrap_limit:
        clouds_container_1.position.x = clouds_container_2.position.x + clouds_wrap_distance

    if clouds_container_2.position.x <= wrap_limit:
        clouds_container_2.position.x = clouds_container_1.position.x + clouds_wrap_distance