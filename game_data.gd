extends Node

var player_count = 0

var player_gear = {}

var tents = {
	"lightweight": {
		"name": "Lightweight tent",
		"weight": 1.0,
	},
	"mountain": {
		"name": "Mountain tent",
		"weight": 1.5,
	}
}

var sleeping_bags = {
	"2_season": {
		"name": "2 season sleeping bag",
		"weight": 1.0,
	},
	"3_4_season": {
		"name": "3 - 4 season sleeping bag",
		"weight": 1.5,
	}
}

var extras = {
	"water_bottles": {
		"name": "Water bottles",
		"weight": 0.5,
	},
	"extra_food": {
		"name": "Extra food",
		"weight": 0.5,
	},
	"extra_clothes": {
		"name": "Hat, Gloves and extra Socks",
		"weight": 0.5,
	}
}
