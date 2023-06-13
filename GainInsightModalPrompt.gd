extends Node2D
class_name GainInsightModalPrompt

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var okbutton : Button = get_node("Holder/OkButton");
onready var cancelbutton : Button = get_node("Holder/CancelButton");

func _ready() -> void:
	cancelbutton.connect("pressed", self, "destroy");
	#cancelbutton.grab_focus();
	okbutton.connect("pressed", self, "accept");

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

func accept() -> void:
	destroy();
	gamelogic.save_file["gain_insight"] = true;
	gamelogic.gain_insight();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
		destroy();
	elif (Input.is_action_just_released("ui_cancel")):
		destroy();
	elif (Input.is_action_just_released("character_undo")):
		destroy();
	elif (Input.is_action_just_released("ui_accept")):
		accept();
	elif (Input.is_action_just_released("character_switch")):
		accept();

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
