extends Node2D

var timer = 0;
var timer_max = 0.5;
var actor = null;
var texture = null;
var material_temp = null;

func initialize(actor: Sprite, undo_color: Color) -> void:
	self.actor = actor;

func set_material(material: Material) -> void:
	material_temp = material;

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
		child.flip_h = actor.flip_h;
		self.position = actor.position;
	if (material_temp != null):
		child.material = material_temp;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta;
	if timer > timer_max:
		queue_free();
		return;
	else:
		modulate = Color(1, 1, 1, (timer_max-timer)/timer_max);
