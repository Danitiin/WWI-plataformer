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
	#Si hay player
	if player:
		#conecta la vida del player para saber cuando cambia
		player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.current_health, player.max_health)

func connect_to_collectibles():
	#Conecta las señales de todos los coleccionables del nivel (diamantes)
	var collectibles = get_tree().get_nodes_in_group("collectibles")

	for collectible in collectibles:
		#Si el coleccionable tiene señal de recogido
		if collectible.has_signal("collected"):
			# Si es una moneda
			if collectible is Coin:
				collectible.collected.connect(_on_coin_collected)
			else:
				collectible.collected.connect(_on_diamond_collected)
				
	update_diamond_display()

#Suma una moneda al contador y las actualiza
func _on_coin_collected(_coin):
	current_coins += 1
	update_coin_display()

#Actualiza los diamantes
func _on_diamond_collected(_collectible):
	update_diamond_display()

func update_diamond_display():
	#Actualiza los sprites de los diamantes
	
	if diamond1:
		diamond1.texture = diamond_filled_texture if 0 in GameManager.temp_collected_items else diamond_empty_texture
	if diamond2:
		diamond2.texture = diamond_filled_texture if 1 in GameManager.temp_collected_items else diamond_empty_texture
	if diamond3:
		diamond3.texture = diamond_filled_texture if 2 in GameManager.temp_collected_items else diamond_empty_texture

func update_coin_display():
	#Actualiza el texto del contador de monedas
	coin_label.text = "%02d x" % current_coins

#Cuando la vida del player cambia, actualiza la barra
func _on_player_health_changed(current_health: int, max_health: int):
	if health_fill:
		health_fill.max_value = max_health
		health_fill.value = current_health
