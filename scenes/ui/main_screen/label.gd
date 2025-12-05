extends Label

var time: float = 0.0

func _process(delta):
    time += delta
    modulate.a = abs(sin(time * 3))