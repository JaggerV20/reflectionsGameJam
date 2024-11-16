class_name Unit extends Node3D

@onready var stage_handler: Node3D = $"../.."
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var blockbench_export: Node3D = $blockbench_export
#@onready var mes

#To be set when unit is generated
var mapLength = 10
var mapWidth = 10

var travelX = 0
var travelZ = 0
var tmpX = 0
var tmpZ = 0
var xPos = 0
var zPos = 0
var unitIndex = 0
var nextIndex = 0 #Safety. Find the next index, check if it's legal
var turnCount = 12
var currentTurnCount = turnCount
var isAlive = true
var actionStack = []

var filler = false
var breaker = false
var flyer = false

var disableAction = false
var onSwitch = 0

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
func _physics_process(delta: float) -> void:
	if(!disableAction):
		
		#global_position.x = xPos
		#global_position.z = zPos
		var isMoving = false
		if (global_position.x != xPos || global_position.z != zPos):
			isMoving = true
		if (isMoving == true):
			var overshootX = abs(tmpX - xPos)
			var overshootZ = abs(tmpZ - zPos)
			if (tmpX < xPos):
				global_position.x += delta * 2
			else:
				global_position.x -= delta * 2
			travelX += delta * 2
			if (travelX > overshootX):
				print("snapped")
				global_position.x = xPos;

			if (tmpZ < zPos):
				global_position.z += delta * 2
			else:
				global_position.z -= delta * 2
			travelZ += delta * 2
			if (travelZ > overshootZ):
				print("snapped")
				global_position.z = zPos;
			
		else:
			if (blockbench_export != null and blockbench_export.get_node("AnimationPlayer").current_animation != "Idle Pose" && isAlive == true):
				blockbench_export.get_node("AnimationPlayer").stop()
				blockbench_export.get_node("AnimationPlayer").speed_scale = 1.0
				blockbench_export.get_node("AnimationPlayer").play("Idle Pose")
			travelX = 0
			travelZ = 0
			if(currentTurnCount == 0 && isAlive == true):
				isAlive = false
				print("done")
				if(blockbench_export != null):
					blockbench_export.get_node("AnimationPlayer").stop()
					blockbench_export.get_node("AnimationPlayer").speed_scale = 1.0
					blockbench_export.get_node("AnimationPlayer").play("Die")
			if(isAlive):
				if(Input.is_action_just_pressed("ui_up")):
					nextIndex -= mapWidth
					rotation_degrees.y = 90
				elif(Input.is_action_just_pressed("ui_down")):
					nextIndex += mapWidth
					rotation_degrees.y = 270
				elif(Input.is_action_just_pressed("ui_left")):
					nextIndex -= 1
					rotation_degrees.y = 180
				elif(Input.is_action_just_pressed("ui_right")):
					nextIndex += 1
					rotation_degrees.y = 0
				if(nextIndex != unitIndex):
					playerInput.emit(self)
			if((currentTurnCount != turnCount) and Input.is_action_just_pressed("reflect")):
				#I just set reflect to r
				isAlive = true
				reflect.emit(self)
			if(Input.is_action_just_pressed("ui_accept")):
				if(!isAlive):
					disableAction = true
					nextUnit.emit()
				else:
					playerInput.emit(self)

			
func _on_stage_response(allowed : bool):
	if(allowed and !disableAction):
		unitIndex = nextIndex
		#while (zPos != (unitIndex / mapWidth) + 0.5 && xPos != (unitIndex % mapLength) + 0.5):
			#zPos = lerp(zPos, (unitIndex / mapWidth) + 0.5, delta)
			#xPos = lerp(xPos, (unitIndex % mapLength) + 0.5, delta)
			#if (zPos - ((unitIndex / mapWidth) + 0.5) < 0.01 && zPos > 0):
				#zPos = (unitIndex / mapWidth) + 0.5
			#elif (zPos - ((unitIndex / mapWidth) + 0.5) > -0.01 && zPos < 0):
				#zPos = (unitIndex / mapWidth) + 0.5
			#if (xPos - ((unitIndex % mapLength) + 0.5) < 0.01 && xPos > 0):
				#xPos = (unitIndex % mapLength) + 0.5
			#elif (xPos - ((unitIndex % mapLength) + 0.5) > -0.01 && xPos < 0):
				#xPos = (unitIndex % mapLength) + 0.5
		tmpX = global_position.x
		tmpZ = global_position.z
		zPos = (unitIndex / mapWidth) + 0.5
		xPos = (unitIndex % mapLength) + 0.5
		currentTurnCount -= 1
		if(blockbench_export != null):
			blockbench_export.get_node("AnimationPlayer").stop()
			blockbench_export.get_node("AnimationPlayer").speed_scale = 2.0
			blockbench_export.get_node("AnimationPlayer").play("Walk")
	else:
		nextIndex = unitIndex
