extends Node2D
class_name EndingCutscene2

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;
onready var holder : Label = get_node("CutsceneHolder/Panel3/Holder");
onready var pointer : Sprite = holder.get_node("Pointer");
onready var creditsbutton : Button = holder.get_node("CreditsButton");
onready var quitbutton : Button = holder.get_node("QuitButton");
onready var puzzlebutton : Button = holder.get_node("PuzzleButton");
var only_mouse = true;
onready var using_controller = gamelogic.using_controller;

var end_timer = 0.0;
var end_timer_max = 0.0;

var cutscene_step = 0;
var cutscene_step_cooldown = 0.1;

var has_shown_advance_label = false;

var skip_cutscene_label = null;

func _ready() -> void:
	gamelogic.target_track = gamelogic.music_info.find("Patashu - Cutscene E");
	gamelogic.fadeout_timer_max = 1.0;
	gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
	
	creditsbutton.connect("pressed", self, "_creditsbutton_pressed");
	quitbutton.connect("pressed", self, "_quitbutton_pressed");
	puzzlebutton.connect("pressed", self, "_puzzlebutton_pressed");
	
	$CutsceneHolder/Panel3.visible = false;
	cutscene_step();

func _creditsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	quitbutton.visible = true;
	puzzlebutton.visible = true;
	$CutsceneHolder/Panel2.visible = false;
	
	var a = preload("res://CreditsModal.tscn").instance();
	gamelogic.add_to_ui_stack(a, get_parent());
	
func _puzzlebutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	begin_the_end();
	
func _quitbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	get_tree().quit();

func cutscene_step() -> void:
	if (cutscene_step_cooldown < 0.1):
		return;
	cutscene_step_cooldown = 0;
	$CutsceneHolder/AdvanceLabel.visible = false;
	
	match cutscene_step:
		0:
			$CutsceneHolder.visible = true;
			$CutsceneHolder/Panel1.visible = true;
			var tween = get_tree().create_tween()
			$CutsceneHolder/Panel1.modulate = Color(1, 1, 1, 0);
			tween.tween_property($CutsceneHolder/Panel1, "modulate", Color.white, 0.5);
		1:
			$CutsceneHolder/Panel2.visible = true;
			var tween = get_tree().create_tween()
			$CutsceneHolder/Panel2.modulate = Color(1, 1, 1, 0);
			tween.tween_property($CutsceneHolder/Panel2, "modulate", Color.white, 0.5);
			
		2:
			setup_label_text();
			$CutsceneHolder/Panel1.visible = false;
			$CutsceneHolder/Panel3.visible = true;
			var tween = get_tree().create_tween()
			$CutsceneHolder/Panel3.modulate = Color(1, 1, 1, 0);
			tween.tween_property($CutsceneHolder/Panel3, "modulate", Color.white, 0.5);
			has_shown_advance_label = false;
	cutscene_step += 1;
	
func setup_label_text() -> void:
	var label = holder.get_node("Label");
	label.text = "Congratulations on beating Entwined Time!\n\nAs a reward, all custom level editor elements are now unlocked!\n\n"
	var standard_completion = standard_completion();
	label.text += "Your rate for Standard puzzle completion is: " + str(standard_completion[0]) + "/" + str(standard_completion[1]);
	if (standard_completion[1] - standard_completion[0] < 5):
		label.text += "! Well done!\n\n"
		var campaign_completion = campaign_completion();
		label.text += "Your rate for Campaign puzzle completion is: " + str(campaign_completion[0]) + "/" + str(campaign_completion[1]) + "\n\n";
		if (campaign_completion[0] >= campaign_completion[1]):
			label.text += "Wow! I couldn't stump you at all! Maybe you can make a puzzle we can't solve now...?"
	
func standard_completion() -> Array:
	# count all standard puzzles except Victory Lap, Secrets of Space-Time and Community Levels
	var result = [0, 0];
	for i in range(gamelogic.custom_past_here - 1):
		if (i == 2):
			continue;
		var standard_start = gamelogic.chapter_standard_starting_levels[i];
		var advanced_start = gamelogic.chapter_advanced_starting_levels[i];
		for j in range(standard_start, advanced_start):
			if (gamelogic.specific_puzzles_completed[j]):
				result[0] += 1;
			result[1] += 1;
	return result;
	
func campaign_completion() -> Array:
	var result = [gamelogic.puzzles_completed, gamelogic.custom_past_here_level_count];
	return result;
	
func begin_the_end() -> void:
	if (end_timer_max > 0.0):
		return;
	end_timer_max = 2.5;
	holder.queue_free();
	pointer = null;
	random_good_level();
	gamelogic.play_sound("bootup");
	
func random_good_level() -> void:
	# logic:
	# if first community puzzle isn't beaten, take the player to that
	# else, take the player to a random unbeaten puzzle
	# else, take the player to a random puzzle
	if (gamelogic.specific_puzzles_completed[gamelogic.custom_past_here_level_count] == false):
		gamelogic.load_level_direct(gamelogic.custom_past_here_level_count);
	else:
		var candidates = [];
		for i in range(gamelogic.specific_puzzles_completed.size()):
			if !gamelogic.specific_puzzles_completed[i]:
				candidates.append(i);
		if (candidates.size()) > 0:
			gamelogic.load_level_direct(candidates[gamelogic.rng.randi_range(0, candidates.size() - 1)]);
		else:
			gamelogic.load_level_direct(gamelogic.rng.randi_range(0, gamelogic.specific_puzzles_completed.size() - 1));
	
func advance_label() -> void:
	if (has_shown_advance_label or (cutscene_step > 1 and cutscene_step < 3)):
		return;
	has_shown_advance_label = true;
	$CutsceneHolder/AdvanceLabel.visible = true;
	var tween = get_tree().create_tween()
	tween.tween_property($CutsceneHolder/AdvanceLabel, "modulate", Color.white, 1);
	if (only_mouse):
		$CutsceneHolder/AdvanceLabel.text = "(Left click or tap the screen to advance cutscene)";
	else:
		$CutsceneHolder/AdvanceLabel.text = "(" + gamelogic.human_readable_input("ui_accept", 1) + " to advance cutscene)";
	
func skip_cutscene_label_grows(delta: float) -> void:
	if (skip_cutscene_label == null):
		skip_cutscene_label = preload("res://SkipCutsceneLabel.tscn").instance();
		self.add_child(skip_cutscene_label);
	var progressbar = skip_cutscene_label.get_node("ProgressBar");
	progressbar.value += delta;
	if (progressbar.value >= progressbar.max_value):
		begin_the_end();
		end_timer_max = 1.0;

func reset_skip_cutscene_label() -> void:
	if (skip_cutscene_label != null):
		skip_cutscene_label.queue_free();
		skip_cutscene_label = null;
	
func play_sound(sound: String) -> void:
	gamelogic.play_sound(sound);
	
func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

func _input(event: InputEvent) -> void:
	if cutscene_step > 0:
		if event is InputEventScreenTouch:
			if event.pressed:
				cutscene_step();

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	cutscene_step_cooldown += delta;

	if (cutscene_step > 0):
		if (cutscene_step < 3 and cutscene_step_cooldown > 4.0):
			advance_label();
		
		if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("character_switch")
		or Input.is_action_just_pressed("lmb")):
			cutscene_step();
		elif (Input.is_action_pressed("escape") and end_timer_max == 0.0):
			skip_cutscene_label_grows(delta);
		else:
			reset_skip_cutscene_label();
	
	if (Input.is_action_just_pressed("any_controller") or Input.is_action_just_pressed("any_controller_2")):
		using_controller = true;
		only_mouse = false;
	
	if Input.is_action_just_pressed("any_keyboard"):
		using_controller = false;
		only_mouse = false;
	
	if (end_timer_max > 0):
		end_timer += delta;
		if (end_timer >= end_timer_max):
			destroy();
		else:
			self.modulate = Color(1, 1, 1, ((end_timer_max-end_timer)/end_timer_max));
			
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		if (pointer != null):
			pointer.visible = false;
		return;
	
	if (pointer != null and $CutsceneHolder/Panel3.visible):
		pointer.visible = true;
		var focus = holder.get_focus_owner();
		if (focus == null):
			creditsbutton.grab_focus();
			focus = creditsbutton;
		
		var focus_middle_x = focus.rect_position.x + focus.rect_size.x / 2;
		pointer.position.y = focus.rect_position.y + focus.rect_size.y / 2;
		if (focus_middle_x > holder.rect_size.x / 2):
			pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
			pointer.position.x = focus.rect_position.x + focus.rect_size.x + 12;
		else:
			pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
			pointer.position.x = focus.rect_position.x - 12;
