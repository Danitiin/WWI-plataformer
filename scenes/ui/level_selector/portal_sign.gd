extends Node3D

@export var level_id: int = -1
@onready var level_label: Label3D = $LevelLabel

func _ready():
	if level_id == -1:
		var parent = get_parent()
		if parent and "level_id" in parent:
			level_id = parent.level_id

	update_level_label()

func update_level_label():
	if level_label:
		#Sumamos 1 porque el id de los niveles empieza en 0
		level_label.text = "Nivel %d" % (level_id + 1)
