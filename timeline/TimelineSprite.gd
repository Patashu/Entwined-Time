extends Sprite
class_name TimelineSprite

var animation_nonce : int = -1;
var previous_modulate : Color = Color(1, 1, 1, 0);
var destination_colour : Color = Color(1, 1, 1, 1);
var next_modulates : Array = [];
var flash_timer : float = 0.0;
var flash_timer_max : float = 0.1;
var viewer = null;
var fading: float = false;
var flashed_to_enter : float = false;
var flashed_while_fading : float = false;
var is_broken : float = false;
var event: Array = [];
var size: int = 12;
var gamelogic = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.connect("tree_exiting", self, "_tree_exiting");
	pass # Replace with function body.

func _tree_exiting() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if next_modulates.size() > 0:
		var next_modulate = next_modulates[0];
		flash_timer += delta;
		if (flash_timer > flash_timer_max):
			flash_timer -= flash_timer_max;
			modulate = next_modulate;
			previous_modulate = modulate;
			next_modulates.pop_front();
		else:
			var current_r = lerp(previous_modulate.r, next_modulate.r, flash_timer/flash_timer_max);
			var current_g = lerp(previous_modulate.g, next_modulate.g, flash_timer/flash_timer_max);
			var current_b = lerp(previous_modulate.b, next_modulate.b, flash_timer/flash_timer_max);
			var current_a = lerp(previous_modulate.a, next_modulate.a, flash_timer/flash_timer_max);
			modulate = Color(current_r, current_g, current_b, current_a);
	elif (fading and flashed_while_fading):
		viewer.broadcast_remove_sprite(self);
		queue_free();

func finish_animations() -> void:
	if (fading):
		viewer.broadcast_remove_sprite(self);
		queue_free();
	elif (!flashed_to_enter):
		flashed_to_enter = true;
		next_modulates.clear();
		previous_modulate = destination_colour;
		modulate = destination_colour;

func flash() -> void:
	flash_timer = 0;
	next_modulates.clear();
	previous_modulate = modulate;
	next_modulates.append(Color(1, 1, 1, 1));
	if (fading):
		flashed_while_fading = true;
		next_modulates.append(Color(1, 1, 1, 0));
	else:
		flashed_to_enter = true;
		next_modulates.append(destination_colour);
		
func update_texture() -> void:
	self.texture = get_texture_for_event(event, size);
		
func get_texture_for_event(event: Array, size: int) -> Texture:
	#add_undo_event([Undo.move, actor, dir], chrono);
	#add_undo_event([Undo.set_actor_var, actor, prop, old_value], chrono);
	match (event[0]):
		GameLogic.Undo.move:
			var dir = event[2];
			if dir == Vector2.LEFT:
				if (event[5].size() > 0):
					if size == 8:
						return preload("res://timeline/timeline-left-phase-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-left-phase-12.png");
				else:
					if size == 8:
						return preload("res://timeline/timeline-left-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-left-12.png");
			elif dir == Vector2.RIGHT:
				if (event[5].size() > 0):
					if size == 8:
						return preload("res://timeline/timeline-right-phase-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-right-phase-12.png");
				else:
					if size == 8:
						return preload("res://timeline/timeline-right-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-right-12.png");
			elif dir == Vector2.UP:
				if (event[5].size() > 0):
					if size == 8:
						return preload("res://timeline/timeline-up-phase-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-up-phase-12.png");
				else:
					if size == 8:
						return preload("res://timeline/timeline-up-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-up-12.png");
			elif dir == Vector2.DOWN:
				if (event[5].size() > 0):
					if size == 8:
						return preload("res://timeline/timeline-down-phase-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-down-phase-12.png");
				else:
					if size == 8:
						return preload("res://timeline/timeline-down-8.png");
					elif size == 12:
						return preload("res://timeline/timeline-down-12.png");
			pass
		GameLogic.Undo.set_actor_var:
			var prop = event[2];
			var new_value = event[4];
			if (gamelogic.save_file["retro_timeline"]):
				new_value = event[3];
			match prop:
				"airborne":
					if new_value == 1:
						if size == 8:
							return preload("res://timeline/timeline-airborne-1-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-airborne-1-12.png");
					elif new_value == 0:
						if size == 8:
							return preload("res://timeline/timeline-airborne-0-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-airborne-0-12.png");
					elif new_value == -1:
						if size == 8:
							return preload("res://timeline/timeline-grounded-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-grounded-12.png");
				"broken":
					if new_value == true:
						if size == 8:
							return preload("res://timeline/timeline-broken-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-broken-12.png");
					else:
						if size == 8:
							return preload("res://timeline/timeline-unbroken-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-unbroken-12.png");
				"momentum":
					if (new_value == Vector2.ZERO):
						if size == 8:
							return preload("res://timeline/timeline-momentum-zero-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-momentum-zero-12.png");
					elif (new_value == Vector2.LEFT):
						if size == 8:
							return preload("res://timeline/timeline-momentum-left-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-momentum-left-12.png");
					elif (new_value == Vector2.RIGHT):
						if size == 8:
							return preload("res://timeline/timeline-momentum-right-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-momentum-right-12.png");
					elif (new_value == Vector2.UP):
						if size == 8:
							return preload("res://timeline/timeline-momentum-up-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-momentum-up-12.png");
					elif (new_value == Vector2.DOWN):
						if size == 8:
							return preload("res://timeline/timeline-momentum-down-8.png");
						elif size == 12:
							return preload("res://timeline/timeline-momentum-down-12.png");
		GameLogic.Undo.change_terrain:
			var old_value = event[4];
			if (old_value == -1):
				if size == 8:
					return preload("res://timeline/timeline-unterrain-8.png");
				elif size == 12:
					return preload("res://timeline/timeline-unterrain-12.png");
			else:
				if size == 8:
					return preload("res://timeline/timeline-terrain-8.png");
				elif size == 12:
					return preload("res://timeline/timeline-terrain-12.png");
		GameLogic.Undo.tick:
			var amount = event[2];
			if (amount < 0):
				if size == 8:
					return preload("res://timeline/timeline-tick-8.png");
				elif size == 12:
					return preload("res://timeline/timeline-tick-12.png");
			elif (amount > 0):
				if size == 8:
					return preload("res://timeline/timeline-untick-8.png");
				elif size == 12:
					return preload("res://timeline/timeline-untick-12.png");
			
	if size == 8:
		return preload("res://timeline/timeline-what-8.png");
	else:
		return preload("res://timeline/timeline-what-12.png");
