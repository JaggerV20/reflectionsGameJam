extends Node3D

@onready var grid_map: GridMap = $GridMap

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass