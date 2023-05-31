extends Sprite
class_name StarSprite

var previous_modulate = Color(1, 1, 1, 0);
var next_modulates = [];
var flash_timer = 0;
var flash_timer_max = 1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if next_modulates.size() > 0:
		var next_modulate = next_modulates[0];
		flash_timer += delta;
		if (flash_timer > flash_timer_max):
			flash_timer -= flash_timer_max;
			modulate = next_modulate;
			previous_modulate = modulate;
			next_modulates.pop_front();
		else:
			var current_r = lerp(previous_modulate.r, next_modulate.r, flash_timer/flash_timer_max);
			var current_g = lerp(previous_modulate.g, next_modulate.g, flash_timer/flash_timer_max);
			var current_b = lerp(previous_modulate.b, next_modulate.b, flash_timer/flash_timer_max);
			var current_a = lerp(previous_modulate.a, next_modulate.a, flash_timer/flash_timer_max);
			modulate = Color(current_r, current_g, current_b, current_a);

func finish_animations() -> void:
	next_modulates.clear();
	modulate = Color(1, 1, 1, 1);

func flash() -> void:
	flash_timer = 0;
	next_modulates.clear();
	modulate = Color(1, 1, 1, 0);
	previous_modulate = modulate;
	next_modulates.append(Color(2, 2, 2, 1));
	next_modulates.append(Color(1, 1, 1, 1));
		
