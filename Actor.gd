extends Sprite
class_name Actor

var actorname = ""
var pos = Vector2.ZERO
var state = {}
var broken = false
var powered = false
# -1 for grounded, 0 for falling, 1+ for turns of coyote time left
var airborne = -1
var strength = 0
var heaviness = 0
var durability = 0
var fall_speed = -1
var climbs = false
var is_character = false
# undo trails logic
var is_ghost = false
var next_ghost = null;
var previous_ghost = null;
var ghost_index = 0;
var ghost_dir = Vector2.ZERO;
var ghost_timer = 0;
var ghost_timer_max = 2;
var color = Color(1, 1, 1, 1);
# animation system logic
var animation_timer = 0;
var animation_timer_max = 0.05;
var animations = [];
var facing_left = false;
# animated sprites logic
var timer = 0;
var timer_max = 0.1;

func update_graphics() -> void:
	# TODO: when we build the animation server, we need this function to instead return a dictionary of properties to set
	# facing
	if facing_left:
		flip_h = true;
	else:
		flip_h = false;
	# powered
	if is_character:
		# this will get overriden by undo trail modulation for ghosts, which is perfectly fine by me
		if powered:
			self.modulate = Color(1, 1, 1, 1);
		else:
			self.modulate = Color(0.25, 0.25, 0.25, 1);
	# airborne, broken
	if actorname == "heavy":
		if broken:
			self.texture = preload("res://assets/heavy_broken.png");
		elif airborne >= 1:
			self.texture = preload("res://assets/heavy_rising.png");
		elif airborne == 0:
			self.texture = preload("res://assets/heavy_falling.png");
		else:
			self.texture = preload("res://assets/heavy_idle.png");
	elif actorname == "light":
		if broken:
			timer = 0;
			hframes = 1;
			frame = 0;
			self.texture = preload("res://assets/light_broken.png");
		elif airborne >= 1:
			timer = 0;
			hframes = 7;
			frame = 0;
			self.texture = preload("res://assets/light_rising.png");
		elif airborne == 0:
			timer = 0;
			hframes = 7;
			frame = 0;
			self.texture = preload("res://assets/light_falling.png");
		else:
			timer = 0;
			hframes = 13;
			frame = 0;
			self.texture = preload("res://assets/light_idle_animation.png");
	elif actorname == "iron_crate":
		if broken:
			self.texture = preload("res://assets/iron_crate_broken.png");
		else:
			self.texture = preload("res://assets/iron_crate.png");
	elif actorname == "steel_crate":
		if broken:
			self.texture = preload("res://assets/steel_crate_broken.png");
		else:
			self.texture = preload("res://assets/steel_crate.png");
	elif actorname == "power_crate":
		if broken:
			self.texture = preload("res://assets/power_crate_broken.png");
		else:
			self.texture = preload("res://assets/power_crate.png");

# POST 'oh shit I have an infinite' gravity rules (AD07):
# (-1 fall speed is infinite.)
# If fall speed is 0, airborne rules are ignored (WIP).
# If fall speed is 1, state becomes airborne 2 when it jumps, 1 when it stops being airborne for any other reasn.
# If fall speed is 2 or higher, state becomes airborne 2 when it jumps, and airborne 0 when it stops being over ground
# for any other reason.
# If fall speed is 1, actor may move sideways at airborne 1 or 0 freely,
# but not upwards unless grounded.
# If fallspeed is 2 or higher, actor may move sideways at airborne 1 and in no direction at airborne 0.
# (A forbidden direction is a null move and passes time.)
func fall_speed() -> int:
	if broken:
		return -1;
	return fall_speed;
	
func climbs() -> bool:
	return climbs and !broken;

func pushable() -> bool:
	if (broken):
		return is_character;
	return true;
		
func tiny_pushable() -> bool:
	return actorname == "key" and !broken;

func _process(delta: float) -> void:
	#animated sprites
	if hframes <= 1:
		pass
	else:
		timer += delta;
		if (timer > timer_max):
			timer -= timer_max;
			if (frame == hframes - 1):
				frame = 0;
			else:
				frame += 1;
	if (is_ghost):
		# undo previous position change
		# and fix rounding errors creeping in by, well, rounding
		position -= ghost_dir*(ghost_timer/ghost_timer_max)*24;
		position.x = round(position.x); position.y = round(position.y);
		ghost_timer += delta;
		if (ghost_timer > ghost_timer_max):
			ghost_timer -= ghost_timer_max;
		# do new position change
		position += ghost_dir*(ghost_timer/ghost_timer_max)*24;
		# modulate
		if (ghost_timer < ghost_timer_max/2):
			self.modulate = Color(1, 1, 1, 2*ghost_timer/ghost_timer_max);
		else:
			self.modulate = Color(1, 1, 1, 2*(ghost_timer_max-ghost_timer)/ghost_timer_max);
	else:
		# animation system stuff
		if (animations.size() > 0):
			var current_animation = animations[0];
			if (current_animation[0] == 0): #move
				animation_timer_max = 0.083;
				position -= current_animation[1]*(animation_timer/animation_timer_max)*24;
				animation_timer += delta;
				if (animation_timer > animation_timer_max):
					position += current_animation[1]*1*24;
					# no rounding errors here! get rounded sucker!
					position.x = round(position.x); position.y = round(position.y);
					animations.pop_front();
					animation_timer -= animation_timer_max;
					# I think ideally we'd be part-way-through the next move but ugh I don't want to write this
					# so ACTUALLY I'm just going to do this LMAO
					animation_timer = 0;
				else:
					position += current_animation[1]*(animation_timer/animation_timer_max)*24;
			elif (current_animation[0] == 1): #bump
				animation_timer_max = 0.1;
				var bump_amount = (animation_timer/animation_timer_max);
				if (bump_amount > 0.5):
					bump_amount = 1-bump_amount;
				bump_amount *= 0.2;
				position -= current_animation[1]*bump_amount*24;
				animation_timer += delta;
				if (animation_timer > animation_timer_max):
					position.x = round(position.x); position.y = round(position.y);
					animations.pop_front();
					animation_timer -= animation_timer_max;
					animation_timer = 0;
				else:
					bump_amount = (animation_timer/animation_timer_max);
					if (bump_amount > 0.5):
						bump_amount = 1-bump_amount;
					bump_amount *= 0.2;
					position += current_animation[1]*bump_amount*24;
		
