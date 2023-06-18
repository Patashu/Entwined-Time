extends Sprite
class_name ThoughtBubble

var frame_timer = 0;
var frame_timer_max = 0.4;

enum State { In, Out, Nominal, Hide };

var state = State.Hide;

var rising = true;
var ticks = 10000;
# REFACTOR: same as in TimeBubble.gd
var time_colour = 0;
var time_colours = [Color("808080"), Color("B200FF"), Color("FF00DC"),
Color("FF0000"), Color("0094FF"), Color("A9F05F"), Color("404040"),
Color("00FFFF"), Color("FF6A00"), Color("FFD800"), Color("FFFFFF")];
var label = null;
var shadow_labels = [];
var alpha = 0.85;

func poof_in() -> void:
	if (state == State.In or state == State.Nominal):
		return;
	self.self_modulate.a = alpha;
	#label.modulate.a = 1;
	self.texture = preload("res://assets/PoofAwayThought1.png");
	state = State.In;
	rising = false;
	frame = 2;
	frame_timer = 0;
	
func poof_out() -> void:
	if (state == State.Out or state == State.Hide):
		return;
	self.self_modulate.a = alpha;
	#label.modulate.a = 1;
	self.texture = preload("res://assets/PoofAwayThought1.png");
	state = State.Out;
	rising = true;
	frame = 0;
	frame_timer = 0;

func nominal() -> void:
	self.self_modulate.a = alpha;
	#label.modulate.a = 1;
	self.texture = preload("res://assets/Thought1.png");
	state = State.Nominal;
	rising = true;
	frame = 0;
	frame_timer = 0;
	
func hide() -> void:
	self.self_modulate.a = 0;
	#label.modulate.a = 1;
	state = State.Hide;

func initialize(time_colour: int, ticks: int) -> void:
	self.time_colour = time_colour;
	self.ticks = ticks;
	self.hframes = 3;
	self.vframes = 1;
	
	var offsets = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT];
	
	for offset in offsets:
		var sl = Label.new();
		shadow_labels.append(sl);
		sl.align = Label.ALIGN_CENTER;
		sl.rect_position = Vector2(-24, -7) + offset;
		sl.rect_size = Vector2(48, 24);
		self.add_child(sl);
		sl.text = str(self.ticks);
		sl.theme = preload("res://DefaultTheme.tres");
		sl.add_color_override("font_color", Color(0, 0, 0, 1));
	
	label = Label.new();
	label.align = Label.ALIGN_CENTER;
	label.rect_position = Vector2(-24, -7);
	label.rect_size = Vector2(48, 24);
	self.add_child(label);
	label.text = str(self.ticks);
	label.theme = preload("res://DefaultTheme.tres");
	label.add_color_override("font_color", time_colours[time_colour]);
	#label.add_color_override("font_color_shadow", Color(0, 0, 0, 1));
	#label.add_constant_override("shadow_as_outline", 1);
	poof_in();
	
func update_ticks(ticks: int) -> void:
	self.ticks = ticks;
	label.text = str(self.ticks);
	for sl in shadow_labels:
		sl.text = label.text;

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
				if (state == State.Out):
					hide();
				else:
					rising = false;
		else:
			if (frame > 0):
				frame -= 1;
			else:
				if (state == State.In):
					nominal();
				else:
					rising = true;
