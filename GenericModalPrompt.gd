extends Node2D
class_name GenericModalPrompt

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var okbutton : Button = get_node("Holder/OkButton");
onready var cancelbutton : Button = get_node("Holder/CancelButton");
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");

func _ready() -> void:
	cancelbutton.connect("pressed", self, "destroy");
	okbutton.connect("pressed", self, "accept");

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

func accept() -> void:
	destroy();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
		destroy();
	elif (Input.is_action_just_released("ui_cancel")):
		destroy();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		cancelbutton.grab_focus();
		focus = cancelbutton;
	
	var focus_middle_x = round(focus.rect_position.x + focus.rect_size.x / 2);
	pointer.position.y = round(focus.rect_position.y + focus.rect_size.y / 2);
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = round(focus.rect_position.x + focus.rect_size.x + 12);
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = round(focus.rect_position.x - 12);

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
