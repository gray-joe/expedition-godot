extends Node

var player_count = 0

var player_gear = {}
var player_skill_cards = {}

var skill_cards = {
	"strength": {
		"name": "Strength",
		"description": "You are a strong walker over rough terrain.
Move at normal speed when moving through marsh and/or scree for one move a day.
"
	},
	"fitness": {
		"name": "Fitness",
		"description": "You are a very good walker uphill.
Add 2 when going uphill for more than 300m for one move a day.
"
	},
	"cooking": {
		"name": "Cooking",
		"description": "You are excellent at choosing and cooking light, nutritious meals on a stove.
Add 1 to each morning move.
"
	},
	"endurance": {
		"name": "Endurance",
		"description": "You have great endurance.
Add 1 to the afternoon move of each day.
"
	},
	"navigation": {
		"name": "Navigation",
		"description": "You are very good at using map and 
compass. Move through forest at normal
speed whilst not on a path 
for one move a day.
"
	},
	"organisation": {
		"name": "Organisation",
		"description": "You are very good at making sure you have all the equipment you need.  
Add 1 to each morning move.
"
	},
	"sure_footedness": {
		"name": "Sure Footedness",
		"description": "You are sure-footed when descending steep slopes.
Add 2 when going downhill more 
than 300m for one move a day.
"
	},
	"route_choice": {
		"name": "Route Choice",
		"description": "You are good at picking out the best route across difficult ground.
Add 2 to one move a day if you travel 
through forest/marsh/scree.
"
	},
	"campcraft": {
		"name": "Campcraft",
		"description": "You are very good at choosing safe, 
sheltered places to camp. Who needs a 
heavy mountain tent?
Play this card against the negative 
effects of camp cards: 1, 4, 6, 13, 21, 35.
"
	},
	"stream_crossing": {
		"name": "Stream Crossing",
		"description": "You are very good at choosing stream crossing points and techniques.
Cross any wide stream once per day, 
without having to shake the risk dice.
"
	},
	"weather_craft": {
		"name": "Weather Craft",
		"description": "You are very good at observing and anticipating changes in weather which 
helps to keep you warm, dry and positive.
Add 1 to a move each day.
"
	},
	"packing": {
		"name": "Packing",
		"description": "You are very good at packing a rucksack quickly and efficiently. 
Add 1 to each morning move.
"
	}
}

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
