extends Node2D
class_name SparkleSpawner

var sparkle_timer = 0;
var sparkle_timer_max = 0.1;
var end = 1;
var color = Color(1, 1, 1, 1);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var parent = self.get_parent();
	var old_times = floor(sparkle_timer/sparkle_timer_max);
	sparkle_timer += delta;
	var new_times = floor(sparkle_timer/sparkle_timer_max);
	if (old_times != new_times):
		# one sparkle
		var sprite = Sprite.new();
		sprite.set_script(preload("res://FadingSprite.gd"));
		sprite.texture = preload("res://assets/Sparkle.png")
		sprite.position = parent.offset + Vector2(parent.gamelogic.rng.randf_range(-12, 12), parent.gamelogic.rng.randf_range(-12, 12));
		sprite.frame = 0;
		sprite.centered = true;
		sprite.scale = Vector2(0.25, 0.25);
		sprite.modulate = color;
		parent.add_child(sprite)
	if (sparkle_timer > end):
		queue_free();
