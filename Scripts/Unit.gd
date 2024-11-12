class_name Unit extends Node3D

@onready var stage_handler: Node3D = $"../.."
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

#To be set when unit is generated
var mapLength = 10
var mapWidth = 10

var xPos = 0
var zPos = 0
var unitIndex = 0
var nextIndex = 0 #Safety. Find the next index, check if it's legal
var turnCount = 12
var currentTurnCount = turnCount
var canReflect = true
var isAlive = true
var actionStack = []

var filler = false
var breaker = false

var disabled = false

#"Propose" movement to the stage handler. Send unit identifier. Stage handler will check if nextIndex is valid
signal playerInput
signal reflect
signal nextUnit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stage_handler.authorizeInput.connect(_on_stage_response)
	actionStack.resize(turnCount)
	global_position.y = 1.05


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!disabled):
		global_position.x = xPos
		global_position.z = zPos
		if(currentTurnCount == 0):
			isAlive = false
		if(isAlive):
			if(Input.is_action_just_pressed("ui_up")):
				nextIndex -= mapWidth
			elif(Input.is_action_just_pressed("ui_down")):
				nextIndex += mapWidth
			elif(Input.is_action_just_pressed("ui_left")):
				nextIndex -= 1
			elif(Input.is_action_just_pressed("ui_right")):
				nextIndex += 1
			if(nextIndex != unitIndex):
				playerInput.emit(self)
		if(canReflect and (currentTurnCount != turnCount) and Input.is_action_just_pressed("reflect")):
			#I just set reflect to r
			canReflect = false
			isAlive = true
			reflect.emit(self)
		if(Input.is_action_just_pressed("ui_accept")):
			print("Wait")
			playerInput.emit(self)
			if(!isAlive):
				disabled = true
				print("emit nextUnit")
				nextUnit.emit()
			
func _on_stage_response(allowed : bool):
	if(allowed and !disabled):
		unitIndex = nextIndex
		zPos = (unitIndex / mapWidth) + 0.5
		xPos = (unitIndex % mapLength) + 0.5
		currentTurnCount -= 1
	else:
		nextIndex = unitIndex
