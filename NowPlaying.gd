extends Label
class_name NowPlaying

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var in_timer = 0;
var in_timer_max = 3.0;
var hold_timer = 0;
var hold_timer_max = 3.0;
var out_timer = 0;
var out_timer_max = 3.0;
var destination_x = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func initialize(textt: String) -> void:
	self.text = "o/` " + textt;
	self.modulate = Color(0, 0, 0, 0);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (destination_x == 0):
		self.modulate = Color(1, 1, 1, 1);
		self.rect_position.x = 512-self.rect_size.x-32; # -32 is a magic number for spacing
		destination_x = self.rect_position.x;
		self.rect_position.x += self.rect_size.x;
	
	if (in_timer < in_timer_max):
		in_timer += delta;
		self.rect_position.x = lerp(self.rect_position.x, destination_x, 1*delta);
	elif (hold_timer < hold_timer_max):
		hold_timer += delta;
	elif (out_timer < out_timer_max):
		#self.modulate = Color(1, 1, 1, (out_timer_max-out_timer)/(out_timer_max));
		self.rect_position.x += 100*delta;
	else:
		self.queue_free();
