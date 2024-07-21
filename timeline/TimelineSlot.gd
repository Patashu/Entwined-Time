extends Sprite
class_name TimelineSlot

var undo_effect_strength : float = 0.0;
var undo_effect_loss_per_second : float = 0.5;
var undo_effect_color : Color = Color(1, 1, 1, 1);
var showing_fuzz : float = false;
var fuzz_timer : float = 0.0;
var locked : bool = false;
var parent = null;
onready var crystalanimation : Sprite = get_node("CrystalAnimation");
onready var timelinesymbols : Node2D = get_node("TimelineSymbols");
onready var overlay : Sprite = get_node("Overlay");
onready var lockanimation : Sprite = get_node("LockAnimation");

var region_timer = 0;
var region_timer_max = 0;
var crystal_timer = 0;
var crystal_timer_max = 0;
var lock_timer = 0;
var lock_timer_max = 0;

var motion_start = Vector2.ZERO;
var motion_end = Vector2.ZERO;
var motion_timer = 0;
var motion_timer_max = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func start_motion(end: Vector2) -> void:
	motion_start = position;
	motion_end = end;
	motion_timer = 0;
	motion_timer_max = 1;

func remember_animation() -> void:
	z_index = 1;
	crystalanimation.visible = true;
	lockanimation.visible = false;
	crystalanimation.texture = preload("res://assets/CrystalFrameAnimationPB.png");
	crystalanimation.hframes = 15;
	crystalanimation.frame = 0;
	crystal_timer = 0;
	crystal_timer_max = 1.0/crystalanimation.hframes;

func lock_animation() -> void:
	z_index = 1;
	crystalanimation.visible = true;
	lockanimation.visible = false;
	crystalanimation.texture = preload("res://assets/CrystalFrameAnimationP.png");
	crystalanimation.hframes = 15;
	crystalanimation.frame = 0;
	crystal_timer = 0;
	crystal_timer_max = 0.5/crystalanimation.hframes;
	
func lock_animation_part_2() -> void:
	crystalanimation.frame = crystalanimation.hframes - 1;
	crystal_timer = 0;
	crystal_timer_max = 0;
	if (crystalanimation.texture == preload("res://assets/CrystalFrameAnimationP.png")):
		lockanimation.visible = true;
		lockanimation.texture = preload("res://assets/LockingTime.png");
		lockanimation.hframes = 5;
		lockanimation.frame = 0;
		lock_timer = 0;
		lock_timer_max = 0.5/lockanimation.hframes;
	else:
		crystalanimation.texture = preload("res://assets/TestCrystalFrame.png");
		crystalanimation.frame = 0;
		crystalanimation.hframes = 1;
	
func lock_animation_part_3() -> void:
	lockanimation.frame = lockanimation.hframes - 1;
	lock_timer = 0;
	lock_timer_max = 0;
	
func undo_lock_animation() -> void:
	crystalanimation.visible = false;
	lockanimation.visible = false;
	
func undo_remember_animation() -> void:
	lock_animation();
	finish_animations();

func fill(buffer: Array) -> void:
	for sprite in timelinesymbols.get_children():
		parent.broadcast_remove_sprite(sprite);
		sprite.queue_free();
		timelinesymbols.remove_child(sprite);
	
	var relevant_buffer = [];
	for event in buffer:
		if event[0] == GameLogic.Undo.move or event[0] == GameLogic.Undo.set_actor_var or event[0] == GameLogic.Undo.change_terrain or event[0] == GameLogic.Undo.tick: # move or set_actor_var or change_terrain or tick
			# whitelist: for set_actor_var, only consider airborne 1 or less and broken
			var whitelisted = false;
			match (event[0]):
				GameLogic.Undo.move:
					whitelisted = true;
				GameLogic.Undo.set_actor_var:
					match event[2]:
						"airborne":
							if event[4] < 2:
								whitelisted = true;
						"broken":
							whitelisted = true;
						"momentum":
							whitelisted = true;
				GameLogic.Undo.change_terrain:
					whitelisted = true;
				GameLogic.Undo.tick:
					whitelisted = true;
			if (!whitelisted):
				continue
			# reverse order since undo buffer is 'in reverse order'
			relevant_buffer.push_front(event);
	if relevant_buffer.size() <= 0:
		return
	var scale = 1;
	var size = 12;
	var y_start = 0;
	if (relevant_buffer.size() == 1):
		scale = 2;
	elif (relevant_buffer.size() == 2):
		y_start = 6;
	elif (relevant_buffer.size() <= 4):
		pass
	elif (relevant_buffer.size() <= 6):
		size = 8;
		y_start = 4;
	else:
		size = 8;
		y_start = 0;
	for i in range(relevant_buffer.size()):
		var event = relevant_buffer[i];
		var sprite = Sprite.new();
		sprite.set_script(preload("res://timeline/TimelineSprite.gd"));
		timelinesymbols.add_child(sprite);
		sprite.offset = Vector2(size/2, size/2);
		sprite.position.x = 0 + (i%(24/size))*size;
		sprite.position.y = y_start + floor(i/(24/size))*size;
		sprite.scale = Vector2(scale, scale);
		sprite.destination_colour = event[1].color;
		sprite.modulate = Color(1, 1, 1, 0);
		sprite.texture = get_texture_for_event(event, size);
		sprite.animation_nonce = get_animation_nonce_for_event(event);
		if (event[0] == GameLogic.Undo.set_actor_var and event[2] == "broken"):
			sprite.is_broken = true;
		sprite.viewer = parent;
		parent.broadcast_sprite(sprite);

func get_animation_nonce_for_event(event) -> int:
	if event[0] == GameLogic.Undo.move:
		return event[6];
	elif event[0] == GameLogic.Undo.set_actor_var:
		return event[5];
	elif event[0] == GameLogic.Undo.change_terrain:
		return event[6];
	elif event[0] == GameLogic.Undo.tick:
		return event[3];
	return -1;

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
			match prop:
				"airborne":
					if new_value == 2:
						pass
					elif new_value == 1:
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
			if size == 8:
				return preload("res://timeline/timeline-terrain-8.png");
			elif size == 12:
				return preload("res://timeline/timeline-terrain-12.png");
		GameLogic.Undo.tick:
			if size == 8:
				return preload("res://timeline/timeline-tick-8.png");
			elif size == 12:
				return preload("res://timeline/timeline-tick-12.png");
			
	if size == 8:
		return preload("res://timeline/timeline-what-8.png");
	else:
		return preload("res://timeline/timeline-what-12.png");

func fuzz_on() -> void:
	if (!showing_fuzz):
		showing_fuzz = true;
		fuzz_timer = 0;
		undo_effect_strength = 1;
		undo_effect_color = Color(1, 1, 1, 1);
		overlay.texture = preload("res://timeline/FuzzOverlayAnimatedTexture.tres");
	
func fuzz_activate() -> void:
	if (showing_fuzz):
		showing_fuzz = false;
		undo_effect_strength = 0.6;
		undo_effect_color = Color(1, 1, 1, 1);
		overlay.texture = preload("res://timeline/white-overlay.png");
	
func fuzz_off() -> void:
	if (showing_fuzz):
		showing_fuzz = false;
		undo_effect_strength = 0.01;
		undo_effect_color = Color(1, 1, 1, 1);
		overlay.texture = preload("res://timeline/white-overlay.png");

func clear(color: Color) -> void:
	for sprite in timelinesymbols.get_children():
		sprite.fading = true;
	undo_effect_color = color;
	undo_effect_strength = 0.5;

func finish_animations() -> void:
	z_index = 0; #have to explicitly do this since we might be elevated but not in motion
	if (region_timer < region_timer_max):
		region_timer = region_timer_max;
		region_enabled = false;
		offset = Vector2(12, 12);
	
	if (crystal_timer_max > 0):
		lock_animation_part_2();
		
	if (lock_timer_max > 0):
		lock_animation_part_3();
		
	if (motion_timer_max > 0):
		finish_motion();
		
func finish_motion() -> void:
	position = motion_end;
	motion_timer_max = 0;
	z_index = 0;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (lock_timer_max > 0):
		lock_timer += delta;
		if (lock_timer >= lock_timer_max):
			lock_timer -= lock_timer_max;
			lockanimation.frame += 1;
			if (lockanimation.frame + 1 == lockanimation.hframes):
				lock_animation_part_3();
	
	if (crystal_timer_max > 0):
		crystal_timer += delta;
		if (crystal_timer >= crystal_timer_max):
			crystal_timer -= crystal_timer_max;
			crystalanimation.frame += 1;
			if (crystalanimation.frame + 1 == crystalanimation.hframes):
				lock_animation_part_2();
	
	if (region_timer < region_timer_max):
		region_timer += delta;
		if (region_timer > region_timer_max):
			region_enabled = false;
			offset = Vector2(12, 12);
		else:
			region_rect = Rect2(20, 20, 32, 32*(region_timer/region_timer_max));
			offset = Vector2(12, 12-16+32*(region_timer/region_timer_max)/2);
	
	if (motion_timer_max > 0):
		motion_timer += delta;
		if (motion_timer >= motion_timer_max):
			finish_motion();
		else:
			position = lerp(motion_start, motion_end, motion_timer / motion_timer_max);
	
	if (showing_fuzz):
		fuzz_timer += delta;
		overlay.modulate = Color(1, 1, 1, 0.25+cos(fuzz_timer*3)/4);
	elif (undo_effect_strength > 0):
		undo_effect_strength -= delta*undo_effect_loss_per_second;
		if (undo_effect_strength > 0):
			overlay.modulate = Color(undo_effect_color.r, undo_effect_color.g, undo_effect_color.b, undo_effect_strength);
		else:
			overlay.modulate = Color(1, 1, 1, 0);
