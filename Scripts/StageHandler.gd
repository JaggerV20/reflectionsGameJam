extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var unit_holder: Node3D = $UnitHolder

var mapLength = 10
var mapWidth = 10
var charMap =  ["-","-","-","-","-","-","-","G","-","-",
				"|",".","l",".","_",".",".","L",".","|",
				"|",".",".",".","_",".",".",".",".","|",
				"|",".",".",".","_",".",".",".",".","|",
				"|","_","_","_","_","X","X","X","X","|",
				"|",".",".",".",".",".",".",".",".","|",
				"|",".",".",".",".",".",".",".",".","|",
				"|",".",".",".",".",".",".",".",".","|",
				"|",".","S",".",".",".",".",".",".","|",
				"-","-","-","-","-","-","-","-","-","-"]
				
var stageMap = []
var startIndex = 0
var goalIndex = 0

var defaultTileDict = {
	"Type" : "Walkable",
	"Walkable" : true,
	"Fillable" : false,
	"Breakable" : false,
	"Start" : false,
	"Goal" : false,
	"Unit" : null,
	"Corpse" : null
}

var setNextUnit = false
var sentUnits = []
var currentUnit = 0
var unitNodes = []
#Needs to be set whenever the player moves to the next unit
var actionStack = []
#Stage handler checks if the player input is valid. It will change the map if needed, then allow player movement
signal authorizeInput

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Stage Handler Ready")
	
	stageMap.resize(mapLength * mapWidth)
	var index = 0
	for i in charMap:
		var zPos = index / mapWidth
		var xPos = index % mapLength
		match charMap[index]:
			".":#Walkable
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),0)
				stageMap[index] = defaultTileDict.duplicate()
			"-":#Wall
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),3)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Wall"
				stageMap[index]["Walkable"] = false
			"|":#Wall
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),3)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Wall"
				stageMap[index]["Walkable"] = false
			"_":#Fillable
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),1)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Fillable"
				stageMap[index]["Walkable"] = false
				stageMap[index]["Fillable"] = true
			"l":#Switch
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),6)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Switch"
				var lockIndex = 0
				var found = false
				while(!found and lockIndex < mapLength * mapWidth):
					if(charMap[lockIndex] == "L"):
						found = true
						stageMap[index]["Unlocks"] = lockIndex
					lockIndex += 1
				if(!found):
					print("Error. switch doesn't have respective lock")
			"L":#Lock. Need to come up with some pairing method. Maybe just more cases for simplicity
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),7)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Lock"
			"X":#Breakable
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),2)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Fillable"
				stageMap[index]["Walkable"] = false
			"S":#Start
				startIndex = index
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),4)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Start"
			"G":#Goal
				goalIndex = index
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),5)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Goal"
		index += 1
	unitNodes = unit_holder.get_children()
	setNextUnit = true
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if(setNextUnit):
		print("set script")
		unitNodes[currentUnit].set_script(load("res://Scripts/Unit.gd"))
		unitNodes[currentUnit].unitIndex = startIndex
		unitNodes[currentUnit].nextIndex = startIndex
		unitNodes[currentUnit].zPos = (startIndex / mapWidth) + 0.5
		unitNodes[currentUnit].xPos = (startIndex % mapLength) + 0.5
		unitNodes[currentUnit].playerInput.connect(_on_player_input)
		unitNodes[currentUnit].reflect.connect(_on_player_reflect)
		unitNodes[currentUnit].nextUnit.connect(_on_next_unit)
		actionStack.resize(unitNodes[currentUnit].turnCount)
		setNextUnit = false
		
func _on_units_sent(arr : Array):
	sentUnits = arr
	setNextUnit = true
#This method will check if an action is legal, like if the player can walk on the tile
#It also needs to handle tile changes, such as filling or breaking tiles.
#This is how I'll store the action stack for reflects
func _on_player_input(unit : Node3D):
	var wantedTile = stageMap[unit.nextIndex]
	#Simple movement test
	if(wantedTile["Walkable"]):
		actionStack[unit.currentTurnCount - 1] = unit.unitIndex
	authorizeInput.emit(wantedTile["Walkable"])
	
func _on_player_reflect(unit : Node3D):
	for action in actionStack:
		if(action != null):
			unit.unitIndex = action
	unit.nextIndex = unit.unitIndex
	unit.zPos = (unit.unitIndex / mapWidth) + 0.5
	unit.xPos = (unit.unitIndex % mapLength) + 0.5
	unit.currentTurnCount = actionStack.size()

func _on_next_unit():
	pass
