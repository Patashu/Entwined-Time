extends Node2D
class_name LevelEditorMenu

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var exiteditorbutton : Button = get_node("Holder/ExitEditorButton");
onready var levelinfobutton : Button = get_node("Holder/LevelInfoButton");
onready var copylevelbutton : Button = get_node("Holder/CopyLevelButton");
onready var pastelevelbutton : Button = get_node("Holder/PasteLevelButton");
onready var instructionsbutton : Button = get_node("Holder/InstructionsButton");
onready var newlevelbutton : Button = get_node("Holder/NewLevelButton");
onready var savetscnbutton : Button = get_node("Holder/SaveTscnButton");
onready var testlevelbutton : Button = get_node("Holder/TestLevelButton");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	okbutton.grab_focus();
	okbutton.connect("pressed", self, "destroy");
	exiteditorbutton.connect("pressed", self, "_exiteditorbutton_pressed");
	levelinfobutton.connect("pressed", self, "_levelinfobutton_pressed");
	copylevelbutton.connect("pressed", self, "_copylevelbutton_pressed");
	pastelevelbutton.connect("pressed", self, "_pastelevelbutton_pressed");
	instructionsbutton.connect("pressed", self, "_instructionsbutton_pressed");
	newlevelbutton.connect("pressed", self, "_newlevelbutton_pressed");
	testlevelbutton.connect("pressed", self, "_testlevelbutton_pressed");
	if (OS.is_debug_build()):
		savetscnbutton.connect("pressed", self, "_savetscnbutton_pressed");
	else:
		savetscnbutton.get_parent().remove_child(savetscnbutton);
		savetscnbutton.queue_free();

func _exiteditorbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	self.get_parent().destroy();
	destroy();
	
func _levelinfobutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://level_editor/LevelInfoEdit.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	destroy();
	
func _copylevelbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	self.get_parent().copy_level();
	destroy();
	
func _pastelevelbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	self.get_parent().paste_level();
	destroy();
	
func _instructionsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://level_editor/Instructions.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	destroy();
	
func _savetscnbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	self.get_parent().save_as_tscn();
	destroy();
	
func _testlevelbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	self.get_parent().test_level();
	destroy();
	
func _newlevelbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	self.get_parent().new_level();
	destroy();

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		destroy();
	if (Input.is_action_just_pressed("ui_cancel")):
		destroy();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		okbutton.grab_focus();
		focus = okbutton;
	
	var focus_middle_x = focus.rect_position.x + focus.rect_size.x / 2;
	pointer.position.y = focus.rect_position.y + focus.rect_size.y / 2;
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = focus.rect_position.x + focus.rect_size.x + 12;
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = focus.rect_position.x - 12;
		
	# constantly check if we could paste this level or not
	if gamelogic.clipboard_contains_level():
		pastelevelbutton.disabled = false;
	else:
		pastelevelbutton.disabled = true;

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
