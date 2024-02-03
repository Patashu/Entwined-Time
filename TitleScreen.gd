extends Node2D
class_name TitleScreen

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var beginbutton : Button = get_node("Holder/BeginButton");
onready var controlsbutton : Button = get_node("Holder/ControlsButton");
onready var settingsbutton : Button = get_node("Holder/SettingsButton");
onready var creditsbutton : Button = get_node("Holder/CreditsButton");

func _ready() -> void:
	beginbutton.connect("pressed", self, "_beginbutton_pressed");
	controlsbutton.connect("pressed", self, "_controlsbutton_pressed");
	settingsbutton.connect("pressed", self, "_settingsbutton_pressed");
	creditsbutton.connect("pressed", self, "_creditsbutton_pressed");

func _beginbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
		
	destroy();

func _controlsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Controls.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	
func _settingsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Settings.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	
func _creditsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
		
	pass
	
func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		beginbutton.grab_focus();
		focus = beginbutton;
	
	var focus_middle_x = focus.rect_position.x + focus.rect_size.x / 2;
	pointer.position.y = focus.rect_position.y + focus.rect_size.y / 2;
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = focus.rect_position.x + focus.rect_size.x + 12;
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = focus.rect_position.x - 12;
