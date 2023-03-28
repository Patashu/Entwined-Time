extends Node2D
class_name TimelineViewer

var is_heavy = false;
var current_move = 0;
var max_moves = 0;
var yy = 24;
onready var timelineslots = self.get_node("TimelineSlots");
onready var timelinedivider = self.get_node("TimelineDivider");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (is_heavy):
		timelinedivider.texture = preload("res://timeline/timeline-divider-heavy.png");
	else:
		timelinedivider.texture = preload("res://timeline/timeline-divider-light.png");
	reset();

func reset() -> void:
	if (timelinedivider == null):
		return
	current_move = 0;
	timelinedivider.position.y = 0;
	for slot in timelineslots.get_children():
		slot.queue_free();
	for i in range(max_moves):
		var slot = preload("res://timeline/TimelineSlot.tscn").instance();
		if (is_heavy):
			slot.texture = preload("res://timeline/timeline-slot-heavy-24.png");
		else:
			slot.texture = preload("res://timeline/timeline-slot-light-24.png");
		timelineslots.add_child(slot);
		slot.position.y += yy*i;

func add_turn(buffer: Array) -> void:
	if current_move >= (max_moves - 1):
		return
	timelineslots.get_child(current_move).fill(buffer);
	current_move += 1;
	timelinedivider.position.y += yy;
	
func remove_turn(color: Color) -> void:
	if current_move <= 0:
		return
	current_move -= 1;
	timelinedivider.position.y -= yy;
	timelineslots.get_child(current_move).clear(color);

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
