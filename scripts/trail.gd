extends Line2D

const MAX_POINTS := 40

@onready var player: Player = get_node("../Player")

func _process(_delta: float) -> void:
	if player.flying:
		add_point(player.global_position + Vector2(-12.0, 4.0))
		while get_point_count() > MAX_POINTS:
			remove_point(0)
	else:
		for i in range(mini(2, get_point_count())):
			remove_point(0)
