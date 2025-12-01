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
	if level_label:
		level_label.text = "Nivel %d" % (level_id + 1)

func update_level_status():
	var check = $Checkmark

	if check:
		check.visible = PlayerData.is_level_completed(level_id)

	var collected = PlayerData.get_collected_items_for_level(level_id)

	print("PORTAL_SIGN UPDATE")
	print("Nivel: ", level_id)
	print("Coleccionables recogidos: ", collected)

	var diamond1_collected = 0 in collected
	var diamond2_collected = 1 in collected
	var diamond3_collected = 2 in collected

	#Mostrar filled y ocultar empty cuando esta recogido pa no terner problemas de superposicion

	$DiamondsFilled/Diamond1Filled.visible = diamond1_collected
	$DiamondsEmptys/Diamond1Empty.visible = not diamond1_collected

	$DiamondsFilled/Diamond2Filled.visible = diamond2_collected
	$DiamondsEmptys/Diamond2Empty.visible = not diamond2_collected

	$DiamondsFilled/Diamond3Filled.visible = diamond3_collected
	$DiamondsEmptys/Diamond3Empty.visible = not diamond3_collected

	print("Diamond1 filled: ", diamond1_collected, " | empty: ", not diamond1_collected)
	print("Diamond2 filled: ", diamond2_collected, " | empty: ", not diamond2_collected)
	print("Diamond3 filled: ", diamond3_collected, " | empty: ", not diamond3_collected)
