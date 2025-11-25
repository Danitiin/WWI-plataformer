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

	$DiamondsFilled/Diamond1Filled.visible = collected.size() >= 1
	$DiamondsFilled/Diamond2Filled.visible = collected.size() >= 2
	$DiamondsFilled/Diamond3Filled.visible = collected.size() >= 3