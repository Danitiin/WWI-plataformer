extends Node2D

var camera: Camera2D
var player: CharacterBody2D

@export var x_offset: float = -250.0
@onready var water = $AnimatedSprite2D

@export_group("Movimiento progresivo del agua")
@export var start_x: float = 0.0
@export var end_x: float = 8000.0
@export var water_start_pos: float = 600.0
@export var water_end_pos: float = -400.0

@export_group("Movimiento de nubes")
@export var clouds_speed: float = 15.0  #vel de las nubes
@export var clouds_wrap_distance: float = 1200.0
@export var extra_offset: float = 400.0

@onready var clouds1: TileMapLayer = $Clouds
@onready var clouds2: TileMapLayer = $Clouds2

var clouds_container_1: Node2D
var clouds_container_2: Node2D

func _ready():
    #inica la animacion del agua
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

    #back sigue a camara
    global_position.x = camera.get_screen_center_position().x + x_offset
    global_position.y = 0

    var player_x = player.global_position.x
    var progress = clamp((player_x - start_x) / (end_x - start_x), 0.0, 1.0)

    #mueve el agua segun el porgreso
    if water:
        water.position.x = lerp(water_start_pos, water_end_pos, progress)

    #Muever las nubes hacia la izquierda
    move_clouds(delta)

func setup_infinite_clouds():
    if not clouds1 or not clouds2:
        return

    clouds_container_1 = Node2D.new()
    clouds_container_1.name = "CloudsContainer1"
    add_child(clouds_container_1)

    var clouds1_pos = clouds1.position
    var clouds2_pos = clouds2.position

    remove_child(clouds1)
    remove_child(clouds2)

    clouds_container_1.add_child(clouds1)
    clouds_container_1.add_child(clouds2)

    clouds1.position = clouds1_pos
    clouds2.position = clouds2_pos

    clouds_container_2 = Node2D.new()
    clouds_container_2.name = "CloudsContainer2"
    add_child(clouds_container_2)

    var clouds1_duplicate = clouds1.duplicate()
    var clouds2_duplicate = clouds2.duplicate()

    clouds_container_2.add_child(clouds1_duplicate)
    clouds_container_2.add_child(clouds2_duplicate)

    clouds_container_2.position.x = clouds_wrap_distance

    print("Sistema de nubes infinitas configurado")

func move_clouds(delta: float):
    if not clouds_container_1 or not clouds_container_2:
        return

    #Mover ambos nubes hacia la izquierda
    clouds_container_1.position.x -= clouds_speed * delta
    clouds_container_2.position.x -= clouds_speed * delta

    var wrap_limit = -clouds_wrap_distance - extra_offset

    if clouds_container_1.position.x <= wrap_limit:
        clouds_container_1.position.x = clouds_container_2.position.x + clouds_wrap_distance

    if clouds_container_2.position.x <= wrap_limit:
        clouds_container_2.position.x = clouds_container_1.position.x + clouds_wrap_distance