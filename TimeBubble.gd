extends Sprite
class_name TimeBubble

var timer = 0;
var time_colour = 5;
# PERF: static/global/const or something
var time_colours = [Color("808080"), Color("B200FF"), Color("FF00DC"),
Color("FF0000"), Color("0094FF"), Color("A9F05F"), Color("404040"),
Color("00FFFF"), Color("FF6A00"), Color("FFD800"), Color("FFFFFF")];
var label = null;

enum TimeColour {
	Gray,
	Purple,
	Magenta,
	Red,
	Blue,
	Green,
	Void,
	Cyan,
	Orange,
	Yellow,
	White,
}

func time_bubble_colour() -> void:
	var c = time_colours[time_colour];
	var coeff = 0.5+(1+sin(timer*2.5))/4;
	var current_r = lerp(0, c.r, coeff);
	var current_g = lerp(0, c.g, coeff);
	var current_b = lerp(0, c.b, coeff);
	self.modulate = Color(current_r, current_g, current_b);

func setup_colourblind_mode(value : bool) -> void:
	if (value and label == null):
		label = OutlinedLabel.new();
		self.add_child(label);
		label.set_align(Label.ALIGN_CENTER);
		if (get_parent().ticks != 0):
			label.set_rect_position(Vector2(-24, -19));
		else:
			label.set_rect_position(Vector2(-24, -24));
		label.set_rect_size(Vector2(48, 24));
		label.change_text(TimeColour.keys()[time_colour]);
	elif (!value and label != null):
		label.queue_free();
		label = null;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta;
	time_bubble_colour();
