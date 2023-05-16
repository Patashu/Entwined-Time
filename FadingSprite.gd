extends Sprite
class_name FadingSprite

var fadeout_timer = 0;
var fadeout_timer_max = 1;
var velocity = Vector2.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (velocity != Vector2.ZERO):
		position += velocity * delta;
	fadeout_timer += delta;
	if (fadeout_timer > fadeout_timer_max):
		queue_free();
	else:
		self.modulate.a = 1-fadeout_timer/fadeout_timer_max;
