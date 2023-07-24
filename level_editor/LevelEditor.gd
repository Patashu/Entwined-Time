extends Node2D
class_name LevelEditor

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var menubutton : Button = get_node("MenuButton");
onready var tilemaps : Node2D = get_node("TileMaps");
var custom_string = "";
var level_info : LevelInfo = null;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_string = gamelogic.serialize_current_level();
	var level = gamelogic.deserialize_custom_level(custom_string);
	menubutton.connect("pressed", self, "_menubutton_pressed");
	tilemaps.add_child(level);
	level_info = level.get_node("LevelInfo");
	gamelogic.tile_changes(true);

func _menubutton_pressed() -> void:
	var a = preload("res://level_editor/LevelEditorMenu.tscn").instance();
	add_child(a);
	gamelogic.ui_stack.push_back(a);

func destroy() -> void:
	gamelogic.tile_changes(false);
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		_menubutton_pressed();
