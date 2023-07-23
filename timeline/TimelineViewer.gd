extends Node2D
class_name TimelineViewer

export var is_heavy = false;
var current_move = 0;
var max_moves = 0;
var yy = 24;
var xx = 24;
var y_max = 11;
var animating_children = [];
onready var timelineslots = self.get_node("TimelineSlots");
onready var timelinedivider = self.get_node("TimelineDivider");
var nonce_to_sprite_dictionary = {};
var fade_timer = 0;
var fade_timer_max = 0;
var label : Label = null;
var actor = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (is_heavy):
		timelinedivider.texture = preload("res://timeline/timeline-divider-heavy.png");
	else:
		xx = -24;
		timelinedivider.texture = preload("res://timeline/timeline-divider-light.png");
	reset();

func reset() -> void:
	if (timelinedivider == null):
		return
	end_fade()
	current_move = 0;
	timelinedivider.position.x = 0;
	timelinedivider.position.y = 0;
	for slot in timelineslots.get_children():
		slot.queue_free();
	for sprite in nonce_to_sprite_dictionary:
		if is_instance_valid(sprite):
			sprite.queue_free();
	nonce_to_sprite_dictionary.clear();
	animating_children.clear();
	for i in range(max_moves):
		var slot = preload("res://timeline/TimelineSlot.tscn").instance();
		slot.parent = self;
		if (is_heavy):
			slot.texture = preload("res://timeline/timeline-slot-heavy-24.png");
		else:
			slot.texture = preload("res://timeline/timeline-slot-light-24.png");
		timelineslots.add_child(slot);
		slot.position.y += yy*(i%y_max);
		slot.position.x += xx*floor(i/y_max);

func finish_slot_positions(slow: bool = false) -> void:
	var i = 0;
	for slot in timelineslots.get_children():
		if (slow):
			slot.start_motion(Vector2(xx*floor(i/y_max), yy*(i%y_max)));
		else:
			slot.position.y = yy*(i%y_max);
			slot.position.x = xx*floor(i/y_max);
		i += 1;

func finish_divider_position() -> void:
	if (current_move) == 0:
		timelinedivider.position.y = 0;
		timelinedivider.position.x = 0;
	else:
		timelinedivider.position.y = yy*(((current_move-1)%y_max)+1);
		timelinedivider.position.x = xx*floor((current_move-1)/y_max);

func broadcast_animation_nonce(animation_nonce: int) -> void:
	if nonce_to_sprite_dictionary.has(animation_nonce) and is_instance_valid(nonce_to_sprite_dictionary[animation_nonce]):
		nonce_to_sprite_dictionary[animation_nonce].flash();
	
func broadcast_remove_sprite(sprite: TimelineSprite) -> void:
	nonce_to_sprite_dictionary.erase(sprite.animation_nonce);
	
func broadcast_sprite(sprite: TimelineSprite) -> void:
	nonce_to_sprite_dictionary[sprite.animation_nonce] = sprite;

func finish_slot_animations() -> void:
	for child in timelineslots.get_children():
		if is_instance_valid(child):
			child.finish_animations();

func finish_animations() -> void:
	finish_slot_animations();
	for sprite in nonce_to_sprite_dictionary.values():
		if is_instance_valid(sprite):
			sprite.finish_animations();

func add_max_turn() -> void:
	max_moves += 1;
	var i = max_moves -1;
	var slot = preload("res://timeline/TimelineSlot.tscn").instance();
	slot.parent = self;
	slot.texture = preload("res://assets/TestCrystalFrame.png");
	slot.region_enabled = true;
	slot.region_rect = Rect2(20, 20, 32, 0);
	slot.region_timer_max = 0.5;
	timelineslots.add_child(slot);
	slot.position.y += yy*(i%y_max);
	slot.position.x += xx*floor(i/y_max);
	
func undo_add_max_turn() -> void:
	max_moves -= 1;
	var last_slot = timelineslots.get_children().pop_back();
	last_slot.queue_free();
	
func lock_turn(turn_locked: int, slow: bool = true) -> TimelineSlot:
	# I didn't actually end up using turn_locked since it's unambiguous, but I COULD.
	# this will have happened AFTER add_turn. So we just lock the appropriate turn or an empty slot at the end.
	# Aha, not so fast! For now we call it from undo_unlock_turn too.
	# Just to be safe, I'll only use the different behaviour in the case I know breaks.
	var slot_to_move = null;
	if (slow == false and turn_locked == -1):
		# bashy, but another case was found (light remembers an empty slot on their turn then meta-undos)
		# that was broken, and I just want to be 100% sure I always get it correct and don't regress old cases, so...
		slot_to_move = timelineslots.get_child(max_moves-1);
		for slot in timelineslots.get_children():
			# 'find last slot that is green crystal and empty'
			if slot.crystalanimation.visible and (slot.crystalanimation.texture == preload("res://assets/CrystalFrameAnimationPB.png") or slot.crystalanimation.texture == preload("res://assets/TestCrystalFrame.png") and slot.timelinesymbols.get_children().size() == 0):
					slot_to_move = slot;
					# no break b/c last
		
	else:
		if current_move > 0:
			slot_to_move = timelineslots.get_child(current_move-1);
			current_move -= 1;
		else:
			slot_to_move = timelineslots.get_child(max_moves-1);
	max_moves -= 1; # NOTE: this means max_moves isn't the same as 'number of slots' anymore
	timelineslots.remove_child(slot_to_move);
	timelineslots.add_child(slot_to_move);
	slot_to_move.fuzz_off();
	slot_to_move.lock_animation();
	slot_to_move.locked = true;
	finish_divider_position();
	finish_slot_positions(slow);
	return slot_to_move;
	
func undo_lock_turn(slow: bool = false) -> TimelineSlot:
	# We know which turn we most recently locked, it's the one at the bottom - so just move it back
	var slot_to_move = timelineslots.get_child(timelineslots.get_children().size()-1);
	# no animation since this is a meta undo function only
	slot_to_move.undo_lock_animation();
	# if it's empty, move it just after max_moves.
	if (slot_to_move.timelinesymbols.get_children().size() == 0):
		timelineslots.move_child(slot_to_move, max_moves);
	# if it's not empty, move it just after current_move and increment current_move by 1.
	else:
		# for some reason we need to distinguish between 'entered a nega time crystal on our move' and 'otherwise'.
		# quickest to just count timelineslots until they stop having non-fading children.
		# or is locked.
		var i = 0;
		for slot in timelineslots.get_children():
			if slot.timelinesymbols.get_children().size() == 0 or slot.locked:
				break
			var fading = false;
			for sprite in slot.timelinesymbols.get_children():
				if sprite.fading:
					fading = true;
					break;
			if fading:
				break; #the legendary double break
			i += 1;
		timelineslots.move_child(slot_to_move, i);
		current_move += 1;
	# either way, now increment max_moves by 1.
	max_moves += 1;
	# and finally unlock.
	slot_to_move.locked = false;
	finish_divider_position();
	finish_slot_positions(slow);
	return slot_to_move;

func unlock_turn(turn: int) -> void:
	# just re-use all that code I wrote real quick and...
	var slot_to_move = undo_lock_turn(true);
	slot_to_move.remember_animation();
	
func undo_unlock_turn(turn: int) -> void:
	# the opposite of unlocking is locking again, so let's try that and see if it works...
	# have to adjust current_move first. hopefully this ain't TOO hacky.
	var slot_to_move = lock_turn(turn, false);
	slot_to_move.undo_remember_animation();

func add_turn(buffer: Array) -> void:
	if current_move >= (max_moves):
		return
	if (current_move > 0):
		timelineslots.get_child(current_move-1).fuzz_off();
	timelineslots.get_child(current_move).fill(buffer);
	current_move += 1;
	finish_divider_position();
	
func remove_turn(color: Color, locked_turn: int, turn_filled_actual: int) -> void:
	# 'we're meta-undoing a turn that ended up stuck behind an unlocked turn' is ALSO weird.
	# Let me try and figure this out...
	if turn_filled_actual > -1:
		var slot = timelineslots.get_child(turn_filled_actual);
		slot.clear(color);
		# then slide everything unlocked above it down one...
		timelineslots.move_child(slot, max_moves-1);
		current_move -= 1;
		finish_divider_position();
		finish_slot_positions();
		return;
	
	# 'we're meta-undoing a turn we took that ended up locked' has different behaviour.
	# I THINK this is correct.
	elif (locked_turn > -1):
		timelineslots.get_child(max_moves + locked_turn).clear(color);
		current_move -= 1;
		finish_divider_position();
		return;
	
	if current_move <= 0:
		return
	elif (current_move > 0):
		timelineslots.get_child(current_move-1).fuzz_off();
	current_move -= 1;
	finish_divider_position();
	timelineslots.get_child(current_move).clear(color);

func fuzz_on() -> void:
	if (current_move <= 0):
		return;
	timelineslots.get_child(current_move-1).fuzz_on();
	
func fuzz_activate() -> void:
	if (current_move <= 0):
		return;
	timelineslots.get_child(current_move-1).fuzz_activate();
	
func fuzz_off() -> void:
	if (current_move <= 0):
		return;
	timelineslots.get_child(current_move-1).fuzz_off();

func start_fade() -> void:
	fade_timer = 0;
	fade_timer_max = 2;

func end_fade() -> void:
	fade_timer = 0;
	fade_timer_max = 0;
	fade_myself_and_friends(1.0);

func fade_myself_and_friends(value: float) -> void:
	modulate.r = value;
	modulate.g = value;
	modulate.b = value;
	if (label != null):
		label.modulate.r = value;
		label.modulate.g = value;
		label.modulate.b = value;
	if (is_instance_valid(actor)):
		actor.self_modulate.r = value;
		actor.self_modulate.g = value;
		actor.self_modulate.b = value;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (fade_timer < fade_timer_max):
		fade_timer += delta;
		if (fade_timer > fade_timer_max):
			fade_timer = fade_timer_max;
		var value = 1-0.6*(fade_timer/fade_timer_max);
		fade_myself_and_friends(value);
		
