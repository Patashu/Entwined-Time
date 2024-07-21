extends Sprite
class_name TimelineDivider

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var timer = 0;
var is_active : bool = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (is_active):
		timer += delta;
		var shade = cos(timer*4)/4;
		self.modulate = Color(1.0+shade, 1.0+shade, 1.0+shade, 1.0);
