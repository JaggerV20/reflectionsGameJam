extends Node2D

@onready var selection_highlight_1: MeshInstance3D = $SelectionBox1/MeshInstance3D/SelectionHighlight1
@onready var selection_highlight_2: MeshInstance3D = $SelectionBox2/MeshInstance3D/SelectionHighlight2
@onready var selection_highlight_3: MeshInstance3D = $SelectionBox3/MeshInstance3D/SelectionHighlight3

@onready var highlight_one: MeshInstance2D = $HighlightLayer/HighlightOne
@onready var highlight_two: MeshInstance2D = $HighlightLayer/HighlightTwo
@onready var highlight_three: MeshInstance2D = $HighlightLayer/HighlightThree
@onready var highlight_four: MeshInstance2D = $HighlightLayer/HighlightFour

const STAGE_ONE = "res://Scenes/StageOne.tscn"
const STAGE_TWO = "res://Scenes/StageTwo.tscn"
const STAGE_THREE = "res://Scenes/StageThree.tscn"
const STAGE_FOUR = "res://Scenes/StageFour.tscn"

@onready var control: Control = $Control
@onready var background: MeshInstance3D = $Background

var possibleStages = []

var highlightArray

var cursorIndex = null
var prevCursorIndex = 0
var indexChange = 0

var unitIndex = 0

var disableAction = false

signal unitSelected
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	possibleStages = [STAGE_ONE, STAGE_TWO, STAGE_THREE, STAGE_FOUR]
	highlightArray = [highlight_one, highlight_two, highlight_three, highlight_four]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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
		get_tree().call_deferred("change_scene_to_file", possibleStages[cursorIndex])
		

		
