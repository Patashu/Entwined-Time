extends Button
class_name BindingButton

export var action: String = "";
export var keyboard_mode: bool = true;
export var i: int = 0;
var parent: Node2D = null;
var image: Sprite = null;

func _ready() -> void:
	set_process_unhandled_input(false)

func _toggled(is_button_pressed):
	set_process_unhandled_input(is_button_pressed)
	if is_button_pressed:
		text = "(What?)"
		if (image != null):
			image.queue_free();
			image = null;
		if (parent.rebinding_button != null):
			parent.rebinding_button.pressed = false;
			parent.rebinding_button._toggled(false);
		parent.rebinding_button = self;
	else:
		display_current_key()
	grab_focus();
		
func _unhandled_input(event):
	if event is InputEventJoypadButton and !keyboard_mode:
		remap_action_to(event)
		pressed = false
	elif event is InputEventKey and keyboard_mode:
		remap_action_to(event)
		pressed = false

func remap_action_to(event):
	pass
	# We first change the event in this game instance.
	#InputMap.action_erase_events(action)
	#InputMap.action_add_event(action, event)
	# And then save it to the keymaps file
	#KeyPersistence.keymaps[action] = event
	#KeyPersistence.save_keymap()
	#text = "%s Key" % event.as_text()


func display_current_key():
	parent.setup_button(self);
	#var current_key = InputMap.action_get_events(action)[0].as_text()
	#text = "%s Key" % current_key
