extends Label
class_name GoldLabel

var previous_modulate = Color("FFE100");
var next_modulates = [];
var flash_timer = 0;
var flash_timer_max = 0.5;
var mundane_color = null;

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
			self.add_color_override("font_color", next_modulate);
			previous_modulate = next_modulate;
			next_modulates.pop_front();
		else:
			var current_r = lerp(previous_modulate.r, next_modulate.r, flash_timer/flash_timer_max);
			var current_g = lerp(previous_modulate.g, next_modulate.g, flash_timer/flash_timer_max);
			var current_b = lerp(previous_modulate.b, next_modulate.b, flash_timer/flash_timer_max);
			var current_a = lerp(previous_modulate.a, next_modulate.a, flash_timer/flash_timer_max);
			self.add_color_override("font_color", Color(current_r, current_g, current_b, current_a));

func finish_animations() -> void:
	set_process(false);
	next_modulates.clear();
	if (mundane_color != null):
		self.add_color_override("font_color", mundane_color)

func flash() -> void:
	mundane_color = get_color("font_color", "Label");
	set_process(true);
	flash_timer = 0;
	next_modulates.clear();
	self.add_color_override("font_color", Color("FFE100"))
	previous_modulate = Color("FFE100");
	next_modulates.append(Color(1, 1, 1, 1));
	next_modulates.append(Color("FFE100"));
		
