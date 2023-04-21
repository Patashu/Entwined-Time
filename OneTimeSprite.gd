extends Sprite
class_name OneTimeSprite

var frame_timer = 0;
var frame_timer_max = 0.1;
var frame_max = 0;
var velocity = Vector2.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (velocity != Vector2.ZERO):
		position += velocity * delta;
	frame_timer += delta;
	if (frame_timer > frame_timer_max):
		frame_timer -= frame_timer_max;
		if (frame == frame_max - 1):
			queue_free();
		elif frame < (hframes * vframes) - 1:
			frame += 1;
