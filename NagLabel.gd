extends GoldLabel
class_name NagLabel
onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[0].name == "Menu"):
		self.queue_free();
		return;
	if gamelogic.save_file["levels"].has(gamelogic.level_name) and gamelogic.save_file["levels"][gamelogic.level_name].has("won") and gamelogic.save_file["levels"][gamelogic.level_name]["won"]:
		self.queue_free();
		return;
