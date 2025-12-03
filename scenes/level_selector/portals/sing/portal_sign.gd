extends Node3D

@export var level_id: int = -1
@onready var level_label: Label3D = $LevelLabel

func _ready():
	if level_id == -1:
		var parent = get_parent()
		if parent and "level_id" in parent:
			level_id = parent.level_id
			
	update_level_label()
	update_level_status()

func update_level_label():
	#Segun el id del portal se cambia el numero de la etiqueta
	if level_label:
		level_label.text = "Nivel %d" % (level_id + 1)

func update_level_status():
	var check = $Checkmark

	#Nivel completado, se muestra el icono check
	if check:
		check.visible = PlayerData.is_level_completed(level_id)

	#Coleccionables que se han recogido en el nivel
	var collected = PlayerData.get_collected_items_for_level(level_id)

	#verificar cuales se han recogido
	var diamond1_collected: bool = 0 in collected
	var diamond2_collected: bool = 1 in collected
	var diamond3_collected: bool = 2 in collected

	#Segun si los coleccionables estan recogidos o no, se muestran o se ocultan

	$DiamondsFilled/Diamond1Filled.visible = diamond1_collected
	$DiamondsEmptys/Diamond1Empty.visible = not diamond1_collected

	$DiamondsFilled/Diamond2Filled.visible = diamond2_collected
	$DiamondsEmptys/Diamond2Empty.visible = not diamond2_collected

	$DiamondsFilled/Diamond3Filled.visible = diamond3_collected
	$DiamondsEmptys/Diamond3Empty.visible = not diamond3_collected
