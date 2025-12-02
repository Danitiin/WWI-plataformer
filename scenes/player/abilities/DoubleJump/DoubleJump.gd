extends AbilityBase

@export var double_jump_velocity: float = -350.0
var has_double_jumped: bool = false

func physics_update(_delta: float) -> bool:
	if player.is_on_floor():
		has_double_jumped = false

	return false

func activate():
	if not player.is_on_floor() and not has_double_jumped and can_double_jump():
		player.velocity.y = double_jump_velocity
		has_double_jumped = true

		if player.has_node("JumpSound"):
			player.get_node("JumpSound").play()
		# efecto visual o particulas abajo

func can_double_jump() -> bool:
	if player.is_spinning:
		return false

	return true
