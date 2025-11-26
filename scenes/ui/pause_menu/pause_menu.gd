extends CanvasLayer

enum Context { LEVEL, LEVEL_SELECTOR }

@onready var panel = $Panel
@onready var resume_button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button = $Panel/VBoxContainer/RestartButton
@onready var options_button = $Panel/VBoxContainer/OptionsButton
@onready var main_menu_button = $Panel/VBoxContainer/MainMenuButton

var current_context: Context = Context.LEVEL

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()

	#en que entorno esta el player
	detect_context()

	#enseñar unos botones u otros segun si el player esta en un nivel o en el mapa
	configure_buttons()

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func detect_context():
	if GameManager.current_level == -1:
		var scene_name = get_tree().current_scene.name
		if scene_name == "LevelSelector":
			current_context = Context.LEVEL_SELECTOR
		else:
			current_context = Context.LEVEL
	else:
		current_context = Context.LEVEL

func configure_buttons():
	match current_context:
		Context.LEVEL:
			restart_button.visible = true
			options_button.visible = false
		Context.LEVEL_SELECTOR:
			restart_button.visible = false
			options_button.visible = true

func _input(event):
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

	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)
		GameManager.checkpoint_collected_items.erase(GameManager.current_level)
		GameManager.temp_collected_items.clear()

	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_options_pressed():
	var options_scene = load("res://scenes/ui/pause_menu/options_menu/options_menu.tscn")
	var options_instance = options_scene.instantiate()
	get_tree().root.add_child(options_instance)
	options_instance.options_closed.connect(_on_options_closed)
	set_process_input(false)
	hide()

func _on_options_closed():
	set_process_input(true)
	show()

func _on_main_menu_pressed():
	#Borrar checkpoint del nivel actual al salir sin completar
	if GameManager.current_level >= 0:
		GameManager.level_checkpoints.erase(GameManager.current_level)
		GameManager.checkpoint_collected_items.erase(GameManager.current_level)
		GameManager.temp_collected_items.clear()

	get_tree().paused = false
	GameManager.return_to_main_menu()