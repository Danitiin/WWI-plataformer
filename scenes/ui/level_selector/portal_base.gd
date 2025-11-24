extends Area3D

@export var level_id: int = -1
@export var level_name: String = "Nivel 1"

var player_inside: bool = false

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    # Actualizar el texto del Label3D con el nombre del nivel
    var label = $Label3D
    if label:
        label.text = level_name

func _process(_delta):
    # Si el jugador está dentro y presiona el botón, cargar el nivel
    if player_inside and Input.is_action_just_pressed("ui_accept"):
        _load_level()

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_inside = true
        print("Jugador cerca del portal. Presiona [ENTER/ESPACIO] para entrar.")

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_inside = false

func _load_level():
    if level_id < 0:
        print("ERROR: El portal no tiene un ID de nivel válido.")
        return

    print("Cargando nivel %s..." % level_id)
    GameManager.load_level(level_id)