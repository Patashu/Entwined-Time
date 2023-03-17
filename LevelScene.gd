extends Node2D
class_name LevelScene

onready var gamelogic : GameLogic = self.get_node("GameLogic");
var last_delta = 0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.undo_effect_strength > 0):
		last_delta = delta;
		update();

func _draw():
	if (gamelogic.undo_effect_strength > 0):
		gamelogic.undo_effect_color.a = gamelogic.undo_effect_strength;
		draw_rect(Rect2(0, 0, get_viewport().size.x, get_viewport().size.y), gamelogic.undo_effect_color, true);
	gamelogic.undo_effect_strength -= gamelogic.undo_effect_per_second*last_delta;
