extends Node2D
class_name Settings

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var okbutton : Button = get_node("Holder/OkButton");
onready var unlockeverything : CheckBox = get_node("Holder/UnlockEverything");
onready var pixelscale : SpinBox = get_node("Holder/PixelScale");
onready var vsync : CheckBox = get_node("Holder/VSync");
onready var sfxslider : HSlider = get_node("Holder/SFXSlider");
onready var musicslider : HSlider = get_node("Holder/MusicSlider");
onready var animationslider : HSlider = get_node("Holder/AnimationSlider");
onready var undotrailslider : HSlider = get_node("Holder/UndoTrailSlider");
onready var labelsfx : Label = get_node("Holder/LabelSFX");
onready var labelmusic : Label = get_node("Holder/LabelMusic");
onready var labelanimation : Label = get_node("Holder/LabelAnimation");
onready var labelundotrail : Label = get_node("Holder/LabelUndoTrail");
onready var puzzlecheckerboard : CheckBox = get_node("Holder/PuzzleCheckerboard");

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
	if (gamelogic.save_file.has("music_volume")):
		musicslider.value = gamelogic.save_file["music_volume"];
		updatelabelmusic(musicslider.value);
	if (gamelogic.save_file.has("animation_speed")):
		animationslider.value = gamelogic.save_file["animation_speed"];
		updatelabelanimation(animationslider.value);
	if (gamelogic.save_file.has("puzzle_checkerboard")):
		puzzlecheckerboard.pressed = gamelogic.save_file["puzzle_checkerboard"];
	
	undotrailslider.value = gamelogic.save_file["undo_trails"];
	updatelabelundotrail(undotrailslider.value);
	
	unlockeverything.connect("pressed", self, "_unlockeverything_pressed");
	vsync.connect("pressed", self, "_vsync_pressed");
	pixelscale.connect("value_changed", self, "_pixelscale_value_changed");
	sfxslider.connect("value_changed", self, "_sfxslider_value_changed");
	musicslider.connect("value_changed", self, "_musicslider_value_changed");
	animationslider.connect("value_changed", self, "_animationslider_value_changed");
	undotrailslider.connect("value_changed", self, "_undotrailslider_value_changed");
	puzzlecheckerboard.connect("pressed", self, "_puzzlecheckerboard_pressed");

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
	
func updatelabelsfx(value: int) -> void:
	if (value <= -30):
		labelsfx.text = "SFX Volume: Muted";
	else:
		labelsfx.text = "SFX Volume: " + str(value) + " dB";
		
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

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
