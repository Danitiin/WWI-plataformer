extends CanvasLayer

#Distingue si se abrio en un nivel o en level selector
enum Context { LEVEL, LEVEL_SELECTOR }

@onready var panel = $Panel
@onready var resume_button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var options_button = $Panel/VBoxContainer/OptionsButton
@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton

var current_context: Context = Context.LEVEL

func _ready():
	#Pasue menu sigue procesandose aunque se congele el juego
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	#En que entorno esta el player
	detect_context()

	#Enseñar unos botones u otros segun si el player esta en un nivel o en el mapa
	configure_buttons()

	#Conecta las señales para saber cuando se pulsan los botones
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func detect_context():
	#Si no estas en un nivel
	if GameManager.current_level == -1:
		var scene_name = get_tree().current_scene.name
		if scene_name == "LevelSelector":
			#Esta en level selector
			current_context = Context.LEVEL_SELECTOR
		else:
			#Esta en un nivel
			current_context = Context.LEVEL
	else:
		current_context = Context.LEVEL

func configure_buttons():
	#Depende de donde este muestra unos botones u otros
	match current_context:
		Context.LEVEL:
			restart_button.visible = true
			options_button.visible = false
		Context.LEVEL_SELECTOR:
			restart_button.visible = false
			options_button.visible = true

func _input(event):
	#Si se presiona "ui_cancel"(ESC) pausa o despausa
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()

func pause_game():
	get_tree().paused = true
	show()
	resume_button.grab_focus()

func resume_game():
	get_tree().paused = false
	hide()

func _on_resume_pressed():
	resume_game()

func _on_restart_pressed():
	#Cuando se reinicia un nivel, si hay un checkpoint activado este se borra

	#Quitar habilidades
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("clear_temp_abilities"):
		player.clear_temp_abilities()

	#Borra el checkpoint guardado del nivel actual
	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)
		GameManager.checkpoint_collected_items.erase(GameManager.current_level)
		GameManager.checkpoint_unlocked_abilities.erase(GameManager.current_level)
		GameManager.temp_collected_items.clear()

	#Recarga la escena
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_options_pressed():
	#Carga e instancia el menu de opciones
	var options_scene = load("res://scenes/ui/pause_menu/options_menu/options_menu.tscn")
	var options_instance = options_scene.instantiate()
	#Conecta la señal para poder cerrar las opciones
	#Y evita que ESC cierre pause menu mientras esta en opciones
	get_tree().root.add_child(options_instance)
	options_instance.options_closed.connect(_on_options_closed)
	set_process_input(false)
	hide()

func _on_options_closed():
	set_process_input(true)
	show()

func _on_main_menu_pressed():
	#Quitar habilidades
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("clear_temp_abilities"):
		player.clear_temp_abilities()

	#Borrar checkpoint del nivel actual al salir sin completar
	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)
		GameManager.checkpoint_collected_items.erase(GameManager.current_level)
		GameManager.checkpoint_unlocked_abilities.erase(GameManager.current_level)
		GameManager.temp_collected_items.clear()

	get_tree().paused = false
	GameManager.return_to_main_menu()