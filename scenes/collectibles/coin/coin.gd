extends Collectible
class_name Coin

func _ready():
	super._ready()

	if sprite:
		sprite.play("idle")

func collect():
	print("collect llamado")
	if has_node("CoinSound"):
		$CoinSound.play()
		await $CoinSound.finished
	super.collect()
