extends Node3D

@onready var selection_label_1: Label = $Control/SelectionLabel1
@onready var selection_label_2: Label = $Control/SelectionLabel2

@onready var selection_highlight_1: MeshInstance3D = $SelectionBox1/MeshInstance3D/SelectionHighlight1
@onready var selection_highlight_2: MeshInstance3D = $SelectionBox2/MeshInstance3D/SelectionHighlight2

var possibleUnits = ["Filler", "Breaker"]
var unitArray = ["Temp", "Temp"]
var highlightArray

var cursorIndex = 0
var prevCursorIndex = 0
var indexChange = 0

var unitIndex = 0

var simultaneous_scene = preload("res://Scenes/JTestScene.tscn").instantiate()
signal sendUnits
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	selection_label_1.text = ""
	selection_label_2.text = ""
	highlightArray = [selection_highlight_1, selection_highlight_2]
	highlightArray[cursorIndex].visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(unitIndex > unitArray.size() - 1):
		sendUnits.emit(unitArray)
		simultaneous_scene.change_scene_to_file()
	if(Input.is_action_just_pressed("ui_right")):
		indexChange = 1
	elif(Input.is_action_just_pressed("ui_left")):
		indexChange = -1
	if(indexChange != 0):
		prevCursorIndex = cursorIndex
		cursorIndex += indexChange
		if(cursorIndex < 0):
			cursorIndex = highlightArray.size() - 1
		elif(cursorIndex > highlightArray.size() - 1):
			cursorIndex = 0
		highlightArray[cursorIndex].visible = true
		highlightArray[prevCursorIndex].visible = false
		indexChange = 0
	if(Input.is_action_just_pressed("ui_accept")):
		unitArray[unitIndex] = possibleUnits[cursorIndex]
		unitIndex += 1
		
