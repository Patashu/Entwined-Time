extends Node2D
class_name TitleScreen

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var beginbutton : Button = get_node("Holder/BeginButton");
onready var controlsbutton : Button = get_node("Holder/ControlsButton");
onready var settingsbutton : Button = get_node("Holder/SettingsButton");
onready var creditsbutton : Button = get_node("Holder/CreditsButton");
onready var disclaimer : Label = get_node("Holder/Disclaimer");
var only_mouse = true;
var using_controller = false;

var end_timer = 0.0;
var end_timer_max = 0.0;

var cutscene_step = 0;
var cutscene_step_cooldown = 0.0;

var has_shown_advance_label = false;

var skip_cutscene_label = null;

var ghost_type = 0;
var ghost_timer = 0.0;
var ghost_timer_max = 0.2;

var is_web = false;

func _ready() -> void:
	var os_name = OS.get_name();
	if (os_name == "HTML5" or os_name == "Android" or os_name == "iOS"):
		is_web = true;
	
	if (!is_web):
		disclaimer.visible = false;
	
	$CutsceneHolder.visible = false;
	$CutsceneHolder/HeavyPortal.visible = false;
	$CutsceneHolder/HeavyActor.visible = false;
	$CutsceneHolder/HeavyFix.visible = false;
	$CutsceneHolder/LightPortal.visible = false;
	$CutsceneHolder/LightActor.visible = false;
	$CutsceneHolder/LightFix.visible = false;
	
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
	gamelogic.add_to_ui_stack(a, get_parent());
	
func _settingsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Settings.tscn").instance();
	gamelogic.add_to_ui_stack(a, get_parent());
	
func _creditsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://CreditsModal.tscn").instance();
	gamelogic.add_to_ui_stack(a, get_parent());
	
func cutscene_step() -> void:
	if (cutscene_step_cooldown < 0.1):
		return;
	if ($CutsceneHolder/AnimationPlayer.current_animation == "Animate" and $CutsceneHolder/AnimationPlayer.is_playing()):
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
			disclaimer.visible = false;
			
			$ColorRect2.queue_free();
			pointer = null;
			$CutsceneHolder.visible = true;
			
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel1, "modulate", Color.white, 0.5);
			gamelogic.target_track = 11;
			gamelogic.fadeout_timer_max = 1.0;
			gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
			gamelogic.play_sound("noodling");
		1:
			$MainMenuBg.visible = false;
			$PatagameNoBg.visible = false;
			$Eyes.visible = false;
			
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
			gamelogic.play_sound("alert3");
		4:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel5, "modulate", Color.white, 0.5);
			gamelogic.play_sound("intothewarp");
		5:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/ColorRect2, "modulate", Color.white, 2.0);
			gamelogic.target_track = -1;
			gamelogic.fadeout_timer_max = 2.0;
			gamelogic.fadeout_timer = 0.0;
			gamelogic.play_sound("getgreenality");
		6:
			var tween = get_tree().create_tween()
			tween.tween_property($CutsceneHolder/Panel6, "modulate", Color.white, 1.0);
			
			$CutsceneHolder/Panel1.visible = false;
			$CutsceneHolder/Panel2.visible = false;
			$CutsceneHolder/Panel3.visible = false;
			$CutsceneHolder/Panel4.visible = false;
			$CutsceneHolder/Panel5.visible = false;
			
			gamelogic.target_track = 13;
			gamelogic.fadeout_timer_max = 1.0;
			gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
			$CutsceneHolder/AnimationPlayer.play("Animate");
			has_shown_advance_label = false;
			ghost_type = 1;
		7:
			begin_the_end();
	cutscene_step += 1;
	
func begin_the_end() -> void:
	if (end_timer_max > 0.0):
		return;
	
	ghost_type = 0;
	end_timer_max = 4.0;
	gamelogic.load_level_direct(0);
	gamelogic.fadeout_timer_max = 6.8;
	gamelogic.fadeout_timer = 0.0;
	gamelogic.play_won("thejourneybegins");
	
	if (gamelogic.puzzles_completed == 0 and only_mouse):
		gamelogic.save_file["virtual_buttons"] = 1;
		gamelogic.setup_virtual_buttons();
	
func advance_label() -> void:
	if (has_shown_advance_label or (cutscene_step > 1 and cutscene_step < 7)):
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
	
func change_ghosts() -> void:
	ghost_type = 2;
	ghost_timer = 0;
	ghost_timer_max = 0.5;
	
func afterimage(sprite: Sprite, color: Color) -> void:
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.actor = sprite;
	afterimage.set_material(gamelogic.get_afterimage_material_for(color));
	$CutsceneHolder/Panel6.add_child(afterimage);
	afterimage.scale = sprite.scale;
	afterimage.get_child(0).centered = sprite.centered;
	
func ghost(sprite: Sprite) -> void:
	var ghost = Sprite.new();
	ghost.script = preload("res://GhostSprite.gd");
	ghost.position = sprite.position;
	ghost.target = sprite;
	ghost.texture = sprite.texture;
	ghost.centered = sprite.centered;
	ghost.scale = sprite.scale;
	$CutsceneHolder/Panel6.add_child(ghost);
	
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
	
	if (ghost_type == 1):
		ghost_timer += delta;
		if (ghost_timer > ghost_timer_max):
			ghost_timer -= ghost_timer_max;
			afterimage($CutsceneHolder/HeavyActor, gamelogic.heavy_color);
			afterimage($CutsceneHolder/LightActor, gamelogic.light_color);
	elif (ghost_type == 2):
		ghost_timer += delta;
		if (ghost_timer > ghost_timer_max):
			ghost_timer -= ghost_timer_max;
			ghost($CutsceneHolder/HeavyActor);
			ghost($CutsceneHolder/LightActor);
	
	if (cutscene_step > 0):
		if (cutscene_step == 6 and cutscene_step_cooldown > 3.0):
			cutscene_step();
			
		if (cutscene_step == 7 and !$CutsceneHolder/AnimationPlayer.is_playing()):
			advance_label();
		
		if (cutscene_step < 6 and cutscene_step_cooldown > 4.0):
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
		disclaimer.visible = false;
	
	if Input.is_action_just_pressed("any_keyboard"):
		using_controller = false;
		only_mouse = false;
		disclaimer.visible = false;
	
	if (end_timer_max > 0):
		if (Input.is_action_pressed("escape")):
			end_timer += delta*3;
		else:
			end_timer += delta;
		if (end_timer >= end_timer_max):
			destroy();
		else:
			self.modulate = Color(1, 1, 1, ((end_timer_max-end_timer)/end_timer_max));
	
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		pointer.visible = false;
		return;
	
	if (pointer != null):
		pointer.visible = true;
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
