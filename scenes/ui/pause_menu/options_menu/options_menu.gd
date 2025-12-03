extends CanvasLayer

signal options_closed

@onready var master_volume_slider = $Panel/MarginContainer/VBoxContainer/MasterVolumeContainer/SliderContainer/MasterVolumeSlider
@onready var music_volume_slider = $Panel/MarginContainer/VBoxContainer/MusicVolumeContainer/SliderContainer/MusicVolumeSlider
@onready var sfx_volume_slider = $Panel/MarginContainer/VBoxContainer/SFXVolumeContainer/SliderContainer/SFXVolumeSlider
@onready var fullscreen_checkbox = $Panel/MarginContainer/VBoxContainer/FullscreenContainer/FullscreenCheckBox
@onready var back_button = $Panel/MarginContainer/VBoxContainer/BackButton

@onready var master_value_label = $Panel/MarginContainer/VBoxContainer/MasterVolumeContainer/SliderContainer/MasterVolumeLabel
@onready var music_value_label = $Panel/MarginContainer/VBoxContainer/MusicVolumeContainer/SliderContainer/MusicVolumeLabel
@onready var sfx_value_label = $Panel/MarginContainer/VBoxContainer/SFXVolumeContainer/SliderContainer/SFXVolumeLabel

const SETTINGS_PATH = "user://settings.cfg"

func _ready():
	#Conecta las señales para saber los cambios en el menu de opciones
	master_volume_slider.value_changed.connect(_on_volume_changed)
	music_volume_slider.value_changed.connect(_on_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_setting_changed)
	back_button.pressed.connect(_on_back_pressed)

	load_settings()

func load_settings():
	#Crea un archivo de configuracion
	var config = ConfigFile.new()

	#Si el archivo existe, lo carga
	if FileAccess.file_exists(SETTINGS_PATH):
		config.load(SETTINGS_PATH)

	#Guarda las configuraciones por defecto
	master_volume_slider.value = config.get_value("audio", "master_volume", 0.8)
	music_volume_slider.value = config.get_value("audio", "music_volume", 0.7)
	sfx_volume_slider.value = config.get_value("audio", "sfx_volume", 0.8)
	fullscreen_checkbox.button_pressed = config.get_value("video", "fullscreen", false)

	_apply_settings()

func save_settings():
	#Guarda los valores actuales en el archivo de configuración
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume_slider.value)
	config.set_value("audio", "music_volume", music_volume_slider.value)
	config.set_value("audio", "sfx_volume", sfx_volume_slider.value)
	config.set_value("video", "fullscreen", fullscreen_checkbox.button_pressed)
	config.save(SETTINGS_PATH)

func _apply_settings():
	#Audio
	#Convierte valores lineales a decibelios segun el slider en el bus master volume
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume_slider.value))

	#Coge el bus Music
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
	#Convierte valores lineales a decibelios segun el slider en el bus Music
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume_slider.value))

	#Coge el bus SFX
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
	#Convierte valores lineales a decibelios segun el slider en el bus SFX
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume_slider.value))

	# Video
	DisplayServer.window_set_mode(
		#Cambia entre ventana y pantalla completa
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_checkbox.button_pressed
		else DisplayServer.WINDOW_MODE_WINDOWED
	)

	# Etiquetas
	# Segun la posicion del slider (0.8 por ejemplo) la convierte a valor de porcentaje
	master_value_label.text = "%d%%" % int(master_volume_slider.value * 100)
	music_value_label.text = "%d%%" % int(music_volume_slider.value * 100)
	sfx_value_label.text = "%d%%" % int(sfx_volume_slider.value * 100)

#Cuando se mueve un slider lo actualiza
func _on_volume_changed(_value: float):
	_apply_settings()
	save_settings()

#Cuando se cambia de modo de pantalla lo actualiza
func _on_setting_changed(_toggled: bool):
	_apply_settings()
	save_settings()

#Se quita el menu de opciones
func _on_back_pressed():
	options_closed.emit()
	queue_free()
