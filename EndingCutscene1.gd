extends Node2D
class_name EndingCutscene1

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;
var only_mouse = true;
onready var using_controller = gamelogic.using_controller;

var end_timer = 0.0;
var end_timer_max = 0.0;

var cutscene_step = 0;
var cutscene_step_cooldown = 0.1;

var has_shown_advance_label = false;

var skip_cutscene_label = null;

var ghost_type = 0;
var ghost_timer = 0.0;
var ghost_timer_max = 0.2;

func _ready() -> void:
	gamelogic.target_track = -1;
	gamelogic.fadeout_timer_max = 1.0;
	gamelogic.fadeout_timer = gamelogic.fadeout_timer_max - 0.0001;
	
	$CutsceneHolder/Panel3.visible = false;
	cutscene_step();

func cutscene_step() -> void:
	if (cutscene_step_cooldown < 0.1):
		return;
	if ($CutsceneHolder/AnimationPlayer.current_animation == "Animate" and $CutsceneHolder/AnimationPlayer.is_playing()):
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
			gamelogic.play_sound("noodling"); #maybe
		1:
			$CutsceneHolder/Panel2.visible = true;
			var tween = get_tree().create_tween()
			$CutsceneHolder/Panel2.modulate = Color(1, 1, 1, 0);
			tween.tween_property($CutsceneHolder/Panel2, "modulate", Color.white, 0.2);
			gamelogic.play_sound("broken"); #maybe
		2:
			$CutsceneHolder/Panel1.visible = false;
			$CutsceneHolder/Panel3.visible = true;
			var tween = get_tree().create_tween()
			$CutsceneHolder/Panel3.modulate = Color(1, 1, 1, 0);
			tween.tween_property($CutsceneHolder/Panel3, "modulate", Color.white, 0.5);
			$CutsceneHolder/AnimationPlayer.play("Animate");
			has_shown_advance_label = false;
			ghost_type = 2;
		3:
			$CutsceneHolder/Panel2.visible = false;
			begin_the_end();
	cutscene_step += 1;
	
func begin_the_end() -> void:
	if (end_timer_max > 0.0):
		return;
	
	ghost_type = 0;
	end_timer_max = 1.0;
	gamelogic.fadeout_timer_max = 1.0;
	gamelogic.fadeout_timer = 0.0;
	var old_target_track = gamelogic.target_track;
	gamelogic.load_level_direct(gamelogic.level_filenames.find("ChronoLabReactor"));
	gamelogic.target_track = old_target_track;
	gamelogic.fadeout_timer_max = 0.0;
	gamelogic.fadeout_timer = 0.0;
	gamelogic.finish_animations(0);
	
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
	$CutsceneHolder/Panel3.add_child(afterimage);
	afterimage.scale = sprite.scale;
	afterimage.get_child(0).centered = sprite.centered;
	
func ghost(sprite: Sprite) -> void:
	var ghost = Sprite.new();
	ghost.script = preload("res://GhostSprite.gd");
	ghost.position = sprite.position;
	ghost.target = sprite;
	ghost.texture = sprite.texture;
	ghost.centered = sprite.centered;
	$CutsceneHolder/Panel3.add_child(ghost);
	
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
			afterimage($CutsceneHolder/Panel3/HeavyActor, gamelogic.heavy_color);
			afterimage($CutsceneHolder/Panel3/LightActor, gamelogic.light_color);
	elif (ghost_type == 2):
		ghost_timer += delta;
		if (ghost_timer > ghost_timer_max):
			ghost_timer -= ghost_timer_max;
			ghost($CutsceneHolder/Panel3/HeavyActor);
			ghost($CutsceneHolder/Panel3/LightActor);
	
	if (cutscene_step > 0):
		if (cutscene_step == 3 and !$CutsceneHolder/AnimationPlayer.is_playing()):
			advance_label();

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
