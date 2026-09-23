extends Node

const SAVE_PATH := "user://save.cfg"

const CATS := [
	{
		"id": "meowicorn", "name": "Meowicorn", "color": "White", "pitch": 1.0, "price": 0,
		"tagline": "The original. Big heart, bigger appetite.",
		"perk": "Balanced. No tricks, just vibes.",
		"stats": {"Speed": 3, "Jump": 3, "Flight": 3, "Health": 1, "Luck": 3, "Appetite": 3},
	},
	{
		"id": "cherry", "name": "Cherry Dash", "color": "Red", "pitch": 1.25, "price": 30,
		"tagline": "Never walks anywhere. Ever.",
		"perk": "Runs 12% faster. More distance, more danger.",
		"speed_mult": 1.12,
		"stats": {"Speed": 5, "Jump": 3, "Flight": 3, "Health": 1, "Luck": 3, "Appetite": 3},
	},
	{
		"id": "mango", "name": "Mango Sunbeam", "color": "Orange", "pitch": 1.12, "price": 45,
		"tagline": "Can smell a donut from three clouds away.",
		"perk": "Donuts are worth 15 points instead of 10.",
		"donut_value": 15,
		"stats": {"Speed": 3, "Jump": 3, "Flight": 3, "Health": 1, "Luck": 3, "Appetite": 5},
	},
	{
		"id": "lemon", "name": "Lemon Sparkle", "color": "Yellow", "pitch": 1.4, "price": 65,
		"tagline": "Believes in luck. Luck believes in her.",
		"perk": "Golden donuts show up 35% more often.",
		"golden_mult": 0.65,
		"stats": {"Speed": 3, "Jump": 3, "Flight": 3, "Health": 1, "Luck": 5, "Appetite": 3},
	},
	{
		"id": "minty", "name": "Minty Hop", "color": "Green", "pitch": 1.08, "price": 90,
		"tagline": "Springs in her paws and mint on her breath.",
		"perk": "Jumps 10% higher.",
		"jump_mult": 1.10,
		"stats": {"Speed": 3, "Jump": 5, "Flight": 3, "Health": 1, "Luck": 3, "Appetite": 3},
	},
	{
		"id": "blueberry", "name": "Blueberry Glide", "color": "Blue", "pitch": 0.85, "price": 120,
		"tagline": "Happiest with her head in the clouds.",
		"perk": "Flights last 3 seconds longer.",
		"fly_bonus": 3.0,
		"stats": {"Speed": 3, "Jump": 3, "Flight": 5, "Health": 1, "Luck": 3, "Appetite": 3},
	},
	{
		"id": "plum", "name": "Plum Twilight", "color": "Purple", "pitch": 0.75, "price": 150,
		"tagline": "A little mysterious. Very hard to knock down.",
		"perk": "A shield absorbs one hit per run.",
		"shield": true,
		"stats": {"Speed": 3, "Jump": 3, "Flight": 3, "Health": 3, "Luck": 3, "Appetite": 3},
	},
	{
		"id": "midnight", "name": "Midnight Velvet", "color": "Black", "pitch": 0.65, "price": 190,
		"tagline": "Cool, calm, and secretly full of rainbows.",
		"perk": "Never speeds up past a gentle pace.",
		"max_speed": 220.0,
		"stats": {"Speed": 1, "Jump": 3, "Flight": 3, "Health": 2, "Luck": 3, "Appetite": 3},
	},
]

signal achievement_unlocked(id: String)

const ACHIEVEMENTS := [
	{"id": "first_flight", "name": "First Flight", "desc": "Grab a golden donut and take off.", "metric": "flights", "target": 1},
	{"id": "sweet_tooth", "name": "Sweet Tooth", "desc": "Collect 100 donuts in total.", "metric": "lifetime_donuts", "target": 100},
	{"id": "hoarder", "name": "Donut Hoarder", "desc": "Collect 500 donuts in total.", "metric": "lifetime_donuts", "target": 500},
	{"id": "long_way", "name": "Long Way Home", "desc": "Score 1000 in a single run.", "metric": "best_score", "target": 1000},
	{"id": "marathon", "name": "Sky Marathon", "desc": "Score 3000 in a single run.", "metric": "best_score", "target": 3000},
	{"id": "frequent_flyer", "name": "Frequent Flyer", "desc": "Fly 10 times.", "metric": "flights", "target": 10},
	{"id": "new_friend", "name": "New Friend", "desc": "Buy your first cat.", "metric": "cats_bought", "target": 1},
	{"id": "full_house", "name": "Full House", "desc": "Unlock all eight cats.", "metric": "cats_owned", "target": 8},
	{"id": "legend", "name": "Lifetime Legend", "desc": "Reach a lifetime score of 25000.", "metric": "lifetime_score", "target": 25000},
	{"id": "never_give_up", "name": "Never Give Up", "desc": "Play 25 runs.", "metric": "runs", "target": 25},
]

var wallet: int = 0
var stats: Dictionary = {"lifetime_score": 0, "lifetime_donuts": 0, "runs": 0, "flights": 0}
var achievements: Array = []
var unlocked: Array = ["meowicorn"]
var selected: String = "meowicorn"
var bests: Dictionary = {}
var best_score: int = 0
var music_volume: float = 0.6
var sfx_volume: float = 0.6
var retry_pending: bool = false

var _by_id: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for cat in CATS:
		_by_id[cat["id"]] = cat
	load_all()

func cat(id: String) -> Dictionary:
	return _by_id.get(id, CATS[0])

func current() -> Dictionary:
	return cat(selected)

func index_of(id: String) -> int:
	for i in range(CATS.size()):
		if CATS[i]["id"] == id:
			return i
	return 0

func texture_path(id: String) -> String:
	return "res://art/cats/cat_%s.png" % id

func is_unlocked(id: String) -> bool:
	return unlocked.has(id)

func can_afford(id: String) -> bool:
	return wallet >= int(cat(id)["price"])

func buy(id: String) -> bool:
	if is_unlocked(id) or not can_afford(id):
		return false
	wallet -= int(cat(id)["price"])
	unlocked.append(id)
	selected = id
	_check_achievements()
	return true

func select(id: String) -> void:
	if is_unlocked(id):
		selected = id
		save_all()

func best_for(id: String) -> int:
	return int(bests.get(id, 0))

func finish_run(score: int, donuts: int) -> void:
	wallet += donuts
	best_score = maxi(best_score, score)
	if score > best_for(selected):
		bests[selected] = score
	stats["lifetime_score"] = int(stats["lifetime_score"]) + score
	stats["lifetime_donuts"] = int(stats["lifetime_donuts"]) + donuts
	stats["runs"] = int(stats["runs"]) + 1
	_check_achievements()

func record_flight() -> void:
	stats["flights"] = int(stats["flights"]) + 1
	_check_achievements()

func has_achievement(id: String) -> bool:
	return achievements.has(id)

func _metric(name: String) -> int:
	match name:
		"best_score": return best_score
		"cats_bought": return unlocked.size() - 1
		"cats_owned": return unlocked.size()
	return int(stats.get(name, 0))

func achievement(id: String) -> Dictionary:
	for entry in ACHIEVEMENTS:
		if entry["id"] == id:
			return entry
	return {}

func progress_for(id: String) -> Array:
	var entry := achievement(id)
	if entry.is_empty():
		return [0, 1]
	var target: int = entry["target"]
	return [mini(_metric(entry["metric"]), target), target]

func _check_achievements() -> void:
	for entry in ACHIEVEMENTS:
		var id: String = entry["id"]
		if not achievements.has(id) and _metric(entry["metric"]) >= int(entry["target"]):
			achievements.append(id)
			achievement_unlocked.emit(id)
	save_all()

func set_volumes(music: float, sfx: float) -> void:
	music_volume = music
	sfx_volume = sfx
	save_all()

func load_all() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	wallet = int(cfg.get_value("shop", "wallet", 0))
	unlocked = cfg.get_value("shop", "unlocked", ["meowicorn"])
	selected = str(cfg.get_value("shop", "selected", "meowicorn"))
	bests = cfg.get_value("shop", "bests", {})
	var saved_stats: Dictionary = cfg.get_value("stats", "totals", {})
	for key in saved_stats:
		stats[key] = saved_stats[key]
	achievements = cfg.get_value("stats", "achievements", [])
	best_score = int(cfg.get_value("game", "best", 0))
	music_volume = float(cfg.get_value("audio", "music", 0.6))
	sfx_volume = float(cfg.get_value("audio", "sfx", 0.6))
	if not unlocked.has("meowicorn"):
		unlocked.append("meowicorn")
	if not unlocked.has(selected):
		selected = "meowicorn"

func save_all() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("shop", "wallet", wallet)
	cfg.set_value("shop", "unlocked", unlocked)
	cfg.set_value("shop", "selected", selected)
	cfg.set_value("shop", "bests", bests)
	cfg.set_value("stats", "totals", stats)
	cfg.set_value("stats", "achievements", achievements)
	cfg.set_value("game", "best", best_score)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SAVE_PATH)
