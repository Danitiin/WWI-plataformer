extends Collectible
class_name Coin

func _ready():
	super._ready()

	if sprite:
		sprite.play("idle")

"""
Funcion para reproducir sonido cada vez que se recoge una moneda
no se puede hacer en collectible base porque big coin tambien lo usa
y sonaria al recoger una bigcoin
"""
func collect():
	if has_node("CoinSound"):
		$CoinSound.play()
	super.collect()
