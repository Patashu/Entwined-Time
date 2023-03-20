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
var floatiness = 0
var climbs = false
# undo trails logic
var is_ghost = false
var next_ghost = null;
var previous_ghost = null;
var ghost_index = 0;
var ghost_dir = Vector2.ZERO;
var ghost_timer = 0;
var ghost_timer_max = 2;
# animation system logic
var animation_timer = 0;
var animation_timer_max = 0.05;
var animations = [];

func _process(delta: float) -> void:
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
			if (current_animation[0] == "move"):
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
			elif (current_animation[0] == "bump"):
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
		
