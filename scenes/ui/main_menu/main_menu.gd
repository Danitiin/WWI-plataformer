extends Control

@onready var play_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/PlayButton
@onready var options_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/OptionsButton
@onready var quit_button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ButtonsContainer/QuitButton

func _ready():
	#Conecta señales para saber cuando se pulsa cada boton
	play_button.pressed.connect(_on_play_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	#Se remarca el boton play
	play_button.grab_focus()

func _on_play_button_pressed():
	#Si pulsas play te lleva a level_selector_3d
	get_tree().change_scene_to_file("res://scenes/level_selector/level_selector_3d.tscn")

func _on_options_button_pressed():
	#Carga la escena de opciones y la instancia
	var options_scene = load("res://scenes/ui/pause_menu/options_menu/options_menu.tscn")
	var options_instance = options_scene.instantiate()
	#Se agrega como hijo y se conecta para saber si se cierra
	get_tree().root.add_child(options_instance)
	options_instance.options_closed.connect(_on_options_closed)

	# Ocultar el main menu mientras opciones está abierto
	hide()

func _on_options_closed():
	# Mostrar el main menu cuando se cierra opciones
	show()
	play_button.grab_focus()

func _on_quit_button_pressed():
	#Sale del juego
	get_tree().quit()