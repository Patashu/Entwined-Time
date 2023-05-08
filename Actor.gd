extends ActorBase
class_name Actor

var gamelogic = null
var actorname = ""
var pos = Vector2.ZERO
#var state = {}
var broken = false
var powered = false
var dinged = false;
# -1 for grounded, 0 for falling, 1+ for turns of coyote time left
var airborne = -1
var strength = 0
var heaviness = 0
var durability = 0
var fall_speed = -1
var climbs = false
var is_character = false
var time_colour = 0
var time_bubble = null
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
var frame_timer = 0;
var frame_timer_max = 0.1;
var post_mortem = -1;
# light fluster logic
var fluster_timer = 0;
var fluster_timer_max = 0;
# ding
var ding = null;

func update_graphics() -> void:
	var tex = get_next_texture();
	set_next_texture(tex);

func get_next_texture() -> Texture:
	# facing and powered modulate also automatically update here, since I want that to be instant
	
	# facing
	if facing_left:
		flip_h = true;
	else:
		flip_h = false;
	
	# powered
	if is_character and !is_ghost:
		if powered:
			self.modulate = Color(1, 1, 1, 1);
		else:
			self.modulate = Color(0.5, 0.5, 0.5, 1);
	elif (!is_character and !is_ghost):
		if dinged and ding == null:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://OneTimeSprite.gd"));
			sprite.texture = preload("res://assets/crate_goal_success.png");
			sprite.hframes = 10;
			sprite.centered = false;
			sprite.frame_max = 99;
			sprite.frame_timer_max = 0.05;
			self.add_child(sprite);
			ding = sprite;
		elif !dinged and ding != null:
			ding.queue_free();
			ding = null;
	
	# airborne, broken
	if actorname == "heavy":
		if broken:
			return preload("res://assets/heavy_broken.png");
		elif airborne >= 1:
			return preload("res://assets/heavy_rising.png");
		elif airborne == 0:
			return preload("res://assets/heavy_falling.png");
		else:
			if !powered:
				return preload("res://assets/heavy_unpowered.png");
			else:
				return preload("res://assets/heavy_idle.png");
	
	elif actorname == "light":
		if broken:
			return preload("res://assets/light_broken.png");
		elif airborne >= 1:
			return preload("res://assets/light_rising.png");
		elif airborne == 0:
			return preload("res://assets/light_falling.png");
		else:
			if !powered:
				return preload("res://assets/light_unpowered.png");
			else:
				return preload("res://assets/light_idle_animation.png");
	
	elif actorname == "iron_crate":
		if broken:
			return preload("res://assets/iron_crate_broken.png");
		else:
			return preload("res://assets/iron_crate.png");
	
	elif actorname == "steel_crate":
		if broken:
			return preload("res://assets/steel_crate_broken.png");
		else:
			return preload("res://assets/steel_crate.png");
	
	elif actorname == "power_crate":
		if broken:
			return preload("res://assets/power_crate_broken.png");
		else:
			return preload("res://assets/power_crate_animation.png");
			
	elif actorname == "wooden_crate":
		if broken:
			return preload("res://assets/wooden_crate_broken.png");
		else:
			return preload("res://assets/wooden_crate.png");
	
	return null;

func set_next_texture(tex: Texture) -> void:
	if (self.texture == tex):
		return;
	if (fluster_timer_max > 0):
		return;
	self.texture = tex;
	frame_timer = 0;
	frame = 0;
	if texture == preload("res://assets/heavy_broken.png"):
		frame_timer_max = 0.4;
		hframes = 8;
	elif texture == preload("res://assets/light_broken.png"):
		frame_timer_max = 0.4;
		hframes = 8;
	elif texture == preload("res://assets/light_rising.png"):
		frame_timer_max = 0.1;
		hframes = 6;
	elif texture == preload("res://assets/light_falling.png"):
		frame_timer_max = 0.1;
		hframes = 6;
	elif texture == preload("res://assets/light_idle_animation.png"):
		frame_timer_max = 0.1;
		hframes = 12;
	elif texture == preload("res://assets/power_crate_animation.png"):
		frame_timer_max = 0.1;
		hframes = 4;
	else:
		hframes = 1;

func fluster():
	if (broken):
		return;
	set_next_texture(preload("res://assets/light_involuntary_bump.png"))
	fluster_timer = 0;
	fluster_timer_max = 0.3;

func native_colour():
	if !is_character:
		return 0; #Gray
	return 1; #Purple

func is_native_colour():
	return native_colour() == time_colour;

func update_time_bubble():
	if is_native_colour():
		if time_bubble != null:
			time_bubble.queue_free();
			time_bubble = null;
	else:
		time_bubble = Sprite.new();
		time_bubble.set_script(preload("res://TimeBubble.gd"));
		time_bubble.texture = preload("res://assets/time_bubble.png");
		time_bubble.centered = true;
		time_bubble.time_colour = time_colour;
		time_bubble.position = Vector2(12, 12);
		self.add_child(time_bubble);
		time_bubble.time_bubble_colour()

# POST 'oh shit I have an infinite' gravity rules (AD07):
# (-1 fall speed is infinite. It's so infinite it breaks glass and keeps going!)
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
		return 99;
	return fall_speed;
	
func climbs() -> bool:
	return climbs and !broken;

func pushable() -> bool:
	if (broken):
		return is_character;
	return true;
		
func tiny_pushable() -> bool:
	return actorname == "key" and !broken;

func afterimage() -> void:
	gamelogic.afterimage(self);

func _process(delta: float) -> void:
	#fluster timer
	if fluster_timer_max > 0:
		fluster_timer += delta;
		if fluster_timer > fluster_timer_max:
			fluster_timer_max = 0;
			update_graphics();
	
	#animated sprites
	if hframes <= 1:
		pass
	else:
		frame_timer += delta;
		if (frame_timer > frame_timer_max):
			frame_timer -= frame_timer_max;
			if (frame == hframes - 1) and !broken:
				frame = 0;
			else:
				if broken and frame >= 4 and post_mortem != 1:
					pass
				elif frame < (hframes * vframes) - 1:
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
			var is_done = true;
			if (current_animation[0] == 0): #move
				# afterimage if it was a retro move
				if (animation_timer == 0 and current_animation[2]):
					afterimage();
				animation_timer_max = 0.083;
				position -= current_animation[1]*(animation_timer/animation_timer_max)*24;
				animation_timer += delta;
				if (animation_timer > animation_timer_max):
					position += current_animation[1]*1*24;
					# no rounding errors here! get rounded sucker!
					position.x = round(position.x); position.y = round(position.y);
				else:
					is_done = false;
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
				else:
					is_done = false;
					bump_amount = (animation_timer/animation_timer_max);
					if (bump_amount > 0.5):
						bump_amount = 1-bump_amount;
					bump_amount *= 0.2;
					position += current_animation[1]*bump_amount*24;
			elif (current_animation[0] == 2): #set_next_texture
				set_next_texture(current_animation[1]);
			elif (current_animation[0] == 3): #sfx
				gamelogic.play_sound(current_animation[1]);
			elif (current_animation[0] == 4): #fluster
				fluster();
			elif (current_animation[0] == 6): #trapdoor_opens
				var sprite = Sprite.new();
				sprite.set_script(preload("res://PingPongSprite.gd"));
				sprite.texture = preload("res://assets/trapdoor_animation_spritesheet.png");
				sprite.vframes = round(sprite.get_rect().size.y/24);
				sprite.hframes = round(sprite.get_rect().size.x/24);
				sprite.frame = 0;
				sprite.centered = false;
				sprite.frame_timer_max = 0.05;
				sprite.position = current_animation[1];
				self.get_parent().get_parent().get_node("UnderActorsParticles").add_child(sprite);
			elif (current_animation[0] == 7): #explode
				if (is_character):
					var overactorsparticles = self.get_parent().get_parent().get_node("OverActorsParticles");
					for i in range(10):
						var sprite = Sprite.new();
						sprite.set_script(preload("res://OneTimeSprite.gd"));
						sprite.texture = preload("res://assets/broken_explosion.png")
						sprite.position = position + Vector2(gamelogic.cell_size/2, gamelogic.cell_size/2);
						sprite.vframes = round(sprite.get_rect().size.y/24);
						sprite.hframes = round(sprite.get_rect().size.x/24);
						sprite.frame = 0;
						if (actorname == "heavy"):
							sprite.frame = 4;
						sprite.centered = true;
						sprite.scale = Vector2(0.5, 0.5);
						sprite.frame_max = sprite.frame + 4;
						sprite.frame_timer_max = 0.2;
						sprite.velocity = Vector2(gamelogic.rng.randf_range(-48, 48), gamelogic.rng.randf_range(-48, 48));
						overactorsparticles.add_child(sprite);
			elif (current_animation[0] == 8): #shatter
				var overactorsparticles = self.get_parent().get_parent().get_node("OverActorsParticles");
				for i in range(4):
					var sprite = Sprite.new();
					sprite.set_script(preload("res://FadingSprite.gd"));
					if (current_animation[2] == 46):
						sprite.texture = preload("res://assets/green_glass_block.png")
					elif (current_animation[2] == 51):
						sprite.texture = preload("res://assets/one_undo.png")
					else:
						sprite.texture = preload("res://assets/glass_block.png")
					sprite.position = current_animation[1] + Vector2(gamelogic.cell_size/2, gamelogic.cell_size/2);
					sprite.position.x += -6+(i%2)*12;
					sprite.position.y += -6+floor(i/2)*12;
					sprite.centered = true;
					sprite.scale = Vector2(0.5, 0.5);
					sprite.velocity = Vector2(gamelogic.rng.randf_range(0, 48), gamelogic.rng.randf_range(0, 48));
					if (i % 2 == 0):
						sprite.velocity.x *= -1;
					if (floor(i / 2) == 0):
						sprite.velocity.y *= -1;
					overactorsparticles.add_child(sprite);
				gamelogic.play_sound("shatter");
			elif (current_animation[0] == 9): #unshatter
				var overactorsparticles = self.get_parent().get_parent().get_node("OverActorsParticles");
				for i in range(4):
					var sprite = Sprite.new();
					sprite.set_script(preload("res://FadingSprite.gd"));
					sprite.texture = preload("res://assets/glass_block.png")
					sprite.position = current_animation[1] + Vector2(gamelogic.cell_size/2, gamelogic.cell_size/2);
					sprite.position.x += -6+(i%2)*12;
					sprite.position.y += -6+floor(i/2)*12;
					sprite.centered = true;
					sprite.scale = Vector2(0.5, 0.5);
					sprite.velocity = Vector2(gamelogic.rng.randf_range(0, 48), gamelogic.rng.randf_range(0, 48));
					if (i % 2 == 0):
						sprite.velocity.x *= -1;
					if (floor(i / 2) == 0):
						sprite.velocity.y *= -1;
					sprite.position += sprite.velocity;
					sprite.velocity = -sprite.velocity;
					overactorsparticles.add_child(sprite);
				gamelogic.play_sound("unshatter");
			elif (current_animation[0] == 10): #afterimage_at
				gamelogic.afterimage_terrain(current_animation[1], current_animation[2], current_animation[3]);
			if (is_done):
				animations.pop_front();
				animation_timer = 0;
		
