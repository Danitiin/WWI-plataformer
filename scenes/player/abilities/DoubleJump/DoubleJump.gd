extends AbilityBase

@export var double_jump_velocity: float = -350.0
var has_double_jumped: bool = false

func physics_update(_delta: float) -> bool:
	#Si el player esta en el suelo no puede hacer doublejump
	if player.is_on_floor():
		has_double_jumped = false

	return false

func activate():
	#Si el player no esta en el suelo y no hizo doublejump y puede hacer doublejump
	if not player.is_on_floor() and not has_double_jumped and can_double_jump():
		#El player salta
		player.velocity.y = double_jump_velocity
		has_double_jumped = true

		if player.has_node("JumpSound"):
			player.get_node("JumpSound").play()

func can_double_jump() -> bool:
	#Si el player esta haciendo un spin, no puede hacer doublejump
	if player.is_spinning:
		return false

	return true
