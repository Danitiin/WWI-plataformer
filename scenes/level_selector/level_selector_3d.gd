extends Node3D

@onready var tin = $Tin
@onready var animated_sprite = $Tin/AnimatedSprite2D

func _ready():
	#Si es la primera vez que se entra al juego
	if not PlayerData.intro_dialogue_seen:
		var player = get_node("PlayerSelector3D")
		#Se bloquea el movimiento del player
		if player:
			player.set_process_mode(Node.PROCESS_MODE_DISABLED)

		#Mostrar sprite de Tin
		tin.visible = true

		#Mostrar dialogo
		var dialogue_resource = load("res://assets/ui/dialogs/tuto_tin_start.dialogue")
		var balloon = DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

		var dialogue_label = balloon.get_node("%DialogueLabel")

		#Mientras el dialogo este "hablando" se reproduce la animación de Tin talk
		#Mientras el dialogo no este "hablando" se reproduce la animación de Tin idle
		dialogue_label.started_typing.connect(func(): animated_sprite.play("talk"))
		dialogue_label.finished_typing.connect(func(): animated_sprite.play("idle"))

		"""
		Una vez el dialogo acabe, y no antes (si se guardara antes y se cerrara el juego
		o el jugador saliera al menu principal una vez el jugador vuelva a entrar a level_selector_3d
		no saltaria el dialogo y no podria verlo) se guarda como visto para que no vuelva a aparecer
		cuando el player vuelva a level selector
		(PUESTO AQUI TEMPORALMENTE, DEBUG)
		"""
		PlayerData.intro_dialogue_seen = true
		PlayerData.save_game()

		await DialogueManager.dialogue_ended

		#Escondemos a Tin
		tin.visible = false

		#El player se puede mover
		if player:
			player.set_process_mode(Node.PROCESS_MODE_INHERIT)