extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var unit_holder: Node3D = $UnitHolder

const FILLER_UNIT = preload("res://Scenes/FillerUnit.tscn")
const BREAKER_UNIT = preload("res://Scenes/BreakerUnit.tscn")

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
	"Loc" : Vector3i(0,0,0),
	"Walkable" : true,
	"Fillable" : false,
	"Breakable" : false,
	"Start" : false,
	"Goal" : false,
	"Unit" : null,
	"Corpse" : null
}

var setNextUnit = false
var availableUnits = ["Filler", "Breaker"]
var currentUnit = 0
var unitNodes = []
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
				stageMap[index]["Loc"] = Vector3i(xPos,0,zPos)
			"-":#Wall
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),3)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Wall"
				stageMap[index]["Walkable"] = false
				stageMap[index]["Loc"] = Vector3i(xPos,1,zPos)
			"|":#Wall
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),3)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Wall"
				stageMap[index]["Walkable"] = false
				stageMap[index]["Loc"] = Vector3i(xPos,1,zPos)
			"_":#Fillable
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),1)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Fillable"
				stageMap[index]["Walkable"] = false
				stageMap[index]["Fillable"] = true
				stageMap[index]["Loc"] = Vector3i(xPos,0,zPos)
			"l":#Switch
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),6)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Switch"
				stageMap[index]["Loc"] = Vector3i(xPos,0,zPos)
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
				stageMap[index]["Loc"] = Vector3i(xPos,1,zPos)
				stageMap[index]["Type"] = "Lock"
			"X":#Breakable
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),2)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Breakable"
				stageMap[index]["Walkable"] = false
				stageMap[index]["Breakable"] = true
				stageMap[index]["Loc"] = Vector3i(xPos,1,zPos)
			"S":#Start
				startIndex = index
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),4)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Start"
				stageMap[index]["Loc"] = Vector3i(xPos,0,zPos)
			"G":#Goal
				goalIndex = index
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),5)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Goal"
				stageMap[index]["Loc"] = Vector3i(xPos,0,zPos)
		index += 1
	var unitIndex = 0
	for unit in availableUnits:
		match unit:
			"Filler":
				unit_holder.add_child(FILLER_UNIT.instantiate())
			"Breaker":
				unit_holder.add_child(BREAKER_UNIT.instantiate())
				
	unitNodes = unit_holder.get_children()
	for unit in unitNodes:
		if(unitIndex > 0):
			unit.disabled = true
			unit.visible = false
		unit.unitIndex = startIndex
		unit.nextIndex = startIndex
		unit.zPos = (startIndex / mapWidth) + 0.5
		unit.xPos = (startIndex % mapLength) + 0.5
		unit.playerInput.connect(_on_player_input)
		unit.reflect.connect(_on_player_reflect)
		unit.nextUnit.connect(_on_next_unit)
		unitIndex += 1
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
#This method will check if an action is legal, like if the player can walk on the tile
#It also needs to handle tile changes, such as filling or breaking tiles.
#This is how I'll store the action stack for reflects
func _on_player_input(unit : Node3D):
	var wantedTile = stageMap[unit.nextIndex]
	print(wantedTile)
	#Simple movement test
	if(unit.nextIndex == unit.unitIndex):
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Wait"}
	elif(wantedTile["Fillable"] and unit.filler):
		grid_map.set_cell_item(wantedTile["Loc"], 0)
		stageMap[unit.nextIndex] = defaultTileDict.duplicate()
		stageMap[unit.nextIndex]["Loc"] = wantedTile["Loc"]
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Fill"} 
	elif(wantedTile["Breakable"] and unit.breaker):
		grid_map.set_cell_item(Vector3i(wantedTile["Loc"].x, 1, wantedTile["Loc"].z), -1)
		grid_map.set_cell_item(Vector3i(wantedTile["Loc"].x, 0, wantedTile["Loc"].z), 0)
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Break"} 
		stageMap[unit.nextIndex] = defaultTileDict.duplicate()
		stageMap[unit.nextIndex]["Loc"] = Vector3i(wantedTile["Loc"].x, 0, wantedTile["Loc"].z)
	elif(wantedTile["Walkable"]):
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "Effect" : "Move"} 
	authorizeInput.emit(stageMap[unit.nextIndex]["Walkable"])
	
func _on_player_reflect(unit : Node3D):
	for action in unit.actionStack:
		print(action)
		if(action != null):
			unit.unitIndex = action["Index"]
			if(action["Effect"] == "Fill"):
				print("Reset fill")
				var changedTile = stageMap[action["ActionIndex"]]
				print(changedTile["Loc"])
				var tempX = changedTile["Loc"].x
				var tempZ = changedTile["Loc"].z
				grid_map.set_cell_item(Vector3i(tempX,0,tempZ),1)
				stageMap[action["ActionIndex"]] = defaultTileDict.duplicate()
				stageMap[action["ActionIndex"]]["Type"] = "Fillable"
				stageMap[action["ActionIndex"]]["Walkable"] = false
				stageMap[action["ActionIndex"]]["Fillable"] = true
				stageMap[action["ActionIndex"]]["Loc"] = Vector3i(tempX,0,tempZ)
			elif(action["Effect"] == "Break"):
				print("Reset break")
				var changedTile = stageMap[action["ActionIndex"]]
				print(changedTile["Loc"])
				var tempX = changedTile["Loc"].x
				var tempZ = changedTile["Loc"].z
				grid_map.set_cell_item(Vector3i(tempX,1,tempZ),2)
				grid_map.set_cell_item(Vector3i(tempX,0,tempZ),-1)
				stageMap[action["ActionIndex"]] = defaultTileDict.duplicate()
				stageMap[action["ActionIndex"]]["Type"] = "Breakable"
				stageMap[action["ActionIndex"]]["Walkable"] = false
				stageMap[action["ActionIndex"]]["Breakable"] = true
				stageMap[action["ActionIndex"]]["Loc"] = Vector3i(tempX,0,tempZ)
				
	unit.nextIndex = unit.unitIndex
	unit.zPos = (unit.unitIndex / mapWidth) + 0.5
	unit.xPos = (unit.unitIndex % mapLength) + 0.5
	unit.currentTurnCount = unit.turnCount

func _on_next_unit():
	currentUnit += 1
	if(currentUnit >= availableUnits.size()):
		currentUnit = 0
	unitNodes[currentUnit].disabled = false
	unitNodes[currentUnit].visible = true
	unitNodes[currentUnit].unitIndex = startIndex
	unitNodes[currentUnit].nextIndex = startIndex
	unitNodes[currentUnit].zPos = (startIndex / mapWidth) + 0.5
	unitNodes[currentUnit].xPos = (startIndex % mapLength) + 0.5
	unitNodes[currentUnit].isAlive = true
	unitNodes[currentUnit].currentTurnCount = unitNodes[currentUnit].turnCount
	unitNodes[currentUnit].actionStack.clear()
	unitNodes[currentUnit].actionStack.resize(unitNodes[currentUnit].turnCount)
