extends CanvasLayer


@onready var colorRect = $ColorRect
@onready var animationPlayer = $AnimationPlayer
func _ready() -> void:
	colorRect.visible = false
	#$RedLine.visible = false
	#$BlueLine.visible = false
	#$GreenLine.visible = false
	#$GreenLine2.visible = false

func loadSceneFade(targetScene: String):
	animationPlayer.play("FadeTransition")
	await animationPlayer.animation_finished
	get_tree().change_scene_to_file(targetScene)
	animationPlayer.play_backwards("FadeTransition")


func loadSceneSplit(targetScene: String, image: Sprite2D):
	animationPlayer.play("SplitTransitionStart")
	await animationPlayer.animation_changed
	get_tree().change_scene_to_file(targetScene)
	animationPlayer.play("SplitTransitionEnd")
