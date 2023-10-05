extends Node2D
class_name Settings

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Control = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var unlockeverything : CheckBox = get_node("Holder/UnlockEverything");
onready var pixelscale : SpinBox = get_node("Holder/PixelScale");
onready var vsync : CheckBox = get_node("Holder/VSync");
onready var sfxslider : HSlider = get_node("Holder/SFXSlider");
onready var fanfareslider : HSlider = get_node("Holder/FanfareSlider");
onready var musicslider : HSlider = get_node("Holder/MusicSlider");
onready var animationslider : HSlider = get_node("Holder/AnimationSlider");
onready var undotrailslider : HSlider = get_node("Holder/UndoTrailSlider");
onready var labelsfx : Label = get_node("Holder/LabelSFX");
onready var labelfanfare : Label = get_node("Holder/LabelFanfare");
onready var labelmusic : Label = get_node("Holder/LabelMusic");
onready var labelanimation : Label = get_node("Holder/LabelAnimation");
onready var labelundotrail : Label = get_node("Holder/LabelUndoTrail");
onready var puzzlecheckerboard : CheckBox = get_node("Holder/PuzzleCheckerboard");
onready var colourblindmode : CheckBox = get_node("Holder/ColourblindMode");
onready var copysavefile : Button = get_node("Holder/CopySaveFile");
onready var pastesavefile : Button = get_node("Holder/PasteSaveFile");
onready var newsavefile : Button = get_node("Holder/NewSaveFile");
onready var virtualbuttons : SpinBox = get_node("Holder/VirtualButtons");

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	get_node("Holder").add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = holder.rect_size.x;
	label.rect_position.y = holder.rect_size.y/2-16;
	label.text = text;

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	okbutton.grab_focus();
	unlockeverything.pressed = gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"];
	if (gamelogic.save_file.has("vsync_enabled")):
		vsync.pressed = gamelogic.save_file["vsync_enabled"];
	if (gamelogic.save_file.has("pixel_scale")):
		pixelscale.value = gamelogic.save_file["pixel_scale"];
	if (gamelogic.save_file.has("sfx_volume")):
		sfxslider.value = gamelogic.save_file["sfx_volume"];
		updatelabelsfx(sfxslider.value);
	if (gamelogic.save_file.has("fanfare_volume")):
		fanfareslider.value = gamelogic.save_file["fanfare_volume"];
		updatelabelfanfare(fanfareslider.value);
	if (gamelogic.save_file.has("music_volume")):
		musicslider.value = gamelogic.save_file["music_volume"];
		updatelabelmusic(musicslider.value);
	if (gamelogic.save_file.has("animation_speed")):
		animationslider.value = gamelogic.save_file["animation_speed"];
		updatelabelanimation(animationslider.value);
	if (gamelogic.save_file.has("puzzle_checkerboard")):
		puzzlecheckerboard.pressed = gamelogic.save_file["puzzle_checkerboard"];
	if (gamelogic.save_file.has("colourblind_mode")):
		colourblindmode.pressed = gamelogic.save_file["colourblind_mode"];
	if (gamelogic.save_file.has("virtual_buttons")):
		virtualbuttons.value = gamelogic.save_file["virtual_buttons"];
	
	undotrailslider.value = gamelogic.save_file["undo_trails"];
	updatelabelundotrail(undotrailslider.value);
	
	unlockeverything.connect("pressed", self, "_unlockeverything_pressed");
	vsync.connect("pressed", self, "_vsync_pressed");
	pixelscale.connect("value_changed", self, "_pixelscale_value_changed");
	sfxslider.connect("value_changed", self, "_sfxslider_value_changed");
	fanfareslider.connect("value_changed", self, "_fanfareslider_value_changed");
	musicslider.connect("value_changed", self, "_musicslider_value_changed");
	animationslider.connect("value_changed", self, "_animationslider_value_changed");
	undotrailslider.connect("value_changed", self, "_undotrailslider_value_changed");
	puzzlecheckerboard.connect("pressed", self, "_puzzlecheckerboard_pressed");
	colourblindmode.connect("pressed", self, "_colourblindmode_pressed");
	copysavefile.connect("pressed", self, "_copysavefile_pressed");
	pastesavefile.connect("pressed", self, "_pastesavefile_pressed");
	newsavefile.connect("pressed", self, "_newsavefile_pressed");
	virtualbuttons.connect("value_changed", self, "_virtualbuttons_value_changed");

func _unlockeverything_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["unlock_everything"] = unlockeverything.pressed;

func _vsync_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["vsync_enabled"] = vsync.pressed;
	OS.vsync_enabled = vsync.pressed;

func _pixelscale_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["pixel_scale"] = value;
	gamelogic.setup_resolution();
	
func _sfxslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["sfx_volume"] = value;
	gamelogic.setup_volume();
	gamelogic.play_sound("switch");
	updatelabelsfx(value);
	
func _fanfareslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["fanfare_volume"] = value;
	gamelogic.setup_volume();
	gamelogic.play_won("winentwined");
	updatelabelfanfare(value);
		
func _musicslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["music_volume"] = value;
	gamelogic.setup_volume();
	updatelabelmusic(value);
	
func _animationslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["animation_speed"] = value;
	gamelogic.setup_animation_speed();
	updatelabelanimation(value);
	
func _undotrailslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["undo_trails"] = value;
	for ghost in gamelogic.ghosts:
		ghost.ghost_alpha = value;
	updatelabelundotrail(value);
	
func _puzzlecheckerboard_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["puzzle_checkerboard"] = puzzlecheckerboard.pressed;
	gamelogic.checkerboard.visible = puzzlecheckerboard.pressed;
	
func _colourblindmode_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["colourblind_mode"] = colourblindmode.pressed;
	gamelogic.setup_colourblind_mode();
	
func _copysavefile_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	OS.set_clipboard(to_json(gamelogic.save_file));
	
	floating_text("Exported save file to clipboard!");
	
func _pastesavefile_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var paste = OS.get_clipboard();
	
	var json_parse_result = JSON.parse(paste)
	
	var result = null;
	
	if json_parse_result.error == OK:
		var data = json_parse_result.result;
		if typeof(data) == TYPE_DICTIONARY:
			result = data;
	
	if (result == null):
		floating_text("Didn't find a valid save file on clipboard")
	else:
		gamelogic.save_file = result;
		gamelogic.react_to_save_file_update();
		gamelogic.load_level(gamelogic.level_number);
		destroy();
	
func _newsavefile_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var new_save_file = gamelogic.save_file.duplicate(true);
	
	new_save_file["levels"] = {};
	new_save_file["level_number"] = 0;
	
	OS.set_clipboard(to_json(new_save_file));
	
	floating_text("Exported fresh save file to clipboard - Import it to confirm.");
	
func _virtualbuttons_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["virtual_buttons"] = value;
	gamelogic.setup_virtual_buttons();
	
func updatelabelsfx(value: int) -> void:
	if (value <= -30):
		labelsfx.text = "SFX Volume: Muted";
	else:
		labelsfx.text = "SFX Volume: " + str(value) + " dB";
		
func updatelabelfanfare(value: int) -> void:
	if (value <= -30):
		labelfanfare.text = "Fanfare Volume: Muted";
	else:
		labelfanfare.text = "Fanfare Volume: " + str(value) + " dB";
		
func updatelabelmusic(value: int) -> void:
	if (value <= -30):
		labelmusic.text = "Music Volume: Muted";
	else:
		labelmusic.text = "Music Volume: " + str(value) + " dB";

func updatelabelanimation(value: float) -> void:
	labelanimation.text = "Animation Speed: " + ("%0.1f" % value) + "x";

func updatelabelundotrail(value: float) -> void:
	labelundotrail.text = "Undo Prediction Opacity: " + str(int(round(value * 100))) + "%";

func destroy() -> void:
	gamelogic.save_game();
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
		destroy();
	if (Input.is_action_just_pressed("ui_cancel")):
		destroy();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		okbutton.grab_focus();
		focus = okbutton;
		
	# spinbox correction hack
	var parent = focus.get_parent();
	if parent is SpinBox:
		focus = parent;

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
