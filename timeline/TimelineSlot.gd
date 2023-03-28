extends Sprite
class_name TimelineSlot

var undo_effect_strength = 0;
var undo_effect_loss_per_second = 0.5;
var undo_effect_color = Color(1, 1, 1, 1);
onready var timelinesymbols : Node2D = get_node("TimelineSymbols");
onready var overlay : Sprite = get_node("Overlay");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func fill(buffer: Array) -> void:
	pass

func clear(color: Color) -> void:
	for sprite in timelinesymbols.get_children():
		sprite.queue_free();
	undo_effect_color = color;
	undo_effect_strength = 0.5;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (undo_effect_strength > 0):
		undo_effect_strength -= delta*undo_effect_loss_per_second;
		if (undo_effect_strength > 0):
			overlay.modulate = Color(undo_effect_color.r, undo_effect_color.g, undo_effect_color.b, undo_effect_strength);
		else:
			overlay.modulate = Color(1, 1, 1, 0);
