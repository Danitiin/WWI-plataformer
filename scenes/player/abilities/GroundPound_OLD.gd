extends AbilityBase

@export var pound_speed: float = 800.0
@export var cooldown: float = 0.5

var cooldown_timer: float = 0.0
var is_pounding: bool = false

func physics_update(delta: float) -> bool:
	if cooldown_timer > 0:
		cooldown_timer -= delta

	if is_pounding:
		player.velocity.x = 0
		player.velocity.y = pound_speed

		if player.is_on_floor():
			is_pounding = false
			cooldown_timer = cooldown
			return false

		return true

	return false

func activate():
	if cooldown_timer <= 0 and not player.is_on_floor():
		is_pounding = true