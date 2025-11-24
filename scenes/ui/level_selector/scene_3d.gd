extends Node3D

func _on_level_selected(level_id: int):
    GameManager.load_level(level_id)