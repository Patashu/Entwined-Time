extends Node2D
class_name LevelSelect

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var chapter = gamelogic.chapter;
onready var prevbutton : Button = get_node("Holder/PrevButton");
onready var nextbutton : Button = get_node("Holder/NextButton");
onready var controlsbutton : Button = get_node("Holder/ControlsButton");
onready var settingsbutton : Button = get_node("Holder/SettingsButton");
onready var leveleditorbutton : Button = get_node("Holder/LevelEditorButton");
onready var closebutton : Button = get_node("Holder/CloseButton");
onready var specialbuttons = [prevbutton, nextbutton, controlsbutton, settingsbutton, leveleditorbutton, closebutton];

func _ready() -> void:
	prepare_chapter();
	prevbutton.connect("pressed", self, "_prevbutton_pressed");
	nextbutton.connect("pressed", self, "_nextbutton_pressed");
	controlsbutton.connect("pressed", self, "_controlsbutton_pressed");
	settingsbutton.connect("pressed", self, "_settingsbutton_pressed");
	leveleditorbutton.connect("pressed", self, "_leveleditorbutton_pressed");
	closebutton.connect("pressed", self, "destroy");
	
func _prevbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	chapter -= 1;
	chapter = posmod(int(chapter), gamelogic.chapter_names.size());
	prepare_chapter();

func _nextbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	chapter += 1;
	chapter = posmod(int(chapter), gamelogic.chapter_names.size());
	prepare_chapter();

func _controlsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var controls = preload("res://Controls.tscn").instance();
	gamelogic.ui_stack.push_back(controls);
	self.add_child(controls);
	
func _settingsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var settings = preload("res://Settings.tscn").instance();
	gamelogic.ui_stack.push_back(settings);
	self.add_child(settings);
	
func _leveleditorbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	pass

func prepare_chapter() -> void:
	for child in holder.get_children():
		if !specialbuttons.has(child):
			child.queue_free();
			
	var unlock_requirement = gamelogic.chapter_standard_unlock_requirements[chapter];	
	var chapter_string = str(chapter);
	if gamelogic.chapter_replacements.has(chapter):
		chapter_string = gamelogic.chapter_replacements[chapter];
	
	if (!(gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]) and gamelogic.puzzles_completed < unlock_requirement):
		holder.text = "Chapter " + chapter_string + " - ???";
		var label = Label.new();
		holder.add_child(label);
		label.rect_position.x = 2;
		label.rect_size.x = holder.rect_size.x - 4;
		label.rect_position.y = 18;
		label.align = 1;
		label.text = "Complete more puzzles: " + str(gamelogic.puzzles_completed) + "/" + str(unlock_requirement);
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
	var xxx = (holder.rect_size.x / 2)-2;
	var x = 0;
	var y = 0;
	var y_max = 12;
	
	# squish for very large chapters
	if (advanced_end - normal_start) > 22:
		y_max = 13;
		yy = 15;
		yyy = 15;
		
	var label = Label.new();
	holder.add_child(label);
	label.rect_position.x = xx + xxx*x;
	label.rect_position.y = yy + yyy*y + 2;
	label.text = "Standard:"
	label.theme = holder.theme;
	
	y += 1;
	if (y == y_max):
		y = 0;
		x += 1;
	
	for i in range(advanced_start - normal_start):
		var button = preload("res://LevelButton.tscn").instance();
		holder.add_child(button);
		button.rect_position.x = xx + xxx*x;
		button.rect_position.y = yy + yyy*y;
		button.level_number = i + normal_start;
		var level_name = gamelogic.level_names[button.level_number];
		var level_string = str(i);
		if (gamelogic.level_replacements.has(button.level_number)):
			level_string = gamelogic.level_replacements[button.level_number];
		button.text = level_string + " - " + level_name;
		button.theme = holder.theme;
		button.levelselect = self;
		
		# if we beat it, add a star :3
		if gamelogic.save_file["levels"].has(level_name) and gamelogic.save_file["levels"][level_name].has("won") and gamelogic.save_file["levels"][level_name]["won"]:
			var star = Sprite.new();
			star.texture = preload("res://assets/star.png");
			star.scale = Vector2(1.0/6.0, 1.0/6.0);
			star.position = Vector2(button.rect_position.x-14, button.rect_position.y+2);
			star.centered = false;
			holder.add_child(star);
			pass;
		
		if (x == 0 and y == 1): # the first button
			button.grab_focus();
		if (button.level_number == gamelogic.level_number): # button corresponding to the current level
			button.grab_focus();
		
		y += 1;
		if (y == y_max):
			y = 0;
			x += 1;
	
	if (advanced_end - advanced_start) > 0:
		# don't put the advanced label at the bottom of a column
		if (y == y_max - 1):
			y = 0;
			x += 1;
		# in fact, if it'll fit on its own one, give it its own one
		if (x == 0 and (advanced_end - advanced_start) < y_max):
			y = 0;
			x += 1;
		
		label = Label.new();
		holder.add_child(label);
		label.rect_position.x = xx + xxx*x;
		label.rect_position.y = yy + yyy*y + 2;
		label.text = "Advanced:"
		label.theme = holder.theme;
		
		y += 1;
		if (y == y_max):
			y = 0;
			x += 1;
		
		if (!(gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]) and gamelogic.puzzles_completed < advanced_unlock_requirement):
			label = Label.new();
			holder.add_child(label);
			label.rect_position.x = xx + xxx*x;
			label.rect_position.y = yy + yyy*y + 2;
			label.text = "Complete more puzzles: " + str(gamelogic.puzzles_completed) + "/" + str(advanced_unlock_requirement);
			label.theme = holder.theme;
		else:
			for i in range(advanced_end - advanced_start):
				var button = preload("res://LevelButton.tscn").instance();
				holder.add_child(button);
				button.rect_position.x = xx + xxx*x;
				button.rect_position.y = yy + yyy*y;
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
					
				# if we beat it, add a star :3
				if gamelogic.save_file["levels"].has(level_name) and gamelogic.save_file["levels"][level_name].has("won") and gamelogic.save_file["levels"][level_name]["won"]:
					var star = Sprite.new();
					star.texture = preload("res://assets/star.png");
					star.scale = Vector2(1.0/6.0, 1.0/6.0);
					star.position = Vector2(button.rect_position.x-14, button.rect_position.y+2);
					star.centered = false;
					holder.add_child(star);
					pass;
				
				y += 1;
				if (y == y_max):
					y = 0;
					x += 1;
		
	# chapter 0 notice
	if chapter == 0:
		label = Label.new();
		holder.add_child(label);
		label.rect_position.x = xx + xxx;
		label.rect_position.y = yy + yyy*(10);
		label.text = "(Advanced puzzles are optional,\nfor those seeking a challenge.)"
		label.theme = holder.theme;
		
	# chapter 2 notice
	if chapter == 2:
		label = Label.new();
		holder.add_child(label);
		label.rect_position.x = 8;
		label.rect_position.y = yy + yyy*(10);
		label.text = "(This is a difficult but rewarding chapter. If you get stuck, try the next chapters\nand come back later. The secrets of space-time will be here when you're ready.)"
		label.theme = holder.theme;

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		destroy();
	if (Input.is_action_just_pressed("previous_level")):
		_prevbutton_pressed();
	if (Input.is_action_just_pressed("next_level")):
		_nextbutton_pressed();

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
