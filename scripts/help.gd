extends Control

signal closed

const PAGES := [
	["Welcome!", [
		"You are a unicorn cat who", "lives in the clouds and", "loves donuts more than", "anything.", "",
		"Run as far as you can,", "eat every donut you see,", "and do not fall out of", "the sky.",
	], "Home screen", [
		[["key", "space"], ["key", "up"], ["key", "w"], "starts the run"], "",
		"Your friends hover above", "you while you nap. Click", "one to play as her.", "",
		[["key", "b"], "opens the Shop"], [["key", "m"], "opens Settings"], [["key", "h"], "opens this book"],
	]],
	["Moves", [
		[["key", "space"], ["key", "up"], ["key", "w"], "Jump"],
		[["key", "s"], ["key", "down"], "Duck"],
		[["key", "s"], ["key", "down"], "in the air: Dive"],
		[["key", "r"], "Restart"], "",
		"Tap jump a moment early", "or late and it still", "counts. Let go early for", "a small hop.",
	], "Score", [
		[["icon", "icon_crown"], "Best run for this cat"],
		[["icon", "icon_bag"], "Total donuts, for the shop"],
		[["icon", "icon_cloud"], "Score: distance plus"], "10 per donut",
		[["icon", "donut"], "Donuts this run"],
	]],
	["Dangers", [
		"Puddles ...... jump over", "Angry dogs ... jump over", "Sad clouds ... duck under", "Pits ......... jump across", "",
		"Sad clouds float at head", "height. Get low or get", "wet.",
	], "Golden donut", [
		"Grab one and you fly!", "",
		[["key", "space"], "flaps your wings,"], "like a flappy bird. Long", "donut chains fill the sky.",
		"Sad clouds up there still", "hurt, so weave around them.", "",
		"When the timer runs out", "you glide back down.",
	]],
	["Shop", [
		"Every donut you collect", "is saved when the run", "ends. Spend them on new", "cat friends.", "",
		"Each cat has a perk and", "her own stat card, voice,", "and best run.", "",
		[["icon", "icon_close"], "closes any page."],
	], "The friends", [
		"Cherry Dash ... fastest", "Mango ......... richer donuts", "Lemon ......... lucky gold", "Minty ......... higher jumps",
		"Blueberry ..... longer flights", "Plum .......... a shield", "Midnight ...... stays calm",
	]],
]
const PAPER := Color(1.0, 0.965, 0.88)
const PAPER_EDGE := Color(0.6, 0.35, 0.75)
const HEADING := Color(0.5, 0.25, 0.6)
const BODY := Color(0.3, 0.2, 0.35)
const ROW_HEIGHT := 14.0

var page := 0
var _left_title: Label
var _left_body: VBoxContainer
var _right_title: Label
var _right_body: VBoxContainer
var _page_label: Label
var _just_opened := false

func _ready() -> void:
	_build()
	visibility_changed.connect(_on_visibility_changed)

func _page_style() -> StyleBoxFlat:
	var sb := Ui.box(PAPER, 6, 12)
	sb.border_color = PAPER_EDGE
	sb.set_border_width_all(3)
	return sb

func _build() -> void:
	var book := HBoxContainer.new()
	book.set_anchors_preset(Control.PRESET_CENTER)
	book.offset_left = -290
	book.offset_right = 290
	book.offset_top = -140
	book.offset_bottom = 120
	book.add_theme_constant_override("separation", 6)
	add_child(book)
	var left := _make_page(book)
	_left_title = left[0]
	_left_body = left[1]
	var right := _make_page(book)
	_right_title = right[0]
	_right_body = right[1]

	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -200
	bar.offset_right = 200
	bar.offset_top = -46
	bar.offset_bottom = -14
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	add_child(bar)
	var prev := Ui.cloud_button("icon_left", 32.0)
	prev.pressed.connect(_turn.bind(-1))
	bar.add_child(prev)
	_page_label = Ui.label("", Ui.INK, 8, false)
	_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar.add_child(_page_label)
	var next := Ui.cloud_button("icon_right", 32.0)
	next.pressed.connect(_turn.bind(1))
	bar.add_child(next)

	var close := Ui.cloud_button("icon_close", 32.0)
	close.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close.offset_left = -44
	close.offset_right = -12
	close.offset_top = 8
	close.offset_bottom = 40
	close.pressed.connect(hide)
	add_child(close)

func _make_page(book: HBoxContainer) -> Array:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _page_style())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	book.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var heading := Ui.label("", HEADING, 16, false)
	column.add_child(heading)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	column.add_child(body)
	return [heading, body]

func _fill(body: VBoxContainer, lines: Array) -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	for line in lines:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
		row.add_theme_constant_override("separation", 5)
		body.add_child(row)
		for part in ([line] if line is String else line):
			row.add_child(_part(part))

func _part(part: Variant) -> Control:
	if part is String:
		var text := Ui.label(part, BODY, 8, false)
		text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return text
	var kind: String = part[0]
	var name: String = part[1]
	if kind == "key":
		var tex: Texture2D = load("res://art/key_%s.png" % name)
		var width := tex.get_width() * ROW_HEIGHT / tex.get_height()
		return Ui.icon(tex, Vector2(width, ROW_HEIGHT))
	if name == "donut":
		return Ui.icon(Ui.atlas("res://art/donut.png", Rect2(0, 0, 16, 16)), Vector2(ROW_HEIGHT, ROW_HEIGHT))
	return Ui.icon(load("res://art/%s.png" % name), Vector2(ROW_HEIGHT, ROW_HEIGHT))

func _on_visibility_changed() -> void:
	if visible:
		_just_opened = true
		page = 0
		_refresh()
	else:
		closed.emit()

func _process(_delta: float) -> void:
	if not visible:
		return
	if _just_opened:
		_just_opened = false
		return
	if Input.is_action_just_pressed("left"):
		_turn(-1)
	elif Input.is_action_just_pressed("right") or Input.is_action_just_pressed("jump"):
		_turn(1)
	elif Input.is_action_just_pressed("settings") or Input.is_action_just_pressed("help"):
		hide()

func _turn(dir: int) -> void:
	page = clampi(page + dir, 0, PAGES.size() - 1)
	Sfx.play("duck", 1.5)
	_refresh()

func _refresh() -> void:
	var p: Array = PAGES[page]
	_left_title.text = p[0]
	_fill(_left_body, p[1])
	_right_title.text = p[2]
	_fill(_right_body, p[3])
	_page_label.text = "Page %d / %d" % [page + 1, PAGES.size()]
