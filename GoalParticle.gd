extends Sprite
class_name GoalParticle

var fadeout_timer = 0;
var fadeout_timer_max = 1.0;
var rotate_magnitude = 0;
var velocity = Vector2.ZERO;
var alpha_max = 1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if rotate_magnitude != 0:
		self.rotation += rotate_magnitude*delta;
	if (velocity != Vector2.ZERO):
		position += velocity * delta;
	fadeout_timer += delta;
	if (fadeout_timer > fadeout_timer_max):
		queue_free();
	else:
		if (fadeout_timer < fadeout_timer_max / 2.0):
			self.modulate.a = alpha_max*(fadeout_timer/(fadeout_timer_max/2.0));
		else:
			self.modulate.a = alpha_max*(1-(fadeout_timer-(fadeout_timer_max/2.0))/(fadeout_timer_max/2.0));
