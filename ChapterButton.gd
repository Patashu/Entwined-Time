extends Button
class_name ChapterButton

onready var levelselect = get_tree().get_root().find_node("LevelSelect", true, false);

func _pressed() -> void:
	if (levelselect.gamelogic.ui_stack.size() > 0 and levelselect.gamelogic.ui_stack[levelselect.gamelogic.ui_stack.size() - 1] != levelselect):
		return;
	
	# find index of our text in chapter_names
	var index = -1;
	for i in range(levelselect.gamelogic.chapter_names.size()):
		if levelselect.gamelogic.chapter_names[i].find(self.text) >= 0:
			index = i;
			break;
	if (index != -1):
		levelselect.chapter = index;
		levelselect.community_levels_landing_state = -1;
		levelselect.communitylevelsholder.visible = false;
		levelselect.prepare_chapter();
	
