extends ColorRect


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var timer = 2.5;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer -= delta;
	self.modulate = Color(1, 1, 1, timer/2.5);
	if (timer < 0):
		queue_free();
