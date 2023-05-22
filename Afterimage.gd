extends Node2D

var timer = 0;
var timer_max = 0.5;
var undo_color = null;
var actor = null;
var texture = null;

func initialize(actor: Sprite, undo_color: Color) -> void:
	self.actor = actor;
	self.undo_color = undo_color;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var child = self.get_child(0);
	child.centered = false;
	child.texture = texture;
	if (actor != null):
		child.hframes = actor.hframes;
		child.vframes = actor.vframes;
		child.frame = actor.frame;
		child.texture = actor.texture;
		self.position = actor.position;
	child.get_material().set_shader_param("color", undo_color);
	child.get_material().set_shader_param("mixture", 1.0);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta;
	if timer > timer_max:
		queue_free();
		return;
	else:
		modulate = Color(1, 1, 1, (timer_max-timer)/timer_max);
