extends Sprite
class_name PingPongSprite

var frame_timer = 0;
var frame_timer_max = 0.1;
var has_ping_ponged = false;
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
		if !has_ping_ponged:
			if frame == (hframes * vframes) - 1:
				has_ping_ponged = true;
			elif frame < (hframes * vframes) - 1:
				frame += 1;
		if has_ping_ponged:
			if frame == 0:
				queue_free();
			else:
				frame -= 1;
