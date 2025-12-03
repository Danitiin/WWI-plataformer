extends Resource
class_name LevelData

#Informacion relevante del nivel
@export var level_id: int
@export var level_name: String
@export var scene_path: String
@export var abilities_in_level: Array[String] = []
@export_multiline var description: String = ""