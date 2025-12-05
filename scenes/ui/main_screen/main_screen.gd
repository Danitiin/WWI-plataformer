extends CanvasLayer

func _ready():
      pass

func _process(_delta):
    if Input.is_action_just_pressed("ui_accept"):
        get_tree().change_scene_to_file("res://scenes/ui/main_menu/main_menu.tscn")