extends Unit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flyer = true
	super()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super(delta)
