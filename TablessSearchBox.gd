extends LineEdit
class_name TablessSearchBox

func _input(event):
	if !self.has_focus():
		return
	
	if (Input.is_action_just_pressed("tab")):
		get_viewport().set_input_as_handled();
