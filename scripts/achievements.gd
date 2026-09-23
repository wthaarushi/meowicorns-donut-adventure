extends Control

signal closed

const ICONS := {
	"first_flight": "golden", "sweet_tooth": "donut", "hoarder": "icon_bag", "long_way": "icon_cloud",
	"marathon": "icon_cloud", "frequent_flyer": "golden", "new_friend": "cat_cherry", "full_house": "cat_meowicorn",
	"legend": "icon_cloud", "never_give_up": "icon_restart",
}
const SCROLL_SPEED := 240.0

var _rows: Array = []
var _count_label: Label
var _best_label: Label
var _scroll: ScrollContainer
var _just_opened := false

func _ready() -> void:
	_build()
	visibility_changed.connect(_on_visibility_changed)

func _icon_for(id: String) -> Texture2D:
	var key: String = ICONS.get(id, "icon_trophy")
	if key == "donut":
		return Ui.atlas("res://art/donut.png", Rect2(0, 0, 16, 16))
	if key == "golden":
		return Ui.atlas("res://art/golden_donut.png", Rect2(0, 0, 16, 16))
	if key.begins_with("cat_"):
		return Ui.atlas("res://art/cats/%s.png" % key, Rect2(0, 0, 40, 28))
	return load("res://art/%s.png" % key)

func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.offset_left = -250
	root.offset_right = 250
	root.offset_top = -172
	root.offset_bottom = 172
	add_child(root)

	var title := Ui.title("Achievements")
	title.position = Vector2(0, 6)
	root.add_child(title)

	_count_label = Ui.label("", Ui.GOLD, 8, false)
	_count_label.position = Vector2(370, 12)
	_count_label.size = Vector2(80, 14)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_count_label)

	var best_row := HBoxContainer.new()
	best_row.position = Vector2(0, 34)
	best_row.size = Vector2(240, 20)
	best_row.add_theme_constant_override("separation", 6)
	root.add_child(best_row)
	best_row.add_child(Ui.icon(load("res://art/icon_crown.png"), Vector2(20, 20)))
	_best_label = Ui.label("", Ui.INK, 8, false)
	_best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best_row.add_child(_best_label)

	Ui.close_button(root, Vector2(462, 2)).pressed.connect(hide)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, 66)
	_scroll.size = Vector2(500, 248)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	_scroll.add_child(list)
	for entry in Progress.ACHIEVEMENTS:
		list.add_child(_make_row(entry))

	var hint := HBoxContainer.new()
	hint.position = Vector2(0, 320)
	hint.size = Vector2(500, 22)
	hint.alignment = BoxContainer.ALIGNMENT_CENTER
	hint.add_theme_constant_override("separation", 6)
	root.add_child(hint)
	hint.add_child(Ui.keycap("up"))
	hint.add_child(Ui.keycap("down"))
	var word := Ui.label("scroll", Color(Ui.INK, 0.7), 8, false)
	word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_child(word)

func _make_row(entry: Dictionary) -> PanelContainer:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", Ui.box(Color(1, 1, 1, 0.14), 8, 10))
	row.custom_minimum_size = Vector2(484, 64)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	row.add_child(h)
	h.add_child(Ui.icon(_icon_for(entry["id"]), Vector2(40, 32)))

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override("separation", 5)
	h.add_child(text)
	var name := Ui.label(entry["name"], Ui.INK, 8, false)
	text.add_child(name)
	var desc := Ui.label(entry["desc"], Color(Ui.INK, 0.65), 8, false)
	desc.scale = Vector2(0.75, 0.75)
	text.add_child(desc)

	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 8)
	text.add_child(bar_row)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 8)
	bar.show_percentage = false
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override("background", Ui.box(Color(0, 0, 0, 0.3), 4, 0))
	bar.add_theme_stylebox_override("fill", Ui.box(Ui.PINK, 4, 0))
	bar_row.add_child(bar)
	var amount := Ui.label("", Color(Ui.INK, 0.8), 8, false)
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bar_row.add_child(amount)

	var trophy := Ui.icon(load("res://art/icon_trophy.png"), Vector2(32, 32))
	trophy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(trophy)

	_rows.append({"id": entry["id"], "name": name, "bar": bar, "amount": amount, "trophy": trophy, "row": row})
	return row

func _on_visibility_changed() -> void:
	if visible:
		_just_opened = true
		_scroll.scroll_vertical = 0
		_refresh()
	else:
		closed.emit()

func _process(delta: float) -> void:
	if not visible:
		return
	if _just_opened:
		_just_opened = false
		return
	if Input.is_action_pressed("duck"):
		_scroll.scroll_vertical += int(SCROLL_SPEED * delta)
	elif Input.is_action_pressed("jump"):
		_scroll.scroll_vertical -= int(SCROLL_SPEED * delta)
	if Input.is_action_just_pressed("settings"):
		hide()

func _refresh() -> void:
	var done := 0
	for row in _rows:
		var got: bool = Progress.has_achievement(row["id"])
		var prog: Array = Progress.progress_for(row["id"])
		var shown: int = prog[1] if got else prog[0]
		row["bar"].max_value = prog[1]
		row["bar"].value = shown
		row["amount"].text = "%d / %d" % [shown, prog[1]]
		row["trophy"].modulate = Color.WHITE if got else Color(0.55, 0.5, 0.6, 0.7)
		row["name"].add_theme_color_override("font_color", Ui.PINK if got else Ui.INK)
		row["row"].modulate.a = 1.0 if got else 0.85
		if got:
			done += 1
	_count_label.text = "%d / %d" % [done, _rows.size()]
	_best_label.text = "All-time best  %d" % Progress.best_score
