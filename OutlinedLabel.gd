extends Node2D
class_name OutlinedLabel

var label = null;
var shadow_labels = [];

func squish_mode() -> void:
	for sl in shadow_labels:
		sl.autowrap = true;
		sl.rect_min_size = Vector2(100, 100);
		sl.align = Label.ALIGN_LEFT;
	label.autowrap = true;
	label.rect_min_size = Vector2(100, 100);
	label.align = Label.ALIGN_LEFT;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var offsets = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT];
	
	for offset in offsets:
		var sl = Label.new();
		shadow_labels.append(sl);
		sl.align = Label.ALIGN_CENTER;
		sl.rect_position = offset;
		self.add_child(sl);
		sl.theme = preload("res://DefaultTheme.tres");
		sl.add_color_override("font_color", Color(0, 0, 0, 1));
		
	label = Label.new();
	label.align = Label.ALIGN_CENTER;
	self.add_child(label);
	label.theme = preload("res://DefaultTheme.tres");

func change_text(text: String) -> void:
	for sl in shadow_labels:
		sl.text = text;
	label.text = text;

func set_align(value: int) -> void:
	for sl in shadow_labels:
		sl.align = value;
	label.align = value;

func get_rect_position() -> Vector2:
	return label.rect_position;

func set_rect_position(value: Vector2) -> void:
	var offsets = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT];
	
	for i in range(4):
		var offset = offsets[i];
		var sl = shadow_labels[i];
		sl.rect_position = offset + value;
	label.rect_position = value;
	
func get_rect_size() -> Vector2:
	return label.rect_size;

func set_rect_size(value: Vector2) -> void:
	for sl in shadow_labels:
		sl.rect_size = value;
	label.rect_size = value;
	
