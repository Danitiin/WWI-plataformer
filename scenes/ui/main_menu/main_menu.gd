extends Control

@onready var play_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/PlayButton
@onready var options_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/OptionsButton
@onready var quit_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/QuitButton

const SETTINGS_PATH = "user://settings.cfg"

func _ready():
	play_button.pressed.connect(_on_play_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	play_button.grab_focus()

func _on_play_button_pressed():
	#Ver si ess la primera vez que se juehga
	if not has_seen_intro_dialogue():
		show_intro_dialogue()
		mark_intro_as_seen()
		#Esperar a que termine el dialog
		await DialogueManager.dialogue_ended

	get_tree().change_scene_to_file("res://scenes/ui/level_selector/scene_3d.tscn")

func has_seen_intro_dialogue() -> bool:
	var config = ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	return config.get_value("game", "intro_seen", false)

func mark_intro_as_seen():
	var config = ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)
	config.set_value("game", "intro_seen", true)
	config.save(SETTINGS_PATH)

func show_intro_dialogue():
	var dialogue_resource = load("res://assets/dialogues/tuto_tin_start.dialogue")
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

func _on_options_button_pressed():
	var options_scene = load("res://scenes/ui/pause_menu/options_menu/options_menu.tscn")
	var options_instance = options_scene.instantiate()
	get_tree().root.add_child(options_instance)
	options_instance.options_closed.connect(_on_options_closed)

	# Ocultar el main menu mientras opciones está abierto
	hide()

func _on_options_closed():
	# Mostrar el main menu cuando se cierra opciones
	show()
	play_button.grab_focus()

func _on_test_level_button_pressed():
	GameManager.load_level(-1)

func _on_quit_button_pressed():
	get_tree().quit()
