extends Control

func _ready():
	$VBoxContainer/PlayButton.pressed.connect(_on_play_button_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_button_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/level_selector/scene_3d.tscn")

func _on_options_button_pressed():
	var options_scene = load("res://scenes/ui/pause_menu/options_menu/options_menu.tscn")
	var options_instance = options_scene.instantiate()
	get_tree().root.add_child(options_instance)
	options_instance.options_closed.connect(_on_options_closed)

func _on_options_closed():
	pass

func _on_test_level_button_pressed():
	GameManager.load_level(-1)

func _on_quit_button_pressed():
	get_tree().quit()
