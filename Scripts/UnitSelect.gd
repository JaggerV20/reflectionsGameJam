extends Node3D

@onready var stage_handler: Node3D = $"../StageHandler"
@onready var selection_highlight_1: MeshInstance3D = $SelectionBox1/MeshInstance3D/SelectionHighlight1
@onready var selection_highlight_2: MeshInstance3D = $SelectionBox2/MeshInstance3D/SelectionHighlight2
@onready var selection_highlight_3: MeshInstance3D = $SelectionBox3/MeshInstance3D/SelectionHighlight3
@onready var control: Control = $Control
@onready var background: MeshInstance3D = $Background

var possibleUnits = ["Filler", "Breaker", "Flyer"]
var highlightArray

var cursorIndex = null
var prevCursorIndex = 0
var indexChange = 0

var unitIndex = 0

var disableAction = false

signal unitSelected
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	stage_handler.toggleSelection.connect(_on_toggle_selection)
	highlightArray = [selection_highlight_1, selection_highlight_2, selection_highlight_3]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(!disableAction):
		if(Input.is_action_just_pressed("ui_right")):
			if(cursorIndex == null):
				cursorIndex = -1
			indexChange = 1
		elif(Input.is_action_just_pressed("ui_left")):
			if(cursorIndex == null):
				cursorIndex = highlightArray.size()
			indexChange = -1
		if(indexChange != 0):
			prevCursorIndex = cursorIndex
			cursorIndex += indexChange
			if(cursorIndex < 0):
				cursorIndex = highlightArray.size() - 1
			elif(cursorIndex > highlightArray.size() - 1):
				cursorIndex = 0
			highlightArray[cursorIndex].visible = true
			if(prevCursorIndex > -1 and prevCursorIndex < highlightArray.size()):
				highlightArray[prevCursorIndex].visible = false
			indexChange = 0
		if(Input.is_action_just_pressed("ui_accept") and cursorIndex != null):
			unitSelected.emit(cursorIndex)
			disableAction = true
			control.visible = false
			visible = false
		
func _on_toggle_selection():
	visible = true
	control.visible = true
	disableAction = false
	cursorIndex = null
	for highlight in highlightArray:
		highlight.visible = false
		
