extends Node
class_name TurnToggler

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;
var timer = 0;
var timer_max = 0.25;
var meta_turn = 0;
var sprites = [preload("res://assets/turn_toggle_1.png"),
preload("res://assets/turn_toggle_2.png"),
preload("res://assets/turn_toggle_3.png"),
preload("res://assets/turn_toggle_4.png"),
preload("res://assets/turn_toggle_5.png")];

func _process(delta: float) -> void:
	timer += delta;
	var timer_clamped = clamp(timer, 0, timer_max);
	var index = ceil((timer_clamped/timer_max) * (sprites.size() - 1));
	var index_2 = sprites.size() - index;
	if (meta_turn % 2 == 1):
		var temp = index;
		index = index_2;
		index_2 = temp;
	gamelogic.terrainmap.tile_set.tile_set_texture(LevelEditor.Tiles.PhaseWallGreenOdd, sprites[index]);
	gamelogic.terrainmap.tile_set.tile_set_texture(LevelEditor.Tiles.PhaseWallGreenEven, sprites[index_2]);
	if (timer >= timer_max):
		queue_free();
