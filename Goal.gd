extends ActorBase
class_name Goal

var gamelogic = null;
var actorname = ""
var pos = Vector2.ZERO
var dinged = false;
var locked = false;
var animations = [];
var scalify_target = 0.1;
var scalify_current = 0.1;
var rotate_magnitude = 1;
var particle_timer = 1;
var particle_timer_max = 1;
var last_particle_angle = 0;
var facing_left = false; #dummied out

func lock() -> void:
	locked = true;
	modulate.r = 0.4;
	modulate.g = 0.4;
	modulate.b = 0.4;
	
func unlock() -> void:
	locked = false;
	modulate.r = 1;
	modulate.g = 1;
	modulate.b = 1;

func update_scalify_target() -> void:
	scalify_target = 0.1;
	if (actorname == Actor.Name.HeavyGoal):
		scalify_target *= 1.7;
	if (dinged and !locked):
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
	particle_timer += delta;
	if (particle_timer > particle_timer_max):
		var underactorsparticles = gamelogic.get_parent().get_node("UnderActorsParticles");
		particle_timer -= particle_timer_max;
		var sprite = Sprite.new();
		sprite.set_script(preload("res://GoalParticle.gd"));
		sprite.texture = self.texture;
		# use parent's position if we're a joke, our own otherwise
		if (self.get_parent() is Actor):
			sprite.position = self.get_parent().position + self.position;
		else:
			sprite.position = self.position;
		sprite.centered = true;
		sprite.rotation = gamelogic.rng.randf_range(0, 2*PI);
		sprite.rotate_magnitude = self.rotate_magnitude*4;
		sprite.alpha_max = 0.4;
		sprite.modulate = Color(modulate.r, modulate.g, modulate.b, 0);
		var next_particle_angle = last_particle_angle + 2*PI/6 + gamelogic.rng.randf_range(0, 2*PI*4/6)
		last_particle_angle = next_particle_angle;
		if (dinged):
			sprite.scale = scale / 3;
			particle_timer_max = 0.5;
			sprite.fadeout_timer_max = 2;
			sprite.velocity = Vector2(0, 18).rotated(next_particle_angle);
		else:
			sprite.scale = scale / 2.2;
			particle_timer_max = 1;
			sprite.fadeout_timer_max = 4;
			sprite.velocity = Vector2(0, 6).rotated(next_particle_angle);
		sprite.position -= sprite.velocity*sprite.fadeout_timer_max;
		underactorsparticles.add_child(sprite);
	
	# by cosmological coincidence this is roughly what I wanted!
	self.rotation += rotate_magnitude*delta;
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
