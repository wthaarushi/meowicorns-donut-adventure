extends Node

const DEFAULTS := {
	"left": [KEY_A, KEY_LEFT],
	"right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE, KEY_W, KEY_UP],
	"duck": [KEY_S, KEY_DOWN],
	"restart": [KEY_R],
	"settings": [KEY_M, KEY_ESCAPE],
	"shop": [KEY_B, KEY_TAB],
	"help": [KEY_H],
}

func _ready() -> void:
	for action in DEFAULTS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		if InputMap.action_get_events(action).is_empty():
			for key in DEFAULTS[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)
