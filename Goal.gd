extends ActorBase
class_name Goal

var actorname = ""
var pos = Vector2.ZERO
var dinged = false;
var animations = [];
var scalify_target = 0.1;
var scalify_current = 0.1;

func update_scalify_target() -> void:
	scalify_target = 0.1;
	if (actorname == "heavy_goal"):
		scalify_target *= 1.7;
	if (dinged):
		scalify_target *= 2;

func instantly_reach_scalify() -> void:
	update_scalify_target();
	scalify_current = scalify_target;
	scale = Vector2(scalify_current, scalify_current);

func update_graphics() -> void:
	update_scalify_target();
	
func get_next_texture() -> Texture:
	return texture
	
func set_next_texture(tex: Texture) -> void:
	pass

func _process(delta: float) -> void:
	# by cosmological coincidence this is roughly what I wanted!
	self.rotation += delta;
	# scale
	if (scalify_target != scalify_current):
		if (scalify_current < scalify_target):
			# again by cosmological coincidence it's perfect
			scalify_current += delta;
			if (scalify_current > scalify_target):
				scalify_current = scalify_target;
		else:
			scalify_current -= delta;
			if (scalify_current < scalify_target):
				scalify_current = scalify_target;
		scale = Vector2(scalify_current, scalify_current);
	
	if (animations.size() > 0):
		var current_animation = animations[0];
		var is_done = true;
		if (current_animation[0] == 2): #set_next_texture
			update_graphics();
		if (is_done):
			animations.pop_front();
