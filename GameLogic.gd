extends Node
class_name GameLogic

var debug_prints = false;

onready var levelscene : Node2D = get_node("/root/LevelScene");
onready var underterrainfolder : Node2D = levelscene.get_node("UnderTerrainFolder");
onready var actorsfolder : Node2D = levelscene.get_node("ActorsFolder");
onready var ghostsfolder : Node2D = levelscene.get_node("GhostsFolder");
onready var levelfolder : Node2D = levelscene.get_node("LevelFolder");
onready var terrainmap : TileMap = levelfolder.get_node("TerrainMap");
onready var overactorsparticles : Node2D = levelscene.get_node("OverActorsParticles");
onready var underactorsparticles : Node2D = levelscene.get_node("UnderActorsParticles");
onready var menubutton : Button = levelscene.get_node("MenuButton");
onready var levellabel : Label = levelscene.get_node("LevelLabel");
onready var levelstar : Sprite = levelscene.get_node("LevelStar");
onready var winlabel : Node2D = levelscene.get_node("WinLabel");
onready var heavyinfolabel : Label = levelscene.get_node("HeavyInfoLabel");
onready var lightinfolabel : Label = levelscene.get_node("LightInfoLabel");
onready var metainfolabel : Label = levelscene.get_node("MetaInfoLabel");
onready var tutoriallabel : RichTextLabel = levelscene.get_node("TutorialLabel");
onready var targeter : Sprite = levelscene.get_node("Targeter")
onready var heavytimeline : Node2D = levelscene.get_node("HeavyTimeline");
onready var lighttimeline : Node2D = levelscene.get_node("LightTimeline");
onready var downarrow : Sprite = levelscene.get_node("DownArrow");
onready var leftarrow : Sprite = levelscene.get_node("LeftArrow");
onready var rightarrow : Sprite = levelscene.get_node("RightArrow");
onready var Static : Sprite = levelscene.get_node("Static");
onready var Shade : Node2D = levelscene.get_node("Shade");
onready var checkerboard : TextureRect = levelscene.get_node("Checkerboard");
onready var rng : RandomNumberGenerator = RandomNumberGenerator.new();
onready var virtualbuttons : Node2D = levelscene.get_node("VirtualButtons");
onready var replaybuttons : Node2D = levelscene.get_node("ReplayButtons");
onready var replayturnlabel : Label = levelscene.get_node("ReplayButtons/ReplayTurn/ReplayTurnLabel");
onready var replayturnslider : HSlider = levelscene.get_node("ReplayButtons/ReplayTurn/ReplayTurnSlider");
onready var replayspeedlabel : Label = levelscene.get_node("ReplayButtons/ReplaySpeed/ReplaySpeedLabel");
onready var replayspeedslider : HSlider = levelscene.get_node("ReplayButtons/ReplaySpeed/ReplaySpeedSlider");
var replayturnsliderset = false;
var replayspeedsliderset = false;

# distinguish between temporal layers when a move or state change happens
# ghosts is for undo trail ghosts
enum Chrono {
	MOVE
	CHAR_UNDO
	META_UNDO
	TIMELESS
	GHOSTS
}

# distinguish between different strengths of movement. Gravity is also special in that it won't try to make
# 'voluntary' movements like going past thin platforms.
enum Strength {
	NONE
	CRYSTAL
	WOODEN
	LIGHT
	HEAVY
	GRAVITY
}

# distinguish between different heaviness. Light is IRON and Heavy is STEEL.
enum Heaviness {
	NONE
	CRYSTAL
	WOODEN
	IRON
	STEEL
	SUPERHEAVY
	INFINITE
}

# distinguish between levels of durability by listing the first thing that will destroy you.
enum Durability {
	SPIKES
	FIRE
	PITS
	NOTHING
}

# yes means 'do the thing you intended'. no means 'cancel it and this won't cause time to pass'.
# surprise means 'cancel it but there was a side effect so time passes'.
enum Success {
	Yes,
	No,
	Surprise,
}

# types of undo events

enum Undo {
	move, #0
	set_actor_var, #1
	heavy_turn,
	light_turn,
	heavy_undo_event_add,
	light_undo_event_add,
	heavy_undo_event_remove,
	light_undo_event_remove,
	animation_substep,
	change_terrain, #9
	# crystal undos
	heavy_undo_event_add_locked,
	light_undo_event_add_locked,
	heavy_green_time_crystal_raw,
	light_green_time_crystal_raw,
	heavy_max_moves,
	light_max_moves,
	heavy_filling_locked_turn_index,
	light_filling_locked_turn_index,
	heavy_turn_locked,
	light_turn_locked,
	heavy_turn_direct,
	light_turn_direct,
	heavy_turn_unlocked,
	light_turn_unlocked,
	heavy_filling_turn_actual,
	light_filling_turn_actual,
	# crystal undos over
	tick, #26
}

# and same for animations
enum Animation {
	move,
	bump,
	set_next_texture,
	sfx,
	fluster,
	fire_roars,
	trapdoor_opens,
	explode,
	shatter,
	unshatter,
	afterimage_at,
	fade,
	heavy_green_time_crystal_raw, #12
	light_green_time_crystal_raw, #13
	heavy_magenta_time_crystal, #14
	light_magenta_time_crystal, #15
	heavy_green_time_crystal_unlock, #16
	light_green_time_crystal_unlock, #17
	tick, #18
	undo_immunity, #19
	grayscale, #20
	generic_green_time_crystal, #21
	generic_magenta_time_crystal, #22
	lose, #23
	time_passes, #24
}

enum TimeColour {
	Gray,
	Purple,
	Blurple,
	Magenta,
	Red,
	Blue,
	Green,
	Void,
	Cyan,
	Orange,
	Yellow,
	White,
}

enum Greenness {
	Mundane,
	Green,
	Void
}

# attempted performance optimization - have an enum of all tile ids and assert at startup that they're right
# order SEEMS to be the same as in DefaultTiles
# keep in sync with LevelEditor
enum Tiles {
	Fire,
	HeavyGoal,
	HeavyIdle,
	IronCrate,
	Key,
	Ladder,
	LadderPlatform,
	LightGoal,
	LightIdle,
	Lock,
	LockClosed,
	LockOpen,
	Spikeball,
	SteelCrate,
	Wall,
	WoodenCrate,
	Checkpoint,
	CheckpointBlue,
	CheckpointRed,
	OnewayEast,
	OnewayNorth,
	OnewaySouth,
	OnewayWest,
	WoodenPlatform,
	Grate,
	OnewayEastGreen,
	OnewayNorthGreen,
	OnewaySouthGreen,
	OnewayWestGreen,
	NoHeavy,
	NoLight,
	PowerCrate,
	CrateGoal,
	NoCrate,
	HeavyFire,
	ColourRed,
	ColourBlue,
	ColourGray,
	ColourMagenta,
	ColourGreen,
	ColourVoid,
	ColourCyan,
	ColourOrange,
	ColourYellow,
	ColourPurple,
	GlassBlock, #45
	GreenGlassBlock, #46
	GreenSpikeball, #47
	GreenFire, #48
	NoRetro,
	NoUndo,
	OneUndo, #51
	Fuzz, #52
	TimeCrystalGreen, #53
	TimeCrystalMagenta, #54
	CuckooClock, #55
	TheNight, #56
	TheStars, #57
	VoidSpikeball, #58
	VoidGlassBlock, #59
	ChronoHelixBlue, #60
	ChronoHelixRed, #61
	HeavyGoalJoke, #62
	LightGoalJoke, #63
	LightFire, #64
	PowerSocket, #65
	GreenPowerSocket, #66
	VoidPowerSocket, #67
	ColourWhite, #68
	GlassBlockCracked, #69
	OnewayEastPurple, #70
	OnewayNorthPurple, #71
	OnewaySouthPurple, #72
	OnewayWestPurple, #73
	ColourBlurple, #74
}
var voidlike_tiles = [];

# information about the level
var is_custom = false;
var test_mode = false;
var custom_string = "";
var chapter = 0;
var level_in_chapter = 0;
var level_is_extra = false;
var in_insight_level = false;
var has_insight_level = false;
var insight_level_scene = null;
var level_number = 0
var level_name = "Blah Blah Blah";
var level_replay = "";
var level_author = "";
var heavy_max_moves = -1;
var light_max_moves = -1;
var clock_turns : String = "";
var map_x_max : int = 0;
var map_y_max : int = 0;
var map_x_max_max : int = 21;
var map_y_max_max : int = 10; #TODO: screen scrolling/zoom
var terrain_layers = []
var voidlike_puzzle = false;

# information about the actors and their state
var heavy_actor : Actor = null
var light_actor : Actor = null
var actors = []
var goals = []
var heavy_turn = 0;
var heavy_undo_buffer : Array = [];
var heavy_filling_locked_turn_index = -1;
var heavy_filling_turn_actual = -1;
var heavy_locked_turns : Array = [];
var light_turn = 0;
var light_undo_buffer : Array = [];
var light_filling_locked_turn_index = -1;
var light_filling_turn_actual = -1;
var light_locked_turns : Array = [];
var meta_turn = 0;
var meta_undo_buffer : Array = [];
var heavy_selected = true;

# for undo trail ghosts
var ghosts = []

# for afterimages
var afterimage_server = {}

# save file, ooo!
var save_file = {}
var puzzles_completed = 0;

# song-and-dance state
var sounds = {}
var music_tracks = [];
var music_info = [];
var now_playing = null;
var speakers = [];
var target_track = -1;
var current_track = -1;
var fadeout_timer = 0;
var fadeout_timer_max = 0;
var fanfare_duck_db = 0;
var music_discount = -10;
var music_speaker = null;
var lost_speaker = null;
var lost_speaker_volume_tween;
var won_speaker = null;
var sounds_played_this_frame = {};
var muted = false;
var won = false;
var nonstandard_won = false;
var won_cooldown = 0;
var lost = false;
var lost_void = false;
var won_fade_started = false;
var joke_portals_present = false;
var cell_size = 24;
var undo_effect_strength = 0;
var undo_effect_per_second = 0;
var undo_effect_color = Color(0, 0, 0, 0);
var heavy_color = Color(1.0, 0, 0, 1);
var light_color = Color(0, 0.58, 1.0, 1);
var meta_color = Color(0.5, 0.5, 0.5, 1);
var fuzz_timer = 0;
var fuzz_timer_max = 0;
var ui_stack = [];
var ready_done = false;
var using_controller = false;

#UI defaults
var HeavyInfoLabel_default_position = Vector2(0, 1);
var HeavyTimeline_default_position = Vector2(6, 26);
var LightInfoLabel_default_position = Vector2(478, 1);
var LightTimeline_default_position = Vector2(482, 26);
var win_label_default_y = 113;
var pixel_width = ProjectSettings.get("display/window/size/width"); #512
var pixel_height = ProjectSettings.get("display/window/size/height"); #300

# animation server
var animation_server = []
var animation_substep = 0;
var animation_nonce_fountain = 0;

#replay system
var replay_timer = 0;
var user_replay = "";
var user_replay_before_restarts = [];
var doing_replay = false;
var replay_paused = false;
var replay_turn = 0;
var replay_interval = 0.5;
var next_replay = -1;
var unit_test_mode = false;
var meta_undo_a_restart_mode = false;

# list of levels in the game
var level_list = [];
var level_filenames = [];
var level_names = [];
var has_remix = {};
var chapter_names = [];
var chapter_skies = [];
var chapter_tracks = [];
var chapter_replacements = {};
var level_replacements = {};
var target_sky = Color("#223C52");
var old_sky = Color("#223C52");
var current_sky = Color("#223C52");
var sky_timer = 0;
var sky_timer_max = 0;
var chapter_standard_starting_levels = [];
var chapter_advanced_starting_levels = [];
var chapter_standard_unlock_requirements = [];
var chapter_advanced_unlock_requirements = [];
var save_file_string = "user://entwinedtime.sav";

func save_game():
	var file = File.new()
	file.open(save_file_string, File.WRITE)
	file.store_line(to_json(save_file))
	file.close()

func default_save_file() -> void:
	if (save_file == null or typeof(save_file) != TYPE_DICTIONARY):
		save_file = {};
	if (!save_file.has("level_number")):
		save_file["level_number"] = 0
	if (!save_file.has("levels")):
		save_file["levels"] = {}
	if (!save_file.has("version")):
		save_file["version"] = 0
	if (!save_file.has("undo_trails")):
		save_file["undo_trails"] = 1.0;

func load_game():
	var file = File.new()
	if not file.file_exists(save_file_string):
		return default_save_file();
		
	file.open(save_file_string, File.READ)
	var json_parse_result = JSON.parse(file.get_as_text())
	file.close();
	
	if json_parse_result.error == OK:
		var data = json_parse_result.result;
		if typeof(data) == TYPE_DICTIONARY:
			save_file = data;
		else:
			return default_save_file();
	else:
		return default_save_file();
	
	default_save_file();
	
	react_to_save_file_update();

func _ready() -> void:
	# Call once when the game is booted up.
	menubutton.connect("pressed", self, "escape");
	levelstar.scale = Vector2(1.0/6.0, 1.0/6.0);
	winlabel.call_deferred("change_text", "You have won!\n\n[Enter]: Continue\nWatch Replay: Menu -> Your Replay");
	connect_virtual_buttons();
	prepare_audio();
	call_deferred("adjust_winlabel");
	load_game();
	initialize_level_list();
	tile_changes();
	initialize_shaders();
	if (OS.is_debug_build()):
		assert_tile_enum();
	prepare_voidlike_tiles();
	
	# Load the first map.
	load_level(0);
	ready_done = true;

func prepare_voidlike_tiles() -> void:
	for i in range (Tiles.size()):
		var expected_tile_name = Tiles.keys()[i];
		if expected_tile_name.findn("void") >= 0:
			voidlike_tiles.append(i);

func connect_virtual_buttons() -> void:
	virtualbuttons.get_node("Verbs/UndoButton").connect("button_down", self, "_undobutton_pressed");
	virtualbuttons.get_node("Verbs/UndoButton").connect("button_up", self, "_undobutton_released");
	virtualbuttons.get_node("Verbs/SwapButton").connect("button_down", self, "_swapbutton_pressed");
	virtualbuttons.get_node("Verbs/SwapButton").connect("button_up", self, "_swapbutton_released");
	virtualbuttons.get_node("Verbs/MetaUndoButton").connect("button_down", self, "_metaundobutton_pressed");
	virtualbuttons.get_node("Verbs/MetaUndoButton").connect("button_up", self, "_metaundobutton_released");
	virtualbuttons.get_node("Dirs/LeftButton").connect("button_down", self, "_leftbutton_pressed");
	virtualbuttons.get_node("Dirs/LeftButton").connect("button_up", self, "_leftbutton_released");
	virtualbuttons.get_node("Dirs/DownButton").connect("button_down", self, "_downbutton_pressed");
	virtualbuttons.get_node("Dirs/DownButton").connect("button_up", self, "_downbutton_released");
	virtualbuttons.get_node("Dirs/RightButton").connect("button_down", self, "_rightbutton_pressed");
	virtualbuttons.get_node("Dirs/RightButton").connect("button_up", self, "_rightbutton_released");
	virtualbuttons.get_node("Dirs/UpButton").connect("button_down", self, "_upbutton_pressed");
	virtualbuttons.get_node("Dirs/UpButton").connect("button_up", self, "_upbutton_released");
	virtualbuttons.get_node("Others/EnterButton").connect("button_down", self, "_enterbutton_pressed");
	virtualbuttons.get_node("Others/EnterButton").connect("button_up", self, "_enterbutton_released");
	replaybuttons.get_node("ReplaySpeed/F9Button").connect("button_down", self, "_f9button_pressed");
	replaybuttons.get_node("ReplaySpeed/F9Button").connect("button_up", self, "_f9button_released");
	replaybuttons.get_node("ReplaySpeed/F10Button").connect("button_down", self, "_f10button_pressed");
	replaybuttons.get_node("ReplaySpeed/F10Button").connect("button_up", self, "_f10button_released");
	replaybuttons.get_node("ReplayTurn/PrevTurnButton").connect("button_down", self, "_prevturnbutton_pressed");
	replaybuttons.get_node("ReplayTurn/PrevTurnButton").connect("button_up", self, "_prevturnbutton_released");
	replaybuttons.get_node("ReplayTurn/NextTurnButton").connect("button_down", self, "_nextturnbutton_pressed");
	replaybuttons.get_node("ReplayTurn/NextTurnButton").connect("button_up", self, "_nextturnbutton_released");
	replaybuttons.get_node("ReplayTurn/PauseButton").connect("button_down", self, "_pausebutton_pressed");
	replaybuttons.get_node("ReplayTurn/PauseButton").connect("button_up", self, "_pausebutton_released");
	replaybuttons.get_node("ReplayTurn/ReplayTurnSlider").connect("value_changed", self, "_replayturnslider_value_changed");
	replaybuttons.get_node("ReplaySpeed/ReplaySpeedSlider").connect("value_changed", self, "_replayspeedslider_value_changed");
	
func virtual_button_pressed(action: String) -> void:
	if (ui_stack.size() > 0 and ui_stack[ui_stack.size() - 1] != self):
		return;
	Input.action_press(action);
	menubutton.grab_focus();
	menubutton.release_focus();
	
func virtual_button_released(action: String) -> void:
	if (ui_stack.size() > 0 and ui_stack[ui_stack.size() - 1] != self):
		return;
	Input.action_release(action);
	menubutton.grab_focus();
	menubutton.release_focus();
	
func _undobutton_pressed() -> void:
	virtual_button_pressed("character_undo");
	
func _swapbutton_pressed() -> void:
	virtual_button_pressed("character_switch");
	
func _metaundobutton_pressed() -> void:
	virtual_button_pressed("meta_undo");
	
func _leftbutton_pressed() -> void:
	virtual_button_pressed("ui_left");
	
func _rightbutton_pressed() -> void:
	virtual_button_pressed("ui_right");
	
func _upbutton_pressed() -> void:
	virtual_button_pressed("ui_up");

func _downbutton_pressed() -> void:
	virtual_button_pressed("ui_down");
	
func _enterbutton_pressed() -> void:
	virtual_button_pressed("ui_accept");
	
func _f9button_pressed() -> void:
	virtual_button_pressed("slowdown_replay");
	
func _f10button_pressed() -> void:
	virtual_button_pressed("speedup_replay");
	
func _prevturnbutton_pressed() -> void:
	virtual_button_pressed("replay_back1");

func _nextturnbutton_pressed() -> void:
	virtual_button_pressed("replay_fwd1");
	
func _pausebutton_pressed() -> void:
	virtual_button_pressed("replay_pause");
	
func _undobutton_released() -> void:
	virtual_button_released("character_undo");
	
func _swapbutton_released() -> void:
	virtual_button_released("character_switch");
	
func _metaundobutton_released() -> void:
	virtual_button_released("meta_undo");
	
func _leftbutton_released() -> void:
	virtual_button_released("ui_left");
	
func _rightbutton_released() -> void:
	virtual_button_released("ui_right");
	
func _upbutton_released() -> void:
	virtual_button_released("ui_up");

func _downbutton_released() -> void:
	virtual_button_released("ui_down");
	
func _enterbutton_released() -> void:
	virtual_button_released("ui_accept");
	
func _f9button_released() -> void:
	virtual_button_released("slowdown_replay");
	
func _f10button_released() -> void:
	virtual_button_released("speedup_replay");
	
func _prevturnbutton_released() -> void:
	virtual_button_released("replay_back1");

func _nextturnbutton_released() -> void:
	virtual_button_released("replay_fwd1");
	
func _pausebutton_released() -> void:
	virtual_button_released("replay_pause");
	
func _replayturnslider_value_changed(value: int) -> void:
	if !doing_replay:
		return;
	if (replayturnsliderset):
		return;
	var differential = value - replay_turn;
	if (differential != 0):
		replay_advance_turn(differential);
	
func _replayspeedslider_value_changed(value: int) -> void:
	if !doing_replay:
		return;
	if (replayspeedsliderset):
		return;
	var old_replay_interval = replay_interval;
	replay_interval = (100-value) * 0.01;
	adjust_next_replay_time(old_replay_interval);
	update_info_labels();

func react_to_save_file_update() -> void:
	#save_file["gain_insight"] = false;
	#save_file["authors_replay"] = false;
	
	level_number = save_file["level_number"];
	if (save_file.has("puzzle_checkerboard")):
		checkerboard.visible = true;
	setup_colourblind_mode();
	setup_resolution();
	setup_volume();
	setup_animation_speed();
	setup_virtual_buttons();
	deserialize_bindings();
	setup_deadzone();
	refresh_puzzles_completed();
	
var actions = ["ui_accept", "ui_cancel", "escape", "ui_left", "ui_right", "ui_up", "ui_down",
"character_undo", "meta_undo", "character_switch", "restart",
"next_level", "previous_level", "mute", "start_replay", "speedup_replay",
"slowdown_replay", "start_saved_replay", "gain_insight", "level_select"];
	
func setup_deadzone() -> void:
	if (!save_file.has("deadzone")):
		save_file["deadzone"] = InputMap.action_get_deadzone("ui_up");
	else:
		InputMap.action_set_deadzone("ui_up", save_file["deadzone"]);
		InputMap.action_set_deadzone("ui_down", save_file["deadzone"]);
		InputMap.action_set_deadzone("ui_left", save_file["deadzone"]);
		InputMap.action_set_deadzone("ui_right", save_file["deadzone"]);
	
func deserialize_bindings() -> void:
	if save_file.has("keyboard_bindings"):
		for action in actions:
			var events = InputMap.get_action_list(action);
			for event in events:
				if (event is InputEventKey):
					InputMap.action_erase_event(action, event);
			for new_event_str in save_file["keyboard_bindings"][action]:
				var parts = new_event_str.split(",");
				var new_event = InputEventKey.new();
				new_event.scancode = int(parts[0]);
				new_event.physical_scancode = int(parts[1]);
				InputMap.action_add_event(action, new_event);
	if save_file.has("controller_bindings"):
		for action in actions:
			var events = InputMap.get_action_list(action);
			for event in events:
				if (event is InputEventJoypadButton):
					InputMap.action_erase_event(action, event);
			for new_event_int in save_file["controller_bindings"][action]:
				var new_event = InputEventJoypadButton.new();
				new_event.button_index = new_event_int;
				InputMap.action_add_event(action, new_event);

func serialize_bindings() -> void:
	if !save_file.has("keyboard_bindings"):
		save_file["keyboard_bindings"] = {};
	else:
		save_file["keyboard_bindings"].clear();
	if !save_file.has("controller_bindings"):
		save_file["controller_bindings"] = {};
	else:
		save_file["controller_bindings"].clear();
	
	for action in actions:
		var events = InputMap.get_action_list(action);
		save_file["keyboard_bindings"][action] = [];
		save_file["controller_bindings"][action] = [];
		for event in events:
			if (event is InputEventKey):
				save_file["keyboard_bindings"][action].append(str(event.scancode) + "," +str(event.physical_scancode));
			elif (event is InputEventJoypadButton):
				save_file["controller_bindings"][action].append(event.button_index);
	
func setup_virtual_buttons() -> void:
	var value = 0;
	if (save_file.has("virtual_buttons")):
		value = save_file["virtual_buttons"];
	if (value > 0):
		for folder in virtualbuttons.get_children():
			for button in folder.get_children():
				button.disabled = false;
		virtualbuttons.visible = true;
		if value == 1:
			virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
		elif value == 2:
			virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(-108, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
		elif value == 3:
			virtualbuttons.get_node("Verbs").position = Vector2(128, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
		elif value == 4:
			virtualbuttons.get_node("Verbs").position = Vector2(128, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(-108, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
		elif value == 5:
			virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(-300, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(160, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
		elif value == 6:
			virtualbuttons.get_node("Verbs").position = Vector2(300, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(-150, 0);
	else:
		replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
		replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
		for folder in virtualbuttons.get_children():
			for button in folder.get_children():
				button.disabled = true;
		virtualbuttons.visible = false;
	
func setup_resolution() -> void:
	if (save_file.has("pixel_scale")):
		var value = save_file["pixel_scale"];
		var size = Vector2(pixel_width*value, pixel_height*value);
		OS.set_window_size(size);
		OS.center_window();
	if (save_file.has("vsync_enabled")):
		OS.vsync_enabled = save_file["vsync_enabled"];
		
func setup_volume() -> void:
	if (save_file.has("sfx_volume")):
		var value = save_file["sfx_volume"];
		for speaker in speakers:
			speaker.volume_db = value;
	if (save_file.has("music_volume")):
		var value = save_file["music_volume"];
		music_speaker.volume_db = value;
		music_speaker.volume_db = music_speaker.volume_db + music_discount;
	if (save_file.has("fanfare_volume")):
		var value = save_file["fanfare_volume"];
		won_speaker.volume_db = value;
	
func setup_animation_speed() -> void:
	if (save_file.has("animation_speed")):
		var value = save_file["animation_speed"];
		Engine.time_scale = value;
		
func setup_colourblind_mode() -> void:
	if (save_file.has("colourblind_mode")):
		var value = save_file["colourblind_mode"];
		#reset all textures to frame 0 to fix any possible drift
		for i in range (Tiles.keys().size()):
			if (i == 9):
				continue;
			var tex = terrainmap.tile_set.tile_get_texture(i);
			if tex is AnimatedTexture:
				tex.current_frame = 0;
		
		# halve the speed of green textures (except green glass cuz no animation but it's darker even under grayscale)
		if (value):
			terrainmap.tile_set.tile_get_texture(Tiles.GreenFire).fps = 2.5;
			terrainmap.tile_set.tile_get_texture(Tiles.GreenSpikeball).fps = 2.5;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewayEastGreen).fps = 5;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewayWestGreen).fps = 5;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewayNorthGreen).fps = 5;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewaySouthGreen).fps = 5;
		else:
			terrainmap.tile_set.tile_get_texture(Tiles.GreenFire).fps = 5;
			terrainmap.tile_set.tile_get_texture(Tiles.GreenSpikeball).fps = 5;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewayEastGreen).fps = 10;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewayWestGreen).fps = 10;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewayNorthGreen).fps = 10;
			terrainmap.tile_set.tile_get_texture(Tiles.OnewaySouthGreen).fps = 10;
		for actor in actors:
			actor.setup_colourblind_mode(value);
		
func initialize_shaders() -> void:
	#each thing that uses a shader has to compile the first time it's used, so... use it now!
	var afterimage = preload("Afterimage.tscn").instance();
	afterimage.initialize(targeter, light_color);
	levelscene.call_deferred("add_child", afterimage);
	afterimage.position = Vector2(-99, -99);
	# TODO: compile the Static shader by flicking it on for a single frame? same for ripple and grayscale
	
func tile_changes(level_editor: bool = false) -> void:
	# hide light and heavy goal sprites when in-game and not in-editor
	if (!level_editor):
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, null);
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, null);
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoalJoke, null);
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoalJoke, null);
	else:
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, preload("res://assets/light_goal.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, preload("res://assets/heavy_goal.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoalJoke, preload("res://assets/light_goal_joke.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoalJoke, preload("res://assets/heavy_goal_joke.png"));
	
func assert_tile_enum() -> void:
	for i in range (Tiles.size()):
		var expected_tile_name = Tiles.keys()[i];
		if (expected_tile_name == "Lock"):
			continue
		var expected_tile_id = Tiles.values()[i];
		var actual_tile_id = terrainmap.tile_set.find_tile_by_name(expected_tile_name);
		var actual_tile_name = terrainmap.tile_set.tile_get_name(expected_tile_id);
		if (actual_tile_name != expected_tile_name):
			print(expected_tile_name, ", ", expected_tile_id, ", ", actual_tile_name, ", ", actual_tile_id);
		elif (actual_tile_id != expected_tile_id):
			print(expected_tile_name, ", ", expected_tile_id, ", ", actual_tile_name, ", ", actual_tile_id);
	
func initialize_level_list() -> void:
	
	chapter_names.push_back("Two Time");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(0);
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	level_filenames.push_back("MeetLight")
	level_filenames.push_back("MeetHeavy")
	level_filenames.push_back("Initiation")
	level_filenames.push_back("Orientation")
	level_filenames.push_back("PushingIt")
	level_filenames.push_back("Wall")
	level_filenames.push_back("Tall")
	level_filenames.push_back("Braid")
	level_filenames.push_back("TheFirstPit")
	level_filenames.push_back("Pachinko")
	level_filenames.push_back("CallACab")
	level_filenames.push_back("Knot")
	level_filenames.push_back("U-Turn")
	level_filenames.push_back("CarryingIt")
	level_filenames.push_back("Roommates")
	level_filenames.push_back("Downhill")
	level_filenames.push_back("Uphill")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_filenames.push_back("Spelunking")
	level_filenames.push_back("TheFirstPitEx")
	level_filenames.push_back("TheFirstPitEx2")
	level_filenames.push_back("CarryingItEx")
	level_filenames.push_back("RoommatesEx")
	level_filenames.push_back("BraidEx")
	level_filenames.push_back("ShouldveCalledaCab")
	level_filenames.push_back("UncabYourself")
	level_filenames.push_back("Cliffs")
	
	chapter_names.push_back("Hazards");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(8);
	chapter_tracks.push_back(1);
	chapter_skies.push_back(Color("#512E22"));
	level_filenames.push_back("Spikes")
	level_filenames.push_back("TrustFall")
	level_filenames.push_back("SnakePit")
	level_filenames.push_back("TheSpikePit")
	level_filenames.push_back("Campfire")
	level_filenames.push_back("SpontaneousCombustion")
	level_filenames.push_back("Firewall")
	level_filenames.push_back("Hell")
	level_filenames.push_back("TheBoundlessSky")
	level_filenames.push_back("Hopscorch")
	level_filenames.push_back("SpontaneousSpikebustion")
	level_filenames.push_back("Roast")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(16);
	level_filenames.push_back("TrustFallEx")
	level_filenames.push_back("SnakePitEx")
	level_filenames.push_back("TheSpikePitEx")
	level_filenames.push_back("FirewallEx")
	level_filenames.push_back("FirewallEx2")
	level_filenames.push_back("HellEx")
	level_filenames.push_back("CampfireEx")
	level_filenames.push_back("FireInTheSky")
	level_filenames.push_back("HopscorchEx")
	level_filenames.push_back("OrbitalDrop")
	
	chapter_names.push_back("Secrets of Space-Time");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(16);
	chapter_skies.push_back(Color("#062138"));
	chapter_tracks.push_back(2);
	chapter_replacements[chapter_names.size() - 1] = "2?";
	level_filenames.push_back("HeavyMovingService")
	level_filenames.push_back("LightMovingService")
	level_filenames.push_back("LightMovingServiceEx")
	level_filenames.push_back("Acrobatics")
	level_filenames.push_back("AcrobaticsEx")
	level_filenames.push_back("InvisibleBridgeL")
	level_filenames.push_back("InvisibleBridge")
	level_filenames.push_back("GraduationPure")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(24);
	level_filenames.push_back("TheFirstPitEx3")
	level_filenames.push_back("TheFirstPitEx4")
	level_filenames.push_back("RoughTerrain")
	level_filenames.push_back("LightMovingServiceEx2")
	level_filenames.push_back("TheBoundlessSkyEx")
	level_filenames.push_back("AcrobatsEscape")
	level_filenames.push_back("AcrobatsEscapeEx")
	level_filenames.push_back("AcrobatsEscapeEx2")
	
	chapter_names.push_back("One-Ways");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(16);
	chapter_tracks.push_back(3);
	chapter_skies.push_back(Color("#1C3D19"));
	level_filenames.push_back("OneWays")
	level_filenames.push_back("PeekaBoo")
	level_filenames.push_back("CoyoteTime")
	level_filenames.push_back("SecurityDoor")
	level_filenames.push_back("Upstream")
	level_filenames.push_back("Downstream")
	level_filenames.push_back("Jail")
	level_filenames.push_back("BoosterSeat")
	level_filenames.push_back("TheOneWayPit")
	level_filenames.push_back("EventHorizon")
	level_filenames.push_back("PushingItSequel")
	level_filenames.push_back("Daredevils")
	level_filenames.push_back("HawkingRadiation")
	level_filenames.push_back("SolidPuzzle")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(24);
	level_filenames.push_back("RemoteVoyage")
	level_filenames.push_back("SecurityDoorEx")
	level_filenames.push_back("SecurityDoorEx2")
	level_filenames.push_back("JailEx")
	level_filenames.push_back("TheOneWayPitEx")
	level_filenames.push_back("TheSpikePitEx2")
	level_filenames.push_back("OneWayToBurn")
	level_filenames.push_back("GraduationSpicy")
	level_filenames.push_back("InvisibleBridgeEx")
	level_filenames.push_back("InvisibleBridgeEx2")
	level_filenames.push_back("TheOneWayPitEx2")
	level_filenames.push_back("Heaven")
	
	chapter_names.push_back("Trap Doors and Ladders");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(24);
	chapter_tracks.push_back(4);
	chapter_skies.push_back(Color("#3B3F1A"));
	level_filenames.push_back("Down")
	level_filenames.push_back("LadderWorld")
	level_filenames.push_back("LadderLattice")
	level_filenames.push_back("PurpleOneWays")
	level_filenames.push_back("LadderDither")
	level_filenames.push_back("StairwayToHell")
	level_filenames.push_back("Mole")
	level_filenames.push_back("Dive")
	level_filenames.push_back("SecretPassage")
	level_filenames.push_back("TrophyCabinet")
	level_filenames.push_back("DoubleJump")
	level_filenames.push_back("FirefightersNew")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(32);
	level_filenames.push_back("TrophyCabinetEx")
	level_filenames.push_back("TrophyCabinetEx2")
	level_filenames.push_back("Bonfire")
	level_filenames.push_back("BonfireEx")
	level_filenames.push_back("TripleJump")
	level_filenames.push_back("CarEngine")
	level_filenames.push_back("JetEngine")
	level_filenames.push_back("RocketEngine")
	level_filenames.push_back("PhotonDrive")
	level_filenames.push_back("FirefightersEx")
	
	chapter_names.push_back("Iron Crates");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(32);
	chapter_tracks.push_back(2);
	chapter_skies.push_back(Color("#424947"));
	level_filenames.push_back("IronCrates")
	level_filenames.push_back("CrateExpectations")
	level_filenames.push_back("Bridge")
	level_filenames.push_back("SteppingStool")
	level_filenames.push_back("OverDestination")
	level_filenames.push_back("ThirdRoommate")
	level_filenames.push_back("Sokoban")
	level_filenames.push_back("OneAtATime")
	level_filenames.push_back("PushingItCrate")
	level_filenames.push_back("SnakeChute")
	level_filenames.push_back("TheCratePit")
	level_filenames.push_back("Landfill")
	level_filenames.push_back("PrecariousSituation")
	level_filenames.push_back("PressEveryKey")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(40);
	level_filenames.push_back("Weakness")
	level_filenames.push_back("ThirdRoommateEx")
	level_filenames.push_back("ThirdRoommateEx2")
	level_filenames.push_back("Levitation")
	level_filenames.push_back("QuantumEntanglement")
	level_filenames.push_back("TheTower")
	level_filenames.push_back("InvisibleBridgeCrate")
	level_filenames.push_back("Jenga")
	
	chapter_names.push_back("There Are Many Colours");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(40);
	chapter_tracks.push_back(0);
	chapter_skies.push_back(Color("#37294F"));
	level_filenames.push_back("RedAndBlue")
	level_filenames.push_back("LevelNotFound")
	level_filenames.push_back("DownhillRedBlue")
	level_filenames.push_back("TrustFallRedBlue")
	level_filenames.push_back("SpontaneousCombustionRedBlue")
	level_filenames.push_back("LunarGravity")
	level_filenames.push_back("LeapOfFaith")
	level_filenames.push_back("BlueAndRed")
	level_filenames.push_back("TheRedPit")
	level_filenames.push_back("TheBluePit")
	level_filenames.push_back("TheMagentaPit")
	level_filenames.push_back("TheGrayPit")
	level_filenames.push_back("PaperPlanes")
	level_filenames.push_back("TimelessBridge")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(48);
	level_filenames.push_back("LevelNotFoundEx")
	level_filenames.push_back("LevelNotFoundEx2")
	level_filenames.push_back("Freedom")
	level_filenames.push_back("BlueAndRedEx")
	level_filenames.push_back("BlueAndRedEx2")
	level_filenames.push_back("TheMagentaPitEx")
	level_filenames.push_back("TheGrayPitEx")
	level_filenames.push_back("PaperPlanesEx")
	level_filenames.push_back("TimelessBridgeEx")
	level_filenames.push_back("Towerplex")
	level_filenames.push_back("TheMagentaPitEx2")
	level_filenames.push_back("TheMagentaPitEx3")
	
	chapter_names.push_back("Change");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(48);
	chapter_tracks.push_back(4);
	chapter_skies.push_back(Color("#446570"));
	level_filenames.push_back("Ahhh")
	level_filenames.push_back("Eeep")
	level_filenames.push_back("DoubleGlazed")
	level_filenames.push_back("LetMeIn")
	level_filenames.push_back("Interleave")
	level_filenames.push_back("LadderWorldGlass")
	level_filenames.push_back("SpelunkingGlass")
	level_filenames.push_back("TheGlassPit")
	level_filenames.push_back("DemolitionSquad")
	level_filenames.push_back("Aquarium")
	level_filenames.push_back("TreasureHunt")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(56);
	level_filenames.push_back("LetMeInEx")
	level_filenames.push_back("HeavyMovingServiceGlass")
	level_filenames.push_back("IcyHot")
	level_filenames.push_back("Deconstruct")
	level_filenames.push_back("TheGlassPitEx")
	level_filenames.push_back("TheRace")
	level_filenames.push_back("CampfireGlass")
	level_filenames.push_back("CampfireGlassEx")
	level_filenames.push_back("SpelunkingGlassEx")
	level_filenames.push_back("LadderWorldGlassEx")
	
	chapter_names.push_back("Permanence");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(56);
	chapter_tracks.push_back(1);
	chapter_skies.push_back(Color("#14492A"));
	level_filenames.push_back("HelpYourself")
	level_filenames.push_back("SpikesGreen")
	level_filenames.push_back("SoBroken")
	level_filenames.push_back("CampfireGreen")
	level_filenames.push_back("SpontaneousCombustionGreen")
	level_filenames.push_back("FirewallGreen")
	level_filenames.push_back("GreenGlass")
	level_filenames.push_back("TheFuture")
	level_filenames.push_back("FasterThanLight")
	level_filenames.push_back("Mundane")
	level_filenames.push_back("LeadPlanes")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(64);
	level_filenames.push_back("DragonsGate")
	level_filenames.push_back("HelpYourselfEx")
	level_filenames.push_back("LightHurtingService")
	level_filenames.push_back("LightHurtingServiceEx")
	level_filenames.push_back("LightHurtingServiceEx2")
	level_filenames.push_back("GreenGrass")
	level_filenames.push_back("SpikesGreenEx")
	level_filenames.push_back("CampfireGreenEx")
	level_filenames.push_back("Skip")
	level_filenames.push_back("Airdodging")
	
	chapter_names.push_back("Exotic Matter");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(64);
	chapter_tracks.push_back(3);
	chapter_skies.push_back(Color("#351731"));
	level_filenames.push_back("TheFuzz")
	level_filenames.push_back("DoubleFuzz")
	level_filenames.push_back("PushingItFurther")
	level_filenames.push_back("Elevator")
	level_filenames.push_back("Stuck")
	level_filenames.push_back("PingPong")
	level_filenames.push_back("FuzzyTrick")
	level_filenames.push_back("LimitedUndo")
	level_filenames.push_back("UphillLimited")
	level_filenames.push_back("TimeStop")
	level_filenames.push_back("KingCrimson")
	level_filenames.push_back("Nomadic")
	level_filenames.push_back("AsTheWorldTurns")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(72);
	level_filenames.push_back("ElevatorEx")
	level_filenames.push_back("PingPongEx")
	level_filenames.push_back("ImaginaryMoves")
	level_filenames.push_back("DontLookDown")
	level_filenames.push_back("LeadBalloon")
	level_filenames.push_back("Durability")
	level_filenames.push_back("UnfathomableGlass")
	level_filenames.push_back("PushingItFurtherEx")
	level_filenames.push_back("LimitedUndoEx")
	level_filenames.push_back("LimitedUndoEx2")
	level_filenames.push_back("KingCrimsonEx")
	
	chapter_names.push_back("Time Crystals");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(72);
	chapter_tracks.push_back(2);
	chapter_skies.push_back(Color("#2A1F82"));
	level_filenames.push_back("Growth")
	level_filenames.push_back("Delivery")
	level_filenames.push_back("Blockage")
	level_filenames.push_back("Wither")
	level_filenames.push_back("Bounce")
	level_filenames.push_back("Pathology")
	level_filenames.push_back("Reflections")
	level_filenames.push_back("Erase")
	level_filenames.push_back("Memento")
	level_filenames.push_back("Forgetfulness")
	level_filenames.push_back("Remembrance")
	level_filenames.push_back("PushingItCrystal")
	level_filenames.push_back("Conservation")
	level_filenames.push_back("Accumulation")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(80);
	level_filenames.push_back("Elementary")
	level_filenames.push_back("BlockageEx")
	level_filenames.push_back("Smuggler")
	level_filenames.push_back("SmugglerEx")
	level_filenames.push_back("Frangible")
	level_filenames.push_back("Switcheroo")
	level_filenames.push_back("SwitcherooEx")
	level_filenames.push_back("StairwayToHeaven")
	
	chapter_names.push_back("Deadline");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(80);
	chapter_skies.push_back(Color("#2D0E07"));
	chapter_tracks.push_back(1);
	chapter_replacements[chapter_names.size() - 1] = "Ω";
	level_filenames.push_back("CuckooClock")
	level_filenames.push_back("ItDoesntAddUp")
	level_filenames.push_back("TimeZones")
	level_filenames.push_back("MoveCounter")
	level_filenames.push_back("Just5MoreMinutes")
	level_filenames.push_back("DST")
	level_filenames.push_back("EngineRoom")
	level_filenames.push_back("TheShroud")
	level_filenames.push_back("ControlledDemolition")
	level_filenames.push_back("Rewind")
	level_filenames.push_back("Cascade")
	level_replacements[level_filenames.size()] = "Ω";
	level_filenames.push_back("AWayIn")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(88);
	level_filenames.push_back("HotPotato")
	level_filenames.push_back("LevelNotFoundEx3")
	level_filenames.push_back("AnnoyingRacket")
	level_filenames.push_back("Rink")
	level_filenames.push_back("Collectathon")
	level_filenames.push_back("Hassle")
	level_filenames.push_back("MidnightParkour")
	level_filenames.push_back("ControlledDemolitionEx")
	level_filenames.push_back("ControlledDemolitionEx2")
	level_filenames.push_back("Permify")
	level_filenames.push_back("CelestialNavigation")
	level_replacements[level_filenames.size()] = "Ω";
	level_filenames.push_back("ChronoLabReactor")
	
	chapter_names.push_back("Victory Lap");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(256, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "-1";
	level_filenames.push_back("RoommatesExL2")
	level_filenames.push_back("SpelunkingL2")
	level_filenames.push_back("UphillL2")
	level_filenames.push_back("DownhillL2")
	level_filenames.push_back("RoommatesL2")
	level_filenames.push_back("RoommatesL2Ex")
	level_filenames.push_back("CarryingItL2")
	level_filenames.push_back("KnotRemixL2")
	level_filenames.push_back("KnotL2")
	level_filenames.push_back("CallACabL2")
	level_filenames.push_back("TheoryOfEverythingA")
	level_filenames.push_back("TheoryOfEverythingB")
	level_filenames.push_back("PachinkoL2")
	level_filenames.push_back("TheFirstPitL2")
	level_filenames.push_back("BraidL2")
	level_filenames.push_back("TallL2")
	level_filenames.push_back("TallL2Ex")
	level_filenames.push_back("WallL2")
	level_filenames.push_back("WallL2Ex")
	level_filenames.push_back("PushingItL2")
	level_filenames.push_back("OrientationL2")
	level_filenames.push_back("OrientationL2Ex")
	level_filenames.push_back("OrientationL2Ex2")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(level_filenames.size());
	level_replacements[level_filenames.size()] = "-1";
	level_filenames.push_back("Joke")

	# sentinel to make overflow checks easy
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	
	for level_filename in level_filenames:
		level_list.push_back(load("res://levels/" + level_filename + ".tscn"));
	
	for level_prototype in level_list:
		var level = level_prototype.instance();
		var level_name = level.get_node("LevelInfo").level_name;
		level_names.push_back(level_name);
		level.queue_free();
		
	for i in range(level_list.size()):
		var level_name = level_names[i];
		var level_filename = level_filenames[i];
		
		# also learn which puzzles are remixes
		var insight_path = "res://levels/insight/" + level_filename + "Insight.tscn";
		if (ResourceLoader.exists(insight_path)):
			var insight_level = load(insight_path).instance();
			var insight_level_name = insight_level.get_node("LevelInfo").level_name;
			if (insight_level_name.find("(Remix)") >= 0 or insight_level_name.find("World's Smallest Puzzle") >= 0):
				has_remix[level_name] = true;
			insight_level.queue_free();
		
	refresh_puzzles_completed();
		
func refresh_puzzles_completed() -> void:
	puzzles_completed = 0;
	for level_name in level_names:
		if save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]:
			puzzles_completed += 1;

func ready_map() -> void:
	won = false;
	nonstandard_won = false;
	end_lose();
	lost_speaker.stop();
	joke_portals_present = false;
	for actor in actors:
		actor.queue_free();
	actors.clear();
	for goal in goals:
		goal.queue_free();
	goals.clear();
	for ghost in ghosts:
		ghost.queue_free();
	ghosts.clear();
	for whatever in underactorsparticles.get_children():
		whatever.queue_free();
	for whatever in overactorsparticles.get_children():
		whatever.queue_free();
	heavy_turn = 0;
	heavy_undo_buffer.clear();
	light_turn = 0;
	light_undo_buffer.clear();
	meta_turn = 0;
	meta_undo_buffer.clear();
	heavy_filling_locked_turn_index = -1;
	heavy_filling_turn_actual = -1;
	heavy_locked_turns.clear();
	light_filling_locked_turn_index = -1;
	light_filling_turn_actual = -1;
	light_locked_turns.clear();
	heavy_selected = true;
	# Meet Light - only Light is selectable
	if (!is_custom and level_number == 0):
		heavy_selected = false;
	user_replay = "";
	
	var level_info = terrainmap.get_node_or_null("LevelInfo");
	if (level_info != null): # might be a custom puzzle
		level_name = level_info.level_name;
		level_author = level_info.level_author;
		level_replay = level_info.level_replay;
		if ("$" in level_replay):
			var level_replay_parts = level_replay.split("$");
			level_replay = level_replay_parts[level_replay_parts.size()-1];
		heavy_max_moves = level_info.heavy_max_moves;
		light_max_moves = level_info.light_max_moves;
		clock_turns = level_info.clock_turns;
	
	has_insight_level = false;
	insight_level_scene = null;
	if (!is_custom):
		var insight_path = "res://levels/insight/" + level_filenames[level_number] + "Insight.tscn";
		if (ResourceLoader.exists(insight_path)):
			has_insight_level = true;
			insight_level_scene = load(insight_path);
	
	calculate_map_size();
	make_actors();
	
	finish_animations(Chrono.TIMELESS);
	update_info_labels();
	check_won();
	
	initialize_timeline_viewers();
	ready_tutorial();
	update_level_label();
	
func ready_tutorial() -> void:
	if is_custom:
		metainfolabel.visible = true;
		tutoriallabel.visible = false;
		downarrow.visible = false;
		leftarrow.visible = false;
		rightarrow.visible = false;
		return;
	
	if level_number > 4:
		metainfolabel.visible = true;
	else:
		metainfolabel.visible = false;
		
	if level_number > 6:
		tutoriallabel.visible = false;
		downarrow.visible = false;
		leftarrow.visible = false;
		rightarrow.visible = false;
	else:
		tutoriallabel.visible = true;
		downarrow.visible = true;
		leftarrow.visible = true;
		rightarrow.visible = true;
		tutoriallabel.rect_position = Vector2(0, 69);
		if (level_number == 0):
			tutoriallabel.bbcode_text = "Arrows: Move\nZ: Undo\nR: Restart\n\n\n\n\n\n\n\n\n(Touchscreen/Mouse only players: Menu > Settings > Virtual Buttons.)\n(In the full game, this will be checked during the opening sequence.)";
		elif (level_number == 1):
			tutoriallabel.bbcode_text = "Arrows: Move\nZ: Undo\nR: Restart";
		elif (level_number == 2):
			tutoriallabel.rect_position.y -= 24;
			tutoriallabel.bbcode_text = "Arrows: Move [color=#FF7459]Character[/color]\nX: Swap [color=#FF7459]Character[/color]\nZ: Undo [color=#FF7459]Character[/color]\nR: Restart";
		elif (level_number == 3):
			tutoriallabel.rect_position.y -= 24;
			tutoriallabel.bbcode_text = "X: Swap [color=#FF7459]Character[/color]\nZ: Undo [color=#FF7459]Character[/color]\nR: Restart";
		elif (level_number == 4):
			tutoriallabel.rect_position.y -= 24;
			tutoriallabel.bbcode_text = "Z: Undo [color=#FF7459]Character[/color]\nR: Restart";
		elif (level_number == 5):
			tutoriallabel.rect_position.y -= 48;
			tutoriallabel.bbcode_text = "C: [color=#A9F05F]Meta-Undo[/color]\nR: Restart\n([color=#A9F05F]Meta-Undo[/color] undoes your last Move or Undo.)";
		elif (level_number == 6):
			tutoriallabel.rect_position.y -= 48;
			tutoriallabel.bbcode_text = "C: [color=#A9F05F]Meta-Undo[/color]\nR: Restart\n(If you Restart by mistake, [color=#A9F05F]Meta-Undo[/color] will undo that too.)";
		tutoriallabel.bbcode_text = "[center]" + tutoriallabel.bbcode_text + "[/center]";
		call_deferred("update_info_labels");
			
	if level_name == "Snake Pit":
		tutoriallabel.visible = true;
		tutoriallabel.rect_position = Vector2(0, 69);
		tutoriallabel.rect_position.y -= 24;
		tutoriallabel.bbcode_text = "[center]You can make Checkpoints by doing:\nCtrl+C: Copy Replay\nCtrl+V: Paste Replay[/center]";
	
func initialize_timeline_viewers() -> void:
	heavytimeline.label = heavyinfolabel;
	lighttimeline.label = lightinfolabel;
	heavytimeline.actor = heavy_actor;
	lighttimeline.actor = light_actor;
	heavytimeline.max_moves = heavy_max_moves;
	lighttimeline.max_moves = light_max_moves;
	heavytimeline.reset();
	lighttimeline.reset();
	
	timeline_squish();
	
func timeline_squish() -> void:
	# timeline squish time
	heavyinfolabel.rect_position = HeavyInfoLabel_default_position;
	heavytimeline.position = HeavyTimeline_default_position;
	lightinfolabel.rect_position = LightInfoLabel_default_position;
	lighttimeline.position = LightTimeline_default_position;
	
	var heavy_max = heavy_max_moves+heavy_locked_turns.size();
	var light_max = light_max_moves+light_locked_turns.size();
	
	# horizontal squish check
	var effective_width = map_x_max;
	var heavy_extra_width = floor((heavy_max-1)/11);
	var light_extra_width = floor((light_max-1)/11);
	effective_width += max(0, heavy_extra_width);
	effective_width += max(0, light_extra_width);
	if (effective_width > 16):
		return;
		
	# calculation: the screen is 512 pixels wide. each cell is 24 pixels.
	# we want 24 pixels of leeway, then our timelines.
	var center = pixel_width/2;
	var left = floor(center-map_x_max*24.0/2.0);
	var right = floor(center+map_x_max*24.0/2.0);
	heavyinfolabel.rect_position.x += left-48-24*heavy_extra_width;
	heavytimeline.position.x += left-48-24*heavy_extra_width;
	lightinfolabel.rect_position.x -= left-48-24*light_extra_width;
	lighttimeline.position.x -= left-48-24*light_extra_width;
	
	# vertical squish check
	if (heavy_max > 10 or light_max > 10):
		return;
	
	# now for vertical squish. screen is 300 pixels tall.
	var heavy_tallness = heavy_max*24 + heavyinfolabel.rect_size.y;
	var light_tallness = light_max*24 + lightinfolabel.rect_size.y;
	var max_tallness = max(heavy_tallness, light_tallness);
	var y_offset = int(floor((pixel_height-max_tallness)/2));
	heavyinfolabel.rect_position.y += y_offset
	heavytimeline.position.y += y_offset
	lightinfolabel.rect_position.y += y_offset
	lighttimeline.position.y += y_offset

func broadcast_animation_nonce(animation_nonce: int) -> void:
	# have to do both to fix a bug where you change characters immediately after making a move
	# (alternatively keep track of it, but meh, it's quick enough right?)
	heavytimeline.broadcast_animation_nonce(animation_nonce);
	lighttimeline.broadcast_animation_nonce(animation_nonce);

func get_used_cells_by_id_all_layers(id: int) -> Array:
	var results = []
	for layer in terrain_layers:
		results.append(layer.get_used_cells_by_id(id));
	return results;
	
func get_used_cells_by_id_one_array(id: int) -> Array:
	var results = []
	for layer in terrain_layers:
		results.append_array(layer.get_used_cells_by_id(id));
	return results;

func make_actors() -> void:
	# mark voidlike puzzle now
	voidlike_puzzle = false;
	if (is_custom):
		for tile in voidlike_tiles:
			for layer in terrain_layers:
				var hits = layer.get_used_cells_by_id(tile);
				if (hits.size() > 0):
					voidlike_puzzle = true;
					break;
	
	# find goals and goal-ify them
	for layer in terrain_layers:
		find_goals(layer);
	
	# find heavy and light and turn them into actors
	# as a you-fucked-up backup, put them in 0,0 if there seems to be none
	var layers_tiles = get_used_cells_by_id_all_layers(Tiles.HeavyIdle);
	var found_one = false;
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		if (tiles.size() > 0):
			found_one = true;
	if !found_one:
		layers_tiles = [[Vector2(0, 0)]];
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for heavy_tile in tiles:
			terrain_layers[i].set_cellv(heavy_tile, -1);
			heavy_actor = make_actor(Actor.Name.Heavy, heavy_tile, true);
			heavy_actor.heaviness = Heaviness.STEEL;
			heavy_actor.strength = Strength.HEAVY;
			heavy_actor.durability = Durability.FIRE;
			heavy_actor.fall_speed = 2;
			heavy_actor.climbs = true;
			heavy_actor.color = heavy_color;
			heavy_actor.powered = heavy_max_moves != 0;
			if (heavy_actor.pos.x > (map_x_max / 2)):
				heavy_actor.facing_left = true;
			heavy_actor.update_graphics();
	
	layers_tiles = get_used_cells_by_id_all_layers(Tiles.LightIdle);
	found_one = false;
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		if (tiles.size() > 0):
			found_one = true;
	if !found_one:
		layers_tiles = [[Vector2(0, 0)]];
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for light_tile in tiles:
			terrain_layers[i].set_cellv(light_tile, -1);
			light_actor = make_actor(Actor.Name.Light, light_tile, true);
			light_actor.heaviness = Heaviness.IRON;
			light_actor.strength = Strength.LIGHT;
			light_actor.durability = Durability.SPIKES;
			light_actor.fall_speed = 1;
			light_actor.climbs = true;
			light_actor.color = light_color;
			light_actor.powered = light_max_moves != 0;
			if (light_actor.pos.x > (map_x_max / 2)):
				light_actor.facing_left = true;
			light_actor.update_graphics();
	
	# crates
	extract_actors(Tiles.IronCrate, Actor.Name.IronCrate, Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 99, false, Color(0.5, 0.5, 0.5, 1));
	extract_actors(Tiles.SteelCrate, Actor.Name.SteelCrate, Heaviness.STEEL, Strength.LIGHT, Durability.PITS, 99, false, Color(0.25, 0.25, 0.25, 1));
	extract_actors(Tiles.PowerCrate, Actor.Name.PowerCrate, Heaviness.WOODEN, Strength.HEAVY, Durability.FIRE, 99, false, Color(1, 0, 0.86, 1));
	extract_actors(Tiles.WoodenCrate, Actor.Name.WoodenCrate, Heaviness.WOODEN, Strength.WOODEN, Durability.SPIKES, 99, false, Color(0.5, 0.25, 0, 1));
	
	# cuckoo clocks
	extract_actors(Tiles.CuckooClock, Actor.Name.CuckooClock, Heaviness.WOODEN, Strength.WOODEN, Durability.SPIKES, 1, false, Color("#AD8255"));
	
	# time crystals
	extract_actors(Tiles.TimeCrystalGreen, Actor.Name.TimeCrystalGreen, Heaviness.CRYSTAL, Strength.CRYSTAL, Durability.NOTHING, 0, false, Color("#A9F05F"));
	extract_actors(Tiles.TimeCrystalMagenta, Actor.Name.TimeCrystalMagenta, Heaviness.CRYSTAL, Strength.CRYSTAL, Durability.NOTHING, 0, false, Color("#9966CC"));
	
	# chrono helixes
	extract_actors(Tiles.ChronoHelixRed, Actor.Name.ChronoHelixRed, Heaviness.IRON, Strength.HEAVY, Durability.NOTHING, 1, false, Color("FF6A00"));
	extract_actors(Tiles.ChronoHelixBlue, Actor.Name.ChronoHelixBlue, Heaviness.IRON, Strength.HEAVY, Durability.NOTHING, 1, false, Color("00FFFF"));
	
	# joke portals
	extract_actors(Tiles.HeavyGoalJoke, Actor.Name.HeavyGoalJoke, Heaviness.CRYSTAL, Strength.CRYSTAL, Durability.NOTHING, 0, false, Color("FF6A00"));
	extract_actors(Tiles.LightGoalJoke, Actor.Name.LightGoalJoke, Heaviness.CRYSTAL, Strength.CRYSTAL, Durability.NOTHING, 0, false, Color("00FFFF"));
	
	find_colours();
	
	tick_clocks();
	
func tick_clocks() -> void:
	if clock_turns == null or clock_turns == "":
		return
	var clock_turns_array = clock_turns.split(",");
	var i = 0;
	if (clock_turns_array.size() <= 0):
		return
	# I'll stable sort if needed
	for actor in actors:
		if actor.actorname == Actor.Name.CuckooClock:
			actor.set_ticks(int(clock_turns_array[i]));
			i += 1;
			if i >= clock_turns_array.size():
				return
	
func find_goals(layer: TileMap) -> void:
	var heavy_goal_tiles = layer.get_used_cells_by_id(Tiles.HeavyGoal);
	for tile in heavy_goal_tiles:
		var goal = Goal.new();
		goal.gamelogic = self;
		goal.actorname = Actor.Name.HeavyGoal;
		goal.texture = preload("res://assets/BigPortalRed.png");
		goal.centered = true;
		goal.pos = tile;
		goal.position = layer.map_to_world(goal.pos) + Vector2(cell_size/2, cell_size/2);
		goal.modulate = Color(1, 1, 1, 0.8);
		goal.instantly_reach_scalify();
		goals.append(goal);
		actorsfolder.add_child(goal);
		goal.update_graphics();
	
	var light_goal_tiles = layer.get_used_cells_by_id(Tiles.LightGoal);
	for tile in light_goal_tiles:
		var goal = Goal.new();
		goal.gamelogic = self;
		goal.actorname = Actor.Name.LightGoal;
		goal.texture = preload("res://assets/BigPortalBlue.png");
		goal.centered = true;
		goal.pos = tile;
		goal.position = layer.map_to_world(goal.pos) + Vector2(cell_size/2, cell_size/2);
		goal.modulate = Color(1, 1, 1, 0.8);
		goal.rotate_magnitude = -1;
		goal.instantly_reach_scalify();
		goals.append(goal);
		actorsfolder.add_child(goal);
		goal.update_graphics();
	
func extract_actors(id: int, actorname: int, heaviness: int, strength: int, durability: int, fall_speed: int, climbs: bool, color: Color) -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			terrain_layers[i].set_cellv(tile, -1);
			var actor = make_actor(actorname, tile, false);
			actor.heaviness = heaviness;
			actor.strength = strength;
			actor.durability = durability;
			actor.fall_speed = fall_speed;
			actor.climbs = climbs;
			actor.is_character = false;
			actor.color = color;
			actor.update_graphics();
			
			if (actor.actorname == Actor.Name.HeavyGoalJoke):
				joke_portals_present = true;
				# manifest a goal to live here
				var goal = Goal.new();
				goal.gamelogic = self;
				goal.actorname = Actor.Name.HeavyGoal;
				goal.texture = preload("res://assets/BigPortalRed.png");
				goal.centered = true;
				goal.pos = actor.pos;
				goal.position = Vector2(cell_size/2, cell_size/2);
				goal.modulate = Color(1, 1, 1, 0.8);
				goal.instantly_reach_scalify();
				goals.append(goal);
				goal.update_graphics();
				actor.joke_goal = goal;
				actor.add_child(goal);
			elif (actor.actorname == Actor.Name.LightGoalJoke):
				joke_portals_present = true;
				# manifest a goal to live here
				var goal = Goal.new();
				goal.gamelogic = self;
				goal.actorname = Actor.Name.LightGoal;
				goal.texture = preload("res://assets/BigPortalBlue.png");
				goal.centered = true;
				goal.pos = actor.pos;
				goal.position = Vector2(cell_size/2, cell_size/2);
				goal.modulate = Color(1, 1, 1, 0.8);
				goal.rotate_magnitude = -1;
				goal.instantly_reach_scalify();
				goals.append(goal);
				goal.update_graphics();
				actor.joke_goal = goal;
				actor.add_child(goal);
	
func find_colours() -> void:
	find_colour(Tiles.ColourRed, TimeColour.Red);
	find_colour(Tiles.ColourBlue, TimeColour.Blue);
	find_colour(Tiles.ColourMagenta, TimeColour.Magenta);
	find_colour(Tiles.ColourGray, TimeColour.Gray);
	find_colour(Tiles.ColourGreen, TimeColour.Green);
	find_colour(Tiles.ColourVoid, TimeColour.Void);
	find_colour(Tiles.ColourPurple, TimeColour.Purple);
	find_colour(Tiles.ColourBlurple, TimeColour.Blurple);
	find_colour(Tiles.ColourCyan, TimeColour.Cyan);
	find_colour(Tiles.ColourOrange, TimeColour.Orange);
	find_colour(Tiles.ColourYellow, TimeColour.Yellow);
	find_colour(Tiles.ColourWhite, TimeColour.White);
	
func find_colour(id: int, time_colour : int) -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			terrain_layers[i].set_cellv(tile, -1);
			# get first actor with the same pos and native colour and change their time_colour
			for actor in actors:
				if actor.pos == tile and actor.is_native_colour():
					actor.time_colour = time_colour;
					actor.update_time_bubble();
					if (save_file.has("colourblind_mode")):
						var value = save_file["colourblind_mode"];
						actor.setup_colourblind_mode(value);
					break;
	
func calculate_map_size() -> void:
	map_x_max = 0;
	map_y_max = 0;
	for layer in terrain_layers:
		var tiles = layer.get_used_cells();
		for tile in tiles:
			if tile.x > map_x_max:
				map_x_max = tile.x;
			if tile.y > map_y_max:
				map_y_max = tile.y;
	terrainmap.position.x = (map_x_max_max-map_x_max)*(cell_size/2)-8;
	terrainmap.position.y = (map_y_max_max-map_y_max)*(cell_size/2)+12;
	underterrainfolder.position = terrainmap.position;
	actorsfolder.position = terrainmap.position;
	ghostsfolder.position = terrainmap.position;
	underactorsparticles.position = terrainmap.position;
	overactorsparticles.position = terrainmap.position;
	checkerboard.rect_position = terrainmap.position;
	checkerboard.rect_size = cell_size*Vector2(map_x_max+1, map_y_max+1);
	# hack for World's Smallest Puzzle!
	if (map_y_max == 0):
		checkerboard.rect_position.y -= cell_size;
		
func update_targeter() -> void:
	if (heavy_selected):
		targeter.position = heavy_actor.position + terrainmap.position - Vector2(2, 2);
	else:
		targeter.position = light_actor.position + terrainmap.position - Vector2(2, 2);
	
	if (!downarrow.visible):
		return;
	
	downarrow.position = targeter.position - Vector2(0, 24);
	
	if (heavy_turn > 0 and heavy_selected):
		rightarrow.position = heavytimeline.position - Vector2(24, 24) + Vector2(0, 24)*heavy_turn;
	else:
		rightarrow.position = Vector2(-48, -48);
	
	if (light_turn > 0 and !heavy_selected):
		leftarrow.position = lighttimeline.position + Vector2(24, -24) + Vector2(0, 24)*light_turn;
	else:
		leftarrow.position = Vector2(-48, -48);
		
func prepare_audio() -> void:
	# TODO: I could automate this if I can iterate the folder
	# TODO: replace this with an enum and assert on startup like tiles
	
	#used
	sounds["abysschime"] = preload("res://sfx/abysschime.ogg");
	sounds["bluefire"] = preload("res://sfx/bluefire.ogg");
	sounds["broken"] = preload("res://sfx/broken.ogg");
	sounds["bump"] = preload("res://sfx/bump.ogg");
	sounds["fall"] = preload("res://sfx/fall.ogg");
	sounds["fuzz"] = preload("res://sfx/fuzz.ogg");
	sounds["greenfire"] = preload("res://sfx/greenfire.ogg");
	sounds["greentimecrystal"] = preload("res://sfx/greentimecrystal.ogg");
	sounds["heavycoyote"] = preload("res://sfx/heavycoyote.ogg");
	sounds["heavyland"] = preload("res://sfx/heavyland.ogg");
	sounds["heavystep"] = preload("res://sfx/heavystep.ogg");
	sounds["heavyuncoyote"] = preload("res://sfx/heavyuncoyote.ogg");
	sounds["heavyunland"] = preload("res://sfx/heavyunland.ogg");
	sounds["involuntarybump"] = preload("res://sfx/involuntarybump.ogg");
	sounds["involuntarybumplight"] = preload("res://sfx/involuntarybumplight.ogg");
	sounds["involuntarybumpother"] = preload("res://sfx/involuntarybumpother.ogg");
	sounds["lightcoyote"] = preload("res://sfx/lightcoyote.ogg");
	sounds["lightland"] = preload("res://sfx/lightland.ogg");
	sounds["lightstep"] = preload("res://sfx/lightstep.ogg");
	sounds["lightuncoyote"] = preload("res://sfx/lightuncoyote.ogg");
	sounds["lightunland"] = preload("res://sfx/lightunland.ogg");
	sounds["lose"] = preload("res://sfx/lose.ogg");
	sounds["magentatimecrystal"] = preload("res://sfx/magentatimecrystal.ogg");
	sounds["metarestart"] = preload("res://sfx/metarestart.ogg");
	sounds["metaundo"] = preload("res://sfx/metaundo.ogg");
	sounds["push"] = preload("res://sfx/push.ogg");
	sounds["redfire"] = preload("res://sfx/redfire.ogg");
	sounds["remembertimecrystal"] = preload("res://sfx/remembertimecrystal.ogg");
	sounds["restart"] = preload("res://sfx/restart.ogg");	
	sounds["shatter"] = preload("res://sfx/shatter.ogg");
	sounds["shroud"] = preload("res://sfx/shroud.ogg");
	sounds["switch"] = preload("res://sfx/switch.ogg");
	sounds["tick"] = preload("res://sfx/tick.ogg");
	sounds["timesup"] = preload("res://sfx/timesup.ogg");
	sounds["unbroken"] = preload("res://sfx/unbroken.ogg");
	sounds["undostrong"] = preload("res://sfx/undostrong.ogg");
	sounds["unfall"] = preload("res://sfx/unfall.ogg");
	sounds["unpush"] = preload("res://sfx/unpush.ogg");
	sounds["unshatter"] = preload("res://sfx/unshatter.ogg");
	sounds["untick"] = preload("res://sfx/untick.ogg");
	sounds["usegreenality"] = preload("res://sfx/usegreenality.ogg");
	sounds["voidundo"] = preload("res://sfx/voidundo.ogg");
	sounds["winentwined"] = preload("res://sfx/winentwined.ogg");
	sounds["winbadtime"] = preload("res://sfx/winbadtime.ogg");
	
	#unused
	sounds["step"] = preload("res://sfx/step.ogg");
	sounds["undo"] = preload("res://sfx/undo.ogg");
	
	music_tracks.append(preload("res://music/New Bounds.ogg"));
	music_info.append("Patashu - New Bounds");
	music_tracks.append(preload("res://music/Effortless Existence.ogg"));
	music_info.append("Patashu - Effortless Existence");
	music_tracks.append(preload("res://music/Starblind.ogg"));
	music_info.append("Patashu - Starblind");
	music_tracks.append(preload("res://music/polygon remix.ogg"));
	music_info.append("Sota Fujimori - polygon (Patashu's Entwined Time Remix)");
	music_tracks.append(preload("res://music/Highs and Lows.ogg"));
	music_info.append("Patashu - Highs & Lows");
	
	for i in range (8):
		var speaker = AudioStreamPlayer.new();
		self.add_child(speaker);
		speakers.append(speaker);
	lost_speaker = AudioStreamPlayer.new();
	lost_speaker.stream = sounds["lose"];
	lost_speaker_volume_tween = Tween.new();
	self.add_child(lost_speaker_volume_tween);
	self.add_child(lost_speaker);
	won_speaker = AudioStreamPlayer.new();
	self.add_child(won_speaker);
	music_speaker = AudioStreamPlayer.new();
	self.add_child(music_speaker);

func fade_in_lost():
	winlabel.visible = true;
	call_deferred("adjust_winlabel");
	Shade.on = true;
	
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	var db = save_file["fanfare_volume"];
	if (db <= -30):
		return;
	lost_speaker.volume_db = -40 + db;
	lost_speaker_volume_tween.interpolate_property(lost_speaker, "volume_db", -40 + db, -10 + db, 3.00, 1, Tween.EASE_IN, 0)
	lost_speaker_volume_tween.start();
	lost_speaker.play();

func cut_sound() -> void:
	if (doing_replay and meta_undo_a_restart_mode):
		return;
	for speaker in speakers:
		speaker.stop();
	lost_speaker.stop();
	won_speaker.stop();

func play_sound(sound: String) -> void:
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	if (sounds_played_this_frame.has(sound)):
		return;
	for speaker in speakers:
		if speaker.volume_db <= -30:
			return;
		if !speaker.playing:
			speaker.stream = sounds[sound];
			sounds_played_this_frame[sound] = true;
			speaker.play();
			return;

func play_won(sound: String) -> void:
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	if (sounds_played_this_frame.has(sound)):
		return;
	var speaker = won_speaker;
	# might adjust to -40 db or whatever depending
	if speaker.volume_db <= -30:
		return;
	if speaker.playing:
		speaker.stop();
	speaker.stream = sounds[sound];
	sounds_played_this_frame[sound] = true;
	speaker.play();
	return;

func toggle_mute() -> void:
	if (!muted):
		floating_text("M: Muted");
	else:
		floating_text("M: Unmuted");
	muted = !muted;
	music_speaker.stream_paused = muted;
	cut_sound();

func make_actor(actorname: int, pos: Vector2, is_character: bool, chrono: int = Chrono.TIMELESS) -> Actor:
	var actor = Actor.new();
	# do this before update_goal_lock()
	actors.append(actor);
	actor.actorname = actorname;
	if actor.actorname == Actor.Name.TimeCrystalGreen or actor.actorname == Actor.Name.TimeCrystalMagenta:
		actor.is_crystal = true;
		update_goal_lock();
	actor.is_character = is_character;
	actor.gamelogic = self;
	actor.offset = Vector2(cell_size/2, cell_size/2);
	actorsfolder.add_child(actor);
	actor.time_colour = actor.native_colour();
	move_actor_to(actor, pos, chrono, false, false);
	if (chrono < Chrono.META_UNDO):
		print("TODO")
	return actor;
	
func update_goal_lock() -> void:
	var locked = false;
	for actor in actors:
		if actor.is_crystal and !actor.broken:
			locked = true;
			break;
	if (!locked):
		for goal in goals:
			if goal.locked:
				goal.unlock();
	else:
		for goal in goals:
			if !goal.locked:
				goal.lock();

func animation_nonce_fountain_dispense() -> int:
	var result = animation_nonce_fountain;
	animation_nonce_fountain += 1;
	return result;
	
func heavy_goal_here(pos: Vector2, terrain: Array) -> bool:
	if (!joke_portals_present):
		return terrain.has(Tiles.HeavyGoal);
	else:
		for goal in goals:
			if goal.actorname == Actor.Name.HeavyGoal and goal.pos == pos:
				return true;
		return false;
	
func light_goal_here(pos: Vector2, terrain: Array) -> bool:
	if (!joke_portals_present):
		return terrain.has(Tiles.LightGoal);
	else:
		for goal in goals:
			if goal.actorname == Actor.Name.LightGoal and goal.pos == pos:
				return true;
		return false;
	
func move_actor_relative(actor: Actor, dir: Vector2, chrono: int, hypothetical: bool, is_gravity: bool,
is_retro: bool = false, pushers_list: Array = [], was_fall = false, was_push = false,
phased_out_of = null, animation_nonce : int = -1, is_move: bool = false) -> int:
	if (chrono == Chrono.GHOSTS):
		var ghost = get_ghost_that_hasnt_moved(actor);
		ghost.ghost_dir = -dir;
		ghost.pos = ghost.previous_ghost.pos + dir;
		ghost.position = terrainmap.map_to_world(ghost.pos);
		return Success.Yes;
	
	return move_actor_to(actor, actor.pos + dir, chrono, hypothetical,
	is_gravity, is_retro, pushers_list, was_push, was_fall, phased_out_of, animation_nonce, is_move);
	
func move_actor_to(actor: Actor, pos: Vector2, chrono: int, hypothetical: bool, is_gravity: bool,
is_retro: bool = false, pushers_list: Array = [], was_fall: bool = false, was_push: bool = false,
phased_out_of = null, animation_nonce: int = -1, is_move: bool = false) -> int:
	var dir = pos - actor.pos;
	var old_pos = actor.pos;
	
	var success = try_enter(actor, dir, chrono, true, hypothetical, is_gravity, is_retro, pushers_list,
	phased_out_of);
	if (success == Success.Yes and !hypothetical):
		if (!is_retro):
			was_push = pushers_list.size() > 0;
			was_fall = is_gravity;
		actor.pos = pos;
		# joke portal update
		if (actor.joke_goal != null):
			var joke_goal = actor.joke_goal;
			joke_goal.pos = pos;
			if joke_goal.dinged:
				set_actor_var(joke_goal, "dinged", false, chrono);
			else:
				if joke_goal.actorname == Actor.Name.HeavyGoal:
					if !heavy_actor.broken and heavy_actor.pos == joke_goal.pos:
						set_actor_var(joke_goal, "dinged", true, chrono);
				elif joke_goal.actorname == Actor.Name.LightGoal:
					if !light_actor.broken and light_actor.pos == joke_goal.pos:
						set_actor_var(joke_goal, "dinged", true, chrono);
		
		# 'phased out of' mechanic: If two actors stack, one actor moves out and then undoes,
		# it should phase back in rather than retro-push since no desyncing or timefuck has happened.
		# (Remember, character undo ALWAYS returns you to the state you were in on that turn... IF nothing changed.)
		phased_out_of = null;
		if (chrono == Chrono.MOVE):
			phased_out_of = [];
			for actor in actors:
				if actor.pushable() and actor.pos == old_pos:
					phased_out_of.append(actor);
		if (animation_nonce == -1):
			animation_nonce = animation_nonce_fountain_dispense();
			
		# do facing change now before move happens
		if (is_move and actor.is_character):
			if (dir == Vector2.LEFT):
				if (heavy_selected and !heavy_actor.facing_left):
					set_actor_var(heavy_actor, "facing_left", true, Chrono.MOVE);
				elif (!heavy_selected and !light_actor.facing_left):
					set_actor_var(light_actor, "facing_left", true, Chrono.MOVE);
			elif (dir == Vector2.RIGHT):
				if (heavy_selected and heavy_actor.facing_left):
					set_actor_var(heavy_actor, "facing_left", false, Chrono.MOVE);
				elif (!heavy_selected and light_actor.facing_left):
					set_actor_var(light_actor, "facing_left", false, Chrono.MOVE);
			
		add_undo_event([Undo.move, actor, dir, was_push, was_fall, phased_out_of, animation_nonce],
		chrono_for_maybe_green_actor(actor, chrono));
		
		# update night and stars state
		var terrain = terrain_in_tile(actor.pos);
		var actor_was_in_night = actor.in_night;
		var actor_was_in_stars = actor.in_stars;
		actor.in_night = false;
		actor.in_stars = false;
		if terrain.has(Tiles.TheNight):
			actor.in_night = true;
			if (!actor_was_in_night):
				add_to_animation_server(actor, [Animation.grayscale, true]);
		if terrain.has(Tiles.TheStars):
			actor.in_stars = true;
		if (actor_was_in_night and !actor.in_night):
			add_to_animation_server(actor, [Animation.grayscale, false]);
		
		#do sound effects for special moves and their undoes
		if (was_push and is_retro):
			add_to_animation_server(actor, [Animation.sfx, "unpush"]);
		if (was_push and !is_retro):
			add_to_animation_server(actor, [Animation.sfx, "push"]);
		if (was_fall and is_retro):
			add_to_animation_server(actor, [Animation.sfx, "unfall"]);
		if (was_fall and !is_retro):
			add_to_animation_server(actor, [Animation.sfx, "fall"]);
		
		#do trapdoor animation (removed until Teal Knight draws something better)
		#if (dir == Vector2.DOWN):
		#	var new_terrain = terrain_in_tile(actor.pos);
		#	if new_terrain.has(Tiles.WoodenPlatform) or new_terrain.has(Tiles.LadderPlatform):
		#		add_to_animation_server(actor, [Animation.trapdoor_opens, terrainmap.map_to_world(actor.pos)]);
		add_to_animation_server(actor, [Animation.move, dir, is_retro, animation_nonce]);
		
		#ding logic
		if (!actor.broken):
			var old_terrain = terrain_in_tile(actor.pos - dir);
			if (!actor.is_character):
				if terrain.has(Tiles.CrateGoal):
					if !actor.dinged:
						set_actor_var(actor, "dinged", true, chrono);
				else:
					if actor.dinged:
						set_actor_var(actor, "dinged", false, chrono);
			else:
				if actor.actorname == Actor.Name.Heavy and heavy_goal_here(actor.pos, terrain):
					for goal in goals:
						if goal.actorname == Actor.Name.HeavyGoal and !goal.dinged and goal.pos == actor.pos:
							set_actor_var(goal, "dinged", true, chrono);
				if actor.actorname == Actor.Name.Light and light_goal_here(actor.pos, terrain):
					for goal in goals:
						if goal.actorname == Actor.Name.LightGoal and !goal.dinged and goal.pos == actor.pos:
							set_actor_var(goal, "dinged", true, chrono);
				if actor.actorname == Actor.Name.Heavy and heavy_goal_here(actor.pos - dir, old_terrain):
					for goal in goals:
						if goal.actorname == Actor.Name.HeavyGoal and goal.dinged and goal.pos != actor.pos:
							set_actor_var(goal, "dinged", false, chrono);
				if actor.actorname == Actor.Name.Light and light_goal_here(actor.pos - dir, old_terrain):
					for goal in goals:
						if goal.actorname == Actor.Name.LightGoal and goal.dinged and goal.pos != actor.pos:
							set_actor_var(goal, "dinged", false, chrono);
		
		# Sticky top: When Heavy moves non-up at Chrono.MOVE, an actor on top of it will try to move too afterwards.
		#(AD03: Chrono.CHAR_UNDO will sticky top green things but not the other character because I don't like the spring effect it'd cause)
		#(AD05: apparently I decided the sticky top can't move things you can't push, which is... valid ig?)
		#(AD12: Sticky top is now considered the 'pusher', which matters for e.g. the light flustered rule)
		#(AD14: I realized too late that this should be 'is_retro' not 'chrono == Chrono.MOVE', whoops.
		#I invented this mechanic before the concept of is_retro and never noticed it was weird until now.
		#(e.g. light on heavy, light jumps, heavy jumps, light undoes, light isn't pulled down by Heavy falling.)
		#Multiple replays rely on this behaviour now I think, I could do a full game pass but EHHH.
		#(Also I just now realized I never did AD03 so???)
		#(June 21st 2023: Finally doing AD14, ahem)
		#(AD15: Non-broken time crystals are sticky toppable! In fact, Heavy can PUSH them upwards thanks to some special logic elsewhere :D)
		#(FIX: Broken time crystals can't be sticky top'd because they're basically not things
		if actor.actorname == Actor.Name.Heavy and !is_retro and dir.y >= 0:
			var sticky_actors = actors_in_tile(actor.pos - dir + Vector2.UP);
			for sticky_actor in sticky_actors:
				if (strength_check(actor.strength, sticky_actor.heaviness) and (!sticky_actor.broken or !sticky_actor.is_crystal)):
					sticky_actor.just_moved = true;
					move_actor_relative(sticky_actor, dir, chrono, hypothetical, false, false, [actor]);
			for sticky_actor in sticky_actors:
				sticky_actor.just_moved = false;
		return success;
	elif (success != Success.Yes):
		# vanity bump goes here, even if it's hypothetical, muahaha
		if pushers_list.size() > 0 and actor.actorname == Actor.Name.Light:
			add_to_animation_server(actor, [Animation.fluster]);
		if (!hypothetical):
			# involuntary bump sfx
			if (pushers_list.size() > 0 or is_retro):
				if (actor.actorname == Actor.Name.Light):
					add_to_animation_server(actor, [Animation.sfx, "involuntarybumplight"]);
				elif (actor.actorname == Actor.Name.Heavy):
					add_to_animation_server(actor, [Animation.sfx, "involuntarybump"]);
				else:
					add_to_animation_server(actor, [Animation.sfx, "involuntarybumpother"]);
		# bump animation always happens, I think?
		add_to_animation_server(actor, [Animation.bump, dir, animation_nonce]);
	return success;
		
func adjust_turn(is_heavy: bool, amount: int, chrono : int) -> void:
	if (is_heavy):
		if (amount > 0):
			if heavy_filling_locked_turn_index > -1:
				heavytimeline.add_turn(heavy_locked_turns[heavy_filling_locked_turn_index]);
			elif heavy_filling_turn_actual > -1:
				heavytimeline.add_turn(heavy_undo_buffer[heavy_filling_turn_actual]);
			else:
				heavytimeline.add_turn(heavy_undo_buffer[heavy_turn]);
		else:
			var color = heavy_color;
			if (chrono >= Chrono.META_UNDO):
				color = meta_color;
			heavytimeline.remove_turn(color, heavy_filling_locked_turn_index, heavy_filling_turn_actual);
		add_undo_event([Undo.heavy_turn, amount], chrono);
		if (heavy_turn + amount == heavy_max_moves):
			set_actor_var(heavy_actor, "powered", false, chrono);
		elif (!heavy_actor.powered):
			set_actor_var(heavy_actor, "powered", true, chrono);
		heavy_turn += amount;
		#if (debug_prints):
		#	print("=== IT IS NOW HEAVY TURN " + str(heavy_turn) + " ===");
	else:
		if (amount > 0):
			if light_filling_locked_turn_index > -1:
				lighttimeline.add_turn(light_locked_turns[light_filling_locked_turn_index]);
			elif light_filling_turn_actual > -1:
				lighttimeline.add_turn(light_undo_buffer[light_filling_turn_actual]);
			else:
				lighttimeline.add_turn(light_undo_buffer[light_turn]);
		else:
			var color = light_color;
			if (chrono >= Chrono.META_UNDO):
				color = meta_color;
			lighttimeline.remove_turn(color, light_filling_locked_turn_index, light_filling_turn_actual);
		add_undo_event([Undo.light_turn, amount], chrono);
		if (light_turn + amount == light_max_moves):
			set_actor_var(light_actor, "powered", false, chrono);
		elif (!light_actor.powered):
			set_actor_var(light_actor, "powered", true, chrono);
		light_turn += amount;
		#if (debug_prints):
		#	print("=== IT IS NOW LIGHT TURN " + str(light_turn) + " ===");
		
func actors_in_tile(pos: Vector2) -> Array:
	var result = [];
	for actor in actors:
		if actor.pos == pos:
			result.append(actor);
	return result;
	
func terrain_in_tile(pos: Vector2) -> Array:
	var result = [];
	for layer in terrain_layers:
		result.append(layer.get_cellv(pos));
	return result;

func chrono_for_maybe_green_actor(actor: Actor, chrono: int) -> int:
	if (chrono >= Chrono.META_UNDO):
		return chrono;
	elif (actor.time_colour == TimeColour.Void):
		return Chrono.META_UNDO;
	elif (chrono >= Chrono.CHAR_UNDO):
		return chrono;
	elif (actor.time_colour == TimeColour.Green):
		return Chrono.CHAR_UNDO;
	return chrono;
	
func maybe_break_actor(actor: Actor, hazard: int, hypothetical: bool, green_terrain: int, chrono: int) -> int:
	# AD04: being broken makes you immune to breaking :D
	if (!actor.broken and actor.durability <= hazard):
		if (!hypothetical):
			actor.post_mortem = hazard;
			if (green_terrain == Greenness.Green and chrono < Chrono.CHAR_UNDO):
				chrono = Chrono.CHAR_UNDO;
			if (green_terrain == Greenness.Void and chrono < Chrono.META_UNDO):
				chrono = Chrono.META_UNDO;
			set_actor_var(actor, "broken", true, chrono);
		return Success.Surprise;
	else:
		return Success.No;

func find_or_create_layer_having_this_tile(pos: Vector2, assumed_old_tile: int) -> int:
	for layer in range(terrain_layers.size()):
		var terrain_layer = terrain_layers[layer];
		var old_tile = terrain_layer.get_cellv(pos);
		if (old_tile == assumed_old_tile):
			return layer;
	# create a new one.
	var new_layer = TileMap.new();
	new_layer.tile_set = terrainmap.tile_set;
	new_layer.cell_size = terrainmap.cell_size;
	# new layer will have to be at the back (first cihld, last terrain_layer), so I don't desync existing memories of layers.
	terrainmap.add_child(new_layer);
	terrainmap.move_child(new_layer, 0);
	terrain_layers.push_back(new_layer);
	return terrain_layers.size() - 1;

func maybe_change_terrain(actor: Actor, pos: Vector2, layer: int, hypothetical: bool, green_terrain: int,
chrono: int, new_tile: int, assumed_old_tile: int = -2, animation_nonce: int = -1) -> int:
	if (chrono == Chrono.GHOSTS):
		# TODO: the ghost will technically be on the wrong layer but, whatever, too much of a pain in the ass to fix rn
		# (I think the solution would be to programatically have one Node2D between each presentation TileMap and put it in the right folder)
		if new_tile != -1:
			var ghost = make_ghost_here_with_texture(pos, terrainmap.tile_set.tile_get_texture(new_tile));
		else:
			var ghost = make_ghost_here_with_texture(pos, preload("res://timeline/timeline-broken-12.png"));
			ghost.scale = Vector2(2, 2);
		return Success.Surprise;
	
	if (!hypothetical):
		var terrain_layer = terrain_layers[layer];
		var old_tile = terrain_layer.get_cellv(pos);
		if (assumed_old_tile != -2 and assumed_old_tile != old_tile):
			# desync (probably due to fuzz doubled glass mechanic). find or create the first layer where assumed_old_tile is correct.
			layer = find_or_create_layer_having_this_tile(pos, assumed_old_tile);
			terrain_layer = terrain_layers[layer];
		terrain_layer.set_cellv(pos, new_tile);
		if (green_terrain == Greenness.Green and chrono < Chrono.CHAR_UNDO):
			chrono = Chrono.CHAR_UNDO;
		if (green_terrain == Greenness.Void and chrono < Chrono.META_UNDO):
			chrono = Chrono.META_UNDO;
		
		if (animation_nonce == -1):
			animation_nonce = animation_nonce_fountain_dispense();
		
		add_undo_event([Undo.change_terrain, actor, pos, layer, old_tile, new_tile, animation_nonce], chrono);
		# TODO: presentation/data terrain layer update (see notes)
		# ~encasement layering/unlayering~~ just kidding, chronofrag time (AD11)
		if new_tile == Tiles.GlassBlock or new_tile == Tiles.GlassBlockCracked:
			add_to_animation_server(actor, [Animation.unshatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
			for actor in actors:
				# time crystal/glass chronofrag interaction: it isn't. that's my decision for now.
				if actor.pos == pos and !actor.broken and actor.durability <= Durability.PITS:
					actor.post_mortem = Durability.PITS;
					set_actor_var(actor, "broken", true, chrono);
		else:
			if (old_tile == Tiles.Fuzz):
				play_sound("fuzz");
			else:
				add_to_animation_server(actor, [Animation.shatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
	return Success.Surprise;

func current_tile_is_solid(actor: Actor, dir: Vector2, _is_gravity: bool, is_retro: bool) -> bool:
	var terrain = terrain_in_tile(actor.pos);
	var blocked = false;
	flash_terrain = -1;
	
	# when moving retrograde, it would have been valid to come out of a oneway, but not to have gone THROUGH one.
	# so check that.
	# besides that, glass blocks prevent exit.
	for id in terrain:
		match id:
			Tiles.OnewayEast:
				blocked = is_retro and dir == Vector2.RIGHT;
				if (blocked):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayWest:
				blocked = is_retro and dir == Vector2.LEFT;
				if (blocked):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayNorth:
				blocked = is_retro and dir == Vector2.UP;
				if (blocked):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewaySouth:
				blocked = is_retro and dir == Vector2.DOWN;
				if (blocked):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.GlassBlock:
				blocked = true;
				if (blocked):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.GlassBlockCracked:
				# it'd be cool to let actors break out of cracked glass blocks under their own power.
				blocked = true;
				if (blocked):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.GreenGlassBlock:
				blocked = true;
				if (blocked):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.VoidGlassBlock:
				blocked = true;
				if (blocked):
					flash_terrain = id;
					flash_colour = no_foo_flash;
		if blocked:
			return true;
	return false;

func no_if_true_yes_if_false(input: bool) -> int:
	if (input):
		return Success.No;
	return Success.Yes;

#helper variable for 'did we just bonk on something that should flash'
var flash_terrain = -1;
var flash_colour = Color(1, 1, 1, 1);
var oneway_flash = Color(1, 0, 0, 1);
var oneway_green_flash = Color(1, 0, 0, 1);
var oneway_purple_flash = Color(1, 1, 1, 1);
var no_foo_flash = Color(1, 1, 1, 1);

func try_enter_terrain(actor: Actor, pos: Vector2, dir: Vector2, hypothetical: bool, is_gravity: bool, is_retro: bool, chrono: int) -> int:
	var result = Success.Yes;
	flash_terrain = -1;
	
	# check for bottomless pits
	if (pos.y > map_y_max):
		return maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Mundane, chrono);

	var terrain = terrain_in_tile(pos);
	for i in range(terrain.size()):
		var id = terrain[i];
		match id:
			Tiles.Wall:
				result = Success.No;
			Tiles.LockClosed:
				result = Success.No;
			Tiles.Spikeball:
				result = maybe_break_actor(actor, Durability.SPIKES, hypothetical, Greenness.Mundane, chrono);
			Tiles.GreenSpikeball:
				result = maybe_break_actor(actor, Durability.SPIKES, hypothetical, Greenness.Green, chrono);
			Tiles.VoidSpikeball:
				result = maybe_break_actor(actor, Durability.SPIKES, hypothetical, Greenness.Void, chrono);
			Tiles.PowerSocket:
				if (actor.is_character):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Mundane, chrono);
				else:
					result = Success.No;
			Tiles.GreenPowerSocket:
				if (actor.is_character):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Green, chrono);
				else:
					result = Success.No;
			Tiles.VoidPowerSocket:
				if (actor.is_character):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Void, chrono);
				else:
					result = Success.No;
			Tiles.NoHeavy:
				result = no_if_true_yes_if_false(actor.actorname == Actor.Name.Heavy);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.NoLight:
				result = no_if_true_yes_if_false(actor.actorname == Actor.Name.Light);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.NoCrate:
				result = no_if_true_yes_if_false(!actor.is_character);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.Grate:
				result = no_if_true_yes_if_false(actor.is_character);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.OnewayEastGreen:
				result = no_if_true_yes_if_false(dir == Vector2.LEFT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewayWestGreen:
				result = no_if_true_yes_if_false(dir == Vector2.RIGHT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewayNorthGreen:
				result = no_if_true_yes_if_false(dir == Vector2.DOWN);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewaySouthGreen:
				result = no_if_true_yes_if_false(dir == Vector2.UP);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewayEastPurple:
				result = no_if_true_yes_if_false(is_retro and dir == Vector2.LEFT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_purple_flash;
			Tiles.OnewayWestPurple:
				result = no_if_true_yes_if_false(is_retro and dir == Vector2.RIGHT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_purple_flash;
			Tiles.OnewayNorthPurple:
				result = no_if_true_yes_if_false(is_retro and dir == Vector2.DOWN);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_purple_flash;
			Tiles.OnewaySouthPurple:
				result = no_if_true_yes_if_false(is_retro and dir == Vector2.UP);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_purple_flash;
			Tiles.LadderPlatform:
				result = no_if_true_yes_if_false(dir == Vector2.DOWN and is_gravity);
			Tiles.WoodenPlatform:
				result = no_if_true_yes_if_false(dir == Vector2.DOWN and is_gravity);
			Tiles.OnewayEast:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.LEFT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayWest:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.RIGHT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayNorth:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.DOWN);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewaySouth:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.UP);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoRetro:
				result = no_if_true_yes_if_false(is_retro);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.GlassBlock:
				# rule I've been thinking about for a while - things lighter than iron can't break glass
				if (actor.heaviness >= Heaviness.IRON):
					result = maybe_change_terrain(actor, pos, i, hypothetical, Greenness.Mundane, chrono, -1);
				else:
					return Success.No;
			Tiles.GlassBlockCracked:
				result = maybe_change_terrain(actor, pos, i, hypothetical, Greenness.Mundane, chrono, -1);
			Tiles.GreenGlassBlock:
				if (actor.heaviness >= Heaviness.IRON):
					result = maybe_change_terrain(actor, pos, i, hypothetical, Greenness.Green, chrono, -1);
				else:
					return Success.No;
			Tiles.VoidGlassBlock:
				if (actor.heaviness >= Heaviness.IRON):
					result = maybe_change_terrain(actor, pos, i, hypothetical, Greenness.Void, chrono, -1);
				else:
					return Success.No;
		if result != Success.Yes:
			return result;
	return result;
	
func is_suspended(actor: Actor):
	#PERF: could try caching this and only updating it when an actor moves or breaks
	if (!actor.climbs()):
		return false;
	var terrain = terrain_in_tile(actor.pos);
	return terrain.has(Tiles.Ladder) || terrain.has(Tiles.LadderPlatform);

func terrain_is_hazardous(actor: Actor, pos: Vector2) -> int:
	if (pos.y > map_y_max and actor.durability <= Durability.PITS):
		return Durability.PITS;
	var terrain = terrain_in_tile(pos);
	if (terrain.has(Tiles.Spikeball) and actor.durability <= Durability.SPIKES):
		return Durability.SPIKES;
	return -1;
	
func strength_check(strength: int, heaviness: int) -> bool:
	if (heaviness == Heaviness.NONE):
		return strength >= Strength.NONE;
	if (heaviness == Heaviness.CRYSTAL):
		return strength >= Strength.CRYSTAL;
	if (heaviness == Heaviness.WOODEN):
		return strength >= Strength.WOODEN;
	if (heaviness == Heaviness.IRON):
		return strength >= Strength.LIGHT;
	if (heaviness == Heaviness.STEEL):
		return strength >= Strength.HEAVY;
	if (heaviness == Heaviness.SUPERHEAVY):
		return strength >= Strength.GRAVITY;
	return false;
	
func try_enter(actor: Actor, dir: Vector2, chrono: int, can_push: bool, hypothetical: bool, is_gravity: bool, is_retro: bool = false, pushers_list: Array = [], phased_out_of = null) -> int:
	var dest = actor.pos + dir;
	if (chrono >= Chrono.TIMELESS):
		return Success.Yes;
	if (chrono >= Chrono.META_UNDO and is_retro):
		# assuming no bugs, if it was overlapping in the meta-past, then it must have been valid to reach then
		return Success.Yes;
	
	# handle solidity in our tile, solidity in the tile over, hazards/surprises in the tile over
	if (!actor.phases_into_terrain()):
		if (current_tile_is_solid(actor, dir, is_gravity, is_retro)):
			if (flash_terrain > -1 and (!hypothetical or !is_gravity)):
				add_to_animation_server(actor, [Animation.afterimage_at, terrainmap.tile_set.tile_get_texture(flash_terrain), terrainmap.map_to_world(actor.pos), flash_colour]);
			return Success.No;
		var solidity_check = try_enter_terrain(actor, dest, dir, hypothetical, is_gravity, is_retro, chrono);
		if (solidity_check != Success.Yes):
			if (flash_terrain > -1 and (!hypothetical or !is_gravity)):
				add_to_animation_server(actor, [Animation.afterimage_at, terrainmap.tile_set.tile_get_texture(flash_terrain), terrainmap.map_to_world(dest), flash_colour]);
			return solidity_check;
	
	# handle pushing
	var actors_there = actors_in_tile(dest);
	var pushables_there = [];
	#var tiny_pushables_there = [];
	for actor_there in actors_there:
		if (phased_out_of != null and phased_out_of.has(actor_there)):
			continue
		#if actor_there.tiny_pushable():
		#	tiny_pushables_there.push_back(actor_there);
		elif actor_there.pushable():
			pushables_there.push_back(actor_there);
	
	if (pushables_there.size() > 0):
		if (!can_push):
			return Success.No;
		# check if the current actor COULD push the next actor, then give them a push and return the result
		# Multi Push Rule: Multipushes are allowed (even multiple things in a tile and etc) unless another rule prohibits it.
		var strength_modifier = 0;
		if (pushers_list.size() > 0):
			if actor.actorname == Actor.Name.Light:
				strength_modifier = -1;
		pushers_list.append(actor);
		for actor_there in pushables_there:
			# chrono helix bump check
			if (actor_there.actorname == Actor.Name.ChronoHelixRed):
				if actor.actorname == Actor.Name.ChronoHelixBlue:
					nonstandard_won = true;
					check_won();
					return Success.No;
			elif (actor_there.actorname == Actor.Name.ChronoHelixBlue):
				if actor.actorname == Actor.Name.ChronoHelixRed:
					nonstandard_won = true;
					check_won();
					return Success.No;
			
			# Strength Rule
			# Modified by the Light Clumsiness Rule: Light's strength is lowered by 1 when it's in the middle of a multi-push.
			if !strength_check(actor.strength + strength_modifier, actor_there.heaviness) and !can_eat(actor_there, actor):
				if (actor.phases_into_actors()):
					pushables_there.clear();
					break;
				else:
					pushers_list.pop_front();
					return Success.No;
		var result = Success.Yes;
		
		# logic to handle time crystals and actor stacks:
		#* for each pushable, hypothetically push-or-eat it.
		#* if any is No: return Success.No
		#* if any is Surprise: if !hypothetical, do all the surprises. then return Suprise.
		#* (if any is Yes): if !hypothetical, do all the push-or-eats, then return Yes
		
		var surprises = [];
		result = Success.Yes;
		for actor_there in pushables_there:
			if can_eat(actor, actor_there) or can_eat(actor_there, actor):
				continue;
			var actor_there_result = move_actor_relative(actor_there, dir, chrono, true, is_gravity, false, pushers_list);
			if actor_there_result == Success.No:
				if (actor.phases_into_actors()):
					pushables_there.clear();
					result = Success.Yes;
					break;
				elif (!actor.broken and pushables_there.size() == 1 and actor_there.actorname == Actor.Name.WoodenCrate and actor.is_character and !is_gravity):
					# 'Wooden Crates special moves'
					# When making a non-gravity move, if the push fails, unbroken Heavy can break a solo Wooden Crate, unbroken Light can push a Wooden Crate upwards.
					# since wooden crate did a bump, robot needs to do a bump too to sync up animations
					# should be OK to have the nonce be -1 since the real thing will still happen?
					add_to_animation_server(actor, [Animation.bump, dir, -1]);
					if actor.actorname == Actor.Name.Heavy:
						set_actor_var(actor_there, "broken", true, chrono);
					elif actor.actorname == Actor.Name.Light:
						dir = Vector2.UP;
						# check again if we can push it up
						actor_there_result = move_actor_relative(actor_there, dir, chrono, true, is_gravity, false, pushers_list);
						if (actor_there_result == Success.No):
							pushers_list.pop_front();
							return Success.No;
						elif(actor_there_result == Success.Surprise):
							result = Success.Surprise;
							surprises.append(actor_there);
				elif (!actor.broken and pushables_there.size() == 1 and actor.actorname == Actor.Name.SteelCrate and !actor_there.broken and (actor_there.actorname == Actor.Name.Light or actor_there.actorname == Actor.Name.CuckooClock)):
					# 'Steel Crates special moves'
					# If an unbroken steel crate tries to move into a solo unbroken Light or Cuckoo Clock for any reason, the target first breaks.
					# this also cancels the pusher's move which is janky but fuck it, I don't feel like fixing the jank for a non main campaign edge case
					result = Success.Surprise;
					add_to_animation_server(actor, [Animation.bump, dir, -1]);
					set_actor_var(actor_there, "broken", true, chrono);
				else:
					pushers_list.pop_front();
					return Success.No;
			if actor_there_result == Success.Surprise:
				result = Success.Surprise;
				surprises.append(actor_there);
		
		if (!hypothetical):
			if (result == Success.Surprise):
				for actor_there in surprises:
					move_actor_relative(actor_there, dir, chrono, hypothetical, is_gravity, false, pushers_list);
			else:
				for actor_there in pushables_there:
					actor_there.just_moved = true;
					#AD13: Heavy prefers to push crystals up instead of eat them. Sticky top baby ;D
					#this definitely won't bite me in the ass I want to make a PUZZLE ok
					if (can_eat(actor, actor_there) or can_eat(actor_there, actor)):
						if actor.actorname == Actor.Name.Heavy and !is_retro and dir == Vector2.UP:
							var crystal_carry = move_actor_relative(actor_there, dir, chrono, hypothetical, is_gravity, false, pushers_list);
							if (crystal_carry == Success.No):
								eat_crystal(actor, actor_there, chrono);
						else:
							eat_crystal(actor, actor_there, chrono);
					else:
						move_actor_relative(actor_there, dir, chrono, hypothetical, is_gravity, false, pushers_list);
				for actor_there in pushables_there:
					actor_there.just_moved = false;
		
		pushers_list.pop_front();
		return result;
	
	return Success.Yes;

func can_eat(eater: Actor, eatee: Actor) -> bool:
	if !eatee.is_crystal:
		return false;
	# right, don't re-eat broken crystals if e.g. Heavy sticky tops them around
	# (I need to decide how sticky topping broken actors works later, but I don't have to right now <w<)
	if eatee.broken:
		return false;
	if (!eater.is_character):
		# new: cuckoo clocks can eat time crystals :9
		# but only if they have a time
		if eater.actorname == Actor.Name.CuckooClock and !eater.broken and eater.ticks != 1000:
			pass
		else:
			return false;
	# for now I've decided you can always eat a time crystal - it'll just break you if it's nega and you're at 0/0 turns
	# other options: push, eat but do nothing, eat and go into negative moves, lose (time paradox)
	return true;
	#if (eatee.actorname == Actor.Name.TimeCrystalGreen):
	#	return true;
	#if (heavy_actor == eater and heavy_max_moves > 0 or light_actor == eater and light_max_moves > 0):
#		return true;
	#return false;
	
func eat_crystal(eater: Actor, eatee: Actor, chrono: int) -> void:
	# might be called backwards, so swap them around
	if eater.is_crystal:
		var temp = eatee;
		eatee = eater;
		eater = temp;
	set_actor_var(eatee, "broken", true, Chrono.CHAR_UNDO);
	if (eatee.actorname == Actor.Name.TimeCrystalGreen):
		if heavy_actor == eater:
			heavy_max_moves += 1;
			if (heavy_locked_turns.size() == 0):
				add_to_animation_server(eatee, [Animation.sfx, "greentimecrystal"])
				# raw: just add a turn to the end
				if (!heavy_actor.powered):
					set_actor_var(heavy_actor, "powered", true, Chrono.CHAR_UNDO);
				add_undo_event([Undo.heavy_green_time_crystal_raw], Chrono.CHAR_UNDO);
				add_to_animation_server(eater, [Animation.heavy_green_time_crystal_raw, eatee]);
			else:
				add_to_animation_server(eatee, [Animation.sfx, "remembertimecrystal"])
				# unlock the most recently locked move.
				var unlocked_move = heavy_locked_turns.pop_back();
				var unlocked_move_being_filled_this_turn = false;
				var filling_turn_actual_set = false;
				# if we were in the middle of filling it, mark that we're now filling a normal move again.
				if (heavy_filling_locked_turn_index == heavy_locked_turns.size()):
					unlocked_move_being_filled_this_turn = true;
					add_undo_event([Undo.heavy_filling_locked_turn_index, heavy_filling_locked_turn_index, -1], Chrono.CHAR_UNDO);
					heavy_filling_locked_turn_index = -1;
				# elif we were filling a move and just unlocked a new move on top of it, mark that fact.
				elif (heavy_selected and chrono == Chrono.MOVE and heavy_filling_locked_turn_index == -1 and heavy_filling_turn_actual == -1):
					heavy_filling_turn_actual = heavy_turn;
					filling_turn_actual_set = true;
					add_undo_event([Undo.heavy_filling_turn_actual, -1, heavy_filling_turn_actual], Chrono.CHAR_UNDO);
				
				# did we just pop an empty locked move?
				if (unlocked_move.size() == 0 and !unlocked_move_being_filled_this_turn):
					add_undo_event([Undo.heavy_turn_unlocked, -1, heavy_locked_turns.size()], Chrono.CHAR_UNDO);
					add_to_animation_server(eater, [Animation.heavy_green_time_crystal_unlock, eatee, -1]);
					set_actor_var(eater, "powered", true, Chrono.CHAR_UNDO);
				# or a locked move with contents?
				else:
					# maybe character hasn't created any events this turn yet
					while (heavy_undo_buffer.size() <= heavy_turn):
						heavy_undo_buffer.append([]);
					# if we're filling a move, we put the unlocked time crystal AFTER the filled move.
					if (filling_turn_actual_set):
						heavy_turn += 1;
						add_undo_event([Undo.heavy_turn_direct, 1], Chrono.CHAR_UNDO);
					heavy_undo_buffer.insert(heavy_turn, unlocked_move);
					add_undo_event([Undo.heavy_turn_unlocked, heavy_turn, heavy_locked_turns.size()], Chrono.CHAR_UNDO);
					if (!filling_turn_actual_set):
						heavy_turn += 1;
						add_undo_event([Undo.heavy_turn_direct, 1], Chrono.CHAR_UNDO);
					add_to_animation_server(eater, [Animation.heavy_green_time_crystal_unlock, eatee, heavy_turn]);
		elif light_actor == eater:
			light_max_moves += 1;
			if (light_locked_turns.size() == 0):
				add_to_animation_server(eatee, [Animation.sfx, "greentimecrystal"])
				if (!light_actor.powered):
					set_actor_var(light_actor, "powered", true, Chrono.CHAR_UNDO);
				add_undo_event([Undo.light_green_time_crystal_raw], Chrono.CHAR_UNDO);
				add_to_animation_server(eater, [Animation.light_green_time_crystal_raw, eatee]);
			else:
				add_to_animation_server(eatee, [Animation.sfx, "remembertimecrystal"])
				# unlock the most recently locked move.
				var unlocked_move = light_locked_turns.pop_back();
				var unlocked_move_being_filled_this_turn = false;
				var filling_turn_actual_set = false;
				# if we were in the middle of filling it, mark that we're now filling a normal move again.
				if (light_filling_locked_turn_index == light_locked_turns.size()):
					unlocked_move_being_filled_this_turn = true;
					add_undo_event([Undo.light_filling_locked_turn_index, light_filling_locked_turn_index, -1], Chrono.CHAR_UNDO);
					light_filling_locked_turn_index = -1;
				# elif we were filling a move and just unlocked a new move on top of it, mark that fact.
				elif (!heavy_selected and chrono == Chrono.MOVE and light_filling_locked_turn_index == -1 and light_filling_turn_actual == -1):
					light_filling_turn_actual = light_turn;
					filling_turn_actual_set = true;
					add_undo_event([Undo.light_filling_turn_actual, -1, light_filling_turn_actual], Chrono.CHAR_UNDO);
				
				# did we just pop an empty locked move?
				if (unlocked_move.size() == 0 and !unlocked_move_being_filled_this_turn):
					add_undo_event([Undo.light_turn_unlocked, -1, light_locked_turns.size()], Chrono.CHAR_UNDO);
					add_to_animation_server(eater, [Animation.light_green_time_crystal_unlock, eatee, -1]);
					set_actor_var(eater, "powered", true, Chrono.CHAR_UNDO);
				# or a locked move with contents?
				else:
					# maybe character hasn't created any events this turn yet
					while (light_undo_buffer.size() <= light_turn):
						light_undo_buffer.append([]);
					# if we're filling a move, we put the unlocked time crystal AFTER the filled move.
					if (filling_turn_actual_set):
						light_turn += 1;
						add_undo_event([Undo.light_turn_direct, 1], Chrono.CHAR_UNDO);
					light_undo_buffer.insert(light_turn, unlocked_move);
					add_undo_event([Undo.light_turn_unlocked, light_turn, light_locked_turns.size()], Chrono.CHAR_UNDO);
					if (!filling_turn_actual_set):
						light_turn += 1;
						add_undo_event([Undo.light_turn_direct, 1], Chrono.CHAR_UNDO);
					add_to_animation_server(eater, [Animation.light_green_time_crystal_unlock, eatee, light_turn]);
		else: #cuckoo clock
			clock_ticks(eater, 1, Chrono.CHAR_UNDO);
			add_to_animation_server(eater, [Animation.generic_green_time_crystal, eatee]);
	else: # magenta time crystal
		add_to_animation_server(eatee, [Animation.sfx, "magentatimecrystal"])
		var just_locked = false;
		var turn_moved = -1;
		if (heavy_actor == eater):
			# Lose (Paradox)
			if (heavy_max_moves <= 0):
				add_to_animation_server(eater, [Animation.heavy_magenta_time_crystal, eatee, -99]);
				lose("Paradox: A character can't have less than 0 moves.", heavy_actor)
				return;
			# accessible timeline is now one move shorter.
			heavy_max_moves -= 1;
			add_undo_event([Undo.heavy_max_moves, -1], Chrono.CHAR_UNDO);
			if (heavy_selected and chrono == Chrono.MOVE and heavy_filling_locked_turn_index == -1 and (heavy_filling_turn_actual == -1 or heavy_filling_turn_actual == heavy_turn)):
				# if we're moving and the turn buffer we're filling up isn't locked, then we need to move that one
				# but continue to fill it up (so mark a variable)
				just_locked = true;
				heavy_filling_locked_turn_index = heavy_locked_turns.size();
				add_undo_event([Undo.heavy_filling_locked_turn_index, -1, heavy_filling_locked_turn_index], Chrono.CHAR_UNDO);
				if (heavy_filling_turn_actual != -1):
					add_undo_event([Undo.heavy_filling_turn_actual, heavy_filling_turn_actual, -1], Chrono.CHAR_UNDO);
			if (heavy_turn > 0 or just_locked or (heavy_filling_locked_turn_index > -1 and heavy_turn > -1)):
				# if we have a slot to move: move it and decrement turn
				turn_moved = heavy_turn;
				# the case of picking up a second magenta crystal in a row on your turn
				# I thought it'd need an adjustment, but it seems to not.
				if (!just_locked and heavy_filling_locked_turn_index > -1):
					pass
				# haven't 100% convinced me of this but seems to be true - if it's not our turn, we actually want to move the turn one lower
				# (e.g. if light_turn is 2, we're creating [2] if it's light's turn, but [1] is what we'd lock next if it's heavy's turn)
				# the spaghetti continues: we also want to -1 if it is our turn and we're undoing
				if (!heavy_selected or chrono == Chrono.CHAR_UNDO):
					turn_moved -= 1;
				# maybe character hasn't created any events this turn yet
				while (heavy_undo_buffer.size() <= turn_moved):
					heavy_undo_buffer.append([]);
				var turn_buffer = heavy_undo_buffer.pop_at(turn_moved);
				heavy_locked_turns.append(turn_buffer);
				add_undo_event([Undo.heavy_turn_locked, turn_moved, heavy_locked_turns.size() - 1], Chrono.CHAR_UNDO);
				heavy_turn -= 1;
				add_undo_event([Undo.heavy_turn_direct, -1], Chrono.CHAR_UNDO);
			else:
				# if we don't have a slot to move: just lock an empty slot
				heavy_locked_turns.append([]);
				add_undo_event([Undo.heavy_turn_locked, -1, heavy_locked_turns.size() - 1], Chrono.CHAR_UNDO);
			# only way eating a magenta time crystal can depower you is if you go to 0 moves,
			#since it always locks a filled turn first.
			if (heavy_max_moves <= 0):
				set_actor_var(heavy_actor, "powered", false, Chrono.CHAR_UNDO);
			
			# animation
			add_to_animation_server(eater, [Animation.heavy_magenta_time_crystal, eatee, turn_moved]);
			
		elif (light_actor == eater):
			# Lose (Paradox)
			if (light_max_moves <= 0):
				add_to_animation_server(eater, [Animation.light_magenta_time_crystal, eatee, -99]);
				lose("Paradox: A character can't have less than 0 moves.", light_actor)
				return;
			# accessible timeline is now one move shorter.
			light_max_moves -= 1;
			add_undo_event([Undo.light_max_moves, -1], Chrono.CHAR_UNDO);
			if (!heavy_selected and chrono == Chrono.MOVE and light_filling_locked_turn_index == -1 and (light_filling_turn_actual == -1 or light_filling_turn_actual == light_turn)):
				# if we're moving and the turn buffer we're filling up isn't locked, then we need to move that one
				# but continue to fill it up (so mark a variable)
				just_locked = true;
				light_filling_locked_turn_index = light_locked_turns.size();
				add_undo_event([Undo.light_filling_locked_turn_index, -1, light_filling_locked_turn_index], Chrono.CHAR_UNDO);
				if (light_filling_turn_actual != -1):
					add_undo_event([Undo.light_filling_turn_actual, light_filling_turn_actual, -1], Chrono.CHAR_UNDO);
			if (light_turn > 0 or just_locked or (light_filling_locked_turn_index > -1 and light_turn > -1)):
				# if we have a slot to move: move it and decrement turn
				turn_moved = light_turn;
				# the case of picking up a second magenta crystal in a row on your turn
				# I thought it'd need an adjustment, but it seems to not.
				if (!just_locked and light_filling_locked_turn_index > -1):
					pass
				# haven't 100% convinced me of this but seems to be true - if it's not our turn, we actually want to move the turn one lower
				# (e.g. if light_turn is 2, we're creating [2] if it's light's turn, but [1] is what we'd lock next if it's heavy's turn)
				# the spaghetti continues: we also want to -1 if it is our turn and we're undoing
				if (heavy_selected or chrono == Chrono.CHAR_UNDO):
					turn_moved -= 1;
				# maybe character hasn't created any events this turn yet
				while (light_undo_buffer.size() <= turn_moved):
					light_undo_buffer.append([]);
				var turn_buffer = light_undo_buffer.pop_at(turn_moved);
				light_locked_turns.append(turn_buffer);
				add_undo_event([Undo.light_turn_locked, turn_moved, light_locked_turns.size() - 1], Chrono.CHAR_UNDO);
				light_turn -= 1;
				add_undo_event([Undo.light_turn_direct, -1], Chrono.CHAR_UNDO);
			else:
				# if we don't have a slot to move: just lock an empty slot
				light_locked_turns.append([]);
				add_undo_event([Undo.light_turn_locked, -1, light_locked_turns.size() - 1], Chrono.CHAR_UNDO);
			# only way eating a magenta time crystal can depower you is if you go to 0 moves,
			#since it always locks a filled turn first.
			if (light_max_moves <= 0):
				set_actor_var(light_actor, "powered", false, Chrono.CHAR_UNDO);
			
			# animation
			add_to_animation_server(eater, [Animation.light_magenta_time_crystal, eatee, turn_moved]);
		else: #cuckoo clock
			clock_ticks(eater, -1, Chrono.CHAR_UNDO);
			add_to_animation_server(eater, [Animation.generic_magenta_time_crystal, eatee]);

func clock_ticks(actor: ActorBase, amount: int, chrono: int, animation_nonce: int = -1) -> void:
	if (animation_nonce == -1):
		animation_nonce = animation_nonce_fountain_dispense();
	actor.update_ticks(actor.ticks + amount);
	if (actor.ticks == 0):
		if actor.actorname == Actor.Name.CuckooClock:
			# end the world
			lose("You didn't make it back to the Chrono Lab Reactor in time.", actor);
	add_undo_event([Undo.tick, actor, amount, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
	add_to_animation_server(actor, [Animation.tick, amount, actor.ticks, animation_nonce]);

func lose(reason: String, suspect: Actor) -> void:
	lost = true;
	if (suspect != null and suspect.time_colour == TimeColour.Void):
		lost_void = true;
		winlabel.change_text(reason + "\n\nRestart to continue.")
	else:
		lost_void = false;
		winlabel.change_text(reason + "\n\nMeta-Undo or Restart to continue.")
	
func end_lose() -> void:
	lost = false;
	lost_speaker.stop();

func set_actor_var(actor: ActorBase, prop: String, value, chrono: int,
animation_nonce: int = -1, is_retro: bool = false, _retro_old_value = null) -> void:
	var old_value = actor.get(prop);
	if animation_nonce == -1:
		animation_nonce = animation_nonce_fountain_dispense();
	if (chrono < Chrono.GHOSTS):
		actor.set(prop, value);
		
		# going to try this to fix a dinged bug - don't make undo events for dinged, since it's purely visual
		if (prop != "dinged"):
			# and now to fix some airborne bugs, all revolving around 2:
			# if you go to 2, emit an event to 1 instead.
			#If you go from 2 to 1, ignore it.
			#If you go from 2 to anything else, pretend you came from 1.
			
			if (prop == "airborne"):
				if (value == 2):
					value = 1;
					add_undo_event([Undo.set_actor_var, actor, prop, old_value, value, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
				elif (value == 1 and old_value == 2):
					pass
				elif (old_value == 2):
					old_value = 1;
					add_undo_event([Undo.set_actor_var, actor, prop, old_value, value, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
				else:
					add_undo_event([Undo.set_actor_var, actor, prop, old_value, value, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
			else:
				add_undo_event([Undo.set_actor_var, actor, prop, old_value, value, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
		
		# sound effects for airborne changes
		if (prop == "airborne"):
			if actor.actorname == Actor.Name.Heavy:
				if is_retro:
					if old_value >= 1 and value <= 0:
						add_to_animation_server(actor, [Animation.sfx, "heavyuncoyote"]);
					elif old_value == -1 and value != -1:
						add_to_animation_server(actor, [Animation.sfx, "heavyunland"]);
				else:
					if value >= 1 and old_value <= 0:
						add_to_animation_server(actor, [Animation.sfx, "heavycoyote"]);
					elif value == -1 and old_value != -1:
						add_to_animation_server(actor, [Animation.sfx, "heavyland"]);
			elif actor.actorname == Actor.Name.Light:
				if is_retro:
					if old_value >= 1 and value <= 0:
						add_to_animation_server(actor, [Animation.sfx, "lightuncoyote"]);
					elif old_value == -1 and value != -1:
						add_to_animation_server(actor, [Animation.sfx, "lightunland"]);
				else:
					if value >= 1 and old_value <= 0:
						add_to_animation_server(actor, [Animation.sfx, "lightcoyote"]);
					elif value == -1 and old_value != -1:
						add_to_animation_server(actor, [Animation.sfx, "lightland"]);
		
		# special case - if we break or unbreak, we can ding or unding too
		# We also need to handle abysschime and meta-undoing it.
		# (I'll write that logic separately just so it's not a giant mess, the performance hit is miniscule.)
		if prop == "broken":
			if actor.is_character:
				if value:
					if (!actor_has_broken_event_anywhere(actor)):
						add_to_animation_server(actor, [Animation.lose]);
				else:
					if actor.actorname == Actor.Name.Heavy:
						heavytimeline.end_fade();
					else:
						lighttimeline.end_fade();
			
			#check goal lock when a crystal breaks or unbreaks
			if (actor.is_crystal):
				update_goal_lock();
			
			var terrain = terrain_in_tile(actor.pos);
			if value == true:
				if (actor.actorname == Actor.Name.TimeCrystalGreen):
					pass #done in eat_crystal now
					#add_to_animation_server(actor, [Animation.sfx, "greentimecrystal"])
				elif (actor.actorname == Actor.Name.TimeCrystalMagenta):
					pass #done in eat_crystal now
					#add_to_animation_server(actor, [Animation.sfx, "magentatimecrystal"])
				else:
					add_to_animation_server(actor, [Animation.sfx, "broken"])
					add_to_animation_server(actor, [Animation.explode])
				if actor.is_character:
					if actor.actorname == Actor.Name.Heavy and heavy_goal_here(actor.pos, terrain):
						for goal in goals:
							if goal.actorname == Actor.Name.HeavyGoal and goal.dinged:
								set_actor_var(goal, "dinged", false, chrono);
					if actor.actorname == Actor.Name.Light and light_goal_here(actor.pos, terrain):
						for goal in goals:
							if goal.actorname == Actor.Name.LightGoal and goal.dinged:
								set_actor_var(goal, "dinged", false, chrono);
				else:
					if actor.dinged:
						set_actor_var(actor, "dinged", false, chrono);
			else:
				add_to_animation_server(actor, [Animation.sfx, "unbroken"])
				if actor.is_character:
					if actor.actorname == Actor.Name.Heavy and heavy_goal_here(actor.pos, terrain):
						for goal in goals:
							if goal.actorname == Actor.Name.HeavyGoal and !goal.dinged:
								set_actor_var(goal, "dinged", true, chrono);
					if actor.actorname == Actor.Name.Light and light_goal_here(actor.pos, terrain):
						for goal in goals:
							if goal.actorname == Actor.Name.LightGoal and !goal.dinged:
								set_actor_var(goal, "dinged", true, chrono);
				else:
					if terrain.has(Tiles.CrateGoal):
						if !actor.dinged:
							set_actor_var(actor, "dinged", true, chrono);
		
		add_to_animation_server(actor, [Animation.set_next_texture, actor.get_next_texture(), animation_nonce, actor.facing_left])
	elif actor is Actor:
		var ghost = null;
		if (prop == "facing_left"):
			# turning facing direction is always the first thing you do, so there'll never be a ghost after this
			# that we'll need to pass on the facing direction to, so just skip it
			pass
			#ghost = get_ghost(actor);
		else:
			ghost = get_ghost_that_hasnt_moved(actor);
			ghost.set(prop, value);
			ghost.update_graphics();

func actor_has_broken_event_anywhere(actor: Actor) -> bool:
	# not edge cases: chrono, actor colour (since we always check)
	# yes edge cases: could be a locked turn or a fuzz doubled turn
	#this code looks HILARIOUS but I swear it is legitimately the best way to write it
	#Undo.set_actor_var, actor, prop, old_value, value,
	var buffers = [heavy_undo_buffer, light_undo_buffer, heavy_locked_turns, light_locked_turns];
	for buffer in buffers:
		for turn in buffer:
			for event in turn:
				if event[0] == Undo.set_actor_var:
					if event[1] == actor:
						if event[2] == "broken":
							if event[3] == false:
								if event[4] == true:
									return true;
	return false

func add_undo_event(event: Array, chrono: int = Chrono.MOVE) -> void:
	#if (debug_prints and chrono < Chrono.META_UNDO):
	#	print("add_undo_event", " ", event, " ", chrono);
	if chrono == Chrono.MOVE:
		if (heavy_selected):
			while (heavy_undo_buffer.size() <= heavy_turn):
				heavy_undo_buffer.append([]);
			if (heavy_filling_locked_turn_index > -1):
				heavy_locked_turns[heavy_filling_locked_turn_index].push_front(event);
				add_undo_event([Undo.heavy_undo_event_add_locked, heavy_filling_locked_turn_index], Chrono.CHAR_UNDO)
			elif (heavy_filling_turn_actual > -1):
				heavy_undo_buffer[heavy_filling_turn_actual].push_front(event);
				add_undo_event([Undo.heavy_undo_event_add, heavy_filling_turn_actual], Chrono.CHAR_UNDO);
			else:
				heavy_undo_buffer[heavy_turn].push_front(event);
				add_undo_event([Undo.heavy_undo_event_add, heavy_turn], Chrono.CHAR_UNDO);
		else:
			while (light_undo_buffer.size() <= light_turn):
				light_undo_buffer.append([]);
			if (light_filling_locked_turn_index > -1):
				light_locked_turns[light_filling_locked_turn_index].push_front(event);
				add_undo_event([Undo.light_undo_event_add_locked, light_filling_locked_turn_index], Chrono.CHAR_UNDO)
			elif (light_filling_turn_actual > -1):
				light_undo_buffer[light_filling_turn_actual].push_front(event);
				add_undo_event([Undo.light_undo_event_add, light_filling_turn_actual], Chrono.CHAR_UNDO);
			else:
				light_undo_buffer[light_turn].push_front(event);
				add_undo_event([Undo.light_undo_event_add, light_turn], Chrono.CHAR_UNDO);
	
	if (chrono == Chrono.MOVE || chrono == Chrono.CHAR_UNDO):
		while (meta_undo_buffer.size() <= meta_turn):
			meta_undo_buffer.append([]);
		meta_undo_buffer[meta_turn].push_front(event);

func append_replay(move: String) -> void:
	if (move == "x"):
		if user_replay.ends_with("x"):
			user_replay = user_replay.left(user_replay.length() - 1);
		else:
			user_replay += move;
	else:
		user_replay += move;
	
func meta_undo_replay() -> bool:
	if (voidlike_puzzle):
		user_replay += "c";
	else:
		if !user_replay.ends_with("x"):
			user_replay = user_replay.left(user_replay.length() - 1);
		else:
			user_replay = user_replay.left(user_replay.length() - 2);
			append_replay("x");
	return true;

func character_undo(is_silent: bool = false) -> bool:
	if (won or lost): return false;
	finish_animations(Chrono.CHAR_UNDO);
	var fuzzed = false;
	if (heavy_selected):
		
		# check if we can undo
		var terrain = terrain_in_tile(heavy_actor.pos);
		if (heavy_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		if (terrain.has(Tiles.NoUndo) and !terrain.has(Tiles.OneUndo)):
			if !is_silent:
				play_sound("bump");
			add_to_animation_server(heavy_actor, [Animation.afterimage_at, terrainmap.tile_set.tile_get_texture(Tiles.NoUndo), terrainmap.map_to_world(heavy_actor.pos), Color(0, 0, 0, 1)]);
			return false;
		
		# before undo effects
		
		if (terrain.has(Tiles.OneUndo)):
			maybe_change_terrain(heavy_actor, heavy_actor.pos, terrain.find(Tiles.OneUndo), false, true, Chrono.CHAR_UNDO, Tiles.NoUndo);
		
		#the undo itself
		
		if (terrain.has(Tiles.Fuzz)):
			fuzzed = true;
			fuzz_timer = 0;
			fuzz_timer_max = 1.5;
			maybe_change_terrain(heavy_actor, heavy_actor.pos, terrain.find(Tiles.Fuzz), false, true, Chrono.CHAR_UNDO, -1);
			heavytimeline.fuzz_activate();
			var events = heavy_undo_buffer[heavy_turn - 1];
			for event in events:
				if event[0] == Undo.heavy_turn or event[0] == Undo.light_turn:
					continue
				if (event[0] == Undo.set_actor_var and event[2] == "powered"):
					continue
				undo_one_event(event, Chrono.CHAR_UNDO);
		else:
			var events = heavy_undo_buffer.pop_at(heavy_turn - 1);
			for event in events:
				undo_one_event(event, Chrono.CHAR_UNDO);
				add_undo_event([Undo.heavy_undo_event_remove, heavy_turn, event], Chrono.CHAR_UNDO);
			time_passes(Chrono.CHAR_UNDO);
		
		append_replay("z");
		adjust_meta_turn(1);
		if (!is_silent):
			play_sound("undostrong");
			if (fuzzed):
				undo_effect_strength = 0.25;
				undo_effect_per_second = undo_effect_strength*(1/0.5);
				undo_effect_color = meta_color;
			else:
				undo_effect_strength = 0.12; #yes stronger on purpose. it doesn't show up as well.
				undo_effect_per_second = undo_effect_strength*(1/0.4);
				undo_effect_color = heavy_color;
		return true;
	else:
		
		# check if we can undo
		var terrain = terrain_in_tile(light_actor.pos);
		if (light_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		if (terrain.has(Tiles.NoUndo) and !terrain.has(Tiles.OneUndo)):
			if !is_silent:
				play_sound("bump");
			add_to_animation_server(light_actor, [Animation.afterimage_at, terrainmap.tile_set.tile_get_texture(Tiles.NoUndo), terrainmap.map_to_world(light_actor.pos), Color(0, 0, 0, 1)]);
			return false;
			
		# before undo effects
		
		if (terrain.has(Tiles.OneUndo)):
			maybe_change_terrain(light_actor, light_actor.pos, terrain.find(Tiles.OneUndo), false, true, Chrono.CHAR_UNDO, Tiles.NoUndo);
		
		#the undo itself
		
		if (terrain.has(Tiles.Fuzz)):
			fuzzed = true;
			fuzz_timer = 0;
			fuzz_timer_max = 1.5;
			maybe_change_terrain(light_actor, light_actor.pos, terrain.find(Tiles.Fuzz), false, true, Chrono.CHAR_UNDO, -1);
			lighttimeline.fuzz_activate();
			var events = light_undo_buffer[light_turn - 1];
			for event in events:
				if event[0] == Undo.heavy_turn or event[0] == Undo.light_turn:
					continue
				if (event[0] == Undo.set_actor_var and event[2] == "powered"):
					continue
				undo_one_event(event, Chrono.CHAR_UNDO);
		else:
			var events = light_undo_buffer.pop_at(light_turn - 1);
			for event in events:
				undo_one_event(event, Chrono.CHAR_UNDO);
				add_undo_event([Undo.light_undo_event_remove, light_turn, event], Chrono.CHAR_UNDO);
			time_passes(Chrono.CHAR_UNDO);
			
		append_replay("z");
		adjust_meta_turn(1);
		if (!is_silent):
			if (fuzzed):
				undo_effect_strength = 0.25;
				undo_effect_per_second = undo_effect_strength*(1/0.5);
				undo_effect_color = meta_color;
			else:
				play_sound("undostrong");
				undo_effect_strength = 0.08;
				undo_effect_per_second = undo_effect_strength*(1/0.4);
				undo_effect_color = light_color;
		return true;

func make_ghost_here_with_texture(pos: Vector2, texture: Texture) -> Actor:
	# TODO: another poor refactor but
	var ghost = Actor.new();
	ghost.gamelogic = self;
	ghost.is_ghost = true;
	ghost.ghost_alpha = save_file["undo_trails"];
	ghost.modulate = Color(1, 1, 1, 0);
	ghosts.append(ghost);
	ghostsfolder.add_child(ghost);
	ghost.texture = texture;
	ghost.pos = pos;
	ghost.position = terrainmap.map_to_world(ghost.pos);
	# TODO: hardcoded but it's correct for tiles
	ghost.offset = Vector2(12, 12)
	return ghost;

func get_ghost(actor: Actor) -> Actor:
	while actor.next_ghost != null:
		actor = actor.next_ghost;
	if (actor.is_ghost):
		return actor;
	return make_ghost_for(actor);

func get_ghost_that_hasnt_moved(actor : Actor) -> Actor:
	while actor.next_ghost != null:
		actor = actor.next_ghost;
	if (actor.is_ghost and actor.ghost_dir == Vector2.ZERO):
		return actor;
	return make_ghost_for(actor);
	
func make_ghost_for(actor: Actor) -> Actor:
	var ghost = clone_actor_but_dont_add_it(actor);
	ghost.is_ghost = true;
	ghost.ghost_alpha = save_file["undo_trails"];
	ghost.modulate = Color(1, 1, 1, 0);
	actor.next_ghost = ghost;
	ghost.previous_ghost = actor;
	ghost.ghost_index = actor.ghost_index + 1;
	ghosts.append(ghost);
	ghostsfolder.add_child(ghost);
	ghost.update_graphics();
	return ghost;
	
func clone_actor_but_dont_add_it(actor : Actor) -> Actor:
	# TODO: poorly refactored with make_actor
	var new = Actor.new();
	new.gamelogic = self;
	new.actorname = actor.actorname;
	new.texture = actor.texture;
	new.offset = actor.offset;
	new.position = terrainmap.map_to_world(actor.pos);
	new.pos = actor.pos;
	#new.state = actor.state.duplicate();
	new.broken = actor.broken;
	new.powered = actor.powered;
	new.airborne = actor.airborne;
	new.strength = actor.strength;
	new.heaviness = actor.heaviness;
	new.durability = actor.durability;
	new.fall_speed = actor.fall_speed;
	new.climbs = actor.climbs;
	new.is_character = actor.is_character;
	new.facing_left = actor.facing_left;
	new.flip_h = actor.flip_h;
	new.frame_timer = actor.frame_timer;
	new.frame_timer_max = actor.frame_timer_max;
	new.hframes = actor.hframes;
	new.frame = actor.frame;
	new.post_mortem = actor.post_mortem;
	return new;

func finish_animations(chrono: int) -> void:
	undo_effect_color = Color.transparent;
	
	if (chrono >= Chrono.META_UNDO):
		for actor in actors:
			actor.animation_timer = 0;
			actor.animations.clear();
	else:
		# new logic instead of clearing animations - run animations over and over until we're done
		# this should get rid of all bugs of the form 'if an animation is skipped over some side effect never completes' 5ever
		while true:
			update_animation_server(true);
			for actor in actors:
				while (actor.animations.size() > 0):
					actor.animation_timer = 99;
					actor._process(0);
				actor.animation_timer = 0;
			if animation_server.size() <= 0:
				break;
			
	for actor in actors:
		actor.position = terrainmap.map_to_world(actor.pos);
		actor.update_graphics();
	for goal in goals:
		goal.animations.clear();
		goal.update_graphics();
	animation_server.clear();
	animation_substep = 0;
	heavytimeline.finish_animations();
	lighttimeline.finish_animations();

func update_ghosts() -> void:
	for ghost in ghosts:
		ghost.queue_free();
	ghosts.clear();
	for actor in actors:
		actor.next_ghost = null;
	# overlaps with character_undo a lot, but I'll try to limit the damage
	if (heavy_selected):
		if (heavy_turn <= 0):
			return;
		var events = heavy_undo_buffer[heavy_turn - 1];
		for event in events:
			undo_one_event(event, Chrono.GHOSTS);
	else:
		if (light_turn <= 0):
			return;
		var events = light_undo_buffer[light_turn - 1];
		for event in events:
			undo_one_event(event, Chrono.GHOSTS);
	
func adjust_meta_turn(amount: int) -> void:
	#check ongoing 'magenta crystaled the current move' and clear:
	if (light_filling_locked_turn_index > -1):
		add_undo_event([Undo.light_filling_locked_turn_index, light_filling_locked_turn_index, -1], Chrono.CHAR_UNDO);
		light_filling_locked_turn_index = -1;
	if (heavy_filling_locked_turn_index > -1):
		add_undo_event([Undo.heavy_filling_locked_turn_index, heavy_filling_locked_turn_index, -1], Chrono.CHAR_UNDO);
		heavy_filling_locked_turn_index = -1;
	#and unlock:
	if (light_filling_turn_actual > -1):
		add_undo_event([Undo.light_filling_turn_actual, light_filling_turn_actual, -1], Chrono.CHAR_UNDO);
		light_filling_turn_actual = -1;
	if (heavy_filling_turn_actual > -1):
		add_undo_event([Undo.heavy_filling_turn_actual, heavy_filling_turn_actual, -1], Chrono.CHAR_UNDO);
		heavy_filling_turn_actual = -1;
	
	meta_turn += amount;
	#if (debug_prints):
	#	print("=== IT IS NOW META TURN " + str(meta_turn) + " ===");
	update_ghosts();
	check_won();
	
func check_won() -> void:
	won = false;
	var locked = false;
	
	if (lost):
		return
	Shade.on = false;
	
	#check goal lock:
	for goal in goals:
		if goal.locked:
			locked = true;
			won = false;
			break;
	
	if (!locked and !light_actor.broken and !heavy_actor.broken
	and heavy_goal_here(heavy_actor.pos, terrain_in_tile(heavy_actor.pos))
	and light_goal_here(light_actor.pos, terrain_in_tile(light_actor.pos))) or nonstandard_won:
		won = true;
		# but wait!
		# check for crate goals as well (crate must be non-broken)
		# PERF: if this ends up being slow, I can cache it on level load since it won't ever change. but it seems fast enough?
		var crate_goals = get_used_cells_by_id_one_array(Tiles.CrateGoal);
		# would fix this O(n^2) with an actors_by_pos dictionary, but then I have to update it all the time.
		# maybe use DINGED?
		for crate_goal in crate_goals:
			var crate_goal_satisfied = false;
			for actor in actors:
				if !actor.broken and actor.pos == crate_goal:
					crate_goal_satisfied = true;
					break;
			if (!crate_goal_satisfied):
				won = false;
				break;
		if (won and test_mode):
			var level_info = terrainmap.get_node_or_null("LevelInfo");
			if (level_info != null):
				level_info.level_replay = annotate_replay(user_replay);
				floating_text("Test successful, recorded replay!");
		if (won == true and !doing_replay):
			if (level_name == "Joke"):
				play_won("winbadtime");
			else:
				play_won("winentwined");
			var levels_save_data = save_file["levels"];
			if (!levels_save_data.has(level_name)):
				levels_save_data[level_name] = {};
			var level_save_data = levels_save_data[level_name];
			if (level_save_data.has("won") and level_save_data["won"]):
				pass
			else:
				level_save_data["won"] = true;
				levelstar.previous_modulate = Color(1, 1, 1, 0);
				levelstar.flash();
				if (!in_insight_level and !is_custom):
					puzzles_completed += 1;
			if (!level_save_data.has("replay")):
				level_save_data["replay"] = annotate_replay(user_replay);
			else:
				var old_replay = level_save_data["replay"];
				var old_replay_parts = old_replay.split("$");
				var old_replay_data = old_replay_parts[old_replay_parts.size()-2];
				var old_replay_mturn_parts = old_replay_data.split("=");
				var old_replay_mturn = int(old_replay_mturn_parts[1]);
				if (old_replay_mturn > meta_turn):
					level_save_data["replay"] = annotate_replay(user_replay);
				elif (old_replay_mturn == meta_turn):
					# same meta-turn but shorter replay also wins
					var old_replay_payload = old_replay_parts[old_replay_parts.size()-1];
					if (len(user_replay) <= len(old_replay_payload)):
						level_save_data["replay"] = annotate_replay(user_replay);
			update_level_label();
			save_game();
	
	winlabel.visible = won;
	virtualbuttons.get_node("Others/EnterButton").visible = won and virtualbuttons.visible;
	virtualbuttons.get_node("Others/EnterButton").disabled = !won or !virtualbuttons.visible;
	if (won):
		won_cooldown = 0;
		if (level_name == "Joke"):
			winlabel.change_text("Thanks for playing :3")
		elif !using_controller and !doing_replay:
			winlabel.change_text("You have won!\n\n[Enter]: Continue\nWatch Replay: Menu -> Your Replay")
		elif !using_controller and doing_replay:
			winlabel.change_text("You have won!\n\n[Enter]: Continue")
		elif using_controller and !doing_replay:
			winlabel.change_text("You have won!\n\n[Bottom Face Button]: Continue\nWatch Replay: Menu -> Your Replay")
		else:
			winlabel.change_text("You have won!\n\n[Bottom Face Button]: Continue")
		won_fade_started = false;
		tutoriallabel.visible = false;
		call_deferred("adjust_winlabel_deferred");
	elif won_fade_started:
		won_fade_started = false;
		heavy_actor.modulate.a = 1;
		light_actor.modulate.a = 1;
	
func adjust_winlabel_deferred() -> void:
	call_deferred("adjust_winlabel");
	
func adjust_winlabel() -> void:
	var winlabel_rect_size = winlabel.get_rect_size();
	winlabel.set_rect_position(Vector2(pixel_width/2 - int(floor(winlabel_rect_size.x/2)), win_label_default_y));
	var tries = 1;
	var heavy_actor_rect = heavy_actor.get_rect();
	var light_actor_rect = light_actor.get_rect();
	var label_rect = Rect2(winlabel.get_rect_position(), winlabel_rect_size);
	heavy_actor_rect.position = terrainmap.map_to_world(heavy_actor.pos) + terrainmap.global_position;
	light_actor_rect.position = terrainmap.map_to_world(light_actor.pos) + terrainmap.global_position;
	while (tries < 99):
		if heavy_actor_rect.intersects(label_rect) or light_actor_rect.intersects(label_rect):
			var polarity = 1;
			if (tries % 2 == 0):
				polarity = -1;
			winlabel.set_rect_position(Vector2(winlabel.get_rect_position().x, winlabel.get_rect_position().y + 8*tries*polarity));
			label_rect.position.y += 8*tries*polarity;
		else:
			break;
		tries += 1;
	
func undo_one_event(event: Array, chrono : int) -> void:
	#if (debug_prints):
	#	print("undo_one_event", " ", event, " ", chrono);
		
	# undo events that should create undo trails
		
	if (event[0] == Undo.move):
		#[Undo.move, actor, dir, was_push, was_fall]
		#func move_actor_relative(actor: Actor, dir: Vector2, chrono: int,
		#hypothetical: bool, is_gravity: bool, is_retro: bool = false,
		#pushers_list: Array = [], was_fall = false, was_push = false, phased_out_of: Array = null) -> int:
		var actor = event[1];
		var animation_nonce = event[6];
		if (chrono < Chrono.META_UNDO and actor.in_stars):
			add_to_animation_server(actor, [Animation.undo_immunity, event[6]]);
		else:
			move_actor_relative(actor, -event[2], chrono, false, false, true, [], event[3], event[4], event[5],
			animation_nonce);
	elif (event[0] == Undo.set_actor_var):
		var actor = event[1];
		var retro_old_value = event[4];
		var animation_nonce = event[5];
		var is_retro = true;
		if (chrono < Chrono.META_UNDO and actor.in_stars):
			add_to_animation_server(actor, [Animation.undo_immunity, animation_nonce]);
		else:
			#[Undo.set_actor_var, actor, prop, old_value, value, animation_nonce]
			
			set_actor_var(actor, event[2], event[3], chrono, animation_nonce, is_retro, retro_old_value);
	elif (event[0] == Undo.change_terrain):
		var actor = event[1];
		var pos = event[2];
		var layer = event[3];
		var old_tile = event[4];
		var new_tile = event[5];
		var animation_nonce = event[6];
		maybe_change_terrain(actor, pos, layer, false, false, chrono, old_tile, new_tile, animation_nonce);
		
	# undo events that should not
		
	if (chrono >= Chrono.GHOSTS):
		return;
		
	elif (event[0] == Undo.heavy_turn):
		adjust_turn(true, -event[1], chrono);
	elif (event[0] == Undo.light_turn):
		adjust_turn(false, -event[1], chrono);
	elif (event[0] == Undo.heavy_turn_direct):
		heavy_turn -= event[1];
	elif (event[0] == Undo.light_turn_direct):
		light_turn -= event[1];
	elif (event[0] == Undo.heavy_undo_event_add):
		while (heavy_undo_buffer.size() <= event[1]):
			heavy_undo_buffer.append([]);
		heavy_undo_buffer[event[1]].pop_front();
	elif (event[0] == Undo.light_undo_event_add):
		while (light_undo_buffer.size() <= event[1]):
			light_undo_buffer.append([]);
		light_undo_buffer[event[1]].pop_front();
	elif (event[0] == Undo.heavy_undo_event_add_locked):
		while (heavy_undo_buffer.size() <= event[1]):
			heavy_undo_buffer.append([]);
		heavy_locked_turns[event[1]].pop_front();
	elif (event[0] == Undo.light_undo_event_add_locked):
		while (light_undo_buffer.size() <= event[1]):
			light_undo_buffer.append([]);
		light_locked_turns[event[1]].pop_front();
	elif (event[0] == Undo.heavy_undo_event_remove):
		# meta undo an undo creates a char undo event but not a meta undo event, it's special!
		while (heavy_undo_buffer.size() <= event[1]):
			heavy_undo_buffer.append([]);
		heavy_undo_buffer[event[1]].push_front(event[2]);
	elif (event[0] == Undo.light_undo_event_remove):
		while (light_undo_buffer.size() <= event[1]):
			light_undo_buffer.append([]);
		light_undo_buffer[event[1]].push_front(event[2]);
	elif (event[0] == Undo.animation_substep):
		# don't need to emit a new event as meta undoing and beyond is a teleport
		animation_substep += 1;
	elif (event[0] == Undo.heavy_green_time_crystal_raw):
		# don't need to emit a new event as this can't be char undone
		# (comment repeats for all other time crystal stuff)
		heavy_max_moves -= 1;
		heavytimeline.undo_add_max_turn();
		timeline_squish();
	elif (event[0] == Undo.light_green_time_crystal_raw):
		light_max_moves -= 1;
		lighttimeline.undo_add_max_turn();
		timeline_squish();
	elif (event[0] == Undo.heavy_max_moves):
		heavy_max_moves -= event[1];
		heavytimeline.undo_lock_turn();
	elif (event[0] == Undo.light_max_moves):
		light_max_moves -= event[1];
		lighttimeline.undo_lock_turn();
	elif (event[0] == Undo.heavy_filling_locked_turn_index):
		heavy_filling_locked_turn_index = event[1]; #the old value, event[2] is the new value
	elif (event[0] == Undo.light_filling_locked_turn_index):
		light_filling_locked_turn_index = event[1]; #the old value, event[2] is the new value
	elif (event[0] == Undo.heavy_turn_locked):
		# don't have to do turn adjustment as a separate undo event was emitted for it
		var locked_turn = heavy_locked_turns.pop_at(event[2]);
		# put it back if we locked an actual turn
		if event[1] == -1:
			pass
		else:
			heavy_undo_buffer.insert(event[1], locked_turn);
	elif (event[0] == Undo.light_turn_locked):
		# don't have to do turn adjustment as a separate undo event was emitted for it
		var locked_turn = light_locked_turns.pop_at(event[2]);
		# put it back if we locked an actual turn
		if event[1] == -1:
			pass
		else:
			light_undo_buffer.insert(event[1], locked_turn);
	elif (event[0] == Undo.heavy_filling_turn_actual):
		heavy_filling_turn_actual = event[1]; #the old value, event[2] is the new value
	elif (event[0] == Undo.light_filling_turn_actual):
		light_filling_turn_actual = event[1]; #the old value, event[2] is the new value
	elif (event[0] == Undo.heavy_turn_unlocked):
		# just lock it again ig
		var was_turn = event[1];
		if (was_turn == -1):
			heavy_locked_turns.append([]);
		else:
			heavy_locked_turns.append(heavy_undo_buffer.pop_at(was_turn));
		heavytimeline.undo_unlock_turn(event[1]);
		heavy_max_moves -= 1;
	elif (event[0] == Undo.light_turn_unlocked):
		var was_turn = event[1];
		if (was_turn == -1):
			light_locked_turns.append([]);
		else:
			light_locked_turns.append(light_undo_buffer.pop_at(was_turn));
		lighttimeline.undo_unlock_turn(event[1]);
		light_max_moves -= 1;
	elif (event[0] == Undo.tick):
		var actor = event[1];
		var amount = event[2];
		var animation_nonce = event[3];
		if (chrono < Chrono.META_UNDO and actor.in_stars):
			add_to_animation_server(actor, [Animation.undo_immunity, animation_nonce]);
		else:
			clock_ticks(actor, -amount, chrono, animation_nonce);

func meta_undo_a_restart() -> bool:
	if (user_replay_before_restarts.size() > 0):
		user_replay = "";
		end_replay();
		toggle_replay();
		cut_sound();
		play_sound("metarestart");
		level_replay = user_replay_before_restarts.pop_back();
		meta_undo_a_restart_mode = true;
		next_replay = -1;
		return true;
	return false;

func meta_undo(is_silent: bool = false) -> bool:
	if (lost and lost_void):
		play_sound("bump");
		return false;
	end_lose();
	finish_animations(Chrono.MOVE);
	if (meta_turn <= 0):
		if (!doing_replay):
			if (meta_undo_a_restart()):
				return true;
		if !is_silent:
			play_sound("bump");
		return false;
	nonstandard_won = false;
	var events = meta_undo_buffer.pop_back();
	for event in events:
		undo_one_event(event, Chrono.META_UNDO);
	adjust_meta_turn(-1);
	if (!is_silent):
		cut_sound();
		play_sound("metaundo");
	undo_effect_strength = 0.08;
	undo_effect_per_second = undo_effect_strength*(1/0.2);
	for whatever in underactorsparticles.get_children():
		whatever.queue_free();
	for whatever in overactorsparticles.get_children():
		whatever.queue_free();
	finish_animations(Chrono.META_UNDO);
	undo_effect_color = meta_color;
	# void things experience time when you undo
	time_passes(Chrono.META_UNDO);
	return meta_undo_replay();
	
func character_switch() -> void:
	# no swapping characters in Meet Heavy or Meet Light, even if you know the button
	if (!is_custom and (level_number == 0 or level_number == 1)):
		return
	heavy_selected = !heavy_selected;
	update_ghosts();
	play_sound("switch")
	append_replay("x")

func restart(_is_silent: bool = false) -> void:
	load_level(0);
	cut_sound();
	play_sound("restart");
	undo_effect_strength = 0.5;
	undo_effect_per_second = undo_effect_strength*(1/0.5);
	finish_animations(Chrono.TIMELESS);
	undo_effect_color = meta_color;
	
func escape() -> void:
	if (test_mode):
		level_editor();
		test_mode = false;
		return;
	
	if (ui_stack.size() > 0):
		# can happen if we click the button directly
		var topmost_ui = ui_stack.pop_front();
		topmost_ui.queue_free();
		return;
	var levelselect = preload("res://Menu.tscn").instance();
	ui_stack.push_back(levelselect);
	levelscene.add_child(levelselect);
	
func level_editor() -> void:
	var a = preload("res://level_editor/LevelEditor.tscn").instance();
	ui_stack.push_back(a);
	levelscene.add_child(a);
	
func level_select() -> void:
	if (test_mode):
		level_editor();
		test_mode = false;
		return;
	
	if (ui_stack.size() > 0):
		# can happen if we click the button directly
		var topmost_ui = ui_stack.pop_front();
		topmost_ui.queue_free();
		return;
	var levelselect = preload("res://LevelSelect.tscn").instance();
	ui_stack.push_back(levelselect);
	levelscene.add_child(levelselect);
	
func trying_to_load_locked_level() -> bool:
	if (is_custom):
		return false;
	if save_file.has("unlock_everything") and save_file["unlock_everything"]:
		return false;
	if (level_names[level_number] == "Chrono Lab Reactor" and !save_file["levels"].has("Chrono Lab Reactor")):
		return true;
	var unlock_requirement = 0;
	if (!level_is_extra):
		unlock_requirement = chapter_standard_unlock_requirements[chapter];
	else:
		unlock_requirement = chapter_advanced_unlock_requirements[chapter];
	if puzzles_completed < unlock_requirement:
		return true;
	return false;
	
func setup_chapter_etc() -> void:
	if (is_custom):
		return;
	chapter = 0;
	level_is_extra = false;
	for i in range(chapter_names.size()):
		if level_number < chapter_standard_starting_levels[i + 1]:
			chapter = i;
			if level_number >= chapter_advanced_starting_levels[i]:
				level_is_extra = true;
				level_in_chapter = level_number - chapter_advanced_starting_levels[i];
			else:
				level_in_chapter = level_number - chapter_standard_starting_levels[i];
			break;
	if (target_sky != chapter_skies[chapter]):
		sky_timer = 0;
		sky_timer_max = 3.0;
		old_sky = current_sky;
		target_sky = chapter_skies[chapter];
	if (target_track != chapter_tracks[chapter]):
		target_track = chapter_tracks[chapter];
		if (current_track == -1):
			play_next_song();
		else:
			fadeout_timer = max(fadeout_timer, 0); #so if we're in the middle of a fadeout it doesn't reset
			fadeout_timer_max = 3.0;
	
func play_next_song() -> void:
	current_track = target_track;
	fadeout_timer = 0;
	fadeout_timer_max = 0;
	if (is_instance_valid(now_playing)):
		now_playing.queue_free();
	now_playing = null;
	
	if (current_track > -1 and current_track < music_tracks.size() and current_track < music_info.size()):
		music_speaker.stream = music_tracks[current_track];
		music_speaker.play();
		var value = save_file["music_volume"];
		if (value > -30 and !muted): #music is not muted
			now_playing = preload("res://NowPlaying.tscn").instance();
			self.get_parent().call_deferred("add_child", now_playing);
			#self.get_parent().add_child(now_playing);
			now_playing.initialize(music_info[current_track]);
	else:
		music_speaker.stop();
	
	
func load_level_direct(new_level: int) -> void:
	is_custom = false;
	end_replay();
	in_insight_level = false;
	has_insight_level = false;
	var impulse = new_level - self.level_number;
	load_level(impulse);
	
func load_level(impulse: int) -> void:
	if (impulse != 0 and test_mode):
		level_editor();
		test_mode = false;
	
	if (impulse != 0):
		is_custom = false; # at least until custom campaigns :eyes:
	level_number = posmod(int(level_number), level_list.size());
	
	if (impulse != 0):
		user_replay_before_restarts.clear();
	elif user_replay.length() > 0:
		user_replay_before_restarts.push_back(user_replay);
	
	if (impulse != 0):
		level_number += impulse;
		level_number = posmod(int(level_number), level_list.size());
	
	setup_chapter_etc();
	
	# we might try to F1/F2 onto a level we don't have access to. if so, back up then show level select.
	if trying_to_load_locked_level():
		impulse *= -1;
		if (impulse == 0):
			impulse = -1;
		for _i in range(999):
			level_number += impulse;
			level_number = posmod(int(level_number), level_list.size());
			setup_chapter_etc();
			if !trying_to_load_locked_level():
				break;
		# buggy if the game just loaded, for some reason, but I didn't want it anyway
		if (ready_done):
			level_select();
			
	if (impulse != 0):
		in_insight_level = false;
		save_file["level_number"] = level_number;
		save_game();
	
	var level = null;
	if (is_custom):
		load_custom_level(custom_string);
		return;
	if (impulse == 0 and has_insight_level and in_insight_level and insight_level_scene != null):
		level = insight_level_scene.instance();
	else:
		level = level_list[level_number].instance();
	levelfolder.remove_child(terrainmap);
	terrainmap.queue_free();
	levelfolder.add_child(level);
	terrainmap = level;
	terrain_layers.clear();
	terrain_layers.append(terrainmap);
	for child in terrainmap.get_children():
		if child is TileMap:
			terrain_layers.push_front(child);
	
	ready_map();

func valid_voluntary_airborne_move(actor: Actor, dir: Vector2) -> bool:
	if actor.fall_speed == 0:
		return true;
	if (actor.airborne <= -1):
		return true;
	# rule change for fall speed 1 actors:
	# if airborne 0+ you can only move left or right.
	if (actor.fall_speed == 1):
		if dir == Vector2.LEFT:
			return true;
		if dir == Vector2.RIGHT:
			return true;
		return false;
	# fall speed 2+ and -1 (infinite)
	if actor.airborne == 0:
		# no air control for fast falling actors
		return false;
	else: # airborne 1+ fall speed 2+ can only move left/right now
		if dir == Vector2.LEFT:
			return true;
		if dir == Vector2.RIGHT:
			return true;
		return false;

func character_move(dir: Vector2) -> bool:
	if (won or lost): return false;
	var chr = "";
	if (dir == Vector2.UP):
		chr = "w";
	elif (dir == Vector2.DOWN):
		chr = "s";
	elif (dir == Vector2.LEFT):
		chr = "a";
	elif (dir == Vector2.RIGHT):
		chr = "d";
	finish_animations(Chrono.MOVE);
	var result = false;
	if heavy_selected:
		if (heavy_actor.broken or (heavy_turn >= heavy_max_moves and heavy_max_moves >= 0)):
			play_sound("bump");
			return false;
		if (!valid_voluntary_airborne_move(heavy_actor, dir)):
			result = Success.Surprise;
		else:
			result = move_actor_relative(heavy_actor, dir, Chrono.MOVE,
			false, false, false, [], false, false, null, -1, true);
	else:
		if (light_actor.broken or (light_turn >= light_max_moves and light_max_moves >= 0)):
			play_sound("bump");
			return false;
		if (!valid_voluntary_airborne_move(light_actor, dir)):
			result = Success.Surprise;
		else:
			result = move_actor_relative(light_actor, dir, Chrono.MOVE,
			false, false, false, [], false, false, null, -1, true);
	if (result == Success.Yes):
		if (!heavy_selected):
			play_sound("lightstep")
		else:
			play_sound("heavystep")
		if (dir == Vector2.UP):
			if heavy_selected and !is_suspended(heavy_actor):
				set_actor_var(heavy_actor, "airborne", 2, Chrono.MOVE);
			elif !heavy_selected and !is_suspended(light_actor):
				set_actor_var(light_actor, "airborne", 2, Chrono.MOVE);
		elif (dir == Vector2.DOWN):
			if heavy_selected and !is_suspended(heavy_actor):
				set_actor_var(heavy_actor, "airborne", 0, Chrono.MOVE);
			#AD10: Light floats gracefully downwards
			#elif !heavy_selected and !is_suspended(light_actor):
			#	set_actor_var(light_actor, "airborne", 0, Chrono.MOVE);
	if (result != Success.No or nonstandard_won):
		append_replay(chr);
	if (result != Success.No):
		time_passes(Chrono.MOVE);
		if anything_happened_meta():
			if heavy_selected:
				if anything_happened_char():
					adjust_turn(true, 1, Chrono.MOVE);
				adjust_meta_turn(1);
			else:
				if anything_happened_char():
					adjust_turn(false, 1, Chrono.MOVE);
				adjust_meta_turn(1);
	if (result != Success.Yes):
		play_sound("bump")
	return result != Success.No;

func anything_happened_char(destructive: bool = true) -> bool:
	# time crystals fuck this logic up and obviously mean something happened, so just say 'yes' if they happened
	# (and hopefully this doesn't come bite me in the ass later)
	if (heavy_filling_locked_turn_index > -1 or light_filling_locked_turn_index > -1):
		return true;
	if (heavy_selected):
		while (heavy_undo_buffer.size() <= heavy_turn):
			heavy_undo_buffer.append([]);
		for event in heavy_undo_buffer[heavy_turn]:
			if event[0] != Undo.animation_substep:
				return true;
		#clear out now unnecessary animation_substeps if nothing else happened
		if (destructive):
			heavy_undo_buffer[heavy_turn].clear();
	else:
		while (light_undo_buffer.size() <= light_turn):
			light_undo_buffer.append([]);
		for event in light_undo_buffer[light_turn]:
			if event[0] != Undo.animation_substep:
				return true;
		if (destructive):
			light_undo_buffer[light_turn].clear();
	return false;
	
func anything_happened_meta() -> bool:
	if anything_happened_char(false):
		return true;
	while (meta_undo_buffer.size() <= meta_turn):
		meta_undo_buffer.append([]);
	var heavy_undo_event_add_count = 0;
	var light_undo_event_add_count = 0;
	for event in meta_undo_buffer[meta_turn]:
		if event[0] == Undo.animation_substep:
			continue;
		elif event[0] == Undo.heavy_undo_event_add:
			heavy_undo_event_add_count += 1;
		elif event[0] == Undo.light_undo_event_add:
			light_undo_event_add_count += 1;
		else:
			return true;
	if heavy_undo_event_add_count > 0:
		if heavy_undo_buffer[heavy_turn].size() != heavy_undo_event_add_count:
			return true;
	if light_undo_event_add_count > 0:
		if light_undo_buffer[light_turn].size() != light_undo_event_add_count:
			return true;
	meta_undo_buffer.pop_at(meta_turn);
	anything_happened_char(true); #to destroy
	return false;

func time_passes(chrono: int) -> void:
	animation_substep(chrono);
	var time_actors = []
	
	if chrono == Chrono.META_UNDO:
		for actor in actors:
			if actor.is_crystal:
				continue;
			if actor.time_colour == TimeColour.Void:
				time_actors.push_back(actor);
			
	elif chrono < Chrono.META_UNDO:
		for actor in actors:
			# broken time crystals being in stacks was messing up the just_moved gravity code,
			# and nothing related to time passage effects time crystals anyway, so just eject them here
			if actor.is_crystal:
				continue;
			
			#AD06: Characters are Purple, other actors are Gray. (But with time colours you can make your own arbitrary rules!
	#		Red: Time passes only when red moves forward.
	#		Blue: Time passes only when blue moves forward.
	#		Purple: The default colour of Heavy. Time passes except when Heavy is undoing.
	#		Blurple: The default colour of Light. Time passes except when Light is undoing.
	#		Gray: The default unrendered colour of non-character actors. Time passes when a character moves forward and doesn't when a character undoes.
	#		Green: Time always passes, AND undo events are not generated/stored for this actor, AND if a green character takes a turn and no events are made, turn is not incremented. (So, having actor be green is equivalent to a no-time-shenanigans version of Entwined Time where time just always moves forward and you need to meta-undo to claw it back.) (Alternatively, I might have turns work as normal but there's a sentinel value for 'no turns, no timeline' like 100, since -1 actually will mean something)
	#		Void: Time always passes AND time passes after a meta-undo AND undo events AND meta undo events are not generated/stored for this actor, AND if a void actor takes a turn and no events are made, turn/meta-turn is not incremented. (In the main campaign this will probably only be used for the void cuckoo clock in the final level.)
	#		Magenta: Time always passes.
	#		Orange: Time passes if Red is moving or undoing.
	#		Cyan: Time passes if Blue is moving or undoing.
	#		Yellow: Time passes if a character is undoing.
	#		White: Time never passes.
			if actor.time_colour == TimeColour.Gray:
				if (chrono == Chrono.MOVE):
					time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Purple:
				if (chrono == Chrono.MOVE):
					time_actors.push_back(actor);
				else:
					if (!heavy_selected):
						time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Blurple:
				if (chrono == Chrono.MOVE):
					time_actors.push_back(actor);
				else:
					if (heavy_selected):
						time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Red:
				if chrono == Chrono.MOVE and heavy_selected:
					time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Blue:
				if chrono == Chrono.MOVE and !heavy_selected:
					time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Green:
				time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Void:
				time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Magenta:
				time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Cyan:
				if !heavy_selected:
					time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Orange:
				if heavy_selected:
					time_actors.push_back(actor);
			elif actor.time_colour == TimeColour.Yellow:
				if (chrono == Chrono.CHAR_UNDO):
					time_actors.push_back(actor);
			# White: No
	
	# Flash time bubbles (Can add other effects here if I think of any).
	for actor in time_actors:
		add_to_animation_server(actor, [Animation.time_passes]);
	
	# Decrement airborne by one (min zero).
	# AD02: Maybe this should be a +1/-1 instead of a set. Haven't decided yet. Doesn't seem to matter until strange matter.
	var has_fallen = {};
	for actor in time_actors:
		has_fallen[actor] = 0;
		if !actor.in_night and actor.airborne > 0 and actor.fall_speed() != 0:
			set_actor_var(actor, "airborne", actor.airborne - 1, chrono);
			
	# AD09: ALL actors go from airborne 2 to 1. (blue/red levels are kind of fucky without this)
	for actor in actors:
		if actor.airborne >= 2:
			set_actor_var(actor, "airborne", 1, chrono);
			
	# GRAVITY
	# For each actor in the list, in order of lowest down to highest up, repeat the following loop until nothing happens:
	# * If airborne is -1 and it COULD push-move down, set airborne to (1 for light, 0 for heavy).
	# * If airborne is 0, push-move down (unless this actor is light and already has this loop). If the push-move fails, set airborne to -1.
	time_actors.sort_custom(self, "bottom_up");
	var something_happened = true;
	var tries = 99;
	# just_moved logic for stacked actors falling together without clipping through e.g. Heavies sticky topping them down:
	# 1) Peek one time_actor ahead.
	# 1a) If it shares our pos, we're part of a stack - before we try to move, set just_moved, and keep it set if we did move.
	# 1b) If it doesn't or it's empty, then we're ending a stack or were never in a stack - unset all just_moveds at the end of the tick
	# This will probably break in some esoteric level editor cases with Heavy sticky top or boost pads, but it's good enough for my needs.
	var just_moveds = [];
	var clear_just_moveds = false;
	while (something_happened and tries > 0):
		animation_substep(chrono);
		tries -= 1;
		something_happened = false;
		var size = time_actors.size();
		for i in range(size):
			var actor = time_actors[i];
			if (actor.fall_speed() >= 0 and has_fallen[actor] >= actor.fall_speed()):
				continue;
			if (actor.in_night):
				continue;
			
			# multi-falling stack check
			if (i < (size - 1)):
				var next_actor = time_actors[i+1];
				if actor.pos != next_actor.pos:
					clear_just_moveds = true;
				else:
					actor.just_moved = true;
					just_moveds.append(actor);
			else:
				clear_just_moveds = true;
			
			if actor.airborne == -1 and !is_suspended(actor):
				var could_fall = try_enter(actor, Vector2.DOWN, chrono, true, true, true);
				# we'll say that falling due to gravity onto spikes/a pressure plate makes you airborne so we try to do it, but only once
				if (could_fall != Success.No and (could_fall == Success.Yes or has_fallen[actor] <= 0)):
					if actor.floats():
						set_actor_var(actor, "airborne", 1, chrono);
					else:
						set_actor_var(actor, "airborne", 0, chrono);
					something_happened = true;
			
			if actor.airborne == 0:
				var did_fall = Success.No;
				if (is_suspended(actor)):
					did_fall = Success.No;
				else:
					did_fall = move_actor_relative(actor, Vector2.DOWN, chrono, false, true);
				
				if (did_fall != Success.No):
					something_happened = true;
					# so Heavy can break a glass block and not fall further, surprises break your fall immediately
					if (did_fall == Success.Surprise):
						has_fallen[actor] += 999;
					else:
						has_fallen[actor] += 1;
				if (did_fall != Success.Yes):
					actor.just_moved = false;
					set_actor_var(actor, "airborne", -1, chrono);
			
			if clear_just_moveds:
				clear_just_moveds = false;
				for a in just_moveds:
					a.just_moved = false;
				just_moveds.clear();
	
	#possible to leak this out the for loop
	for a in just_moveds:
		a.just_moved = false;
	
	animation_substep(chrono);
	
	# NEW (as part of AD07) post-gravity cleanups: If an actor is airborne 1 and would be grounded next fall,
	# land.
	# (UPDATE AD08: Now it's 'and the tile under you is no_push solid', so Heavy can land on Light, because
	# it's an interesting mechanic)
	# It was vaguely tolerable for Light but I don't know if it was ever a mechanic I was like 'whoo' about,
	#and now it definitely sucks.
	for actor in time_actors:
		if (actor.in_night):
			continue;
		if (actor.airborne == 0):
			if is_suspended(actor):
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
			var could_fall = try_enter(actor, Vector2.DOWN, chrono, false, true, true);
			if (could_fall == Success.No):
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
	
	animation_substep(chrono);
	
	# AFTER-GRAVITY TILE ARRIVAL
	
	# Chrono helixes repel each other.
	if !nonstandard_won:
		for actor in time_actors:
			if actor.actorname == Actor.Name.ChronoHelixRed:
				for actor2 in actors:
					if actor2.actorname == Actor.Name.ChronoHelixBlue:
						var diff = actor.pos - actor2.pos;
						if (abs(diff.x) <= 1 and abs(diff.y) <= 1):
							add_to_animation_server(actor, [Animation.sfx, "fall"]);
							move_actor_relative(actor, diff, chrono, false, false);
							move_actor_relative(actor2, -diff, chrono, false, false);
			elif actor.actorname == Actor.Name.ChronoHelixBlue:
				for actor2 in actors:
					if actor2.actorname == Actor.Name.ChronoHelixRed:
						var diff = actor.pos - actor2.pos;
						if (abs(diff.x) <= 1 and abs(diff.y) <= 1):
							add_to_animation_server(actor, [Animation.sfx, "fall"]);
							move_actor_relative(actor, diff, chrono, false, false);
							move_actor_relative(actor2, -diff, chrono, false, false);
	
	# Things in fire break.
	# TODO: once colours exist this gets more complicated
	# might be sufficient to just check which of Heavy/Light are in time_actors, since that's really what matters
	if chrono <= Chrono.CHAR_UNDO:
		var time_colour = TimeColour.Magenta;
		if (heavy_selected and chrono == Chrono.CHAR_UNDO):
			time_colour = TimeColour.Blue;
		elif (!heavy_selected and chrono == Chrono.CHAR_UNDO):
			time_colour = TimeColour.Red;
		add_to_animation_server(null, [Animation.fire_roars, time_colour])
	for actor in time_actors:
		var terrain = terrain_in_tile(actor.pos);		
		if !actor.broken and terrain.has(Tiles.Fire) and actor.durability <= Durability.FIRE:
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		if !actor.broken and terrain.has(Tiles.HeavyFire) and actor.durability <= Durability.FIRE and actor.actorname != Actor.Name.Light:
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		if !actor.broken and terrain.has(Tiles.LightFire) and actor.durability <= Durability.FIRE and actor.actorname != Actor.Name.Heavy:
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		
	# Green fire happens after regular fire, so you can have that matter if you'd like it to :D	
	if chrono <= Chrono.CHAR_UNDO:
		for actor in actors:
			var terrain = terrain_in_tile(actor.pos);
			if !actor.broken and terrain.has(Tiles.GreenFire) and actor.durability <= Durability.FIRE:
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, Chrono.CHAR_UNDO);
	
	# Lucky last - clocks tick.
	for actor in time_actors:
		if actor.in_night:
			continue;
		if actor.ticks != 1000 and !actor.broken:
			clock_ticks(actor, -1, chrono);
	
func bottom_up(a, b) -> bool:
	# TODO: make this tiebreak by x, then by layer or id, so I can use it as a stable sort in general?
	return a.pos.y > b.pos.y;
	
func replay_interval() -> float:
	if unit_test_mode:
		return 0.01;
	if meta_undo_a_restart_mode:
		return 0.01;
	return replay_interval;
	
func authors_replay() -> void:
	if (ui_stack.size() > 0):
		return;
	
	if (!doing_replay):
		if (!unit_test_mode):
			if (!save_file.has("authors_replay") or save_file["authors_replay"] != true):
				var modal = preload("res://AuthorsReplayModalPrompt.tscn").instance();
				ui_stack.push_back(modal);
				levelscene.add_child(modal);
				return;
	
	toggle_replay();
	if (level_replay.find("c") >= 0):
		voidlike_puzzle = true;
	
func toggle_replay() -> void:
	meta_undo_a_restart_mode = false;
	unit_test_mode = false;
	if (doing_replay):
		end_replay();
		return;
	doing_replay = true;
	replaybuttons.visible = true;
	restart();
	replay_paused = false;
	replay_turn = 0;
	next_replay = replay_timer + replay_interval();
	unit_test_mode = OS.is_debug_build() and Input.is_action_pressed(("shift"));
	
var double_unit_test_mode : bool = false;
var unit_test_mode_do_second_pass : bool = false;
	
func do_one_replay_turn() -> void:
	if (!doing_replay):
		return;
	if replay_turn >= level_replay.length():
		meta_undo_a_restart_mode = false;
		if (unit_test_mode and won and level_number < (level_list.size() - 1)):
			doing_replay = true;
			replaybuttons.visible = true;
			if (double_unit_test_mode):
				if unit_test_mode_do_second_pass:
					unit_test_mode_do_second_pass = false;
					var replay = user_replay;
					load_level(0);
					level_replay = replay;
				else:
					unit_test_mode_do_second_pass = true;
					if (has_insight_level and !in_insight_level):
						gain_insight();
					else:
						load_level(1);
			else:
				if (has_insight_level and !in_insight_level):
					gain_insight();
				else:
					load_level(1);
			replay_turn = 0;
			next_replay = replay_timer + replay_interval();
			return;
		else:
			if (unit_test_mode):
				floating_text("Tested up to level: " + str(level_number) + " (This is 0 indexed lol)" );
				end_replay();
			return;
	next_replay = replay_timer+replay_interval();
	var replay_char = level_replay[replay_turn];
	var old_meta_turn = meta_turn;
	replay_turn += 1;
	if (replay_char == "w"):
		character_move(Vector2.UP);
	elif (replay_char == "a"):
		character_move(Vector2.LEFT);
	elif (replay_char == "s"):
		character_move(Vector2.DOWN);
	elif (replay_char == "d"):
		character_move(Vector2.RIGHT);
	elif (replay_char == "z"):
		character_undo();
	elif (replay_char == "x"):
		character_switch();
	elif (replay_char == "c"):
		meta_undo();
	if replay_char == "x":
		return
	elif old_meta_turn == meta_turn:
		replay_turn -= 1;
		# replay contains a bump - silently delete the bump so we don't desync when trying to meta-undo it
		level_replay = level_replay.left(replay_turn) + level_replay.right(replay_turn + 1)
	
func end_replay() -> void:
	doing_replay = false;
	update_level_label();
	
func pause_replay() -> void:
	if replay_paused:
		replay_paused = false;
		floating_text("Replay unpaused");
		replay_timer = next_replay;
	else:
		replay_paused = true;
		floating_text("Replay paused");
	update_info_labels();
	
func replay_advance_turn(amount: int) -> void:
	if amount > 0:
		for _i in range(amount):
			if (replay_turn < (level_replay.length())):
				do_one_replay_turn();
			else:
				play_sound("bump");
				break;
	elif (replay_turn <= 0):
		play_sound("bump");
	else:
		var target_turn = replay_turn + amount;
		if (target_turn < 0):
			target_turn = 0;
		
		# Restart and advance the puzzle from the start if:
		# 1) voidlike_puzzle (contains void elements or the replay contains a meta undo)
		# 2) it's a long jump, and going forward from the start would be quicker
		# (currently assuming an undo is 2.1x as fast as a forward move, which seems roughly right)
		var restart_and_advance = false;
		if (voidlike_puzzle):
			restart_and_advance = true;
		elif amount < -50 and target_turn*2.1 < -amount:
			restart_and_advance = true;
			
		if (restart_and_advance):
			var replay = level_replay;
			user_replay = ""; #to not pollute meta undo a restart buffer
			var old_muted = muted;
			muted = true;
			load_level(0);
			start_specific_replay(replay);
			for _i in range(target_turn):
				do_one_replay_turn();
			finish_animations(Chrono.TIMELESS);
			calm_down_timelines();
			muted = old_muted;
			# weaker and slower than meta-undo
			undo_effect_strength = 0.04;
			undo_effect_per_second = undo_effect_strength*(1/0.4);
			play_sound("voidundo");
		else:
			var iterations = replay_turn - target_turn;
			for _i in range(iterations):
				var last_input = level_replay[replay_turn - 1];
				if (last_input == "x"):
					character_switch();
				else:
					meta_undo();
				replay_turn -= 1;
	replay_paused = true;
	update_info_labels();
			
func calm_down_timelines() -> void:
	heavytimeline.calm_down();
	lighttimeline.calm_down();
			
func update_level_label() -> void:
	var levelnumberastext = ""
	if (is_custom):
		levelnumberastext = "CUSTOM";
	else:
		var chapter_string = str(chapter);
		if chapter_replacements.has(chapter):
			chapter_string = chapter_replacements[chapter];
		var level_string = str(level_in_chapter);
		if (level_replacements.has(level_number)):
			level_string = level_replacements[level_number];
		levelnumberastext = chapter_string + "-" + level_string;
		if (level_is_extra):
			levelnumberastext += "X";
	levellabel.text = levelnumberastext + " - " + level_name;
	if (level_author != "" and level_author != "Patashu"):
		levellabel.text += " (By " + level_author + ")"
	if (doing_replay):
		levellabel.text += " (REPLAY)"
		if (heavy_max_moves < 11 and light_max_moves < 11):
			if (using_controller):
				levellabel.text += " (L2/R2 ADJUST SPEED)";
			else:
				pass #there are now virtual buttons for kb+m players
	if save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]:
		if (levelstar.next_modulates.size() > 0):
			# in the middle of a flash from just having won
			pass
		else:
			levelstar.modulate = Color(1, 1, 1, 1);
		var string_size = preload("res://standardfont.tres").get_string_size(levellabel.text);
		var label_middle = levellabel.rect_position.x + int(floor(levellabel.rect_size.x / 2));
		var string_left = label_middle - int(floor(string_size.x/2));
		levelstar.position = Vector2(string_left-14, levellabel.rect_position.y);
	else:
		levelstar.finish_animations();
		levelstar.modulate = Color(1, 1, 1, 0);
	
func update_info_labels() -> void:
	#also do fuzz indicator here
	if terrain_in_tile(heavy_actor.pos).has(Tiles.Fuzz):
		heavytimeline.fuzz_on();
	else:
		heavytimeline.fuzz_off();
		
	if terrain_in_tile(light_actor.pos).has(Tiles.Fuzz):
		lighttimeline.fuzz_on();
	else:
		lighttimeline.fuzz_off();
	
	heavyinfolabel.text = "Heavy" + "\n" + str(heavy_turn);
	if heavy_max_moves >= 0:
		heavyinfolabel.text += "/" + str(heavy_max_moves);
	
	lightinfolabel.text = "Light" + "\n" + str(light_turn);
	if light_max_moves >= 0:
		lightinfolabel.text += "/" + str(light_max_moves);
	
	metainfolabel.text = "Meta-Turn: " + str(meta_turn)
	
	if (doing_replay):
		replaybuttons.visible = true;
		replayturnlabel.text = "Input " + str(replay_turn) + "/" + str(level_replay.length());
		replayturnsliderset = true;
		replayturnslider.max_value = level_replay.length();
		replayturnslider.value = replay_turn;
		replayturnsliderset = false;
		if (replay_paused):
			replayspeedlabel.text = "Replay Paused";
		else:
			replayspeedlabel.text = "Speed: " + "%0.2f" % (replay_interval) + "s";
	else:
		replaybuttons.visible = false;
	
	if (!is_custom):
		if (level_number >= 2 and level_number <= 4):
			if (heavy_selected):
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("#7FC9FF", "#FF7459");
			else:
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("#FF7459", "#7FC9FF");
				
		if tutoriallabel.visible:
			if using_controller:
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Arrows:", "D-Pad/Either Stick:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("X:", "Bottom Face Button:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Z:", "Right Face Button:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("C:", "Top Face Button:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("R:", "Select:");
			else:
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("D-Pad/Either Stick:", "Arrows:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Bottom Face Button:", "X:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Right Face Button:", "Z:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Top Face Button:", "C:");
				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Select:", "R:");

func animation_substep(chrono: int) -> void:
	animation_substep += 1;
	add_undo_event([Undo.animation_substep], chrono);

func add_to_animation_server(actor: ActorBase, animation: Array) -> void:
	while animation_server.size() <= animation_substep:
		animation_server.push_back([]);
	animation_server[animation_substep].push_back([actor, animation]);

func handle_global_animation(animation: Array) -> void:
	var redfire = false;
	var bluefire = false;
	var greenfire = false;
	if animation[0] == Animation.fire_roars:
		#have green fires animate first so if someone puts green and non-green fires in the same tile they layer correctly
		var green_fires = get_used_cells_by_id_one_array(Tiles.GreenFire);
		for fire in green_fires:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://OneTimeSprite.gd"));
			sprite.texture = preload("res://assets/green_fire_spritesheet.png");
			sprite.position = terrainmap.map_to_world(fire);
			sprite.vframes = 1;
			sprite.hframes = 8;
			sprite.frame = 0;
			sprite.centered = false;
			sprite.frame_max = sprite.frame + 8;
			underactorsparticles.add_child(sprite);
			greenfire = true;
		var fires = get_used_cells_by_id_one_array(Tiles.Fire);
		for fire in fires:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://OneTimeSprite.gd"));
			sprite.texture = preload("res://assets/fire_spritesheet.png");
			sprite.position = terrainmap.map_to_world(fire);
			sprite.vframes = 3;
			sprite.hframes = 8;
			sprite.frame = 0;
			sprite.centered = false;
			if animation[1] == TimeColour.Blue:
				bluefire = true;
				sprite.frame = 8;
			elif animation[1] == TimeColour.Magenta:
				redfire = true;
				bluefire = true;
				sprite.frame = 16;
			else:
				redfire = true;
			sprite.frame_max = sprite.frame + 8;
			underactorsparticles.add_child(sprite);
		if (animation[1] == TimeColour.Magenta or animation[1] == TimeColour.Red):
			fires = get_used_cells_by_id_one_array(Tiles.HeavyFire);
			for fire in fires:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://OneTimeSprite.gd"));
				sprite.texture = preload("res://assets/fire_spritesheet.png");
				sprite.position = terrainmap.map_to_world(fire);
				sprite.vframes = 3;
				sprite.hframes = 8;
				sprite.frame = 0;
				sprite.centered = false;
				sprite.frame_max = sprite.frame + 8;
				underactorsparticles.add_child(sprite);
				redfire = true;
		if (animation[1] == TimeColour.Magenta or animation[1] == TimeColour.Blue):
			fires = get_used_cells_by_id_one_array(Tiles.LightFire);
			for fire in fires:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://OneTimeSprite.gd"));
				sprite.texture = preload("res://assets/fire_spritesheet.png");
				sprite.position = terrainmap.map_to_world(fire);
				sprite.vframes = 3;
				sprite.hframes = 8;
				sprite.frame = 8;
				sprite.centered = false;
				sprite.frame_max = sprite.frame + 8;
				underactorsparticles.add_child(sprite);
				bluefire = true;
	# we can immediately play sounds since the animation just started
	if (redfire):
		play_sound("redfire");
	if (bluefire):
		play_sound("bluefire");
	if (greenfire):
		play_sound("greenfire");

func update_animation_server(skip_globals: bool = false) -> void:
	# don't interrupt ongoing animations
	for actor in actors:
		if actor.animations.size() > 0:
			return;
	
	# look for new animations to play
	while animation_server.size() > 0 and animation_server[0].size() == 0:
		animation_server.pop_front();
	if animation_server.size() == 0:
		# won_fade starts here
		if ((won or lost) and !won_fade_started):
			won_fade_started = true;
			if (lost):
				fade_in_lost();
			add_to_animation_server(heavy_actor, [Animation.fade]);
			add_to_animation_server(light_actor, [Animation.fade]);
		return;
	
	# we found new animations - give them to everyone at once
	var animations = animation_server.pop_front();
	for animation in animations:
		if animation[0] == null:
			if !skip_globals:
				handle_global_animation(animation[1]);
		else:
			animation[0].animations.push_back(animation[1]);

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	levelscene.add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = pixel_width;
	label.rect_position.y = pixel_height/2-16;
	label.text = text;

func is_valid_replay(replay: String) -> bool:
	var replay_parts = replay.split("$");
	replay = replay_parts[replay_parts.size()-1];
	replay = replay.strip_edges();
	replay = replay.to_lower();
	if replay.length() <= 0:
		return false;
	for letter in replay:
		if !(letter in "wasdzxc"):
			return false;
	return true;

func start_specific_replay(replay: String) -> void:
	var replay_parts = replay.split("$");
	replay = replay_parts[replay_parts.size()-1];
	replay = replay.strip_edges();
	replay = replay.to_lower();
	if (!is_valid_replay(replay)):
		floating_text("Ctrl+V: Invalid replay");
		return;
	end_replay();
	toggle_replay();
	level_replay = replay;
	if (level_replay.find("c") >= 0):
		voidlike_puzzle = true;
	update_info_labels();

func replay_from_clipboard() -> void:
	var replay = OS.get_clipboard();
	start_specific_replay(replay);

func start_saved_replay() -> void:
	if (doing_replay):
		end_replay();
		return;
	
	var levels_save_data = save_file["levels"];
	if (!levels_save_data.has(level_name)):
		floating_text("F11: Level not beaten");
		return;
	var level_save_data = levels_save_data[level_name];
	if (!level_save_data.has("replay")):
		floating_text("F11: Level not beaten");
		return;
	var replay = level_save_data["replay"];
	start_specific_replay(replay);

func annotate_replay(replay: String) -> String:
	return level_name + "$" + "mturn=" + str(meta_turn) + "$" + replay;

func get_afterimage_material_for(color: Color) -> Material:
	if (afterimage_server.has(color)):
		return afterimage_server[color];
	var new_material = preload("res://afterimage_shadermaterial.tres").duplicate();
	new_material.set_shader_param("color", color);
	afterimage_server[color] = new_material;
	return new_material;

func afterimage(actor: Actor) -> void:
	if undo_effect_color == Color.transparent:
		return;
	# ok, we're mid undo.
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.actor = actor;
	afterimage.set_material(get_afterimage_material_for(undo_effect_color));
	underactorsparticles.add_child(afterimage);
	
func afterimage_terrain(texture: Texture, position: Vector2, color: Color) -> void:
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.texture = texture;
	afterimage.position = position;
	afterimage.set_material(get_afterimage_material_for(color));
	underactorsparticles.add_child(afterimage);
		
func last_level_of_section() -> bool:
	var chapter_standard_starting_level = chapter_standard_starting_levels[chapter+1];
	var chapter_advanced_starting_level = chapter_advanced_starting_levels[chapter];
	if (level_number+1 == chapter_standard_starting_level or level_number+1 == chapter_advanced_starting_level):
		return true;
	return false;
		
func unwin() -> void:
	floating_text("Shift+F11: Unwin");
	if (save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]):
		puzzles_completed -= 1;
	if (save_file["levels"].has(level_name)):
		save_file["levels"][level_name].clear();
	save_game();
	update_level_label();
	
func _input(event: InputEvent) -> void:
	if (ui_stack.size() > 0):
		return;
	
	if event is InputEventMouseButton:
		var mouse_position = get_parent().get_global_mouse_position();
		var heavy_rect = heavy_actor.get_rect();
		var light_rect = light_actor.get_rect();
		heavy_rect.position += heavy_actor.global_position;
		light_rect.position += light_actor.global_position;
		if !heavy_selected and heavy_rect.has_point(mouse_position):
			end_replay();
			character_switch();
			update_info_labels();
		elif heavy_selected and light_rect.has_point(mouse_position):
			end_replay();
			character_switch();
			update_info_labels();
	
func gain_insight() -> void:
	if (ui_stack.size() > 0):
		return;
	
	if (has_insight_level and !unit_test_mode):
		if (!save_file.has("gain_insight") or save_file["gain_insight"] != true):
			var modal = preload("res://GainInsightModalPrompt.tscn").instance();
			ui_stack.push_back(modal);
			levelscene.add_child(modal);
			return;
	
	if (has_insight_level):
		if (in_insight_level):
			in_insight_level = false;
		else:
			in_insight_level = true;
		load_level(0);
		cut_sound();
		play_sound("usegreenality");
		undo_effect_strength = 0.5;
		undo_effect_per_second = undo_effect_strength*(1/0.5);
		finish_animations(Chrono.TIMELESS);
		undo_effect_color = Color("A9F05F");
	
func serialize_current_level() -> String:
	# keep in sync with LevelEditor.gd serialize_current_level()
	var result = "EntwinedTimePuzzleStart: " + level_name + " by " + level_author + "\n";
	var level_metadata = {};
	var metadatas = ["level_name", "level_author", #"level_replay", "heavy_max_moves", "light_max_moves",
	"clock_turns", "map_x_max", "map_y_max", "target_track" #"target_sky"
	];
	for metadata in metadatas:
		level_metadata[metadata] = self.get(metadata);
	level_metadata["target_sky"] = target_sky.to_html(false);
	
	# we now have to grab the original values for: terrain_layers, heavy_max_moves, light_max_moves
	# has to be kept in sync with load_level/ready_map and any custom level logic we end up adding
	var level = null;
	if (has_insight_level and in_insight_level and insight_level_scene != null):
		level = insight_level_scene.instance();
	else:
		level = level_list[level_number].instance();
		
	var level_info = level.get_node("LevelInfo");
	level_metadata["level_replay"] = level_info.level_replay;
	level_metadata["heavy_max_moves"] = level_info.heavy_max_moves;
	level_metadata["light_max_moves"] = level_info.light_max_moves;
		
	var layers = [];
	layers.append(level);
	for child in level.get_children():
		if child is TileMap:
			layers.push_front(child);
			
	level_metadata["layers"] = layers.size();
			
	result += to_json(level_metadata);
	
	for i in layers.size():
		result += "\nLAYER " + str(i) + ":\n";
		var layer = layers[layers.size() - 1 - i];
		for y in range(map_y_max+1):
			for x in range(map_x_max+1):
				if (x > 0):
					result += ",";
				var tile = layer.get_cell(x, y);
				if tile >= 0 and tile <= 9:
					result += "0" + str(tile);
				else:
					result += str(tile);
			result += "\n";
	
	result += "EntwinedTimePuzzleEnd"
	level.queue_free();
	return result;
	
func copy_level() -> void:
	var result = serialize_current_level();
	floating_text("Ctrl+Shift+C: Level copied to clipboard!");
	OS.set_clipboard(result);
	
func clipboard_contains_level() -> bool:
	var clipboard = OS.get_clipboard();
	clipboard = clipboard.strip_edges();
	if clipboard.find("EntwinedTimePuzzleStart") >= 0 and clipboard.find("EntwinedTimePuzzleEnd") >= 0:
		return true
	return false
	
func deserialize_custom_level(custom: String) -> Node:
	var lines = custom.split("\n");
	for i in range(lines.size()):
		lines[i] = lines[i].strip_edges();
	
	if (lines[0].find("EntwinedTimePuzzleStart") == -1):
		floating_text("Assert failed: Line 1 should start EntwinedTimePuzzleStart");
		return null;
	if (lines[(lines.size() - 1)] != "EntwinedTimePuzzleEnd"):
		floating_text("Assert failed: Last line should be EntwinedTimePuzzleEnd");
		return null;
	var json_parse_result = JSON.parse(lines[1])
	
	var result = null;
	
	if json_parse_result.error == OK:
		var data = json_parse_result.result;
		if typeof(data) == TYPE_DICTIONARY:
			result = data;
	
	if (result == null):
		floating_text("Assert failed: Line 2 should be a valid dictionary")
		return null;
	
	var metadatas = ["level_name", "level_author", "level_replay", "heavy_max_moves", "light_max_moves",
	"clock_turns", "map_x_max", "map_y_max", "target_sky", "layers", "target_track"];
	
	#datafix: old custom levels without target_track
	if (!result.has("target_track")):
		result["target_track"] = target_track;
	
	for metadata in metadatas:
		if (!result.has(metadata)):
			floating_text("Assert failed: Line 2 is missing " + metadata);
			return null;
	
	var layers = result["layers"];
	var xx = 2;
	var xxx = result["map_y_max"] + 1 + 1 + 1; #1 for the header, 1 for the off-by-one, 1 for the blank line
	var terrain_layers = [];
	var terrainmap = null;
	for i in range(layers):
		var tile_map = TileMap.new();
		tile_map.tile_set = preload("res://DefaultTiles.tres");
		tile_map.cell_size = Vector2(cell_size, cell_size);
		var a = xx + xxx*i;
		var header = lines[a];
		if (header != "LAYER " + str(i) + ":"):
			floating_text("Assert failed: Line " + str(a) + " should be 'LAYER " + str(i) + ":'.");
			return null;
		for j in range(result["map_y_max"] + 1):
			var layer_line = lines[a + 1 + j];
			var layer_cells = layer_line.split(",");
			for k in range(layer_cells.size()):
				var layer_cell = layer_cells[k];
				tile_map.set_cell(k, j, int(layer_cell));
		terrain_layers.append(tile_map);
		tile_map.update_bitmask_region();
	terrainmap = terrain_layers[0];
	for i in range(layers - 1):
		terrainmap.add_child(terrain_layers[i + 1]);
	
	var level_info = Node.new();
	level_info.set_script(preload("res://levels/LevelInfo.gd"));
	level_info.name = "LevelInfo";
	for metadata in metadatas:
		level_info.set(metadata, result[metadata]);
	terrainmap.add_child(level_info);
			
	return terrainmap;
	
func load_custom_level(custom: String) -> void:
	var level = deserialize_custom_level(custom);
	if level == null:
		return;
	
	is_custom = true;
	custom_string = custom;
	var level_info = level.get_node("LevelInfo");
	level_name = level_info["level_name"];
	level_author = level_info["level_author"];
	level_replay = level_info["level_replay"];
	heavy_max_moves = int(level_info["heavy_max_moves"]);
	light_max_moves = int(level_info["light_max_moves"]);
	clock_turns = level_info["clock_turns"];
	map_x_max = int(level_info["map_x_max"]);
	map_y_max = int(level_info["map_y_max"]);
	sky_timer = 0;
	sky_timer_max = 3.0;
	old_sky = current_sky;
	target_sky = Color(level_info["target_sky"]);
	# TODO: poorly refactored
	if (target_track != level_info["target_track"]):
		target_track = level_info["target_track"];
		if (current_track == -1):
			play_next_song();
		else:
			fadeout_timer = max(fadeout_timer, 0); #so if we're in the middle of a fadeout it doesn't reset
			fadeout_timer_max = 3.0;
	
	levelfolder.remove_child(terrainmap);
	terrainmap.queue_free();
	levelfolder.add_child(level);
	terrainmap = level;
	terrain_layers.clear();
	terrain_layers.append(terrainmap);
	for child in terrainmap.get_children():
		if child is TileMap:
			terrain_layers.push_front(child);
	
	ready_map();
	
func give_up_and_restart() -> void:
	is_custom = false;
	custom_string = "";
	restart();
	
func paste_level() -> void:
	var clipboard = OS.get_clipboard();
	clipboard = clipboard.strip_edges();
	end_replay();
	load_custom_level(clipboard);
	
func adjust_next_replay_time(old_replay_interval: float) -> void:
	next_replay += replay_interval - old_replay_interval;
	
var last_dir_release_times = [0, 0, 0, 0];
	
func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("any_controller") or Input.is_action_just_pressed("any_controller_2")) and !using_controller:
		using_controller = true;
		menubutton.text = "Menu (Start)";
		menubutton.rect_position.x = 222;
		update_info_labels();
	
	if Input.is_action_just_pressed("any_keyboard") and using_controller:
		using_controller = false;
		menubutton.text = "Menu (Esc)";
		menubutton.rect_position.x = 226;
		menubutton.rect_size.x = 60;
		update_info_labels();
	
	#hysteresis: dynamically update dead zone based on if a direction is currently held or not
	#(this should happen even when ui_stack is filled so it applies to menus as well)
	#debouncing: if the player uses a controller to re-press a direction within (debounce_ms) ms,
	#allow it but in gameplay code ignore movement this frame
	#(this means debouncing doesn't work in menus since I don't control focus logic.)
	#(maybe it's somehow possible another way?)
	var get_debounced = false;
	if (using_controller):
		if (!save_file.has("deadzone")):
			save_file["deadzone"] = InputMap.action_get_deadzone("ui_up");
		if (!save_file.has("debounce")):
			save_file["debounce"] = 40;
		
		var normal = save_file["deadzone"];
		var debounce_ms = save_file["debounce"];
		var held = normal*0.95;
		var dirs = ["ui_up", "ui_down", "ui_left", "ui_right"];
		for i in range(dirs.size()):
			
			var dir = dirs[i];
			var current_time = Time.get_ticks_msec();
			
			if Input.is_action_just_pressed(dir):
				if ((current_time - debounce_ms) < last_dir_release_times[i]):
					get_debounced = true;
					#floating_text("get debounced");
			elif Input.is_action_just_released(dir):
				last_dir_release_times[i] = current_time;
				
			if Input.is_action_pressed(dir):
				InputMap.action_set_deadzone(dir, held);
			else:
				InputMap.action_set_deadzone(dir, normal);
				
		#tutoriallabel.text = str(Input.get_action_raw_strength("ui_up"));
			
	sounds_played_this_frame.clear();
	
	if (won):
		won_cooldown += delta;
	
	if (doing_replay and !replay_paused):
		replay_timer += delta;
		
	# handle current music volume
	var value = save_file["music_volume"];
	music_speaker.volume_db = value + music_discount;
	if fadeout_timer < fadeout_timer_max:
		fadeout_timer += delta;
		if (fadeout_timer >= fadeout_timer_max):
			play_next_song();
		else:
			music_speaker.volume_db = music_speaker.volume_db - 30*(fadeout_timer/fadeout_timer_max);
		
	# duck when a fanfare is playing. this might need tweaking...
	var new_fanfare_duck_db = 0;
	if (lost_speaker.playing and lost_speaker.volume_db > -30):
		new_fanfare_duck_db += lost_speaker.volume_db + 30;
	if (won_speaker.playing and won_speaker.volume_db > -30):
		new_fanfare_duck_db += won_speaker.volume_db + 10; # try ducking less for won
	if (new_fanfare_duck_db > 0):
		fanfare_duck_db = new_fanfare_duck_db;
	else:
		fanfare_duck_db -= delta*100;
	if (fanfare_duck_db < 0):
		fanfare_duck_db = 0;
	music_speaker.volume_db = music_speaker.volume_db - fanfare_duck_db;
		
	if (sky_timer < sky_timer_max):
		sky_timer += delta;
		if (sky_timer > sky_timer_max):
			sky_timer = sky_timer_max;
		# rgb lerp (I tried hsv lerp but the hue changing feels super nonlinear)
		var current_r = lerp(old_sky.r, target_sky.r, sky_timer/sky_timer_max);
		var current_g = lerp(old_sky.g, target_sky.g, sky_timer/sky_timer_max);
		var current_b = lerp(old_sky.b, target_sky.b, sky_timer/sky_timer_max);
		current_sky = Color(current_r, current_g, current_b);
		VisualServer.set_default_clear_color(current_sky);
		
	if (fuzz_timer_max > 0):
		fuzz_timer += delta;
		if (fuzz_timer < fuzz_timer_max):
			Static.visible = true;
			Static.modulate = Color(1, 1, 1, 1-(fuzz_timer/fuzz_timer_max));
		else:
			Static.visible = false;
			Static.modulate = Color(1, 1, 1, 1);
		
	if ui_stack.size() == 0:
		var dir = Vector2.ZERO;
		
		if (doing_replay and replay_timer > next_replay):
			do_one_replay_turn();
			update_info_labels();
		
		if (won and Input.is_action_just_pressed("ui_accept")):
			end_replay();
			if (in_insight_level):
				gain_insight();
			elif last_level_of_section():
				level_select();
			else:
				load_level(1);
		elif (Input.is_action_just_pressed("escape")):
			#end_replay(); #done in escape();
			escape();
		elif (Input.is_action_just_pressed("previous_level")
		and (!using_controller or ((!doing_replay or won) and (!won or won_cooldown > 0.5)))):
			if (!using_controller or won or lost or meta_turn <= 0):
				end_replay();
				load_level(-1);
			else:
				play_sound("bump");
		elif (Input.is_action_just_pressed("next_level")
		and (!using_controller or ((!doing_replay or won) and (!won or won_cooldown > 0.5)))):
			if (!using_controller or won or lost or meta_turn <= 0):
				end_replay();
				load_level(1);
			else:
				play_sound("bump");
		elif (Input.is_action_just_pressed("mute")):
			toggle_mute();
		elif (doing_replay and Input.is_action_just_pressed("replay_back1")):
			replay_advance_turn(-1);
		elif (doing_replay and Input.is_action_just_pressed("replay_fwd1")):
			replay_advance_turn(1);
		elif (doing_replay and Input.is_action_just_pressed("replay_pause")):
			pause_replay();
		elif (Input.is_action_just_pressed("speedup_replay")):
			var old_replay_interval = replay_interval;
			if (Input.is_action_pressed("shift")):
				replay_interval = 0.015;
			else:
				replay_interval *= (2.0/3.0);
			replayspeedsliderset = true;
			replayspeedslider.value = 100 - floor(replay_interval * 100);
			replayspeedsliderset = false;
			adjust_next_replay_time(old_replay_interval);
			update_info_labels();
		elif (Input.is_action_just_pressed("slowdown_replay")):
			var old_replay_interval = replay_interval;
			if (Input.is_action_pressed("shift")):
				replay_interval = 0.5;
			elif replay_interval < 0.015:
				replay_interval = 0.015;
			else:
				replay_interval /= (2.0/3.0);
			if (replay_interval > 2.0):
				replay_interval = 2.0;
			replayspeedsliderset = true;
			replayspeedslider.value = 100 - floor(replay_interval * 100);
			replayspeedsliderset = false;
			adjust_next_replay_time(old_replay_interval);
			update_info_labels();
		elif (Input.is_action_just_pressed("start_saved_replay")):
			if (Input.is_action_pressed("shift")):
				# must be kept in sync with Menu
				if (won):
					if (!save_file["levels"].has(level_name)):
						save_file["levels"][level_name] = {};
					save_file["levels"][level_name]["replay"] = annotate_replay(user_replay);
					save_game();
					floating_text("Shift+F11: Replay force saved!");
			else:
				# must be kept in sync with Menu
				start_saved_replay();
				update_info_labels();
		elif (Input.is_action_just_pressed("start_replay")):
			# must be kept in sync with Menu
			authors_replay();
			update_info_labels();
		elif (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("copy")):
			if (Input.is_action_pressed("shift")):
				copy_level();
			else:
				# must be kept in sync with Menu
				OS.set_clipboard(annotate_replay(user_replay));
				floating_text("Ctrl+C: Replay copied");
		elif (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("paste")):
			# must be kept in sync with Menu
			if (clipboard_contains_level()):
				paste_level();
			else:
				replay_from_clipboard();
		elif (Input.is_action_just_pressed("character_undo")):
			end_replay();
			character_undo();
			update_info_labels();
		elif (Input.is_action_just_pressed("meta_undo")):
			end_replay();
			meta_undo();
			update_info_labels();
		elif (Input.is_action_just_pressed("restart")):
			# must be kept in sync with Menu "restart"
			end_replay();
			restart();
			update_info_labels();
		elif (Input.is_action_just_pressed("level_select")):
			level_select();
		elif (Input.is_action_just_pressed("gain_insight")):
			end_replay();
			gain_insight();
		elif (Input.is_action_just_pressed("character_switch")):
			end_replay();
			character_switch();
			update_info_labels();
		elif (!get_debounced):
			if (Input.is_action_just_pressed("ui_left")):
				dir = Vector2.LEFT;
			if (Input.is_action_just_pressed("ui_right")):
				dir = Vector2.RIGHT;
			if (Input.is_action_just_pressed("ui_up")):
				dir = Vector2.UP;
			if (Input.is_action_just_pressed("ui_down")):
				dir = Vector2.DOWN;
				
			if dir != Vector2.ZERO:
				end_replay();
				character_move(dir);
				update_info_labels();
		
	update_targeter();
	update_animation_server();
