extends CanvasLayer
@onready var colorRect = $ColorRect
@onready var animationPlayer = $AnimationPlayer
func _ready() -> void:
	colorRect.visible = false
func reflectTransition():
	var image = get_viewport().get_texture().get_image()
	var texture = ImageTexture.create_from_image(image)
	$TransitionSprite.texture = texture
	animationPlayer.play("ReflectTransition")
	await animationPlayer.animation_finished
