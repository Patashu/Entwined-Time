extends ActorBase
class_name Actor

var gamelogic = null
var actorname : int = -1
var stored_position : Vector2 = Vector2.ZERO
var pos : Vector2 = Vector2.ZERO
#var state = {}
var broken : bool = false
var powered : bool = false
var dinged : bool = false;
# -1 for grounded, 0 for falling, 1+ for turns of coyote time left
var airborne : int = -1
var strength : int = 0
var heaviness : int = 0
var durability : int = 0
var fall_speed : int = -1
var floats : bool = false
var climbs : bool = false
var is_character : bool = false
var time_colour : int = 0
var time_bubble = null
var momentum : Vector2 = Vector2.ZERO;
var boulder_moved_horizontally_this_turn : bool = false;
# undo trails logic
var is_ghost : bool = false
var next_ghost = null;
var previous_ghost = null;
var ghost_index : int = 0;
var ghost_dir : Vector2 = Vector2.ZERO;
var ghost_timer : float = 0.0;
var ghost_timer_max : float = 2.0;
var color : Color = Color(1, 1, 1, 1);
var ghost_alpha : float = 1.0;
# animation system logic
var animation_timer : float = 0.0;
var animation_timer_max : float = 0.05;
var animations : Array = [];
var facing_left : bool = false;
# animated sprites logic
var frame_timer : float = 0.0;
var frame_timer_max : float = 0.1;
var post_mortem : int = -1;
# light fluster logic
var fluster_timer : float = 0.0;
var fluster_timer_max : float = 0.0;
# ding
var ding = null;
# crystal effects
var is_crystal : float = false;
var crystal_timer : float = 0.0;
var crystal_timer_max : float = 1.6;
# cuckoo clock
var ticks : int = 1000;
var thought_bubble = null;
var ripple = null;
var ripple_timer : float = 0.0;
var ripple_timer_max : float = 1.0;
# night and stars
var in_night : bool = false;
var in_stars : bool = false;
# transient multi-push/multi-fall state:
# basically, things that move become non-colliding until the end of the multi-push/fall tick they're
# a part of, so other things that shared their tile can move with them
var just_moved : bool = false;
# joke goals logic
var joke_goal = null;
# action lines!
var action_lines_timer : float = 0.0;
var action_lines_timer_max : float = 0.25;
var propellor = null;
var gravity_halo = null;
var heavy_mimic = null;
var light_mimic = null;
var bowl = null;
var superbowl = null;
var fade_tween = null;

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
	Hole,
	GreenHole,
	VoidHole,
	Boulder,
}

func update_graphics() -> void:
	var tex = get_next_texture();
	set_next_texture(tex, facing_left);
	if (thought_bubble != null):
		thought_bubble.update_ticks(ticks);
	# I should figure out a nice way to have arbitrarily many materials, but in the mean time
	if (actorname != Name.ChronoHelixRed and actorname != Name.ChronoHelixBlue):
		update_grayscale(in_night);
	if (is_ghost and actorname == Name.HeavyGoalJoke):
		texture = preload("res://assets/BigPortalRed.png");
		offset = Vector2(12, 12)/0.1;
		scale = Vector2(0.1, 0.1);
	elif (is_ghost and actorname == Name.LightGoalJoke):
		texture = preload("res://assets/BigPortalBlue.png");
		offset = Vector2(12, 12)/0.1;
		scale = Vector2(0.1, 0.1);

func get_next_texture(skip_powered: bool = false) -> Texture:
	# powered modulate also update here, since I want that to be instant
	
	# powered
	if (!skip_powered and !is_ghost):
		if is_main_character():
			if (fade_tween != null):
				fade_tween.queue_free();
				fade_tween = null;
			if powered:
				self.modulate = Color(1, 1, 1, 1);
			else:
				self.modulate = Color(0.5, 0.5, 0.5, 1);
		else:
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
	match actorname:
		Name.Heavy:
			if broken:
				return preload("res://assets/heavy_broken.png");
			elif airborne >= 1:
				return preload("res://assets/heavy_rising.png");
			elif airborne == 0:
				return preload("res://assets/heavy_falling.png");
			else:
				if !powered:
					return preload("res://assets/heavy_unpowered.png");
				elif gamelogic.has_no_move and gamelogic.terrain_in_tile(pos, self, 0).has(LevelEditor.Tiles.NoMove):
					return preload("res://assets/heavy_unpowered.png");
				else:
					if (!is_ghost and gamelogic.heavy_actor != self and heavy_mimic == null and light_mimic == null):
						return preload("res://assets/heavy_unpowered.png");
					else:
						return preload("res://assets/heavy_idle.png");
		
		Name.Light:
			if broken:
				return preload("res://assets/light_broken.png");
			elif airborne >= 1:
				return preload("res://assets/light_rising.png");
			elif airborne == 0:
				return preload("res://assets/light_falling.png");
			else:
				if !powered:
					return preload("res://assets/light_unpowered.png");
				elif gamelogic.has_no_move and gamelogic.terrain_in_tile(pos, self, 0).has(LevelEditor.Tiles.NoMove):
					return preload("res://assets/light_unpowered.png");
				else:
					if (!is_ghost and gamelogic.light_actor != self and heavy_mimic == null and light_mimic == null):
						return preload("res://assets/light_unpowered.png");
					return preload("res://assets/light_idle_animation.png");
		
		Name.IronCrate:
			if broken:
				return preload("res://assets/iron_crate_broken.png");
			else:
				return preload("res://assets/iron_crate.png");
		
		Name.SteelCrate:
			if broken:
				return preload("res://assets/steel_crate_broken.png");
			else:
				return preload("res://assets/steel_crate.png");
		
		Name.PowerCrate:
			if broken:
				return preload("res://assets/power_crate_broken.png");
			else:
				return preload("res://assets/power_crate_animation.png");
				
		Name.WoodenCrate:
			if broken:
				return preload("res://assets/wooden_crate_broken.png");
			else:
				return preload("res://assets/wooden_crate.png");
				
		Name.CuckooClock:
			if ticks == 0 and gamelogic.lost:
				return preload("res://assets/cuckoo_clock_end.png");
			elif broken:
				return preload("res://assets/cuckoo_clock_broken.png");
			else:
				return preload("res://assets/cuckoo_clock.png");
				
		Name.TimeCrystalGreen:
			if broken:
				return null;
			else:
				return preload("res://assets/timecrystalgreen.png");
				
		Name.TimeCrystalMagenta:
			if broken:
				return null;
			else:
				return preload("res://assets/timecrystalmagenta.png");
				
		Name.ChronoHelixBlue:
			if (gamelogic.nonstandard_won):
				return null;
			else:
				return preload("res://assets/chrono_helix_blue_anim.png");
		Name.ChronoHelixRed:
			if (gamelogic.nonstandard_won):
				return preload("res://assets/chrono_helix_all_anim.png");
			else:
				return preload("res://assets/chrono_helix_red_anim.png");
			
		Name.Hole:
			if broken:
				return preload("res://assets/hole_broken.png");
			else:
				return preload("res://assets/hole.png");
				
		Name.GreenHole:
			if broken:
				return preload("res://assets/hole_green_broken.png");
			else:
				return preload("res://assets/hole_green.png");
				
		Name.VoidHole:
			if broken:
				return preload("res://assets/hole_void_broken.png");
			else:
				return preload("res://assets/hole_void.png");
	
		Name.Boulder:
			if broken:
				return preload("res://assets/boulder_broken.png");
			else:
				return preload("res://assets/Boulder.png");
	
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
	match texture:
		preload("res://assets/heavy_broken.png"):
			frame_timer_max = 0.4;
			hframes = 8;
		preload("res://assets/light_broken.png"):
			frame_timer_max = 0.4;
			hframes = 8;
		preload("res://assets/light_rising.png"):
			frame_timer_max = 0.1;
			hframes = 6;
		preload("res://assets/light_falling.png"):
			frame_timer_max = 0.1;
			hframes = 6;
		preload("res://assets/light_idle_animation.png"):
			frame_timer_max = 0.1;
			hframes = 12;
		preload("res://assets/power_crate_animation.png"):
			frame_timer_max = 0.1;
			hframes = 4;
		preload("res://assets/cuckoo_clock_end.png"):
			frame_timer_max = 0.4;
			hframes = 3;
		preload("res://assets/chrono_helix_red_anim.png"):
			frame_timer_max = 0.1;
			hframes = 24;
		preload("res://assets/chrono_helix_blue_anim.png"):
			frame_timer_max = 0.1;
			hframes = 24;
		preload("res://assets/chrono_helix_all_anim.png"):
			frame_timer_max = 0.1;
			hframes = 24;
		_:
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
	if (actorname == Name.GreenHole):
		return 6; #Green
	if (actorname == Name.VoidHole):
		return 7; #Void
	return 0; 

func is_native_colour():
	return native_colour() == time_colour;

func update_time_bubble():
	if time_bubble != null:
		time_bubble.queue_free();
		time_bubble = null;
	if !is_native_colour():
		if (time_bubble == null):
			time_bubble = Sprite.new();
			time_bubble.set_script(preload("res://TimeBubble.gd"));
			time_bubble.texture = preload("res://assets/time_bubble.png");
			time_bubble.centered = true;
			time_bubble.position = Vector2(12, 12);
			self.add_child(time_bubble);
		time_bubble.time_colour = time_colour;
		time_bubble.time_bubble_colour()
	if (thought_bubble != null):
		thought_bubble.update_time_colour(time_colour);
	setup_colourblind_mode(gamelogic.save_file["colourblind_mode"]);
	
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
	if propellor != null:
		return 0;
	if broken and !is_crystal:
		return 99;
	return fall_speed;
	
func has_sticky_top() -> bool:
	if (superbowl != null):
		return true;
	var has_sticky_top = false;
	if (actorname == Name.Heavy):
		has_sticky_top = !has_sticky_top;
	if (bowl != null):
		has_sticky_top = !has_sticky_top;
	return has_sticky_top;
	
# because I want Light to float but not cuckoo clocks <w<
func floats() -> bool:
	return floats and fall_speed() == 1;
	
func climbs() -> bool:
	return climbs and !broken;

func is_hole() -> bool:
	return !broken and (actorname == Name.Hole or actorname == Name.GreenHole or actorname == Name.VoidHole);

func is_main_character() -> bool:
	return is_character and (gamelogic.heavy_actor == self or gamelogic.light_actor == self);

func pushable(checking_phased_out: bool = false) -> bool:
	if (!checking_phased_out and just_moved):
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

func action_line(dir: Vector2) -> void:
	var sprite = Sprite.new();
	sprite.set_script(preload("res://GoalParticle.gd"));
	if (actorname == Name.Heavy):
		sprite.texture = preload("res://assets/action_line_heavy.png");
	elif (actorname == Name.Light):
		sprite.texture = preload("res://assets/action_line_light.png");
	else:
		sprite.texture = preload("res://assets/action_line_other.png");
	sprite.position = self.position;
	if (dir.y > 0):
		sprite.position.x += gamelogic.rng.randf_range(0, gamelogic.cell_size);
		sprite.position.y += gamelogic.rng.randf_range(0, gamelogic.cell_size/2);
		sprite.velocity = Vector2(0, -24);
	elif (dir.y < 0):
		sprite.position.x += gamelogic.rng.randf_range(0, gamelogic.cell_size);
		sprite.position.y += gamelogic.rng.randf_range(0, gamelogic.cell_size/2);
		sprite.velocity = Vector2(0, 24);
		sprite.position.y += gamelogic.cell_size/2;
	elif (dir.x < 0):
		sprite.position.x += gamelogic.rng.randf_range(0, gamelogic.cell_size/2);
		sprite.position.y += gamelogic.rng.randf_range(0, gamelogic.cell_size);
		sprite.velocity = Vector2(24, 0);
		sprite.position.x += gamelogic.cell_size/2;
		sprite.rotation_degrees = 90;
	elif (dir.x > 0):
		sprite.position.x += gamelogic.rng.randf_range(0, gamelogic.cell_size/2);
		sprite.position.y += gamelogic.rng.randf_range(0, gamelogic.cell_size);
		sprite.velocity = Vector2(-24, 0);
		sprite.rotation_degrees = 90;
	sprite.centered = true;
	sprite.rotate_magnitude = 0;
	sprite.alpha_max = 1;
	sprite.modulate = self.modulate;
	sprite.modulate.a = 0;
	sprite.fadeout_timer_max = 0.75;
	gamelogic.overactorsparticles.add_child(sprite);

func _process(delta: float) -> void:
	#action lines
	if (!is_ghost and (airborne != -1 or momentum != Vector2.ZERO)):
		action_lines_timer += delta;
		if (action_lines_timer > action_lines_timer_max):
			action_lines_timer -= action_lines_timer_max;
			if (airborne == 0):
				action_line(Vector2.DOWN);
			elif (airborne > 0):
				action_line(Vector2.UP);
			if (momentum != Vector2.ZERO):
				action_line(momentum);
	
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
			if (fade_tween == null):
				update_graphics();
	
	#animated sprites
	if hframes <= 1:
		pass
	else:
		if (!is_ghost and actorname == Name.ChronoHelixRed or actorname == Name.ChronoHelixBlue):
			var glow_color = Color(0.2, 0.5, 1, 1);
			if (actorname == Name.ChronoHelixRed):
				if (gamelogic.nonstandard_won):
					glow_color = Color("A9F05F");
				else:
					glow_color = Color(1, 0.4, 0.1, 1);
				
			#reusing this lol
			crystal_timer += delta;
			var coeff = 0.1+(1+sin(crystal_timer*2.5))/5;
			glow_color.a = coeff;
			material.set_shader_param("color", glow_color);
		
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
			match current_animation[0]:
				0: #move
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
				1: #bump
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
				2: #set_next_texture
					set_next_texture(current_animation[1], current_animation[3]);
					gamelogic.broadcast_animation_nonce(current_animation[2]);
				3: #sfx
					gamelogic.play_sound(current_animation[1]);
				4: #fluster
					fluster();
				6: #trapdoor_opens
					var sprite = Sprite.new();
					sprite.set_script(preload("res://PingPongSprite.gd"));
					sprite.texture = preload("res://assets/trapdoor_animation_spritesheet.png");
					sprite.vframes = round(sprite.get_rect().size.y/24);
					sprite.hframes = round(sprite.get_rect().size.x/24);
					sprite.frame = 0;
					sprite.centered = false;
					sprite.frame_timer_max = 0.05;
					sprite.position = current_animation[1];
					gamelogic.underactorsparticles.add_child(sprite);
				7: #explode
					var broken = current_animation[1];
					if (is_character):
						var overactorsparticles = gamelogic.overactorsparticles;
						if (broken):
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
						else:
							for i in range(10):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/Sparkle.png")
								sprite.position = position + Vector2(gamelogic.cell_size/2, gamelogic.cell_size/2);
								sprite.centered = true;
								sprite.scale = Vector2(0.25, 0.25);
								sprite.fadeout_timer_max = 0.5;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(-48, 48), gamelogic.rng.randf_range(-48, 48));
								sprite.position -= sprite.velocity/2;
								overactorsparticles.add_child(sprite);
								sprite.modulate = color;
				8: #shatter
					var overactorsparticles = gamelogic.overactorsparticles;
					gamelogic.broadcast_animation_nonce(current_animation[4]);
					for i in range(4):
						var sprite = Sprite.new();
						sprite.set_script(preload("res://FadingSprite.gd"));
						match (current_animation[2]):
							45:
								sprite.texture = preload("res://assets/glass_block.png")
							46:
								sprite.texture = preload("res://assets/green_glass_block.png")
							51:
								sprite.texture = preload("res://assets/one_undo.png")
							69:
								sprite.texture = preload("res://assets/glass_block_cracked.png")
							88:
								sprite.texture = preload("res://assets/floorboards_gray.png")
							89:
								sprite.texture = preload("res://assets/floorboards_green.png")
							90:
								sprite.texture = preload("res://assets/floorboards_void.png")
							112:
								sprite.texture = preload("res://assets/floorboards_magenta.png")
							124:
								sprite.texture = preload("res://assets/repair_station.png");
							125:
								sprite.texture = preload("res://assets/repair_station_gray.png");
							126:
								sprite.texture = preload("res://assets/repair_station_green.png");
							#TODO: all of the above might be redundant
							14:
								sprite.texture = preload("res://assets/wall.png");
							_:
								sprite.texture = gamelogic.terrainmap.tile_set.tile_get_texture(current_animation[2]);
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
				9: #unshatter
					var overactorsparticles = gamelogic.overactorsparticles;
					gamelogic.broadcast_animation_nonce(current_animation[4]);
					for i in range(4):
						var sprite = Sprite.new();
						sprite.set_script(preload("res://FadingSprite.gd"));
						match (current_animation[3]):
							45:
								sprite.texture = preload("res://assets/glass_block.png")
							69:
								sprite.texture = preload("res://assets/glass_block_cracked.png")
							88:
								sprite.texture = preload("res://assets/floorboards_gray.png")
							112:
								sprite.texture = preload("res://assets/floorboards_magenta.png")
							124:
								sprite.texture = preload("res://assets/repair_station.png");
							125:
								sprite.texture = preload("res://assets/repair_station_gray.png");
							#TODO: all of the above might be redundant
							-1:
								sprite.texture = null;
							14:
								sprite.texture = preload("res://assets/wall.png");
							_:
								sprite.texture = gamelogic.terrainmap.tile_set.tile_get_texture(current_animation[3]);
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
				10: #afterimage_at
					gamelogic.afterimage_terrain(current_animation[1], current_animation[2], current_animation[3]);
				11: #fade
					if (fade_tween != null):
						fade_tween.queue_free();
					fade_tween = Tween.new();
					self.add_child(fade_tween);
					fade_tween.interpolate_property(self, "modulate:a", current_animation[1], current_animation[2], current_animation[3]);
					fade_tween.start();
				12: #heavy_green_time_crystal_raw
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
				13: #light_green_time_crystal_raw
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
				14: #heavy_magenta_time_crystal
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
				15: #light_magenta_time_crystal
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
				16: #heavy_green_time_crystal_unlock
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
				17: #light_green_time_crystal_unlock
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
				18: #tick
					var amount = current_animation[1];
					var new_ticks = current_animation[2];
					var newly_lost = current_animation[3];
					gamelogic.broadcast_animation_nonce(current_animation[4]);
					thought_bubble.update_ticks(new_ticks);
					if (newly_lost):
						gamelogic.play_sound("timesup");
						if (animation_timer < 99): #don't make ripples while a replay is going fast
							ripple = preload("res://Ripple.tscn").instance();
							ripple_timer = 0;
							ripple.rect_position += Vector2(12, 12);
							self.add_child(ripple);
						self.update_graphics();
					elif new_ticks == 0 and gamelogic.lost:
						self.update_graphics();
					elif (amount < 0):
						gamelogic.play_sound("tick");
					else:
						gamelogic.play_sound("untick");
				19: #undo_immunity
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
				20: #grayscale
					var new_value = current_animation[1];
					update_grayscale(new_value);
				21: #generic_green_time_crystal
					var color = current_animation[1];
					gamelogic.undo_effect_strength = 0.4;
					gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
					gamelogic.undo_effect_color = color;
					var sparklespawner = Node2D.new();
					sparklespawner.script = preload("res://SparkleSpawner.gd");
					sparklespawner.color = color;
					self.add_child(sparklespawner);
				22: #generic_magenta_time_crystal;
					var color = current_animation[1];
					gamelogic.undo_effect_strength = 0.4;
					gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
					gamelogic.undo_effect_color = color;
					var sparklespawner = Node2D.new();
					sparklespawner.script = preload("res://SparkleSpawner.gd");
					sparklespawner.color = color;
					self.add_child(sparklespawner);
				23: #lose
					if (actorname == Name.Heavy):
						gamelogic.heavytimeline.start_fade();
					else:
						gamelogic.lighttimeline.start_fade();
					gamelogic.play_sound("abysschime");
				24: #time_passes
					if time_bubble != null:
						time_bubble.flash();
				#skip 25, that's lightning_strikes, continue with 26
				26: #heavy_timeline_finish_animations
					gamelogic.heavytimeline.finish_animations();
				27: #light_timeline_finish_animations
					gamelogic.lighttimeline.finish_animations();
				28: #intro_hop
					if (!powered):
						is_done = true;
					else:
						var mult = 5;
						if (actorname == Name.Heavy):
							animation_timer_max = 0.5;
							mult = 8;
						else:
							animation_timer_max = 1.0;
							
						position.y += sin((animation_timer/animation_timer_max)*PI)*mult;
						animation_timer += delta;
						if (animation_timer > animation_timer_max):
							if (actorname == Name.Heavy):
								var tex = get_next_texture(true);
								set_next_texture(tex, facing_left);
							else:
								var tex = get_next_texture(true);
								set_next_texture(tex, facing_left);
						else:
							is_done = false;
							position.y -= sin((animation_timer/animation_timer_max)*PI)*mult;
							
							if (animation_timer < animation_timer_max * (1.5/4.0)):
								if (actorname == Name.Heavy):
									set_next_texture(preload("res://assets/heavy_rising.png"), facing_left);
								else:
									set_next_texture(preload("res://assets/light_rising.png"), facing_left);
							elif (animation_timer > animation_timer_max * (2.5/4.0)):
								if (actorname == Name.Heavy):
									set_next_texture(preload("res://assets/heavy_falling.png"), facing_left);
								else:
									set_next_texture(preload("res://assets/light_falling.png"), facing_left);
							else:
								if (actorname == Name.Heavy):
									set_next_texture(preload("res://assets/heavy_idle.png"), facing_left);
								else:
									set_next_texture(preload("res://assets/light_idle_animation.png"), facing_left);
				29: #stall
					animation_timer_max = current_animation[1];
					animation_timer += delta;
					if (animation_timer > animation_timer_max):
						is_done = true;
					else:
						is_done = false;
				30: #dust
					match current_animation[1]:
						0: #rising
							for i in range(6):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/dust.png")
								sprite.position = self.position + Vector2(12, 24) + Vector2(gamelogic.rng.randf_range(-6, 6), 0);
								sprite.fadeout_timer_max = 0.25;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(-24, 24), gamelogic.rng.randf_range(48, 96));
								sprite.hframes = 7;
								sprite.frame = gamelogic.rng.randi_range(0, 6);
								sprite.centered = true;
								sprite.scale = Vector2(1, 1);
								gamelogic.overactorsparticles.add_child(sprite);
						1: #falling
							for i in range(6):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/dust.png")
								sprite.position = self.position + Vector2(12, 0) + Vector2(gamelogic.rng.randf_range(-6, 6), 0);
								sprite.fadeout_timer_max = 0.25;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(-24, 24), gamelogic.rng.randf_range(-48, -96));
								sprite.hframes = 7;
								sprite.frame = gamelogic.rng.randi_range(0, 6);
								sprite.centered = true;
								sprite.scale = Vector2(1, 1);
								gamelogic.overactorsparticles.add_child(sprite);
						2: #landing
							for i in range(6):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/dust.png")
								sprite.position = self.position + Vector2(12, 24) + Vector2(gamelogic.rng.randf_range(-6, 6), 0);
								sprite.fadeout_timer_max = 0.25;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(48, 96), 0);
								if (i % 2 == 1):
									sprite.velocity.x *= -1;
								sprite.hframes = 7;
								sprite.frame = gamelogic.rng.randi_range(0, 6);
								sprite.centered = true;
								sprite.scale = Vector2(1, 1);
								gamelogic.overactorsparticles.add_child(sprite);
						3: #un-rising
							for i in range(6):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/dust.png")
								sprite.position = self.position + Vector2(12, 24) + Vector2(gamelogic.rng.randf_range(-6, 6), 0);
								sprite.fadeout_timer_max = 0.25;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(-24, 24), gamelogic.rng.randf_range(48, 96));
								sprite.hframes = 7;
								sprite.frame = gamelogic.rng.randi_range(0, 6);
								sprite.centered = true;
								sprite.scale = Vector2(1, 1);
								gamelogic.overactorsparticles.add_child(sprite);
								sprite.position += sprite.velocity*0.25;
								sprite.velocity *= -1;
								sprite.modulate = color;
						4: #un-falling
							for i in range(6):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/dust.png")
								sprite.position = self.position + Vector2(12, 0) + Vector2(gamelogic.rng.randf_range(-6, 6), 0);
								sprite.fadeout_timer_max = 0.25;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(-24, 24), gamelogic.rng.randf_range(-48, -96));
								sprite.hframes = 7;
								sprite.frame = gamelogic.rng.randi_range(0, 6);
								sprite.centered = true;
								sprite.scale = Vector2(1, 1);
								gamelogic.overactorsparticles.add_child(sprite);
								sprite.position += sprite.velocity*0.25;
								sprite.velocity *= -1;
								sprite.modulate = color;
						5: #un-landing
							for i in range(6):
								var sprite = Sprite.new();
								sprite.set_script(preload("res://FadingSprite.gd"));
								sprite.texture = preload("res://assets/dust.png")
								sprite.position = self.position + Vector2(12, 24) + Vector2(gamelogic.rng.randf_range(-6, 6), 0);
								sprite.fadeout_timer_max = 0.25;
								sprite.velocity = Vector2(gamelogic.rng.randf_range(48, 96), 0);
								if (i % 2 == 1):
									sprite.velocity.x *= -1;
								sprite.hframes = 7;
								sprite.frame = gamelogic.rng.randi_range(0, 6);
								sprite.centered = true;
								sprite.scale = Vector2(1, 1);
								gamelogic.overactorsparticles.add_child(sprite);
								sprite.position += sprite.velocity*0.25;
								sprite.velocity *= -1;
								sprite.modulate = color;
				31: #time_bubble
					update_time_bubble();
					# PERF: static/global/const or something
					var time_colours = [Color("808080"), Color("FF2A00"), Color("26C8FF"), Color("FF00DC"),
					Color("FF0000"), Color("0094FF"), Color("A9F05F"), Color("404040"),
					Color("00FFFF"), Color("FF6A00"), Color("5400FF"), Color("FFFFFF")];
					var color = time_colours[current_animation[1]];
					gamelogic.play_sound("usegreenality");
					gamelogic.undo_effect_strength = 0.4;
					gamelogic.undo_effect_per_second = gamelogic.undo_effect_strength*(1);
					gamelogic.undo_effect_color = color;
				32: #nonce
					gamelogic.broadcast_animation_nonce(current_animation[1]);
			if (is_done):
				animations.pop_front();
				animation_timer = 0;
		
