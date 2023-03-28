extends Button
class_name LevelButton

var level_number = 0;
var levelselect;

func _pressed() -> void:
	levelselect.gamelogic.load_level_direct(level_number);
	levelselect.destroy();
	
