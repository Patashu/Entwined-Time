extends Button
class_name BindingButton

export var action: String = "";
export var keyboard_mode: bool = true;
export var i: int = 0;
var event: InputEvent = null;
var parent: Node2D = null;
var image: Sprite = null;

func _ready() -> void:
	set_process_unhandled_input(false)
	set_process_unhandled_key_input(false)

func _toggled(is_button_pressed):
	set_process_unhandled_input(is_button_pressed)
	set_process_unhandled_key_input(is_button_pressed)
	if is_button_pressed:
		text = "(What?)"
		if (image != null):
			image.queue_free();
			image = null;
		if (parent.rebinding_button != null):
			parent.rebinding_button.pressed = false;
			parent.rebinding_button._toggled(false);
		parent.rebinding_button = self;
		release_focus();
	else:
		display_current_key()
		
func _unhandled_input(new_event : InputEvent):
	if new_event is InputEventJoypadButton and !keyboard_mode and new_event.is_pressed():
		parent.remap_dance(self, new_event)
		pressed = false
		
func _unhandled_key_input(new_event : InputEventKey):
	if keyboard_mode and new_event.is_pressed():
		parent.remap_dance(self, new_event)
		pressed = false

func display_current_key():
	parent.setup_button(self);
