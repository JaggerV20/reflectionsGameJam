extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var unit_holder: Node3D = $UnitHolder
@onready var ghost_holder: Node3D = $GhostHolder
#@onready var j_test_select_scene: Node3D = $"../JTestSelectScene"
@onready var selection: Node3D = $"../Selection"
@onready var soul_holder: Node3D = $SoulHolder
@onready var stage_hud: Control = $StageHUD
@onready var soul_count: Label = $StageHUD/SoulCount
@onready var turn_count: Label = $StageHUD/TurnCount

const FILLER_UNIT = preload("res://Scenes/FillerUnit.tscn")
const BREAKER_UNIT = preload("res://Scenes/BreakerUnit.tscn")
const FLYER_UNIT = preload("res://Scenes/FlyerUnit.tscn")

const BREAKER_GHOST = preload("res://Scenes/BreakerGhost.tscn")
const FILLER_GHOST = preload("res://Scenes/FillerGhost.tscn")
const FLYER_GHOST = preload("res://Scenes/FlyerGhost.tscn")

const SOUL = preload("res://Scenes/Soul.tscn")

var mapLength = 10
var mapWidth = 10
var charMap =  ["-","-","G","-","-","-","-","-","-","-",
				"|",".",".",".","_",".",".","_",".","|",
				"|",".",".",".","_",".",".",".",".","|",
				"|",".","X","_",".",".",".",".",".","|",
				"|",".",".",".",".",".",".","X",".","|",
				"|","X",".","_",".","X",".",".","_","|",
				"|",".",".",".",".",".",".",".",".","|",
				"|",".",".",".",".",".","X",".",".","|",
				"|",".","S",".","X",".",".","X",".","|",
				"-","-","-","-","-","-","-","-","-","-"]
var soulArray = [11,15,18,35,41,43,46,48,81,88]
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
	"Corpse" : null,
	"ContainsSoul" : false
}

var setNextUnit = false
var availableUnits = ["Filler", "Breaker", "Flyer"]
var currentUnit = 0
var unitNodes = []
var ghostNodes = []
var soulNodes = []
#Needs to be set whenever the player moves to the next unit
var actionStack = []
@export var stageTurnCount = 16

var collectedSouls = 0
var soulsNeeded = 7

#Stage handler checks if the player input is valid. It will change the map if needed, then allow player movement
signal authorizeInput
signal toggleSelection

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	#j_test_select_scene.unitSelected.connect(_on_unit_selected)
	selection.unitSelected.connect(_on_unit_selected)
	stageMap.resize(mapLength * mapWidth)
	var index = 0
	var soulIndex = 0
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
				stageMap[index]["OnSwitch"] = []
				stageMap[index]["OnSwitch"].resize(availableUnits.size())
				for unit in stageMap[index]["OnSwitch"]:
					unit = false
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
				grid_map.set_cell_item(Vector3i(xPos,0,zPos),0)
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),7)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Loc"] = Vector3i(xPos,1,zPos)
				stageMap[index]["Walkable"] = false
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
				grid_map.set_cell_item(Vector3i(xPos,1,zPos),5)
				stageMap[index] = defaultTileDict.duplicate()
				stageMap[index]["Type"] = "Goal"
				stageMap[index]["Walkable"] = false
				stageMap[index]["Loc"] = Vector3i(xPos,0,zPos)
		if(soulIndex < soulArray.size() and index == soulArray[soulIndex]):
			stageMap[index]["ContainsSoul"] = true
			stageMap[index]["SoulIndex"] = soulIndex
			var soulTemp = SOUL.instantiate()
			soulTemp.soulIndex = index
			soulTemp.global_position = Vector3(xPos + 0.5, 1.05, zPos + 0.5)
			soul_holder.add_child(soulTemp)
			soulIndex += 1
			
		index += 1
	for unit in availableUnits:
		match unit:
			"Filler":
				unit_holder.add_child(FILLER_UNIT.instantiate())
				ghost_holder.add_child(FILLER_GHOST.instantiate())
			"Breaker":
				unit_holder.add_child(BREAKER_UNIT.instantiate())
				ghost_holder.add_child(BREAKER_GHOST.instantiate())
			"Flyer":
				unit_holder.add_child(FLYER_UNIT.instantiate())
				ghost_holder.add_child(FLYER_GHOST.instantiate())

	unitNodes = unit_holder.get_children()
	soulNodes = soul_holder.get_children()
	for unit in unitNodes:
		unit.disableAction = true
		unit.visible = false
		unit.unitIndex = startIndex
		unit.nextIndex = startIndex
		unit.zPos = (startIndex / mapWidth) + 0.5
		unit.xPos = (startIndex % mapLength) + 0.5
		unit.turnCount = stageTurnCount
		unit.currentTurnCount = stageTurnCount
		unit.playerInput.connect(_on_player_input)
		unit.reflect.connect(_on_player_reflect)
		unit.nextUnit.connect(_on_next_unit)
	ghostNodes = ghost_holder.get_children()
	for ghost in ghostNodes:
		ghost.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
func _on_unit_selected(index : int):
	stage_hud.visible = true
	soul_count.text = "Souls: " + str(collectedSouls) + "/" + str(soulsNeeded)
	turn_count.text = "Turns Remaining: " + str(unitNodes[currentUnit].currentTurnCount) + "/" + str(unitNodes[currentUnit].turnCount)
	currentUnit = index
	unitNodes[currentUnit].disableAction = false
	unitNodes[currentUnit].isAlive = true
	unitNodes[currentUnit].visible = true
	unitNodes[currentUnit].actionStack.clear()
	unitNodes[currentUnit].actionStack.resize(unitNodes[currentUnit].turnCount)
	unitNodes[currentUnit].unitIndex = startIndex
	unitNodes[currentUnit].nextIndex = startIndex
	unitNodes[currentUnit].zPos = (startIndex / mapWidth) + 0.5
	unitNodes[currentUnit].xPos = (startIndex % mapLength) + 0.5
	unitNodes[currentUnit].global_position.z = unitNodes[currentUnit].zPos
	unitNodes[currentUnit].global_position.x = unitNodes[currentUnit].xPos
	unitNodes[currentUnit].onSwitch = 0
	ghostNodes[currentUnit].visible = false
#This method will check if an action is legal, like if the player can walk on the tile
#It also needs to handle tile changes, such as filling or breaking tiles.
#This is how I'll store the action stack for reflects
func _on_player_input(unit : Node3D):
	var wantedTile = stageMap[unit.nextIndex]
	var levelComplete = false #I want the animations to play out before ending
	if(wantedTile["Type"] == "Goal" and wantedTile["Walkable"]):
		get_tree().call_deferred("change_scene_to_file","res://Scenes/StageSelect.tscn")
	elif(unit.nextIndex == unit.unitIndex):
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Wait", "CollectedSoul" : false}
	elif(wantedTile["Fillable"] and unit.filler):
		grid_map.set_cell_item(wantedTile["Loc"], 0)
		stageMap[unit.nextIndex] = defaultTileDict.duplicate()
		stageMap[unit.nextIndex]["Loc"] = wantedTile["Loc"]
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Fill", "CollectedSoul" : false} 
	elif(wantedTile["Breakable"] and unit.breaker):
		grid_map.set_cell_item(Vector3i(wantedTile["Loc"].x, 1, wantedTile["Loc"].z), -1)
		grid_map.set_cell_item(Vector3i(wantedTile["Loc"].x, 0, wantedTile["Loc"].z), 0)
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Break", "CollectedSoul" : false} 
		stageMap[unit.nextIndex] = defaultTileDict.duplicate()
		stageMap[unit.nextIndex]["Loc"] = Vector3i(wantedTile["Loc"].x, 0, wantedTile["Loc"].z)
	elif(wantedTile["Walkable"] or (wantedTile["Fillable"] and unit.flyer)):
		unit.actionStack[unit.currentTurnCount - 1] = {"Index" : unit.unitIndex, "ActionIndex" : unit.nextIndex, "Effect" : "Move", "CollectedSoul" : false} 
		if(wantedTile["Type"] == "Switch"):
			var lockIndex = stageMap[unit.nextIndex]["Unlocks"]
			var lockLoc = stageMap[lockIndex]["Loc"]
			stageMap[unit.nextIndex]["OnSwitch"][currentUnit] = true
			grid_map.set_cell_item(lockLoc, -1)
			stageMap[lockIndex] = defaultTileDict.duplicate()
			stageMap[lockIndex]["Loc"] = lockLoc
	if(wantedTile["ContainsSoul"]):
		soulNodes[wantedTile["SoulIndex"]].visible = false
		stageMap[unit.nextIndex]["ContainsSoul"] = false
		collectedSouls += 1
	
	#Confirming action is valid
	if(stageMap[unit.nextIndex]["Walkable"] or (wantedTile["Fillable"] and unit.flyer)):
		#Check if a unit was on a switch, and has left the switch
		if(stageMap[unit.unitIndex]["Type"] == "Switch" and unit.unitIndex != unit.nextIndex):
			stageMap[unit.unitIndex]["OnSwitch"][currentUnit] = false
			var lockIndex = stageMap[unit.unitIndex]["Unlocks"]
			var tempLoc = stageMap[lockIndex]["Loc"]
			var unitsOnSwitch = false
			for switchUnits in stageMap[unit.unitIndex]["OnSwitch"]:
				unitsOnSwitch = unitsOnSwitch or switchUnits
			if(!unitsOnSwitch):
				grid_map.set_cell_item(tempLoc, 7)
				stageMap[lockIndex] = defaultTileDict.duplicate()
				stageMap[lockIndex]["Loc"] = tempLoc
				stageMap[lockIndex]["Walkable"] = false
				stageMap[lockIndex]["Type"] = "Lock"
		authorizeInput.emit(true)
		playbackActionStack(unit.currentTurnCount)
		soul_count.text = "Souls: " + str(collectedSouls) + "/" + str(soulsNeeded)
		turn_count.text = "Turns Remaining: " + str(unitNodes[currentUnit].currentTurnCount) + "/" + str(unitNodes[currentUnit].turnCount)
		if(collectedSouls >= soulsNeeded):
			var goalLoc = stageMap[goalIndex]["Loc"]
			grid_map.set_cell_item(Vector3i(goalLoc.x, 1, goalLoc.z),-1)
			stageMap[goalIndex]["Walkable"] = true
	else:
		authorizeInput.emit(false)
	
#This will be very similar to _on_player_input, but it doesn't validate anything.
#If an action is in the actionStack, it's legal. Just ignore the currentIndex unit
func playbackActionStack(turn : int):
	var ghostIndex = 0
	var unitNum = 0
	for unit in unitNodes:
		if(!unit.isAlive):
			var index = turn
			if(unit.actionStack[index] != null):
				var tempX = (unit.actionStack[index]["ActionIndex"] % mapWidth) + 0.5
				var tempZ = (unit.actionStack[index]["ActionIndex"] / mapLength) + 0.5
				var tempY = 1.05
				ghostNodes[ghostIndex].global_position = Vector3(tempX, tempY, tempZ)
				#Movement change can be applied even if the unit doesn't move.
				#Only need to check if tiles are changed
				if(unit.actionStack[index]["Effect"] == "Fill"):
					var tempLoc = stageMap[unit.actionStack[index]["ActionIndex"]]["Loc"]
					grid_map.set_cell_item(tempLoc, 0)
					stageMap[unit.actionStack[index]["ActionIndex"]] = defaultTileDict.duplicate()
					stageMap[unit.actionStack[index]["ActionIndex"]]["Loc"] = tempLoc
				elif(unit.actionStack[index]["Effect"] == "Break"):
					var tempLoc = stageMap[unit.actionStack[index]["ActionIndex"]]["Loc"]
					grid_map.set_cell_item(Vector3i(tempLoc.x, 1, tempLoc.z), -1)
					grid_map.set_cell_item(Vector3i(tempLoc.x, 0, tempLoc.z), 0)
					stageMap[unit.actionStack[index]["ActionIndex"]] = defaultTileDict.duplicate()
					stageMap[unit.actionStack[index]["ActionIndex"]]["Loc"] = Vector3i(tempLoc.x, 0, tempLoc.z)
				elif(stageMap[unit.actionStack[index]["ActionIndex"]]["Type"] == "Switch"):
					var lockIndex = stageMap[unit.actionStack[index]["ActionIndex"]]["Unlocks"]
					var lockLoc = stageMap[lockIndex]["Loc"]
					grid_map.set_cell_item(lockLoc, -1)
					stageMap[lockIndex] = defaultTileDict.duplicate()
					stageMap[lockIndex]["Loc"] = lockLoc
				#Checking if unit is no longer on switch
				if(stageMap[unit.actionStack[index]["Index"]]["Type"] == "Switch" and unit.actionStack[index]["Index"] != unit.actionStack[index]["ActionIndex"]):
					stageMap[unit.actionStack[index]["Index"]]["OnSwitch"][unitNum] = false
					var lockIndex = stageMap[unit.actionStack[index]["Index"]]["Unlocks"]
					var tempLoc = stageMap[lockIndex]["Loc"]
					var unitsOnSwitch = false
					for switchUnits in stageMap[unit.actionStack[index]["Index"]]["OnSwitch"]:
						unitsOnSwitch = unitsOnSwitch or switchUnits
					if(!unitsOnSwitch):
						grid_map.set_cell_item(tempLoc, 7)
						stageMap[lockIndex] = defaultTileDict.duplicate()
						stageMap[lockIndex]["Loc"] = tempLoc
						stageMap[lockIndex]["Walkable"] = false
						stageMap[lockIndex]["Type"] = "Lock"
				if(stageMap[unit.actionStack[index]["ActionIndex"]]["ContainsSoul"]):
					soulNodes[stageMap[unit.actionStack[index]["ActionIndex"]]["SoulIndex"]].visible = false
					stageMap[unit.actionStack[index]["ActionIndex"]]["ContainsSoul"] = false
					collectedSouls += 1
		ghostIndex += 1
		unitNum += 1


func _on_player_reflect(unit : Node3D):
	undoActionStack()
	soul_count.text = "Souls: " + str(collectedSouls) + "/" + str(soulsNeeded)
	turn_count.text = "Turns Remaining: " + str(unitNodes[currentUnit].currentTurnCount) + "/" + str(unitNodes[currentUnit].turnCount)
	unit.zPos = (unit.unitIndex / mapWidth) + 0.5
	unit.xPos = (unit.unitIndex % mapLength) + 0.5
	unit.global_position.x = unit.xPos
	unit.global_position.z = unit.zPos

func undoActionStack():
	for unit in unitNodes:
		for action in unit.actionStack:
			if(action != null):
				unit.unitIndex = action["Index"]
				if(action["Effect"] == "Fill"):
					var changedTile = stageMap[action["ActionIndex"]]
					var tempX = changedTile["Loc"].x
					var tempZ = changedTile["Loc"].z
					grid_map.set_cell_item(Vector3i(tempX,0,tempZ),1)
					stageMap[action["ActionIndex"]] = defaultTileDict.duplicate()
					stageMap[action["ActionIndex"]]["Type"] = "Fillable"
					stageMap[action["ActionIndex"]]["Walkable"] = false
					stageMap[action["ActionIndex"]]["Fillable"] = true
					stageMap[action["ActionIndex"]]["Loc"] = Vector3i(tempX,0,tempZ)
				elif(action["Effect"] == "Break"):
					var changedTile = stageMap[action["ActionIndex"]]
					var tempX = changedTile["Loc"].x
					var tempZ = changedTile["Loc"].z
					grid_map.set_cell_item(Vector3i(tempX,1,tempZ),2)
					grid_map.set_cell_item(Vector3i(tempX,0,tempZ),-1)
					stageMap[action["ActionIndex"]] = defaultTileDict.duplicate()
					stageMap[action["ActionIndex"]]["Type"] = "Breakable"
					stageMap[action["ActionIndex"]]["Walkable"] = false
					stageMap[action["ActionIndex"]]["Breakable"] = true
					stageMap[action["ActionIndex"]]["Loc"] = Vector3i(tempX,0,tempZ)
				elif(stageMap[action["ActionIndex"]]["Type"] == "Switch"):
					var lockIndex = stageMap[action["ActionIndex"]]["Unlocks"]
					var lockLoc = stageMap[lockIndex]["Loc"]
					grid_map.set_cell_item(lockLoc, 7)
					stageMap[lockIndex] = defaultTileDict.duplicate()
					stageMap[lockIndex]["Loc"] = lockLoc
					stageMap[lockIndex]["Walkable"] = false
					stageMap[lockIndex]["Type"] = "Lock"
		unit.nextIndex = unit.unitIndex
		unit.currentTurnCount = unit.turnCount
		
	if(collectedSouls >= soulsNeeded):
		var goalLoc = stageMap[goalIndex]["Loc"]
		grid_map.set_cell_item(Vector3i(goalLoc.x, 1, goalLoc.z),5)
		stageMap[goalIndex]["Walkable"] = false
	for soul in soulNodes:
		if(!soul.visible):
			stageMap[soul.soulIndex]["ContainsSoul"] = true
			soul.visible = true
			collectedSouls -= 1 
	for ghost in ghostNodes:
		var tempX = (startIndex % mapWidth) + 0.5
		var tempZ = (startIndex / mapLength) + 0.5
		ghost.global_position = Vector3(tempX, 1.05, tempZ)
	

func _on_next_unit():
	undoActionStack()
	ghostNodes[currentUnit].visible = true
	var tempX = (startIndex % mapWidth) + 0.5
	var tempZ = (startIndex / mapLength) + 0.5
	ghostNodes[currentUnit].global_position = Vector3(tempX, 1.05, tempZ)
	#j_test_select_scene.visible = true
	selection.visible = true
	stage_hud.visible = false
	toggleSelection.emit()
