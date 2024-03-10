extends Node2D
class_name LevelSelect

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;
onready var holder : Label = get_node("Holder");
onready var chapter = gamelogic.chapter;
onready var prevbutton : Button = get_node("Holder/PrevButton");
onready var nextbutton : Button = get_node("Holder/NextButton");
onready var leveleditorbutton : Button = get_node("Holder/LevelEditorButton");
onready var communitylevelsbutton : Button = get_node("Holder/CommunityLevelsButton");
onready var closebutton : Button = get_node("Holder/CloseButton");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var specialbuttons = [prevbutton, nextbutton, leveleditorbutton, communitylevelsbutton, closebutton, pointer];
var buttons_by_xy = {};
var cutscene_button = null;
var in_community_puzzles = false;

func _ready() -> void:
	prepare_chapter();
	update_focus_neighbors();
	prevbutton.connect("pressed", self, "_prevbutton_pressed");
	nextbutton.connect("pressed", self, "_nextbutton_pressed");
	leveleditorbutton.connect("pressed", self, "_leveleditorbutton_pressed");
	communitylevelsbutton.connect("pressed", self, "_communitylevelsbutton_pressed");
	closebutton.connect("pressed", self, "destroy");
	
	if (gamelogic.chapter >= gamelogic.custom_past_here):
		in_community_puzzles = true;
		communitylevelsbutton.text = "Campaign Levels";
		if (gamelogic.chapter_names.size() -1 == gamelogic.custom_past_here):
			prevbutton.disabled = true;
			nextbutton.disabled = true;
	elif !(gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]):
		if (gamelogic.puzzles_completed < gamelogic.chapter_standard_unlock_requirements[gamelogic.custom_past_here]):
			communitylevelsbutton.disabled = true;
			communitylevelsbutton.text = "???";
	
	nextbutton.text = "Next Chapter (" + gamelogic.human_readable_input("next_level", 1) + ")";
	prevbutton.text = "Prev. Chapter (" + gamelogic.human_readable_input("previous_level", 1) + ")";
	
func _prevbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	chapter -= 1;
	if (in_community_puzzles):
		chapter = posmod(int(chapter) - gamelogic.custom_past_here, gamelogic.chapter_names.size() - gamelogic.custom_past_here) + gamelogic.custom_past_here;
	else:
		chapter = posmod(int(chapter), gamelogic.custom_past_here);
	prepare_chapter();
	update_focus_neighbors();
	prevbutton.grab_focus();

func _nextbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	chapter += 1;
	if (in_community_puzzles):
		chapter = posmod(int(chapter) - gamelogic.custom_past_here, gamelogic.chapter_names.size() - gamelogic.custom_past_here) + gamelogic.custom_past_here;
	else:
		chapter = posmod(int(chapter), gamelogic.custom_past_here);
	prepare_chapter();
	update_focus_neighbors();
	nextbutton.grab_focus();

func _leveleditorbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://level_editor/LevelEditor.tscn").instance();
	gamelogic.add_to_ui_stack(a, get_parent());
	destroy();

func _communitylevelsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
		
	in_community_puzzles = !in_community_puzzles;
	if (in_community_puzzles):
		chapter = gamelogic.custom_past_here;
		prepare_chapter();
		update_focus_neighbors();
		communitylevelsbutton.text = "Campaign Levels";
		if (gamelogic.chapter_names.size() -1 == gamelogic.custom_past_here):
			prevbutton.disabled = true;
			nextbutton.disabled = true;
	else:
		chapter = 0;
		prepare_chapter();
		update_focus_neighbors();
		communitylevelsbutton.text = "Community Levels";
		prevbutton.disabled = false;
		nextbutton.disabled = false;

func update_focus_neighbors() -> void:
	for pos in buttons_by_xy.keys():
		var button = buttons_by_xy[pos];
		
		# up
		button.focus_neighbour_top = button.get_path_to(closebutton);
		# also handle close button right right now ig
		if (pos.x == 0 and pos.y == 1 and cutscene_button == null):
			closebutton.focus_neighbour_right = closebutton.get_path_to(button);
			prevbutton.focus_neighbour_bottom = prevbutton.get_path_to(button);
		
		if (pos.x == 0 and pos.y == 1 and cutscene_button != null):
			button.focus_neighbour_top = button.get_path_to(cutscene_button);
			prevbutton.focus_neighbour_bottom = prevbutton.get_path_to(cutscene_button);
		elif (buttons_by_xy.has(pos + Vector2.UP)):
			button.focus_neighbour_top = button.get_path_to(buttons_by_xy[pos + Vector2.UP]);
		elif (buttons_by_xy.has(pos + Vector2.UP + Vector2.UP)):
			button.focus_neighbour_top = button.get_path_to(buttons_by_xy[pos + Vector2.UP + Vector2.UP]);
		elif (buttons_by_xy.has(pos + Vector2.LEFT + Vector2.UP)):
			button.focus_neighbour_top = button.get_path_to(buttons_by_xy[pos + Vector2.LEFT + Vector2.UP]);
		elif (buttons_by_xy.has(pos + Vector2.RIGHT + Vector2.UP)):
			button.focus_neighbour_top = button.get_path_to(buttons_by_xy[pos + Vector2.RIGHT + Vector2.UP]);
			
		# down
		var sideways = Vector2.RIGHT;
		if (pos.x == 0):
			button.focus_neighbour_bottom = button.get_path_to(prevbutton);
		else:
			button.focus_neighbour_bottom = button.get_path_to(nextbutton);
			sideways = Vector2.LEFT;
		
		if (buttons_by_xy.has(pos + Vector2.DOWN)):
			button.focus_neighbour_bottom = button.get_path_to(buttons_by_xy[pos + Vector2.DOWN]);
		elif (buttons_by_xy.has(pos + Vector2.DOWN + Vector2.DOWN)):
			button.focus_neighbour_bottom = button.get_path_to(buttons_by_xy[pos + Vector2.DOWN + Vector2.DOWN]);
		# make sure it's symmetrical
		elif (button.focus_neighbour_bottom == button.get_path_to(prevbutton)):
			prevbutton.focus_neighbour_top = prevbutton.get_path_to(button);
		elif (button.focus_neighbour_bottom == button.get_path_to(nextbutton)):
			nextbutton.focus_neighbour_top = prevbutton.get_path_to(button);
			
		# left and right
		for i in range(10):
			if (buttons_by_xy.has(pos + sideways - Vector2.UP*i)):
				button.focus_neighbour_left = button.get_path_to(buttons_by_xy[pos + sideways - Vector2.UP*i]);
				button.focus_neighbour_right = button.get_path_to(buttons_by_xy[pos + sideways - Vector2.UP*i]);
				break;
			elif (buttons_by_xy.has(pos + sideways - Vector2.UP*i)):
				button.focus_neighbour_left = button.get_path_to(buttons_by_xy[pos + sideways - Vector2.UP*i]);
				button.focus_neighbour_right = button.get_path_to(buttons_by_xy[pos + sideways - Vector2.UP*i]);
				break;
			
		# focus button down and left
		if (buttons_by_xy.has(Vector2(0, 0))):
			closebutton.focus_neighbour_left = button.get_path_to(buttons_by_xy[Vector2(0, 0)]);
			closebutton.focus_neighbour_bottom = button.get_path_to(buttons_by_xy[Vector2(0, 0)]);
		elif (buttons_by_xy.has(Vector2(0, 1))):
			closebutton.focus_neighbour_left = button.get_path_to(buttons_by_xy[Vector2(0, 1)]);
			closebutton.focus_neighbour_bottom = button.get_path_to(buttons_by_xy[Vector2(0, 1)]);
			
		if (buttons_by_xy.has(Vector2(1, 0))):
			closebutton.focus_neighbour_bottom = button.get_path_to(buttons_by_xy[Vector2(1, 0)]);
		elif (buttons_by_xy.has(Vector2(1, 1))):
			closebutton.focus_neighbour_bottom = button.get_path_to(buttons_by_xy[Vector2(1, 1)]);
			
	#copy over level editor and community levels up/down from neighbours
	leveleditorbutton.focus_neighbour_top = prevbutton.focus_neighbour_top;
	leveleditorbutton.focus_neighbour_bottom = prevbutton.focus_neighbour_bottom;
	communitylevelsbutton.focus_neighbour_top = nextbutton.focus_neighbour_top;
	communitylevelsbutton.focus_neighbour_bottom = nextbutton.focus_neighbour_bottom;

func prepare_chapter() -> void:
	buttons_by_xy.clear();
	
	for child in holder.get_children():
		if !specialbuttons.has(child):
			child.queue_free();
			
	var unlock_requirement = gamelogic.chapter_standard_unlock_requirements[chapter];
	var requires_advanced_levels = (chapter == 2);
	if (requires_advanced_levels):
		holder.add_stylebox_override("normal", preload("res://dark_styleboxtexture.tres"));
	else:
		holder.add_stylebox_override("normal", preload("res://default_styleboxtexture.tres"));
	var chapter_string = str(chapter);
	if gamelogic.chapter_replacements.has(chapter):
		chapter_string = gamelogic.chapter_replacements[chapter];
	
	holder.finish_animations();
	var all_standard_stars = true;
	var all_advanced_stars = true;
	var ending_part_1 = false;
	var ending_part_2 = false;
	
	if (chapter == 0):
		cutscene_button = Button.new();
		holder.add_child(cutscene_button);
		cutscene_button.text = "Intro/Credits";
		cutscene_button.connect("pressed", self, "_intro_cutscene_pressed");
		cutscene_button.focus_neighbour_left = cutscene_button.get_path_to(closebutton);
		cutscene_button.focus_neighbour_top = cutscene_button.get_path_to(prevbutton);
		closebutton.focus_neighbour_right = closebutton.get_path_to(cutscene_button);
	elif (chapter == 11):
		cutscene_button = Button.new();
		holder.add_child(cutscene_button);
		
		if gamelogic.save_file["levels"].has("A Way In?") and gamelogic.save_file["levels"]["A Way In?"].has("won") and gamelogic.save_file["levels"]["A Way In?"]["won"]:
			ending_part_1 = true;
		if gamelogic.save_file["levels"].has("Chrono Lab Reactor") and gamelogic.save_file["levels"]["Chrono Lab Reactor"].has("won") and gamelogic.save_file["levels"]["Chrono Lab Reactor"]["won"]:
			ending_part_2 = true;
		
		if (ending_part_1 or (gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"])):
			cutscene_button.text = "Outro Cutscene";
			cutscene_button.connect("pressed", self, "_outro_cutscene_pressed");
		else:
			cutscene_button.text = "???";
			cutscene_button.disabled = true;
		cutscene_button.focus_neighbour_left = cutscene_button.get_path_to(closebutton);
		cutscene_button.focus_neighbour_top = cutscene_button.get_path_to(prevbutton);
		closebutton.focus_neighbour_right = closebutton.get_path_to(cutscene_button);
	else:
		cutscene_button = null;
	
	var puzzles_completed = gamelogic.puzzles_completed;
	if (requires_advanced_levels):
		puzzles_completed = gamelogic.advanced_puzzles_completed;
	if (!(gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]) and puzzles_completed < unlock_requirement):
		holder.text = "Chapter " + chapter_string + " - ???";
		var label = Label.new();
		holder.add_child(label);
		label.rect_position.x = 2;
		label.rect_size.x = holder.rect_size.x - 4;
		label.rect_position.y = 18;
		label.align = 1;
		if (requires_advanced_levels):
			label.text = "Complete more Advanced puzzles: " + str(puzzles_completed) + "/" + str(unlock_requirement);
			#ch2 is locked disclaimer
			var b = Button.new();
			holder.add_child(b);
			b.text = nextbutton.text;
			b.connect("pressed", self, "_nextbutton_pressed");
			b.rect_position = Vector2(int(holder.rect_size.x/2-48), 51);
			b.focus_neighbour_bottom = b.get_path_to(nextbutton);
			nextbutton.focus_neighbour_top = nextbutton.get_path_to(b);
			prevbutton.focus_neighbour_top = prevbutton.get_path_to(b);
			leveleditorbutton.focus_neighbour_top = leveleditorbutton.get_path_to(b);
			communitylevelsbutton.focus_neighbour_top = communitylevelsbutton.get_path_to(b);
			closebutton.focus_neighbour_left = closebutton.get_path_to(b);
			closebutton.focus_neighbour_bottom = closebutton.get_path_to(b);
			var label2 = Label.new();
			holder.add_child(label2);
			label2.rect_position.x = 2;
			label2.rect_position.y = 35;
			label2.rect_size.x = holder.rect_size.x - 4;
			label2.align = 1;
			label2.text = "(This chapter is optional.)"
			label2.theme = holder.theme;
		else:
			label.text = "Complete more puzzles: " + str(puzzles_completed) + "/" + str(unlock_requirement);
		label.theme = holder.theme;
		return
		
	var advanced_unlock_requirement = gamelogic.chapter_advanced_unlock_requirements[chapter];
		
	holder.text = "Chapter " + chapter_string + " - " + gamelogic.chapter_names[chapter];
	var normal_start = gamelogic.chapter_standard_starting_levels[chapter];
	var advanced_start = gamelogic.chapter_advanced_starting_levels[chapter];
	var advanced_end = gamelogic.chapter_standard_starting_levels[chapter+1];
	
	var yy = 16;
	var yyy = 16;
	var xx = 19;
	var xxx = int(floor(holder.rect_size.x / 2))-2;
	var x = 0;
	var y = 0;
	var y_max = 12;
	
	# squish for very large chapters
	# (need a hack for chapter 0 b/c it has the extra note it needs to render)
	if (advanced_end - normal_start) > 22 or chapter == 0:
		y_max = 13;
		yy = 15;
		yyy = 15;
	
	# and another squish...
	if (advanced_end - normal_start) > 23:
		y_max = 14;
		yy = 13;
		yyy = 15;
		
	# final squish
	if (advanced_end - normal_start) > 26:
		y = -1;
		
	var standard_label = Label.new();
	holder.add_child(standard_label);
	standard_label.rect_position.x = round(xx + xxx*x);
	standard_label.rect_position.y = round(yy + yyy*y + 2);
	standard_label.text = "Standard:"
	standard_label.theme = holder.theme;
	if (y == -1):
		standard_label.rect_position.y += 2;
	
	y += 1;
	if (y == y_max):
		y = 0;
		x += 1;
	
	for i in range(advanced_start - normal_start):
		var button = preload("res://LevelButton.tscn").instance();
		buttons_by_xy[Vector2(x, y)] = button;
		holder.add_child(button);
		button.rect_position.x = round(xx + xxx*x);
		button.rect_position.y = round(yy + yyy*y);
		button.level_number = i + normal_start;
		var level_name = gamelogic.level_names[button.level_number];
		var level_string = str(i);
		if (gamelogic.level_replacements.has(button.level_number)):
			level_string = gamelogic.level_replacements[button.level_number];
		button.text = level_string + " - " + level_name;
		button.theme = holder.theme;
		button.levelselect = self;
		
		if (chapter == 11):
			if (level_name == "A Way In?"):
				var stylebox = preload("res://heavy_styleboxtexture.tres")
				if (gamelogic.save_file["levels"].has(level_name) and gamelogic.save_file["levels"][level_name].has("won") and gamelogic.save_file["levels"][level_name]["won"]):
					stylebox = preload("res://meta_styleboxtexture.tres");
				button.add_stylebox_override("hover", stylebox);
				button.add_stylebox_override("pressed", stylebox);
				button.add_stylebox_override("focus", stylebox);
				button.add_stylebox_override("disabled", stylebox);
				button.add_stylebox_override("normal", stylebox);
		
		# if we beat it, add a star :3
		if gamelogic.save_file["levels"].has(level_name) and gamelogic.save_file["levels"][level_name].has("won") and gamelogic.save_file["levels"][level_name]["won"]:
			var star = Sprite.new();
			star.texture = preload("res://assets/star.png");
			star.scale = Vector2(1.0/6.0, 1.0/6.0);
			star.position = Vector2(button.rect_position.x-14, button.rect_position.y+2);
			star.centered = false;
			holder.add_child(star);
		else:
			all_standard_stars = false;
		
		if (x == 0 and y == 1): # the first button
			button.grab_focus();
		if (button.level_number == gamelogic.level_number): # button corresponding to the current level
			button.grab_focus();
		
		y += 1;
		if (y == y_max):
			y = 0;
			x += 1;
	
	var advanced_label = null;
	
	if (advanced_end - advanced_start) > 0:
		# don't put the advanced label at the bottom of a column
		if (y == y_max - 1):
			y = 0;
			x += 1;
		# in fact, if it'll fit on its own one, give it its own one
		if (x == 0 and (advanced_end - advanced_start) < y_max):
			y = 0;
			x += 1;
		
		advanced_label = Label.new();
		holder.add_child(advanced_label);
		advanced_label.rect_position.x = round(xx + xxx*x);
		advanced_label.rect_position.y = round(yy + yyy*y + 2);
		advanced_label.text = "Advanced:"
		advanced_label.theme = holder.theme;
		
		y += 1;
		if (y == y_max):
			y = 0;
			x += 1;
		
		var a = gamelogic.how_many_standard_puzzles_are_solved_in_chapter(chapter);
		var you_have = a[0];
		var you_need = a[1];
		if (!(gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]) and you_have < you_need):
			all_advanced_stars = false;
			var label = Label.new();
			holder.add_child(label);
			label.rect_position.x = round(xx + xxx*x);
			label.rect_position.y = round(yy + yyy*y + 2);
			label.text = "Complete puzzles here: " + str(you_have) + "/" + str(you_need);
			label.theme = holder.theme;
		else:
			for i in range(advanced_end - advanced_start):
				var button = preload("res://LevelButton.tscn").instance();
				var stylebox = preload("res://dark_styleboxtexture.tres");
				button.add_stylebox_override("hover", stylebox);
				button.add_stylebox_override("pressed", stylebox);
				button.add_stylebox_override("focus", stylebox);
				button.add_stylebox_override("disabled", stylebox);
				button.add_stylebox_override("normal", stylebox);
				buttons_by_xy[Vector2(x, y)] = button;
				holder.add_child(button);
				button.rect_position.x = round(xx + xxx*x);
				button.rect_position.y = round(yy + yyy*y);
				button.level_number = i + advanced_start;
				var level_name = gamelogic.level_names[button.level_number];
				var level_string = str(i);
				if (gamelogic.level_replacements.has(button.level_number)):
					level_string = gamelogic.level_replacements[button.level_number];
				button.text = level_string + "X - " + level_name;
				button.theme = holder.theme;
				button.levelselect = self;
				if (x == 0 and y == 1): # the first button
					button.grab_focus();
				if (button.level_number == gamelogic.level_number): # button corresponding to the current level
					button.grab_focus();
					
				# lock Chrono Lab Reactor if not seen yet
				if (chapter == 11):
					if (level_name == "Chrono Lab Reactor"):
						if (!(gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]) and !gamelogic.save_file["levels"].has(level_name)):
							button.text = "???";
							button.disabled = true;
							
						stylebox = preload("res://heavy_styleboxtexture.tres")
						if (gamelogic.save_file["levels"].has(level_name) and gamelogic.save_file["levels"][level_name].has("won") and gamelogic.save_file["levels"][level_name]["won"]):
							stylebox = preload("res://meta_styleboxtexture.tres");
						button.add_stylebox_override("hover", stylebox);
						button.add_stylebox_override("pressed", stylebox);
						button.add_stylebox_override("focus", stylebox);
						button.add_stylebox_override("disabled", stylebox);
						button.add_stylebox_override("normal", stylebox);
					
				# if we beat it, add a star :3
				if gamelogic.save_file["levels"].has(level_name) and gamelogic.save_file["levels"][level_name].has("won") and gamelogic.save_file["levels"][level_name]["won"]:
					var star = Sprite.new();
					star.texture = preload("res://assets/star.png");
					star.scale = Vector2(1.0/6.0, 1.0/6.0);
					star.position = Vector2(button.rect_position.x-14, button.rect_position.y+2);
					star.centered = false;
					holder.add_child(star);
				else:
					all_advanced_stars = false;
				
				y += 1;
				if (y == y_max):
					y = 0;
					x += 1;
		
	# chapter 0 notice
	# nvm there's not room anymore LMAO
	#if chapter == 0:
	#	var label = Label.new();
	#	holder.add_child(label);
	#	label.rect_position.x = round(xx + xxx);
	#	label.rect_position.y = round(yy + yyy*(12));
	#	label.text = "(Advanced puzzles are optional,\nfor those seeking a challenge.)"
	#	label.theme = holder.theme;
		
	# chapter 2 notice
	if chapter == 2:
		var label = Label.new();
		holder.add_child(label);
		label.rect_position.x = 8;
		label.rect_position.y = round(yy + yyy*(10));
		label.text = "(Welcome! The techniques taught here are used only in Advanced Puzzles.)\r\n(If you just want to beat all Standard Puzzles, you don't need to step foot here.)"
		label.theme = holder.theme;
		
	# gold label flashes for completionists
	if (all_standard_stars):
		standard_label.set_script(preload("res://GoldLabel.gd"));
		standard_label.flash();
		if (all_advanced_stars):
			holder.flash();
	if (all_advanced_stars and advanced_label != null):
		advanced_label.set_script(preload("res://GoldLabel.gd"));
		advanced_label.flash();

func _intro_cutscene_pressed() -> void:
	destroy();
	gamelogic.title_screen();
	
func _outro_cutscene_pressed() -> void:
	destroy();
	gamelogic.ending_cutscene_1();

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		destroy();
	if (Input.is_action_just_pressed("ui_cancel")):
		destroy();
	if (Input.is_action_just_pressed("level_select")):
		destroy();
	if (Input.is_action_just_pressed("previous_level")):
		_prevbutton_pressed();
	if (Input.is_action_just_pressed("next_level")):
		_nextbutton_pressed();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		closebutton.grab_focus();
		focus = closebutton;

	var focus_middle_x = round(focus.rect_position.x + focus.rect_size.x / 2);
	pointer.position.y = round(focus.rect_position.y + focus.rect_size.y / 2);
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = round(focus.rect_position.x + focus.rect_size.x + 12);
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = round(focus.rect_position.x - 12);

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
