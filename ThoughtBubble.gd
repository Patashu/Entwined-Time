extends Sprite
class_name ThoughtBubble

var frame_timer = 0;
var frame_timer_max = 0.4;
var poofing_in = true;
var poofing_out = false;
var rising = true;
var ticks = 10000;
# REFACTOR: same as in TimeBubble.gd
var time_colour = 0;
var time_colours = [Color("808080"), Color("B200FF"), Color("FF00DC"),
Color("FF0000"), Color("0094FF"), Color("A9F05F"), Color("404040"),
Color("00FFFF"), Color("FF6A00"), Color("FFD800")];
var label = null;

func poof_in() -> void:
	self.modulate.a = 0.95;
	label.modulate.a = 1;
	self.texture = preload("res://assets/PoofAwayThought1.png");
	poofing_in = true;
	poofing_out = false;
	rising = false;
	frame = 2;
	frame_timer = 0;
	
func poof_out() -> void:
	self.modulate.a = 0.95;
	label.modulate.a = 0;
	self.texture = preload("res://assets/PoofAwayThought1.png");
	poofing_in = false;
	poofing_out = true;
	rising = true;
	frame = 0;
	frame_timer = 0;

func nominal() -> void:
	self.modulate.a = 0.95;
	label.modulate.a = 1;
	self.texture = preload("res://assets/Thought1.png");
	poofing_in = false;
	poofing_out = false;
	rising = true;
	frame = 0;
	frame_timer = 0;
	
func hide() -> void:
	self.modulate.a = 0;
	label.modulate.a = 1;

func initialize(time_colour: int, ticks: int) -> void:
	self.time_colour = time_colour;
	self.ticks = ticks;
	self.hframes = 3;
	self.vframes = 1;
	label = Label.new();
	label.align = Label.ALIGN_CENTER;
	label.rect_position = Vector2(-24, -6);
	label.rect_size = Vector2(48, 24);
	self.add_child(label);
	label.text = str(self.ticks);
	label.theme = preload("res://DefaultTheme.tres");
	label.add_color_override("font_color", time_colours[time_colour]);
	#label.add_color_override("font_color_shadow", Color(0, 0, 0, 1));
	poof_in();
	
func update_ticks(ticks: int) -> void:
	self.ticks = ticks;
	label.text = str(self.ticks);

# Called when the node enters the scene tree for the first time.
#func _ready() -> void:
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frame_timer += delta;
	if (frame_timer > frame_timer_max):
		frame_timer -= frame_timer_max;
		if rising:
			if (frame < self.hframes - 1):
				frame += 1;
			else:
				if (poofing_out):
					hide();
				else:
					rising = false;
		else:
			if (frame > 0):
				frame -= 1;
			else:
				if (poofing_in):
					nominal();
				else:
					rising = true;
