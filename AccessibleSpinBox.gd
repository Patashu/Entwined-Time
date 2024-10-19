extends SpinBox
class_name AccessibleSpinBox

func _input(event):
	# the line edit inside of us
	if !self.get_child(0).has_focus():
		return
	
	if (event.is_action_pressed("ui_left") or Input.is_action_just_pressed("nonaxis_left")):
		self.value -= 1;
		get_viewport().set_input_as_handled();
	elif (event.is_action_pressed("ui_right") or Input.is_action_just_pressed("nonaxis_right")):
		self.value += 1;
		get_viewport().set_input_as_handled();
	else:
		pass
