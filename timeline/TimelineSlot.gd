extends Sprite
class_name TimelineSlot

var undo_effect_strength = 0;
var undo_effect_loss_per_second = 0.5;
var undo_effect_color = Color(1, 1, 1, 1);
onready var timelinesymbols : Node2D = get_node("TimelineSymbols");
onready var overlay : Sprite = get_node("Overlay");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func fill(buffer: Array) -> void:
	var relevant_buffer = [];
	for event in buffer:
		if event[0] == 0 or event[0] == 1: # move or set_actor_var
			# also filter out airborne 2 for now
			# and powered
			if (event[0] == 1 and event[2] == "powered"):
				continue
			if event[0] == 1 and event[2] == "airborne" and event[4] == 2:
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
		timelinesymbols.add_child(sprite);
		sprite.offset = Vector2(size/2, size/2);
		sprite.position.x = 0 + (i%(24/size))*size;
		sprite.position.y = y_start + floor(i/(24/size))*size;
		sprite.scale = Vector2(scale, scale);
		sprite.modulate = event[1].color;
		sprite.texture = get_texture_for_event(event, size);

func get_texture_for_event(event: Array, size: int) -> Texture:
	#add_undo_event([Undo.move, actor, dir], chrono);
	#add_undo_event([Undo.set_actor_var, actor, prop, old_value], chrono);
	if event[0] == 0: #move
		var dir = event[2];
		if dir == Vector2.LEFT:
			if size == 8:
				return preload("res://timeline/timeline-left-8.png");
			elif size == 12:
				return preload("res://timeline/timeline-left-12.png");
		elif dir == Vector2.RIGHT:
			if size == 8:
				return preload("res://timeline/timeline-right-8.png");
			elif size == 12:
				return preload("res://timeline/timeline-right-12.png");
		elif dir == Vector2.UP:
			if size == 8:
				return preload("res://timeline/timeline-up-8.png");
			elif size == 12:
				return preload("res://timeline/timeline-up-12.png");
		elif dir == Vector2.DOWN:
			if size == 8:
				return preload("res://timeline/timeline-down-8.png");
			elif size == 12:
				return preload("res://timeline/timeline-down-12.png");
		pass
	if event[0] == 1: #set_actor_var
		var prop = event[2];
		var new_value = event[4];
		if prop == "airborne":
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
		elif prop == "broken":
			if new_value == true:
				if size == 8:
					return preload("res://timeline/timeline-broken-8.png");
				elif size == 12:
					return preload("res://timeline/timeline-broken-12.png");
			pass
		
	return null

func clear(color: Color) -> void:
	for sprite in timelinesymbols.get_children():
		sprite.queue_free();
	undo_effect_color = color;
	undo_effect_strength = 0.5;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (undo_effect_strength > 0):
		undo_effect_strength -= delta*undo_effect_loss_per_second;
		if (undo_effect_strength > 0):
			overlay.modulate = Color(undo_effect_color.r, undo_effect_color.g, undo_effect_color.b, undo_effect_strength);
		else:
			overlay.modulate = Color(1, 1, 1, 0);
