extends Node2D
class_name Shade

var alpha = 0;
var on = false;

func _process(delta: float) -> void:
	if (on):
		alpha += delta/10;
		alpha = min(0.5, alpha);
	elif alpha > 0:
		alpha = 0;
	update();

func _draw():
	if (alpha > 0):
		draw_rect(Rect2(0, 0, get_viewport().size.x, get_viewport().size.y), Color(0, 0, 0, alpha), true);
