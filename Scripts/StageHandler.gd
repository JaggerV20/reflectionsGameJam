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
#Possibly not necessary
var unitsArray = []
#Needs to be set whenever the player moves to the next unit
var actionStack = []
#Stage handler checks if the player input is valid. It will change the map if needed, then allow player movement
signal authorizeInput

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	var units = unit_holder.get_children()
	unitsArray.resize(units.size())
	var unitArrayIndex = 0
	for unit in units:
		if(unitArrayIndex == 0):
			actionStack.resize(unit.turnCount)
		unitsArray[unitArrayIndex] = unit
		unit.mapWidth = mapWidth
		unit.mapLength = mapLength
		unit.unitIndex = startIndex
		unit.nextIndex = startIndex
		unit.zPos = (startIndex / mapWidth) + 0.5
		unit.xPos = (startIndex % mapLength) + 0.5
		unit.playerInput.connect(_on_player_input)
		unit.reflect.connect(_on_player_reflect)
		unit.nextUnit.connect(_on_next_unit)
		#Attach scripts once I write them
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
#This method will check if an action is legal, like if the player can walk on the tile
#It also needs to handle tile changes, such as filling or breaking tiles.
#This is how I'll store the action stack for reflects
func _on_player_input(unit : Node3D):
	var wantedTile = stageMap[unit.nextIndex]
	#Simple movement test
	if(wantedTile["Walkable"]):
		actionStack[unit.turnCount - 1] = unit.unitIndex
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
