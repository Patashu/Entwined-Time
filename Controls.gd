extends Node2D
class_name Controls

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var okbutton : Button = get_node("Holder/OkButton");

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	okbutton.grab_focus();

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
		destroy();

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
