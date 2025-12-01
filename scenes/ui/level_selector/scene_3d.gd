extends Node3D

func _on_level_selected(level_id: int):
	GameManager.load_level(level_id)

func _ready():
	#Ver si es la primera vez que se juega
	if not PlayerData.intro_dialogue_seen:

		var player = get_node("PlayerSelector3D")
		if player:
			player.set_process_mode(Node.PROCESS_MODE_DISABLED)

		show_intro_dialogue()
		PlayerData.intro_dialogue_seen = true
		PlayerData.save_game()
		#Esperar a que termine el dialog
		await DialogueManager.dialogue_ended
        
		if player:
			player.set_process_mode(Node.PROCESS_MODE_INHERIT)

func show_intro_dialogue():
	var dialogue_resource = load("res://assets/dialogues/tuto_tin_start.dialogue")
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")