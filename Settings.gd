extends Node2D
class_name Settings

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var okbutton : Button = get_node("Holder/OkButton");
onready var unlockeverything : CheckBox = get_node("Holder/UnlockEverything");
onready var pixelscale : SpinBox = get_node("Holder/PixelScale");
onready var vsync : CheckBox = get_node("Holder/VSync");

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	okbutton.grab_focus();
	unlockeverything.pressed = gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"];
	if (gamelogic.save_file.has("vsync_enabled")):
		vsync.pressed = gamelogic.save_file["vsync_enabled"];
	if (gamelogic.save_file.has("pixel_scale")):
		pixelscale.value = gamelogic.save_file["pixel_scale"];
	unlockeverything.connect("pressed", self, "_unlockeverything_pressed");
	vsync.connect("pressed", self, "_vsync_pressed");
	pixelscale.connect("value_changed", self, "_pixelscale_value_changed");

func _unlockeverything_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["unlock_everything"] = unlockeverything.pressed;

func _vsync_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["vsync_enabled"] = vsync.pressed;
	OS.vsync_enabled = vsync.pressed;

func _pixelscale_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["pixel_scale"] = value;
	gamelogic.setup_resolution();

func destroy() -> void:
	gamelogic.save_game();
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
		destroy();

func _draw() -> void:
	draw_rect(Rect2(-get_viewport().size.x, -get_viewport().size.y,
	get_viewport().size.x*2, get_viewport().size.y*2), Color(0, 0, 0, 0.5), true);
