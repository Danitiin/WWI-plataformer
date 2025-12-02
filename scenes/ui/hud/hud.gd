extends CanvasLayer

@onready var diamond1 = $VBoxContainer/DiamondContainer/Diamond1
@onready var diamond2 = $VBoxContainer/DiamondContainer/Diamond2
@onready var diamond3 = $VBoxContainer/DiamondContainer/Diamond3
@onready var coin_label = $VBoxContainer/CoinContainer/CoinLabel
@onready var health_fill: TextureProgressBar = $HealthFill

@export var diamond_empty_texture: Texture2D
@export var diamond_filled_texture: Texture2D

var current_coins: int = 0 

func _ready():
	add_to_group("hud")
	# Esperar pa que el nivel cargue todos los nodos
	await get_tree().process_frame

	# Actualizar display
	update_diamond_display()

	# Conectar a todos los coleccionables
	connect_to_collectibles()

	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.current_health, player.max_health)

func connect_to_collectibles():
	var collectibles = get_tree().get_nodes_in_group("collectibles")

	for collectible in collectibles:
		if collectible.has_signal("collected"):
			if collectible is Coin:
				collectible.collected.connect(_on_coin_collected)
			else:
				collectible.collected.connect(_on_diamond_collected)
				
	update_diamond_display()

func _on_diamond_collected(_collectible):
	update_diamond_display()
	print("Diamante recogido! Total: ", GameManager.temp_collected_items.size())

func _on_coin_collected(_coin):
	current_coins += 1
	update_coin_display()

func update_diamond_display():
	
	if diamond1:
		diamond1.texture = diamond_filled_texture if 0 in GameManager.temp_collected_items else diamond_empty_texture
	if diamond2:
		diamond2.texture = diamond_filled_texture if 1 in GameManager.temp_collected_items else diamond_empty_texture
	if diamond3:
		diamond3.texture = diamond_filled_texture if 2 in GameManager.temp_collected_items else diamond_empty_texture

func update_coin_display():
	coin_label.text = "%02d x" % current_coins

func _on_player_health_changed(current_health: int, max_health: int):
	if health_fill:
		health_fill.max_value = max_health
		health_fill.value = current_health
