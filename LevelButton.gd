extends Button
class_name LevelButton

var level_number = 0;
var levelselect;

func _pressed() -> void:
	if (levelselect.gamelogic.ui_stack.size() > 0 and levelselect.gamelogic.ui_stack[levelselect.gamelogic.ui_stack.size() - 1] != levelselect):
		return;
	
	levelselect.gamelogic.load_level_direct(level_number);
	levelselect.destroy();
	
