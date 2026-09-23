class_name Ui
extends RefCounted

const INK := Color(1, 0.93, 0.98)
const INK_DARK := Color(0.4, 0.2, 0.45)
const PINK := Color(1, 0.6, 0.85)
const GOLD := Color(1, 0.8, 0.3)
const MINT := Color(0.7, 1, 0.8)

static func box(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb

static func style_button(button: Button, normal: Color, hover: Color, radius: int, margin: int) -> void:
	button.focus_mode = Control.FOCUS_NONE
	for style in ["normal", "focus"]:
		button.add_theme_stylebox_override(style, box(normal, radius, margin))
	for style in ["hover", "pressed"]:
		button.add_theme_stylebox_override(style, box(hover, radius, margin))

static func cloud_button(icon_name: String, size: float = 40.0) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(size, size)
	button.icon = load("res://art/%s.png" % icon_name)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	style_button(button, Color(1, 1, 1, 0.55), Color(1, 1, 1, 0.85), 8, 3)
	return button

static func label(text: String, color: Color, size: int = 8, center: bool = true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func title(text: String) -> Label:
	var l := label(text, PINK, 16, false)
	l.add_theme_color_override("font_shadow_color", Color(0.3, 0.1, 0.35, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

static func icon(texture: Texture2D, size: Vector2) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = size
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func keycap(key_name: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = load("res://art/key_%s.png" % key_name)
	rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func atlas(path: String, region: Rect2) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = load(path)
	tex.region = region
	return tex

static func portrait(cat_id: String) -> AtlasTexture:
	return atlas(Progress.texture_path(cat_id), Rect2(0, 0, 40, 28))

static func close_button(root: Control, at: Vector2) -> Button:
	var button := cloud_button("icon_close", 32.0)
	button.position = at
	root.add_child(button)
	return button
