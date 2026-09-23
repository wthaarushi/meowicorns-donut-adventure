extends TileMapLayer

const BOTTOM_ROW := 32
const MIN_TOP := 22
const MAX_TOP := 28
const LOOKAHEAD := 40
const CLEARANCE_AFTER_PLATFORM := 6
const CLOUD_TOP := Vector2i(0, 0)
const CLOUD_BODY := Vector2i(1, 0)
const CLOUD_WISP := Vector2i(2, 0)
const CLOUD_THIN := Vector2i(3, 0)
const CLOUD_CANDY := Vector2i(4, 0)

var _tops: Dictionary = {}
var _filled_to: int = 0
var _top: int = 26
var _land_top: int = 26
var _run_left: int = 0
var _platform_end: int = -1
var _rng := RandomNumberGenerator.new()

@onready var player: Node2D = get_node("../Player")

func _ready() -> void:
	_rng.randomize()
	var columns := {}
	for cell in get_used_cells():
		_filled_to = maxi(_filled_to, cell.x)
		columns[cell.x] = mini(columns.get(cell.x, 999), cell.y)
	var first_col: int = columns.keys().min()
	for x in range(0, first_col):
		columns[x] = columns[first_col]
		set_cell(Vector2i(x, columns[x]), 0, CLOUD_TOP)
		for row in range(columns[x] + 1, 31):
			set_cell(Vector2i(x, row), 0, CLOUD_BODY)
	for x in columns:
		_tops[x] = columns[x]
		for row in range(31, BOTTOM_ROW):
			set_cell(Vector2i(x, row), 0, CLOUD_BODY)
		set_cell(Vector2i(x, BOTTOM_ROW), 0, CLOUD_WISP)
	_top = _tops.get(_filled_to, 26)
	_run_left = 8

func _process(_delta: float) -> void:
	var player_col := int(player.global_position.x) / tile_set.tile_size.x
	while _filled_to < player_col + LOOKAHEAD:
		_next_column()

func _next_column() -> void:
	if _run_left <= 0:
		_pick_segment()
	_filled_to += 1
	_run_left -= 1
	if _top < 0:
		_tops[_filled_to] = -1
		return
	_tops[_filled_to] = _top
	set_cell(Vector2i(_filled_to, _top), 0, CLOUD_TOP)
	for row in range(_top + 1, BOTTOM_ROW):
		set_cell(Vector2i(_filled_to, row), 0, CLOUD_BODY)
	set_cell(Vector2i(_filled_to, BOTTOM_ROW), 0, CLOUD_WISP)

func _under_platform() -> bool:
	return _filled_to < _platform_end + CLEARANCE_AFTER_PLATFORM

func _pick_segment() -> void:
	if _top < 0:
		_top = _land_top
		_run_left = _rng.randi_range(6, 12)
		return
	var roll := _rng.randf()
	if roll < 0.3:
		_land_top = maxi(clampi(_top + _rng.randi_range(-2, 2), MIN_TOP, MAX_TOP), _top - 1)
		if _under_platform():
			_land_top = maxi(_land_top, _top)
		_run_left = 2 if _land_top < _top else _rng.randi_range(2, 3)
		_top = -1
	elif roll < 0.55:
		var next_top := clampi(_top + _rng.randi_range(-2, 2), MIN_TOP, MAX_TOP)
		_top = maxi(next_top, _top) if _under_platform() else next_top
		_run_left = _rng.randi_range(5, 10)
	else:
		_run_left = _rng.randi_range(6, 14)
		if _rng.randf() < 0.5:
			_place_platforms()

func _place_platforms() -> void:
	var start := _filled_to + 2
	var width := _rng.randi_range(2, 6)
	var height := 3 if _rng.randf() < 0.6 else 4
	_paint_platform(start, width, _top - height)
	if _rng.randf() < 0.4:
		_paint_platform(start + width + _rng.randi_range(1, 3), _rng.randi_range(2, 4), _top - (7 - height))
	_run_left = maxi(_run_left, _platform_end - _filled_to + CLEARANCE_AFTER_PLATFORM)

func _paint_platform(start: int, width: int, row: int) -> void:
	if row < MIN_TOP - 4:
		return
	var tile := CLOUD_CANDY if _rng.randf() < 0.4 else CLOUD_THIN
	for x in range(start, start + width):
		set_cell(Vector2i(x, row), 0, tile)
	_platform_end = maxi(_platform_end, start + width - 1)

func _column(world_x: float) -> int:
	return int(world_x) / tile_set.tile_size.x

func has_ground_at(world_x: float) -> bool:
	return _tops.get(_column(world_x), -1) != -1

func surface_y(world_x: float) -> float:
	var col := _column(world_x)
	var top: int = _tops.get(col, -1)
	var back := 1
	while top == -1 and back < 8:
		top = _tops.get(col - back, -1)
		back += 1
	if top == -1:
		top = 26
	return float(top * tile_set.tile_size.y)

func is_flat_around(world_x: float, span: float) -> bool:
	var first: int = _tops.get(_column(world_x - span), -1)
	if first == -1:
		return false
	for col in range(_column(world_x - span), _column(world_x + span) + 1):
		if _tops.get(col, -1) != first:
			return false
	return true
