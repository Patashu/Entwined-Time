extends Node2D
class_name TitleScreen

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var beginbutton : Button = get_node("Holder/BeginButton");
onready var controlsbutton : Button = get_node("Holder/ControlsButton");
onready var settingsbutton : Button = get_node("Holder/SettingsButton");
onready var creditsbutton : Button = get_node("Holder/CreditsButton");
var only_mouse = true;
var using_controller = false;

var end_timer = 0.0;
var end_timer_max = 0.0;

var cutscene_step = 0;
var cutscene_step_cooldown = 0.0;

var has_shown_advance_label = false;

var skip_cutscene_label = null;

func _ready() -> void:
	beginbutton.connect("pressed", self, "_beginbutton_pressed");
	controlsbutton.connect("pressed", self, "_controlsbutton_pressed");
	settingsbutton.connect("pressed", self, "_settingsbutton_pressed");
	creditsbutton.connect("pressed", self, "_creditsbutton_pressed");
	
	gamelogic.target_track = 10;
	gamelogic.fadeout_timer_max = 1.0;
	gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
	
	holder.modulate = Color(1, 1, 1, 0);
	var tween = get_tree().create_tween()
	tween.tween_property(holder, "modulate", Color.white, 1)

func _beginbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
		
	cutscene_step();

func _controlsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Controls.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	
func _settingsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Settings.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	
func _creditsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://CreditsModal.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	
func cutscene_step() -> void:
	if (cutscene_step_cooldown < 0.1):
		return;
	cutscene_step_cooldown = 0;
	$CutsceneHolder/AdvanceLabel.visible = false;
	
	match cutscene_step:
		0:
			beginbutton.queue_free();
			controlsbutton.queue_free();
			settingsbutton.queue_free();
			creditsbutton.queue_free();
			pointer.queue_free();
			$Holder/Label.queue_free();
			pointer = null;
			$CutsceneHolder.visible = true;
			
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel1, "modulate", Color.white, 0.5);
			gamelogic.target_track = 11;
			gamelogic.fadeout_timer_max = 1.0;
			gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
			gamelogic.play_sound("noodling");
		1:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel2, "modulate", Color.white, 0.5);
			gamelogic.play_sound("alert");
		2:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel3, "modulate", Color.white, 0.5);
			gamelogic.play_sound("alert2");
			gamelogic.target_track = 12;
			gamelogic.fadeout_timer_max = 1.5;
			gamelogic.fadeout_timer = 0.0;
		3:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel4, "modulate", Color.white, 0.5);
		4:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel5, "modulate", Color.white, 0.5);
		5:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/ColorRect2, "modulate", Color.white, 0.5);
			gamelogic.target_track = -1;
			gamelogic.fadeout_timer_max = 1.0;
			gamelogic.fadeout_timer = 0.0;
		6:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel6, "modulate", Color.white, 0.5);
			
			$CutsceneHolder/Panel1.visible = false;
			$CutsceneHolder/Panel2.visible = false;
			$CutsceneHolder/Panel3.visible = false;
			$CutsceneHolder/Panel4.visible = false;
			$CutsceneHolder/Panel5.visible = false;
			
			gamelogic.target_track = 13;
			gamelogic.fadeout_timer_max = 1.0;
			gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
		7:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel61, "modulate", Color.white, 0.5);
		8:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel62, "modulate", Color.white, 0.5);
			tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel61, "modulate", Color(1, 1, 1, 0), 0.5);
		9:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel63, "modulate", Color.white, 0.5);
			tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel62, "modulate", Color(1, 1, 1, 0), 0.5);
		10:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel64, "modulate", Color.white, 0.5);
			tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel63, "modulate", Color(1, 1, 1, 0), 0.5);
		11:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel65, "modulate", Color.white, 0.5);
		12:
			begin_the_end();
	cutscene_step += 1;
	
func begin_the_end() -> void:
	if (end_timer_max > 0.0):
		return;
	
	end_timer_max = 4.0;
	gamelogic.load_level_direct(0);
	gamelogic.fadeout_timer_max = 6.8;
	gamelogic.fadeout_timer = 0.0;
	gamelogic.play_won("thejourneybegins");
	
	if (gamelogic.puzzles_completed == 0 and only_mouse):
		gamelogic.save_file["virtual_buttons"] = 1;
		gamelogic.setup_virtual_buttons();
	
func advance_label() -> void:
	if (has_shown_advance_label or cutscene_step > 1):
		return;
	has_shown_advance_label = true;
	$CutsceneHolder/AdvanceLabel.visible = true;
	var tween = get_tree().create_tween()
	tween.tween_property($CutsceneHolder/AdvanceLabel, "modulate", Color.white, 1);
	if (only_mouse):
		$CutsceneHolder/AdvanceLabel.text = "(Left click or tap the screen to advance cutscene)";
	elif (using_controller):
		$CutsceneHolder/AdvanceLabel.text = "(Bottom Face Button to advance cutscene)";
	else:
		$CutsceneHolder/AdvanceLabel.text = "(X to advance cutscene)";
	
func skip_cutscene_label_grows(delta: float) -> void:
	if (skip_cutscene_label == null):
		skip_cutscene_label = preload("res://SkipCutsceneLabel.tscn").instance();
		self.add_child(skip_cutscene_label);
	var progressbar = skip_cutscene_label.get_node("ProgressBar");
	progressbar.value += delta;
	if (progressbar.value >= progressbar.max_value):
		begin_the_end();

func reset_skip_cutscene_label() -> void:
	if (skip_cutscene_label != null):
		skip_cutscene_label.queue_free();
		skip_cutscene_label = null;
	
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
		if (cutscene_step_cooldown > 4.0):
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
		return;
	
	if (pointer != null):
		var focus = holder.get_focus_owner();
		if (focus == null):
			beginbutton.grab_focus();
			focus = beginbutton;
		
		var focus_middle_x = focus.rect_position.x + focus.rect_size.x / 2;
		pointer.position.y = focus.rect_position.y + focus.rect_size.y / 2;
		if (focus_middle_x > holder.rect_size.x / 2):
			pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
			pointer.position.x = focus.rect_position.x + focus.rect_size.x + 12;
		else:
			pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
			pointer.position.x = focus.rect_position.x - 12;
