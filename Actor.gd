extends ActorBase
class_name Actor

var gamelogic = null
var actorname = -1
var stored_position = Vector2.ZERO
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
var ghost_alpha = 1.0;
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
# crystal effects
var is_crystal = false;
var crystal_timer = 0;
var crystal_timer_max = 1.6;
# cuckoo clock
var ticks = 1000;
var thought_bubble = null;
var ripple = null;
var ripple_timer = 0;
var ripple_timer_max = 1;
# night and stars
var in_night = false;
var in_stars = false;
# transient multi-push/multi-fall state:
# basically, things that move become non-colliding until the end of the multi-push/fall tick they're
# a part of, so other things that shared their tile can move with them
var just_moved = false;
# joke goals logic
var joke_goal = null;
# action lines!
var action_lines_timer = 0;
var action_lines_timer_max = 0.25;

# faster than string comparisons
enum Name {
	Heavy,
	Light,
	HeavyGoal,
	LightGoal,
	IronCrate,
	SteelCrate,
	WoodenCrate,
	PowerCrate,
	TimeCrystalGreen,
	TimeCrystalMagenta,
	CuckooClock,
	ChronoHelixRed,
	ChronoHelixBlue,
	HeavyGoalJoke,
	LightGoalJoke,
}

func update_graphics() -> void:
	var tex = get_next_texture();
	set_next_texture(tex, facing_left);
	if (thought_bubble != null):
		thought_bubble.update_ticks(ticks);
	update_grayscale(in_night);
	if (is_ghost and actorname == Name.HeavyGoalJoke):
		texture = preload("res://assets/BigPortalRed.png");
		offset = Vector2(12, 12)/0.1;
		scale = Vector2(0.1, 0.1);
	elif (is_ghost and actorname == Name.LightGoalJoke):
		texture = preload("res://assets/BigPortalBlue.png");
		offset = Vector2(12, 12)/0.1;
		scale = Vector2(0.1, 0.1);

func get_next_texture() -> Texture:
	# powered modulate also update here, since I want that to be instant
	
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
	if actorname == Name.Heavy:
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
	
	elif actorname == Name.Light:
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
	
	elif actorname == Name.IronCrate:
		if broken:
			return preload("res://assets/iron_crate_broken.png");
		else:
			return preload("res://assets/iron_crate.png");
	
	elif actorname == Name.SteelCrate:
		if broken:
			return preload("res://assets/steel_crate_broken.png");
		else:
			return preload("res://assets/steel_crate.png");
	
	elif actorname == Name.PowerCrate:
		if broken:
			return preload("res://assets/power_crate_broken.png");
		else:
			return preload("res://assets/power_crate_animation.png");
			
	elif actorname == Name.WoodenCrate:
		if broken:
			return preload("res://assets/wooden_crate_broken.png");
		else:
			return preload("res://assets/wooden_crate.png");
			
	elif actorname == Name.CuckooClock:
		if ticks == 0:
			return preload("res://assets/cuckoo_clock_end.png");
		elif broken:
			return preload("res://assets/cuckoo_clock_broken.png");
		else:
			return preload("res://assets/cuckoo_clock.png");
			
	elif actorname == Name.TimeCrystalGreen:
		if broken:
			return null;
		else:
			return preload("res://assets/timecrystalgreen.png");
			
	elif actorname == Name.TimeCrystalMagenta:
		if broken:
			return null;
		else:
			return preload("res://assets/timecrystalmagenta.png");
			
	elif actorname == Name.ChronoHelixBlue:
		return preload("res://assets/chrono_helix_blue.png");
	elif actorname == Name.ChronoHelixRed:
		return preload("res://assets/chrono_helix_red.png");
	
	return null;

func set_next_texture(tex: Texture, facing_left_at_the_time: bool) -> void:
	# facing updates here, even if the texture didn't change
	if facing_left_at_the_time:
		flip_h = true;
	else:
		flip_h = false;
	
	if (self.texture == tex):
		return;
	if (fluster_timer_max > 0):
		return;
		
	if tex == null:
		visible = false;
	elif self.texture == null:
		visible = true;
		
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
	elif texture == preload("res://assets/cuckoo_clock_end.png"):
		frame_timer_max = 0.4;
		hframes = 3;
	else:
		hframes = 1;
		
	if (thought_bubble != null):
		if broken:
			thought_bubble.poof_out();
		else:
			thought_bubble.poof_in();

func fluster():
	if (broken):
		return;
	set_next_texture(preload("res://assets/light_involuntary_bump.png"), facing_left)
	fluster_timer = 0;
	fluster_timer_max = 0.3;

func native_colour():
	if (is_crystal):
		return 6; #Green
	if (actorname == Name.Heavy):
		return 1; #Purple
	if (actorname == Name.Light):
		return 2; #Blurple
	return 0; 

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
		
func setup_colourblind_mode(value: bool) -> void:
	if time_bubble != null:
		time_bubble.setup_colourblind_mode(value);

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
	if broken and !is_crystal:
		return 99;
	return fall_speed;
	
# because I want Light to float but not cuckoo clocks <w<
func floats() -> bool:
	return fall_speed() == 1 and is_character;
	
func climbs() -> bool:
	return climbs and !broken;

func pushable() -> bool:
	if (just_moved):
		return false;
	if (broken):
		return is_character;
	return true;
		
func phases_into_terrain() -> bool:
	if actorname == Name.HeavyGoalJoke or actorname == Name.LightGoalJoke:
		return true;
	return false;
	
func phases_into_actors() -> bool:
	if actorname == Name.HeavyGoalJoke or actorname == Name.LightGoalJoke:
		return true;
	return false;
		
#func tiny_pushable() -> bool:
#	if (just_moved):
#		return false;
#	return actorname == "key" and !broken;

func afterimage() -> void:
	gamelogic.afterimage(self);
	
func update_ticks(ticks: int) -> void:
	self.ticks = ticks;
	if (thought_bubble == null):
		set_ticks(ticks);
	
func set_ticks(ticks: int) -> void:
	self.ticks = ticks;
	# thought bubble
	thought_bubble = Sprite.new();
	thought_bubble.set_script(preload("res://ThoughtBubble.gd"));
	thought_bubble.initialize(self.time_colour, self.ticks);
	thought_bubble.position = Vector2(12, -12);
	self.add_child(thought_bubble);

func update_grayscale(yes: bool) -> void:
	if yes and self.material == null:
		self.material = preload("res://GrayscaleMaterial.tres");
	elif !yes and self.material != null:
		self.material = null;

func _process(delta: float) -> void:
	#action lines
	if (!is_ghost and is_character and airborne != -1):
		action_lines_timer += delta;
		if (action_lines_timer > action_lines_timer_max):
			action_lines_timer -= action_lines_timer_max;
			var sprite = Sprite.new();
			sprite.set_script(preload("res://GoalParticle.gd"));
			if (actorname == Name.Heavy):
				sprite.texture = preload("res://assets/action_line_heavy.png");
			else:
				sprite.texture = preload("res://assets/action_line_light.png");
			sprite.position = self.position;
			sprite.position.x += gamelogic.rng.randf_range(0, gamelogic.cell_size);
			sprite.position.y += gamelogic.rng.randf_range(0, gamelogic.cell_size/2);
			if (airborne == 0):
				sprite.velocity = Vector2(0, -24);
			else:
				sprite.velocity = Vector2(0, 24);
				sprite.position.y += gamelogic.cell_size/2;
			sprite.centered = true;
			sprite.rotate_magnitude = 0;
			sprite.alpha_max = 1;
			sprite.modulate = self.modulate;
			sprite.modulate.a = 0;
			sprite.fadeout_timer_max = 0.75;
			gamelogic.overactorsparticles.add_child(sprite);
	
	#crystal effects
	if (is_crystal):
		var old_times = floor(crystal_timer/crystal_timer_max);
		crystal_timer += delta;
		var new_times = floor(crystal_timer/crystal_timer_max);
		if (old_times != new_times):
			# one sparkle
			var sprite = Sprite.new();
			sprite.set_script(preload("res://FadingSprite.gd"));
			sprite.texture = preload("res://assets/Sparkle.png")
			sprite.position = self.offset + Vector2(gamelogic.rng.randf_range(-6, 6), gamelogic.rng.randf_range(-6, 6));
			sprite.frame = 0;
			sprite.centered = true;
			sprite.scale = Vector2(0.25, 0.25);
			sprite.modulate = color;
			self.add_child(sprite)
		#bob up and down
		self.offset = Vector2(12, 12+3*sin(crystal_timer));
	
	#ripple
	if (ripple != null):
		ripple_timer += delta;
		if (ripple_timer > ripple_timer_max):
			ripple.queue_free();
			ripple = null;
		else:
			ripple.get_material().set_shader_param("height", ((ripple_timer_max-ripple_timer)/ripple_timer_max)*0.003);
			#child.get_material().set_shader_param("color", undo_color);
			#child.get_material().set_shader_param("mixture", 1.0);
	
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
			if (frame == hframes - 1) and !broken and ticks != 0:
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
			self.modulate = Color(1, 1, 1, 2*ghost_alpha*ghost_timer/ghost_timer_max);
		else:
			self.modulate = Color(1, 1, 1, 2*ghost_alpha*(ghost_timer_max-ghost_timer)/ghost_timer_max);
	else:
		# animation system stuff
		if (animations.size() > 0):
			var current_animation = animations[0];
			var is_done = true;
			if (current_animation[0] == 0): #move
				# afterimage if it was a retro move
				if (animation_timer == 0):
					gamelogic.broadcast_animation_nonce(current_animation[3]);
					if current_animation[2]:
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
				if (animation_timer == 0):
					gamelogic.broadcast_animation_nonce(current_animation[2]);
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
				set_next_texture(current_animation[1], current_animation[3]);
				gamelogic.broadcast_animation_nonce(current_animation[2]);
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
						if (actorname == Name.Heavy):
							sprite.frame = 4;
						sprite.centered = true;
						sprite.scale = Vector2(0.5, 0.5);
						sprite.frame_max = sprite.frame + 4;
						sprite.frame_timer_max = 0.2;
						sprite.velocity = Vector2(gamelogic.rng.randf_range(-48, 48), gamelogic.rng.randf_range(-48, 48));
						overactorsparticles.add_child(sprite);
			elif (current_animation[0] == 8): #shatter
				var overactorsparticles = self.get_parent().get_parent().get_node("OverActorsParticles");
				gamelogic.broadcast_animation_nonce(current_animation[4]);
				for i in range(4):
					var sprite = Sprite.new();
					sprite.set_script(preload("res://FadingSprite.gd"));
					if (current_animation[2] == 46):
						sprite.texture = preload("res://assets/green_glass_block.png")
					elif (current_animation[2] == 51):
						sprite.texture = preload("res://assets/one_undo.png")
					elif (current_animation[2] == 69):
						sprite.texture = preload("res://assets/glass_block_cracked.png")
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
				gamelogic.broadcast_animation_nonce(current_animation[4]);
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
			elif (current_animation[0] == 11): #fade
				animation_timer_max = 3;
				animation_timer += delta;
				if (animation_timer > animation_timer_max):
					self.modulate.a = 0;
				else:
					is_done = false;
					self.modulate.a = 1-(animation_timer/animation_timer_max);
			elif (current_animation[0] == 12): #heavy_green_time_crystal_raw
				var color = current_animation[1].color;
				gamelogic.heavytimeline.add_max_turn();
				gamelogic.timeline_squish();
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 13): #light_green_time_crystal_raw
				var color = current_animation[1].color;
				gamelogic.lighttimeline.add_max_turn();
				gamelogic.timeline_squish();
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 14): #heavy_magenta_time_crystal
				var color = current_animation[1].color;
				gamelogic.heavytimeline.lock_turn(current_animation[2]);
				gamelogic.timeline_squish();
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 15): #light_magenta_time_crystal
				var color = current_animation[1].color;
				var turn = current_animation[2];
				if (turn != -99):
					gamelogic.lighttimeline.lock_turn(turn);
					gamelogic.timeline_squish();
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 16): #heavy_green_time_crystal_unlock
				var color = current_animation[1].color;
				gamelogic.heavytimeline.unlock_turn(current_animation[2]);
				gamelogic.timeline_squish();
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 17): #light_green_time_crystal_unlock
				var color = current_animation[1].color;
				var turn = current_animation[2];
				if (turn != -99):
					gamelogic.lighttimeline.unlock_turn(current_animation[2]);
					gamelogic.timeline_squish();
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 18): #tick
				var amount = current_animation[1];
				var new_ticks = current_animation[2];
				gamelogic.broadcast_animation_nonce(current_animation[3]);
				thought_bubble.update_ticks(new_ticks);
				if (new_ticks == 0):
					gamelogic.play_sound("timesup");
					ripple = preload("res://Ripple.tscn").instance();
					ripple_timer = 0;
					ripple.rect_position += Vector2(12, 12);
					self.add_child(ripple);
					self.update_graphics();
				elif (amount < 0):
					gamelogic.play_sound("tick");
				else:
					gamelogic.play_sound("untick");
			elif (current_animation[0] == 19): #undo_immunity
				if (animation_timer == 0):
					gamelogic.broadcast_animation_nonce(current_animation[1]);
					stored_position = position;
					gamelogic.play_sound("shroud");
				animation_timer_max = 0.083;
				position = stored_position + Vector2(gamelogic.rng.randf_range(-2, 2), gamelogic.rng.randf_range(-2, 2));
				animation_timer += delta;
				if (animation_timer > animation_timer_max):
					position = stored_position;
				else:
					is_done = false;
			elif (current_animation[0] == 20): #grayscale
				var new_value = current_animation[1];
				update_grayscale(new_value);
			elif (current_animation[0] == 21): #generic_green_time_crystal
				var color = current_animation[1].color;
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 22): #generic_magenta_time_crystal;
				var color = current_animation[1].color;
				gamelogic.undo_effect_strength = 0.4;
				gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
				gamelogic.undo_effect_color = color;
				var sparklespawner = Node2D.new();
				sparklespawner.script = preload("res://SparkleSpawner.gd");
				sparklespawner.color = color;
				self.add_child(sparklespawner);
			elif (current_animation[0] == 23): #lose
				if (actorname == Name.Heavy):
					gamelogic.heavytimeline.start_fade();
				else:
					gamelogic.lighttimeline.start_fade();
				gamelogic.play_sound("abysschime");
			elif (current_animation[0] == 24): #time_passes
				if time_bubble != null:
					time_bubble.flash();
			if (is_done):
				animations.pop_front();
				animation_timer = 0;
		
