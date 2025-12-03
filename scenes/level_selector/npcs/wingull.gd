extends Area3D

@onready var interaction_label: Label3D = get_node_or_null("InteractionLabel")

var player_nearby: bool = false
var dialogue_active: bool = false

func _ready():
	#conecta señales para avisar si algo entra y sale de su area
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if interaction_label:
		interaction_label.visible = false

func _on_body_entered(body: Node3D):
	#si el que entra es el player, se muestra la etiqueta
	if body.is_in_group("player"):
		player_nearby = true
		if interaction_label:
			interaction_label.visible = true

func _on_body_exited(body: Node3D):
	#si el que sale es el player, se quita la etiqueta
	if body.is_in_group("player"):
		player_nearby = false
		if interaction_label:
			interaction_label.visible = false

func _unhandled_input(event):
	#player pulsa espacio, enseñar dialogo
	if player_nearby and not dialogue_active and event.is_action_pressed("interact"):
		show_dialogue()

func show_dialogue():
	#se quita la etiqueta
	dialogue_active = true
	if interaction_label:
		interaction_label.visible = false
	
	#durante el dialogo el player no se puede mover
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_process_mode(Node.PROCESS_MODE_DISABLED)
	
	# Cargar el diálogo desde el archivo
	var dialogue_resource = load("res://assets/ui/dialogs/map_joke_seagull.dialogue")
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")
	await DialogueManager.dialogue_ended
	
	# El player se puede volver a mover
	if player:
		player.set_process_mode(Node.PROCESS_MODE_INHERIT)
	
	# si sigue cerca se muestra la etiqueta
	dialogue_active = false
	if player_nearby and interaction_label:
		interaction_label.visible = true