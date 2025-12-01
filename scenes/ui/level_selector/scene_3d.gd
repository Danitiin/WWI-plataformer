extends Node3D

@onready var tin = $Tin
@onready var animated_sprite = $Tin/AnimatedSprite2D

func _on_level_selected(level_id: int):
	GameManager.load_level(level_id)

func _ready():
	if not PlayerData.intro_dialogue_seen:
		var player = get_node("PlayerSelector3D")
		if player:
			player.set_process_mode(Node.PROCESS_MODE_DISABLED)

		tin.visible = true

		var dialogue_resource = load("res://assets/dialogues/tuto_tin_start.dialogue")
		var balloon = DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")

		var dialogue_label = balloon.get_node("%DialogueLabel")

		dialogue_label.started_typing.connect(func(): animated_sprite.play("talk"))
		dialogue_label.finished_typing.connect(func(): animated_sprite.play("idle"))

		PlayerData.intro_dialogue_seen = true
		PlayerData.save_game()

		await DialogueManager.dialogue_ended

		tin.visible = false

		if player:
			player.set_process_mode(Node.PROCESS_MODE_INHERIT)