extends Sprite
class_name GhostSprite

var fadeout_timer = 0;
var fadeout_timer_max = 1;
var target = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = lerp(self.position, target.position, 0.1);
	fadeout_timer += delta;
	if (fadeout_timer > fadeout_timer_max):
		queue_free();
	elif fadeout_timer < fadeout_timer_max/2:
		self.modulate.a = fadeout_timer*2/fadeout_timer_max;
	else:
		self.modulate.a = 1-(fadeout_timer*2-fadeout_timer_max/2)/fadeout_timer_max;
