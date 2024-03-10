extends Sprite
class_name TransitionToTheEnd

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;

func _ready() -> void:
	gamelogic.target_track = -1;
	gamelogic.fadeout_timer = 0.0;
	gamelogic.fadeout_timer_max = 1.0;
	gamelogic.play_sound("helixfixed");
	self.modulate = Color("#223c52");
	$AnimationPlayer.play("Animate");
	$AnimationPlayer.connect("animation_finished", self, "_animation_finished");

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

func _animation_finished(anim_name: String) -> void:
	gamelogic.ending_cutscene_2();
	destroy();

var sparkle_timer = 0.0;
func _process(delta: float) -> void:
	sparkle_timer += delta;
	if (sparkle_timer > 0.05):
		sparkle_timer -= 0.05;
		add_sparkle();

func add_sparkle() -> void:
	var rng = gamelogic.rng;
	var sprite = Sprite.new();
	sprite.set_script(preload("res://FadingSprite.gd"));
	sprite.texture = preload("res://assets/Sparkle.png")
	sprite.position = Vector2(gamelogic.rng.randf_range(0, gamelogic.pixel_width), gamelogic.rng.randf_range(0, gamelogic.pixel_height));
	sprite.frame = 0;
	sprite.centered = true;
	sprite.modulate = self.modulate;
	sprite.scale = self.scale/10;
	
	self.get_parent().add_child(sprite);
