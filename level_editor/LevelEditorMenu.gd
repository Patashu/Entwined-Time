extends Node2D
class_name LevelEditorMenu

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var exiteditorbutton : Button = get_node("Holder/ExitEditorButton");

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	exiteditorbutton.connect("pressed", self, "_exiteditorbutton_pressed");

func _exiteditorbutton_pressed() -> void:
	self.get_parent().destroy();
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
		
	# constantly check if we could paste this replay or not
	#if gamelogic.clipboard_contains_level():
	#	pastereplaybutton.disabled = false;
	#	pastereplaybutton.text = "Paste Level";
	#elif (gamelogic.is_valid_replay(OS.get_clipboard())):
	#	pastereplaybutton.disabled = false;
	#	pastereplaybutton.text = "Paste Replay";
	#else:
	#	pastereplaybutton.disabled = true;
	#	pastereplaybutton.text = "Paste Replay";