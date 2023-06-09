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
onready var winlabel : Label = levelscene.get_node("WinLabel");
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
}

enum TimeColour {
	Gray,
	Purple,
	Magenta,
	Red,
	Blue,
	Green,
	Void,
	Cyan,
	Orange,
	Yellow,
}

enum Greenness {
	Mundane,
	Green,
	Void
}

# attempted performance optimization - have an enum of all tile ids and assert at startup that they're right
# order SEEMS to be the same as in DefaultTiles
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
}

# information about the level
var chapter = 0
var level_in_chapter = 0;
var level_is_extra = false;
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

# information about the actors and their state
var heavy_actor : Actor = null
var light_actor : Actor = null
var actors = []
var goals = []
var void_cuckoo_clocks = [];
var void_cuckoo_clock_timer = 0;
var void_cuckoo_clock_timer_max = 1;
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

# save file, ooo!
var save_file = {}
var puzzles_completed = 0;

# song-and-dance state
var sounds = {}
var speakers = [];
var music_speaker = null;
var lost_speaker = null;
var lost_speaker_volume_tween;
var sounds_played_this_frame = {};
var muted = false;
var won = false;
var lost = false;
var lost_void = false;
var won_fade_started = false;
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
var replay_turn = 0;
var replay_interval = 0.5;
var next_replay = -1;
var unit_test_mode = false;
var meta_undo_a_restart_mode = false;

# list of levels in the game
var level_list = [];
var level_names = [];
var chapter_names = [];
var chapter_skies = [];
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
	level_number = save_file["level_number"];

func _ready() -> void:
	# Call once when the game is booted up.
	menubutton.connect("pressed", self, "escape");
	levelstar.scale = Vector2(1.0/6.0, 1.0/6.0);
	load_game();
	if (save_file.has("puzzle_checkerboard")):
		checkerboard.visible = true;
	setup_resolution();
	prepare_audio();
	setup_volume();
	setup_animation_speed();
	initialize_level_list();
	tile_changes();
	initialize_shaders();
	if (OS.is_debug_build()):
		assert_tile_enum();
	
	# Load the first map.
	load_level(0);
	ready_done = true;
	
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
	
func setup_animation_speed() -> void:
	if (save_file.has("animation_speed")):
		var value = save_file["animation_speed"];
		Engine.time_scale = value;
		
func initialize_shaders() -> void:
	#each thing that uses a shader has to compile the first time it's used, so... use it now!
	var afterimage = preload("Afterimage.tscn").instance();
	afterimage.initialize(targeter, light_color);
	levelscene.call_deferred("add_child", afterimage);
	afterimage.position = Vector2(-99, -99);
	pass
	# TODO: compile the Static shader by flicking it on for a single frame?
	
func tile_changes() -> void:
	# hide light and heavy goal sprites when in-game and not in-editor
	terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, null);
	terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, null);
	
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
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(0);
	chapter_skies.push_back(Color("#223C52"));
	level_list.push_back(preload("res://levels/MeetHeavy.tscn"));
	level_list.push_back(preload("res://levels/MeetLight.tscn"));
	level_list.push_back(preload("res://levels/Initiation.tscn"));
	level_list.push_back(preload("res://levels/Orientation.tscn"));
	level_list.push_back(preload("res://levels/PushingIt.tscn"));
	level_list.push_back(preload("res://levels/Wall.tscn"));
	level_list.push_back(preload("res://levels/Tall.tscn"));
	level_list.push_back(preload("res://levels/Braid.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPit.tscn"));	
	level_list.push_back(preload("res://levels/Pachinko.tscn"));
	level_list.push_back(preload("res://levels/CallACab.tscn"));
	level_list.push_back(preload("res://levels/CarryingIt.tscn"));
	level_list.push_back(preload("res://levels/Roommates.tscn"));
	level_list.push_back(preload("res://levels/Downhill.tscn"));
	level_list.push_back(preload("res://levels/Uphill.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_list.push_back(preload("res://levels/Spelunking.tscn"));
	level_list.push_back(preload("res://levels/ShouldveCalledaCab.tscn"));
	level_list.push_back(preload("res://levels/UncabYourself.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPitEx.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPitEx2.tscn"));
	level_list.push_back(preload("res://levels/RoommatesEx.tscn"));
	
	chapter_names.push_back("Hazards");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(8);
	chapter_skies.push_back(Color("#512E22"));
	level_list.push_back(preload("res://levels/Spikes.tscn"));
	level_list.push_back(preload("res://levels/SnakePit.tscn"));
	level_list.push_back(preload("res://levels/TheSpikePit.tscn"));
	level_list.push_back(preload("res://levels/TrustFall.tscn"));
	level_list.push_back(preload("res://levels/Campfire.tscn"));
	level_list.push_back(preload("res://levels/SpontaneousCombustion.tscn"));
	level_list.push_back(preload("res://levels/Firewall.tscn"));
	level_list.push_back(preload("res://levels/Hell.tscn"));
	level_list.push_back(preload("res://levels/No.tscn"));
	level_list.push_back(preload("res://levels/TheBoundlessSky.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(16);
	level_list.push_back(preload("res://levels/SnakePitEx.tscn"));
	level_list.push_back(preload("res://levels/SnakePitEx2.tscn"));
	level_list.push_back(preload("res://levels/TheSpikePitEx.tscn"));
	level_list.push_back(preload("res://levels/TrustFallEx.tscn"));
	level_list.push_back(preload("res://levels/FirewallEx.tscn"));
	level_list.push_back(preload("res://levels/FirewallEx2.tscn"));
	level_list.push_back(preload("res://levels/HellEx.tscn"));
	level_list.push_back(preload("res://levels/FireInTheSky.tscn"));
	level_list.push_back(preload("res://levels/FireInTheSkyExLuKAs.tscn"));
	level_list.push_back(preload("res://levels/FireInTheSkyEx.tscn"));
	level_list.push_back(preload("res://levels/OrbitalDrop.tscn"));
	
	chapter_names.push_back("Secrets of Space-Time");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(16);
	chapter_skies.push_back(Color("#062138"));
	level_list.push_back(preload("res://levels/HeavyMovingService.tscn"));
	level_list.push_back(preload("res://levels/LightMovingService.tscn"));
	level_list.push_back(preload("res://levels/LightMovingServiceEx.tscn"));
	level_list.push_back(preload("res://levels/InvisibleBridgeL.tscn"));
	level_list.push_back(preload("res://levels/InvisibleBridge.tscn"));
	level_list.push_back(preload("res://levels/Acrobatics.tscn"));
	level_list.push_back(preload("res://levels/AcrobaticsEx.tscn"));
	level_list.push_back(preload("res://levels/GraduationPure.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(24);
	level_list.push_back(preload("res://levels/TheFirstPitEx3.tscn"));
	level_list.push_back(preload("res://levels/RoughTerrain.tscn"));
	level_list.push_back(preload("res://levels/TheBoundlessSkyEx.tscn"));
	level_list.push_back(preload("res://levels/TheBoundlessSkyEx2.tscn"));
	level_list.push_back(preload("res://levels/AcrobatsEscape.tscn"));
	level_list.push_back(preload("res://levels/AcrobatsEscapeEx.tscn"));
	level_list.push_back(preload("res://levels/AcrobatsEscapeEx2.tscn"));
	
	chapter_names.push_back("One-Ways");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(16);
	chapter_skies.push_back(Color("#1C3D19"));
	level_list.push_back(preload("res://levels/OneWays.tscn"));
	level_list.push_back(preload("res://levels/PeekaBoo.tscn"));
	level_list.push_back(preload("res://levels/CoyoteTime.tscn"));
	level_list.push_back(preload("res://levels/SecurityDoor.tscn"));
	level_list.push_back(preload("res://levels/Jail.tscn"));
	level_list.push_back(preload("res://levels/Upstream.tscn"));
	level_list.push_back(preload("res://levels/Downstream.tscn"));
	level_list.push_back(preload("res://levels/TheOneWayPit.tscn"));
	level_list.push_back(preload("res://levels/EventHorizon.tscn"));
	level_list.push_back(preload("res://levels/PushingItSequel.tscn"));
	level_list.push_back(preload("res://levels/Daredevils.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(24);
	level_list.push_back(preload("res://levels/SecurityDoorEx.tscn"));
	level_list.push_back(preload("res://levels/SecurityDoorEx2.tscn"));
	level_list.push_back(preload("res://levels/JailEx.tscn"));
	level_list.push_back(preload("res://levels/JailEx2.tscn"));
	level_list.push_back(preload("res://levels/TheOneWayPitEx.tscn"));
	level_list.push_back(preload("res://levels/TheSpikePitEx2.tscn"));
	level_list.push_back(preload("res://levels/InvisibleBridgeEx.tscn"));
	level_list.push_back(preload("res://levels/InvisibleBridgeEx2.tscn"));
	level_list.push_back(preload("res://levels/HawkingRadiation.tscn"));
	level_list.push_back(preload("res://levels/GraduationSpicy.tscn"));
	level_list.push_back(preload("res://levels/Heaven.tscn"));
	
	chapter_names.push_back("Trap Doors and Ladders");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(24);
	chapter_skies.push_back(Color("#3B3F1A"));
	level_list.push_back(preload("res://levels/Down.tscn"));
	level_list.push_back(preload("res://levels/LadderWorld.tscn"));
	level_list.push_back(preload("res://levels/LadderLattice.tscn"));
	level_list.push_back(preload("res://levels/StairwayToHell.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinet.tscn"));
	level_list.push_back(preload("res://levels/Mole.tscn"));
	level_list.push_back(preload("res://levels/Dive.tscn"))
	level_list.push_back(preload("res://levels/DoubleJump.tscn"));
	level_list.push_back(preload("res://levels/Firefighters.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(32);
	level_list.push_back(preload("res://levels/FirewallEx3.tscn"));
	level_list.push_back(preload("res://levels/LadderWorldEx.tscn"));
	level_list.push_back(preload("res://levels/LadderLatticeEx.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinetEx.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinetEx2.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinetEx3.tscn"));
	level_list.push_back(preload("res://levels/Bonfire.tscn"));
	level_list.push_back(preload("res://levels/BonfireEx.tscn"));
	level_list.push_back(preload("res://levels/BonfireEx2.tscn"));
	level_list.push_back(preload("res://levels/DivingBoard.tscn"));
	
	chapter_names.push_back("Iron Crates");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(32);
	chapter_skies.push_back(Color("#424947"));
	level_list.push_back(preload("res://levels/IronCrates.tscn"));
	level_list.push_back(preload("res://levels/CrateExpectations.tscn"));
	level_list.push_back(preload("res://levels/Bridge.tscn"));
	level_list.push_back(preload("res://levels/Weakness.tscn"));
	level_list.push_back(preload("res://levels/SteppingStool.tscn"));
	level_list.push_back(preload("res://levels/OverDestination.tscn"));
	level_list.push_back(preload("res://levels/ThirdRoommate.tscn"));
	level_list.push_back(preload("res://levels/Sokoban.tscn"));
	level_list.push_back(preload("res://levels/OneAtATime.tscn"));
	level_list.push_back(preload("res://levels/PushingItCrate.tscn"));
	level_list.push_back(preload("res://levels/SnakeChute.tscn"));
	level_list.push_back(preload("res://levels/TheCratePit.tscn"));
	level_list.push_back(preload("res://levels/Landfill.tscn"));
	level_list.push_back(preload("res://levels/PressEveryKey.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(40);
	level_list.push_back(preload("res://levels/Levitation.tscn"));
	level_list.push_back(preload("res://levels/WeaknessEx.tscn"));
	level_list.push_back(preload("res://levels/SteppingStoolEx.tscn"));
	level_list.push_back(preload("res://levels/OverDestinationEx.tscn"));
	level_list.push_back(preload("res://levels/ThirdRoommateEx.tscn"));
	level_list.push_back(preload("res://levels/TheCratePitEx.tscn"));
	level_list.push_back(preload("res://levels/TheCratePitEx2.tscn"));
	level_list.push_back(preload("res://levels/QuantumEntanglement.tscn"));
	level_list.push_back(preload("res://levels/LandfillEx.tscn"));
	level_list.push_back(preload("res://levels/TheTower.tscn"));
	
	chapter_names.push_back("There Are Many Colours");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(40);
	chapter_skies.push_back(Color("#37294F"));
	level_list.push_back(preload("res://levels/RedAndBlue.tscn"));
	level_list.push_back(preload("res://levels/LevelNotFound.tscn"));
	level_list.push_back(preload("res://levels/DownhillRedBlue.tscn"));
	level_list.push_back(preload("res://levels/LunarGravity.tscn"));
	level_list.push_back(preload("res://levels/BlueAndRed.tscn"));
	level_list.push_back(preload("res://levels/TheRedPit.tscn"));
	level_list.push_back(preload("res://levels/TheBluePit.tscn"));
	level_list.push_back(preload("res://levels/TheMagentaPit.tscn"));
	level_list.push_back(preload("res://levels/TheGrayPit.tscn"));
	level_list.push_back(preload("res://levels/PaperPlanes.tscn"));
	level_list.push_back(preload("res://levels/TimelessBridge.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(48);
	level_list.push_back(preload("res://levels/LevelNotFoundEx.tscn"));
	level_list.push_back(preload("res://levels/LevelNotFoundEx2.tscn"));
	level_list.push_back(preload("res://levels/Freedom.tscn"));
	level_list.push_back(preload("res://levels/BlueAndRedEx.tscn"));
	level_list.push_back(preload("res://levels/BlueAndRedEx2.tscn"));
	level_list.push_back(preload("res://levels/PaperPlanesEx.tscn"));
	level_list.push_back(preload("res://levels/TimelessBridgeEx.tscn"));
	level_list.push_back(preload("res://levels/LevitationColours.tscn"));
	level_list.push_back(preload("res://levels/Towerplex.tscn"));
	level_list.push_back(preload("res://levels/TheMagentaPitEx.tscn"));
	
	chapter_names.push_back("Change");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(48);
	chapter_skies.push_back(Color("#446570"));
	level_list.push_back(preload("res://levels/Ahhh.tscn"));
	level_list.push_back(preload("res://levels/Eeep.tscn"));
	level_list.push_back(preload("res://levels/DoubleGlazed.tscn"));
	level_list.push_back(preload("res://levels/LetMeIn.tscn"));
	level_list.push_back(preload("res://levels/Interleave.tscn"));
	level_list.push_back(preload("res://levels/SpelunkingGlass.tscn"));
	level_list.push_back(preload("res://levels/LadderWorldGlass.tscn"));
	level_list.push_back(preload("res://levels/TheGlassPit.tscn"));
	level_list.push_back(preload("res://levels/DemolitionSquad.tscn"));
	level_list.push_back(preload("res://levels/Aquarium.tscn"));
	level_list.push_back(preload("res://levels/Deconstruct.tscn"));
	level_list.push_back(preload("res://levels/TreasureHunt.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(56);
	level_list.push_back(preload("res://levels/LetMeInEx.tscn"));
	level_list.push_back(preload("res://levels/HeavyMovingServiceGlass.tscn"));
	level_list.push_back(preload("res://levels/DoubleGlazedEx.tscn"));
	level_list.push_back(preload("res://levels/SpelunkingGlassEx.tscn"));
	level_list.push_back(preload("res://levels/DemolitionSquadEx.tscn"));
	level_list.push_back(preload("res://levels/TheGlassPitEx.tscn"));
	level_list.push_back(preload("res://levels/CampfireGlass.tscn"));
	level_list.push_back(preload("res://levels/CampfireGlassEx.tscn"));
	level_list.push_back(preload("res://levels/SpelunkingGlassEx2.tscn"));
	level_list.push_back(preload("res://levels/LadderWorldGlassEx.tscn"));
	
	chapter_names.push_back("Permanence");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(56);
	chapter_skies.push_back(Color("#14492A"));
	level_list.push_back(preload("res://levels/HelpYourself.tscn"));
	level_list.push_back(preload("res://levels/SpikesGreen.tscn"));
	level_list.push_back(preload("res://levels/SoBroken.tscn"));
	level_list.push_back(preload("res://levels/CampfireGreen.tscn"));
	level_list.push_back(preload("res://levels/SpontaneousCombustionGreen.tscn"));
	level_list.push_back(preload("res://levels/FirewallGreen.tscn"));
	level_list.push_back(preload("res://levels/GreenGlass.tscn"));
	level_list.push_back(preload("res://levels/TheFuture.tscn"));
	level_list.push_back(preload("res://levels/FasterThanLight.tscn"));
	level_list.push_back(preload("res://levels/Mundane.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(64);
	level_list.push_back(preload("res://levels/LightHurtingService.tscn"));
	level_list.push_back(preload("res://levels/LightHurtingServiceEx.tscn"));
	level_list.push_back(preload("res://levels/LightHurtingServiceEx2.tscn"));
	level_list.push_back(preload("res://levels/GreenGrass.tscn"));
	level_list.push_back(preload("res://levels/HelpYourselfEx.tscn"));
	level_list.push_back(preload("res://levels/SpikesGreenEx.tscn"));
	level_list.push_back(preload("res://levels/CampfireGreenEx.tscn"));
	level_list.push_back(preload("res://levels/CampfireGreenEx2.tscn"));
	level_list.push_back(preload("res://levels/FirewallGreenEx.tscn"));
	level_list.push_back(preload("res://levels/Skip.tscn"));
	level_list.push_back(preload("res://levels/LeadPlanes.tscn"))
	level_list.push_back(preload("res://levels/Airdodging.tscn"));
	level_list.push_back(preload("res://levels/DragonsGate.tscn"))
	
	chapter_names.push_back("Exotic Matter");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(64);
	chapter_skies.push_back(Color("#351731"));
	level_list.push_back(preload("res://levels/TheFuzz.tscn"));
	level_list.push_back(preload("res://levels/DoubleFuzz.tscn"));
	level_list.push_back(preload("res://levels/PushingItFurther.tscn"));
	level_list.push_back(preload("res://levels/Elevator.tscn"));
	level_list.push_back(preload("res://levels/FuzzyTrick.tscn"));
	level_list.push_back(preload("res://levels/LimitedUndo.tscn"));
	level_list.push_back(preload("res://levels/UphillLimited.tscn"));
	level_list.push_back(preload("res://levels/TimeStop.tscn"));
	level_list.push_back(preload("res://levels/KingCrimson.tscn"));
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(72);
	level_list.push_back(preload("res://levels/ElevatorEx.tscn"));
	level_list.push_back(preload("res://levels/ImaginaryMoves.tscn"));
	level_list.push_back(preload("res://levels/DontLookDown.tscn"));
	level_list.push_back(preload("res://levels/LeadBalloon.tscn"));
	level_list.push_back(preload("res://levels/Durability.tscn"));
	level_list.push_back(preload("res://levels/UnfathomableGlass.tscn"));
	level_list.push_back(preload("res://levels/PushingItFurtherEx.tscn"));
	level_list.push_back(preload("res://levels/LimitedUndoEx.tscn"));
	level_list.push_back(preload("res://levels/LimitedUndoEx2.tscn"));
	level_list.push_back(preload("res://levels/KingCrimsonEx.tscn"));
	
	chapter_names.push_back("Time Crystals");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(72);
	chapter_skies.push_back(Color("#2A1F82"));
	level_list.push_back(preload("res://levels/Growth.tscn"));
	level_list.push_back(preload("res://levels/Delivery.tscn"));
	level_list.push_back(preload("res://levels/Blockage.tscn"));
	level_list.push_back(preload("res://levels/Wither.tscn"));
	level_list.push_back(preload("res://levels/Bounce.tscn"));
	level_list.push_back(preload("res://levels/Pathology.tscn"));
	level_list.push_back(preload("res://levels/Reflections.tscn"));
	level_list.push_back(preload("res://levels/Forgetfulness.tscn"));
	level_list.push_back(preload("res://levels/Remembrance.tscn"));
	level_list.push_back(preload("res://levels/Conservation.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(80);
	level_list.push_back(preload("res://levels/Elementary.tscn"));
	level_list.push_back(preload("res://levels/BlockageEx.tscn"));
	level_list.push_back(preload("res://levels/Smuggler.tscn"));
	level_list.push_back(preload("res://levels/SmugglerEx.tscn"));
	level_list.push_back(preload("res://levels/Frangible.tscn"));
	level_list.push_back(preload("res://levels/Switcheroo.tscn"));
	level_list.push_back(preload("res://levels/SwitcherooEx.tscn"));
	level_list.push_back(preload("res://levels/StairwayToHeaven.tscn"));
	
	chapter_names.push_back("Deadline");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(80);
	chapter_skies.push_back(Color("#2D0E07"));
	chapter_replacements[chapter_names.size() - 1] = "Ω";
	level_list.push_back(preload("res://levels/CuckooClock.tscn"));
	level_list.push_back(preload("res://levels/ItDoesntAddUp.tscn"));
	level_list.push_back(preload("res://levels/TimeZones.tscn"));
	level_list.push_back(preload("res://levels/GreenCuckoo1.tscn"));
	level_list.push_back(preload("res://levels/GreenCuckoo2.tscn"));
	level_list.push_back(preload("res://levels/DST.tscn"));
	level_list.push_back(preload("res://levels/EngineRoom.tscn"));
	level_list.push_back(preload("res://levels/TheShroud.tscn"));
	level_list.push_back(preload("res://levels/MidnightParkour.tscn"));
	level_list.push_back(preload("res://levels/Rewind.tscn"));
	level_list.push_back(preload("res://levels/ControlledDemolition.tscn"));
	level_list.push_back(preload("res://levels/Cascade.tscn"));
	#level_replacements[level_list.size()] = "Ω";
	#level_list.push_back(preload("res://levels/AWayIn.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(88);
	level_list.push_back(preload("res://levels/HotPotato.tscn"));
	level_list.push_back(preload("res://levels/LevelNotFoundEx3.tscn"));
	level_list.push_back(preload("res://levels/AnnoyingRacket.tscn"));
	level_list.push_back(preload("res://levels/Rink.tscn"));
	level_list.push_back(preload("res://levels/Collectathon.tscn"));
	level_list.push_back(preload("res://levels/Hassle.tscn"));
	level_list.push_back(preload("res://levels/ControlledDemolitionEx.tscn"));
	level_list.push_back(preload("res://levels/ControlledDemolitionEx2.tscn"));
	level_list.push_back(preload("res://levels/Permify.tscn"));
	level_list.push_back(preload("res://levels/CelestialNavigation.tscn"));
	#level_replacements[level_list.size()] = "Ω";
	#level_list.push_back(preload("res://levels/ChronoLabReactor.tscn"));
	
	chapter_names.push_back("Victory Lap");
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_standard_unlock_requirements.push_back(level_list.size());
	chapter_skies.push_back(Color("#223C52"));
	chapter_replacements[chapter_names.size() - 1] = "-1";
	level_list.push_back(preload("res://levels/RoommatesExL2.tscn"));
	level_list.push_back(preload("res://levels/SpelunkingL2.tscn"));
	level_list.push_back(preload("res://levels/UphillL2.tscn"));
	level_list.push_back(preload("res://levels/DownhillL2.tscn"));
	level_list.push_back(preload("res://levels/RoommatesL2.tscn"));
	level_list.push_back(preload("res://levels/RoommatesL2Ex.tscn"));
	level_list.push_back(preload("res://levels/CarryingItL2.tscn"));
	level_list.push_back(preload("res://levels/CallACabL2.tscn"));
	level_list.push_back(preload("res://levels/TheoryOfEverythingA.tscn"));
	level_list.push_back(preload("res://levels/TheoryOfEverythingB.tscn"));
	level_list.push_back(preload("res://levels/PachinkoL2.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPitL2.tscn"));
	level_list.push_back(preload("res://levels/BraidL2.tscn"));
	level_list.push_back(preload("res://levels/BraidL2Ex.tscn"));
	level_list.push_back(preload("res://levels/TallL2.tscn"));
	level_list.push_back(preload("res://levels/TallL2Ex.tscn"));
	level_list.push_back(preload("res://levels/TallL2Ex2.tscn"));
	level_list.push_back(preload("res://levels/WallL2.tscn"));
	level_list.push_back(preload("res://levels/WallL2Ex.tscn"));
	level_list.push_back(preload("res://levels/PushingItL2.tscn"));
	level_list.push_back(preload("res://levels/OrientationL2.tscn"));
	level_list.push_back(preload("res://levels/OrientationL2Ex.tscn"));
	level_list.push_back(preload("res://levels/OrientationL2Ex2.tscn"));
	chapter_advanced_starting_levels.push_back(level_list.size());
	chapter_advanced_unlock_requirements.push_back(level_list.size());
	# level_list.push_back(preload("res://levels/Joke.tscn"));
	
	# sentinel to make overflow checks easy
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_advanced_starting_levels.push_back(level_list.size());
	
	#needs keys/locks
	#level_list.push_back(preload("res://levels/InsightDontPushIt.tscn"));
	#level_list.push_back(preload("res://levels/InsightDidntPushIt.tscn"));
	
	for level_prototype in level_list:
		var level = level_prototype.instance();
		var level_name = level.get_node("LevelInfo").level_name;
		level_names.push_back(level_name);
		if save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]:
			puzzles_completed += 1;
		level.queue_free();

func ready_map() -> void:
	won = false;
	end_lose();
	lost_speaker.stop();
	for actor in actors:
		actor.queue_free();
	actors.clear();
	for goal in goals:
		goal.queue_free();
	goals.clear();
	for ghost in ghosts:
		ghost.queue_free();
	ghosts.clear();
	void_cuckoo_clocks.clear();
	void_cuckoo_clock_timer = 0;
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
	if (level_number == 1):
		heavy_selected = false;
	user_replay = "";
	
	var level_info = terrainmap.get_node("LevelInfo");
	level_name = level_info.level_name;
	level_author = level_info.level_author;
	level_replay = level_info.level_replay;
	if ("$" in level_replay):
		var level_replay_parts = level_replay.split("$");
		level_replay = level_replay_parts[level_replay_parts.size()-1];
	heavy_max_moves = level_info.heavy_max_moves;
	light_max_moves = level_info.light_max_moves;
	clock_turns = level_info.clock_turns;
	calculate_map_size();
	make_actors();
	
	finish_animations(Chrono.TIMELESS);
	update_info_labels();
	check_won();
	
	initialize_timeline_viewers();
	ready_tutorial();
	
func ready_tutorial() -> void:
	if level_number > 4:
		metainfolabel.visible = true;
	else:
		metainfolabel.visible = false;
		
	if level_number > 7:
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
		if (level_number == 0 or level_number == 1):
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
		elif (level_number == 7):
			tutoriallabel.rect_position.y -= 48;
			tutoriallabel.bbcode_text = "Esc: Level Select/Controls/Settings";
		tutoriallabel.bbcode_text = "[center]" + tutoriallabel.bbcode_text + "[/center]";
			
	if level_name == "Snake Pit":
		tutoriallabel.visible = true;
		tutoriallabel.rect_position = Vector2(0, 69);
		tutoriallabel.rect_position.y -= 24;
		tutoriallabel.bbcode_text = "[center]You can make Checkpoints by doing:\nCtrl+C: Copy Replay\nCtrl+V: Paste Replay[/center]";
	
func initialize_timeline_viewers() -> void:
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
	var heavy_extra_width = (heavy_max-1)/11;
	var light_extra_width = (light_max-1)/11;
	effective_width += max(0, heavy_extra_width);
	effective_width += max(0, light_extra_width);
	if (effective_width > 16):
		return;
		
	# calculation: the screen is 512 pixels wide. each cell is 24 pixels.
	# we want 24 pixels of leeway, then our timelines.
	var center = pixel_width/2;
	var left = center-map_x_max*24/2;
	var right = center+map_x_max*24/2;
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
			heavy_actor = make_actor("heavy", heavy_tile, true);
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
			light_actor = make_actor("light", light_tile, true);
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
	extract_actors(Tiles.IronCrate, "iron_crate", Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 99, false, Color(0.5, 0.5, 0.5, 1));
	extract_actors(Tiles.SteelCrate, "steel_crate", Heaviness.STEEL, Strength.WOODEN, Durability.PITS, 99, false, Color(0.25, 0.25, 0.25, 1));
	extract_actors(Tiles.PowerCrate, "power_crate", Heaviness.WOODEN, Strength.HEAVY, Durability.FIRE, 99, false, Color(1, 0, 0.86, 1));
	extract_actors(Tiles.WoodenCrate, "wooden_crate", Heaviness.WOODEN, Strength.WOODEN, Durability.SPIKES, 99, false, Color(0.5, 0.25, 0, 1));
	
	# cuckoo clocks
	extract_actors(Tiles.CuckooClock, "cuckoo_clock", Heaviness.WOODEN, Strength.WOODEN, Durability.SPIKES, 1, false, Color("#AD8255"));
	
	# time crystals
	extract_actors(Tiles.TimeCrystalGreen, "time_crystal_green", Heaviness.CRYSTAL, Strength.CRYSTAL, Durability.NOTHING, 0, false, Color("#A9F05F"));
	extract_actors(Tiles.TimeCrystalMagenta, "time_crystal_magenta", Heaviness.CRYSTAL, Strength.CRYSTAL, Durability.NOTHING, 0, false, Color("#9966CC"));
	
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
		if actor.actorname == "cuckoo_clock":
			actor.set_ticks(int(clock_turns_array[i]));
			i += 1;
			if i >= clock_turns_array.size():
				return
	
func find_goals(layer: TileMap) -> void:
	var heavy_goal_tiles = layer.get_used_cells_by_id(Tiles.HeavyGoal);
	for tile in heavy_goal_tiles:
		var goal = Goal.new();
		goal.gamelogic = self;
		goal.actorname = "heavy_goal";
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
		goal.actorname = "light_goal";
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
	
func extract_actors(id: int, actorname: String, heaviness: int, strength: int, durability: int, fall_speed: int, climbs: bool, color: Color) -> void:
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
	
func find_colours() -> void:
	find_colour(Tiles.ColourRed, TimeColour.Red);
	find_colour(Tiles.ColourBlue, TimeColour.Blue);
	find_colour(Tiles.ColourMagenta, TimeColour.Magenta);
	find_colour(Tiles.ColourGray, TimeColour.Gray);
	find_colour(Tiles.ColourGreen, TimeColour.Green);
	find_colour(Tiles.ColourVoid, TimeColour.Void);
	find_colour(Tiles.ColourPurple, TimeColour.Purple);
	find_colour(Tiles.ColourCyan, TimeColour.Cyan);
	find_colour(Tiles.ColourOrange, TimeColour.Orange);
	find_colour(Tiles.ColourYellow, TimeColour.Yellow);
	
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
					if (actor.time_colour == TimeColour.Void and actor.actorname == "cuckoo_clock"):
						void_cuckoo_clocks.append(actor);
					actor.update_time_bubble();
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
		
func update_targeter() -> void:
	if (heavy_selected):
		targeter.position = heavy_actor.position + terrainmap.position;
	else:
		targeter.position = light_actor.position + terrainmap.position;
	
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
	sounds["bump"] = preload("res://sfx/bump.ogg");
	sounds["broken"] = preload("res://sfx/broken.ogg");
	sounds["fall"] = preload("res://sfx/fall.ogg");
	sounds["fuzz"] = preload("res://sfx/fuzz.ogg");
	sounds["greentimecrystal"] = preload("res://sfx/greentimecrystal.ogg");
	sounds["heavycoyote"] = preload("res://sfx/heavycoyote.ogg");
	sounds["heavyland"] = preload("res://sfx/heavyland.ogg");
	sounds["heavyuncoyote"] = preload("res://sfx/heavyuncoyote.ogg");
	sounds["heavyunland"] = preload("res://sfx/heavyunland.ogg");
	sounds["involuntarybump"] = preload("res://sfx/involuntarybump.ogg");
	sounds["lightcoyote"] = preload("res://sfx/lightcoyote.ogg");
	sounds["lightland"] = preload("res://sfx/lightland.ogg");
	sounds["lightuncoyote"] = preload("res://sfx/lightuncoyote.ogg");
	sounds["lightunland"] = preload("res://sfx/lightunland.ogg");
	sounds["lose"] = preload("res://sfx/lose.ogg");
	sounds["magentatimecrystal"] = preload("res://sfx/magentatimecrystal.ogg");
	sounds["metarestart"] = preload("res://sfx/metarestart.ogg");
	sounds["metaundo"] = preload("res://sfx/metaundo.ogg");
	sounds["restart"] = preload("res://sfx/restart.ogg");
	sounds["push"] = preload("res://sfx/push.ogg");
	sounds["shatter"] = preload("res://sfx/shatter.ogg");
	sounds["shroud"] = preload("res://sfx/shroud.ogg");
	sounds["step"] = preload("res://sfx/step.ogg");
	sounds["switch"] = preload("res://sfx/switch.ogg");
	sounds["tick"] = preload("res://sfx/tick.ogg");
	sounds["timesup"] = preload("res://sfx/timesup.ogg");
	sounds["unbroken"] = preload("res://sfx/unbroken.ogg");
	sounds["undo"] = preload("res://sfx/undo.ogg");
	sounds["unfall"] = preload("res://sfx/unfall.ogg");
	sounds["unpush"] = preload("res://sfx/unpush.ogg");
	sounds["unshatter"] = preload("res://sfx/unshatter.ogg");
	sounds["untick"] = preload("res://sfx/untick.ogg");
	sounds["winentwined"] = preload("res://sfx/winentwined.ogg");
	sounds["winbadtime"] = preload("res://sfx/winbadtime.ogg");
	
	for i in range (8):
		var speaker = AudioStreamPlayer.new();
		self.add_child(speaker);
		speakers.append(speaker);
	lost_speaker = AudioStreamPlayer.new();
	lost_speaker.stream = sounds["lose"];
	lost_speaker_volume_tween = Tween.new();
	self.add_child(lost_speaker_volume_tween);
	self.add_child(lost_speaker);
	music_speaker = AudioStreamPlayer.new();
	self.add_child(music_speaker);

func fade_in_lost():
	winlabel.visible = true;
	adjust_winlabel();
	call_deferred("adjust_winlabel");
	Shade.on = true;
	
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	var db = save_file["music_volume"];
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

func toggle_mute() -> void:
	muted = !muted;
	cut_sound();

func make_actor(actorname: String, pos: Vector2, is_character: bool, chrono: int = Chrono.TIMELESS) -> Actor:
	var actor = Actor.new();
	# do this before update_goal_lock()
	actors.append(actor);
	actor.actorname = actorname;
	if actor.actorname == "time_crystal_green" or actor.actorname == "time_crystal_magenta":
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
				if actor.actorname == "heavy" and terrain.has(Tiles.HeavyGoal):
					for goal in goals:
						if goal.actorname == "heavy_goal" and !goal.dinged and goal.pos == actor.pos:
							set_actor_var(goal, "dinged", true, chrono);
				if actor.actorname == "light" and terrain.has(Tiles.LightGoal):
					for goal in goals:
						if goal.actorname == "light_goal" and !goal.dinged and goal.pos == actor.pos:
							set_actor_var(goal, "dinged", true, chrono);
				if actor.actorname == "heavy" and old_terrain.has(Tiles.HeavyGoal):
					for goal in goals:
						if goal.actorname == "heavy_goal" and goal.dinged and goal.pos != actor.pos:
							set_actor_var(goal, "dinged", false, chrono);
				if actor.actorname == "light" and old_terrain.has(Tiles.LightGoal):
					for goal in goals:
						if goal.actorname == "light_goal" and goal.dinged and goal.pos != actor.pos:
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
		#(AD15: Non-broken time crystals are sticky toppable! In fact, Heavy can PUSH them upwards thanks to some special logic elsewhere :D)
		#(FIX: Broken time crystals can't be sticky top'd because they're basically not things
		if actor.actorname == "heavy" and chrono == Chrono.MOVE and dir.y >= 0:
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
		if pushers_list.size() > 0 and actor.actorname == "light":
			add_to_animation_server(actor, [Animation.fluster]);
		if (!hypothetical):
			# involuntary bump sfx
			if (pushers_list.size() > 0 or is_retro):
				add_to_animation_server(actor, [Animation.sfx, "involuntarybump"]);
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
		if new_tile == Tiles.GlassBlock:
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

func current_tile_is_solid(actor: Actor, dir: Vector2, is_gravity: bool, is_retro: bool) -> bool:
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
			Tiles.GreenGlassBlock:
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
				result = no_if_true_yes_if_false(actor.actorname == "heavy");
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.NoLight:
				result = no_if_true_yes_if_false(actor.actorname == "light");
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
	if (chrono >= Chrono.META_UNDO):
		# assuming no bugs, if it was overlapping in the meta-past, then it must have been valid to reach then
		return Success.Yes;
	
	# handle solidity in our tile, solidity in the tile over, hazards/surprises in the tile over
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
			if actor.actorname == "light":
				strength_modifier = -1;
		pushers_list.append(actor);
		for actor_there in pushables_there:
			# Strength Rule
			# Modified by the Light Clumsiness Rule: Light's strength is lowered by 1 when it's in the middle of a multi-push.
			if !strength_check(actor.strength + strength_modifier, actor_there.heaviness) and !can_eat(actor_there, actor):
				pushers_list.pop_front();
				return Success.No;
		var result = Success.Yes;
		
		# logic to handle time crystals and actor stacks:
		#* for each pushable, hypothetically push-or-eat it.
		#* if any is No: return Success.No
		#* if any is Surprise: if !hypothetical, do all the surprises. then return Suprise.
		#* (if any is Yes): if !hypothetical, do all the push-or-eats, then return Yes
		
		# TODO: logic for wooden crates special moves, logic for keys
		
		var surprises = [];
		result = Success.Yes;
		for actor_there in pushables_there:
			if can_eat(actor, actor_there) or can_eat(actor_there, actor):
				continue;
			var actor_there_result = move_actor_relative(actor_there, dir, chrono, true, is_gravity, false, pushers_list);
			if actor_there_result == Success.No:
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
						if actor.actorname == "heavy" and !is_retro and dir == Vector2.UP:
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
		if eater.actorname == "cuckoo_clock" and !eater.broken:
			pass
		else:
			return false;
	# for now I've decided you can always eat a time crystal - it'll just break you if it's nega and you're at 0/0 turns
	# other options: push, eat but do nothing, eat and go into negative moves, lose (time paradox)
	return true;
	#if (eatee.actorname == "time_crystal_green"):
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
	if (eatee.actorname == "time_crystal_green"):
		if heavy_actor == eater:
			heavy_max_moves += 1;
			if (heavy_locked_turns.size() == 0):
				# raw: just add a turn to the end
				if (!heavy_actor.powered):
					set_actor_var(heavy_actor, "powered", true, Chrono.CHAR_UNDO);
				add_undo_event([Undo.heavy_green_time_crystal_raw], Chrono.CHAR_UNDO);
				add_to_animation_server(eater, [Animation.heavy_green_time_crystal_raw, eatee]);
			else:
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
				if (!light_actor.powered):
					set_actor_var(light_actor, "powered", true, Chrono.CHAR_UNDO);
				add_undo_event([Undo.light_green_time_crystal_raw], Chrono.CHAR_UNDO);
				add_to_animation_server(eater, [Animation.light_green_time_crystal_raw, eatee]);
			else:
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
		var just_locked = false;
		var turn_moved = -1;
		if (heavy_actor == eater):
			# Lose (Paradox)
			if (heavy_max_moves <= 0):
				set_actor_var(heavy_actor, "broken", true, Chrono.CHAR_UNDO);
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
			if (heavy_turn > 0 or just_locked):
				# if we have a slot to move: move it and decrement turn
				turn_moved = heavy_turn;
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
				set_actor_var(light_actor, "broken", true, Chrono.CHAR_UNDO);
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
			if (light_turn > 0 or just_locked):
				# if we have a slot to move: move it and decrement turn
				turn_moved = light_turn;
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
	actor.ticks += amount;
	if (actor.ticks == 0):
		if actor.actorname == "cuckoo_clock":
			# end the world
			lose("You didn't make it back to the Chrono Lab Reactor in time.", actor);
	add_undo_event([Undo.tick, actor, amount, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
	add_to_animation_server(actor, [Animation.tick, amount, animation_nonce]);

func lose(reason: String, suspect: Actor) -> void:
	lost = true;
	if (suspect != null and suspect.time_colour == TimeColour.Void):
		lost_void = true;
		winlabel.text = reason + "\n\nRestart to continue."
	else:
		lost_void = false;
		winlabel.text = reason + "\n\nMeta-Undo or Restart to continue."
	
func end_lose() -> void:
	lost = false;
	lost_speaker.stop();

func set_actor_var(actor: ActorBase, prop: String, value, chrono: int,
animation_nonce: int = -1, is_retro: bool = false, retro_old_value = null) -> void:
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
			if actor.actorname == "heavy":
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
			elif actor.actorname == "light":
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
		if prop == "broken":
			#check goal lock when a crystal breaks or unbreaks
			if (actor.is_crystal):
				update_goal_lock();
			
			var terrain = terrain_in_tile(actor.pos);
			if value == true:
				if (actor.actorname == "time_crystal_green"):
					add_to_animation_server(actor, [Animation.sfx, "greentimecrystal"])
				elif (actor.actorname == "time_crystal_magenta"):
					add_to_animation_server(actor, [Animation.sfx, "magentatimecrystal"])
				else:
					add_to_animation_server(actor, [Animation.sfx, "broken"])
					add_to_animation_server(actor, [Animation.explode])
				if actor.is_character:
					if actor.actorname == "heavy" and terrain.has(Tiles.HeavyGoal):
						for goal in goals:
							if goal.actorname == "heavy_goal" and goal.dinged:
								set_actor_var(goal, "dinged", false, chrono);
					if actor.actorname == "light" and terrain.has(Tiles.LightGoal):
						for goal in goals:
							if goal.actorname == "light_goal" and goal.dinged:
								set_actor_var(goal, "dinged", false, chrono);
				else:
					if actor.dinged:
						set_actor_var(actor, "dinged", false, chrono);
			else:
				add_to_animation_server(actor, [Animation.sfx, "unbroken"])
				if actor.is_character:
					if actor.actorname == "heavy" and terrain.has(Tiles.HeavyGoal):
						for goal in goals:
							if goal.actorname == "heavy_goal" and !goal.dinged:
								set_actor_var(goal, "dinged", true, chrono);
					if actor.actorname == "light" and terrain.has(Tiles.LightGoal):
						for goal in goals:
							if goal.actorname == "light_goal" and !goal.dinged:
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

func character_undo(is_silent: bool = false) -> bool:
	if (won or lost): return false;
	user_replay += "z";
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
		
		adjust_meta_turn(1);
		if (!is_silent):
			play_sound("undo");
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
			
		adjust_meta_turn(1);
		if (!is_silent):
			if (fuzzed):
				undo_effect_strength = 0.25;
				undo_effect_per_second = undo_effect_strength*(1/0.5);
				undo_effect_color = meta_color;
			else:
				play_sound("undo");
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
	
	if (!locked and !light_actor.broken and !heavy_actor.broken and terrain_in_tile(heavy_actor.pos).has(Tiles.HeavyGoal) and terrain_in_tile(light_actor.pos).has(Tiles.LightGoal)):
		won = true;
		# but wait!
		# check for crate goals as well
		# PERF: if this ends up being slow, I can cache it on level load since it won't ever change. but it seems fast enough?
		var crate_goals = get_used_cells_by_id_one_array(Tiles.CrateGoal);
		# would fix this O(n^2) with an actors_by_pos dictionary, but then I have to update it all the time.
		# maybe use DINGED?
		for crate_goal in crate_goals:
			var crate_goal_satisfied = false;
			for actor in actors:
				if actor.pos == crate_goal:
					crate_goal_satisfied = true;
					break;
			if (!crate_goal_satisfied):
				won = false;
				break;
		if (won == true and !doing_replay):
			if (level_name == "Joke"):
				play_sound("winbadtime");
			else:
				play_sound("winentwined");
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
	if (won):
		winlabel.text = "You have won!\n\n[Enter]: Continue\n[F11]: Watch Replay"
		won_fade_started = false;
		tutoriallabel.visible = false;
		adjust_winlabel();
	elif won_fade_started:
		won_fade_started = false;
		heavy_actor.modulate.a = 1;
		light_actor.modulate.a = 1;
	
func adjust_winlabel() -> void:
	winlabel.rect_position.y = win_label_default_y;
	winlabel.rect_position.x = pixel_width/2 - int(floor(winlabel.rect_size.x/2));
	var tries = 1;
	var heavy_actor_rect = heavy_actor.get_rect();
	var light_actor_rect = light_actor.get_rect();
	var label_rect = Rect2(winlabel.rect_position, winlabel.rect_size);
	heavy_actor_rect.position = terrainmap.map_to_world(heavy_actor.pos) + terrainmap.global_position;
	light_actor_rect.position = terrainmap.map_to_world(light_actor.pos) + terrainmap.global_position;
	while (tries < 99):
		if heavy_actor_rect.intersects(label_rect) or light_actor_rect.intersects(label_rect):
			var polarity = 1;
			if (tries % 2 == 0):
				polarity = -1;
			winlabel.rect_position.y += 8*tries*polarity;
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
		heavy_undo_buffer[event[1]].pop_front();
	elif (event[0] == Undo.light_undo_event_add):
		light_undo_buffer[event[1]].pop_front();
	elif (event[0] == Undo.heavy_undo_event_add_locked):
		heavy_locked_turns[event[1]].pop_front();
	elif (event[0] == Undo.light_undo_event_add_locked):
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
	user_replay += "c";
	finish_animations(Chrono.MOVE);
	if (meta_turn <= 0):
		if (meta_undo_a_restart()):
			return true;
		if !is_silent:
			play_sound("bump");
		return false;
	var events = meta_undo_buffer.pop_back();
	for event in events:
		undo_one_event(event, Chrono.META_UNDO);
	time_passes(Chrono.META_UNDO);
	adjust_meta_turn(-1);
	if (!is_silent):
		cut_sound();
		play_sound("metaundo");
	undo_effect_strength = 0.08;
	undo_effect_per_second = undo_effect_strength*(1/0.2);
	undo_effect_color = meta_color;
	for whatever in underactorsparticles.get_children():
		whatever.queue_free();
	for whatever in overactorsparticles.get_children():
		whatever.queue_free();
	finish_animations(Chrono.META_UNDO);
	return true;
	
func character_switch() -> void:
	# no swapping characters in Meet Heavy or Meet Light, even if you know the button
	if (level_number == 0 or level_number == 1):
		return
	heavy_selected = !heavy_selected;
	user_replay += "x";
	update_ghosts();
	play_sound("switch")

func restart(is_silent: bool = false) -> void:
	load_level(0);
	cut_sound();
	play_sound("restart");
	undo_effect_strength = 0.5;
	undo_effect_per_second = undo_effect_strength*(1/0.5);
	undo_effect_color = meta_color;
	finish_animations(Chrono.TIMELESS);
	
func escape() -> void:
	if (ui_stack.size() > 0):
		# can happen if we click the button directly
		var topmost_ui = ui_stack.pop_front();
		topmost_ui.queue_free();
		return;
	end_replay();
	var levelselect = preload("res://LevelSelect.tscn").instance();
	ui_stack.push_back(levelselect);
	levelscene.add_child(levelselect);
	
func trying_to_load_locked_level() -> bool:
	if save_file.has("unlock_everything") and save_file["unlock_everything"]:
		return false;
	var unlock_requirement = 0;
	if (!level_is_extra):
		unlock_requirement = chapter_standard_unlock_requirements[chapter];
	else:
		unlock_requirement = chapter_advanced_unlock_requirements[chapter];
	if puzzles_completed < unlock_requirement:
		return true;
	return false;
	
func setup_chapter_etc() -> void:
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
	
func load_level_direct(new_level: int) -> void:
	var impulse = new_level - self.level_number;
	load_level(impulse);
	
func load_level(impulse: int) -> void:
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
		for i in range(999):
			level_number += impulse;
			level_number = posmod(int(level_number), level_list.size());
			setup_chapter_etc();
			if !trying_to_load_locked_level():
				break;
		# buggy if the game just loaded, for some reason, but I didn't want it anyway
		if (ready_done):
			escape();
			
	if (impulse != 0):
		save_file["level_number"] = level_number;
		save_game();
	
	var level = level_list[level_number].instance();
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
	update_level_label();

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
	if (dir == Vector2.UP):
		user_replay += "w";
	elif (dir == Vector2.DOWN):
		user_replay += "s";
	elif (dir == Vector2.LEFT):
		user_replay += "a";
	elif (dir == Vector2.RIGHT):
		user_replay += "d";
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
		play_sound("step")
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
	return result;

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
	if (chrono >= Chrono.META_UNDO):
		return
	animation_substep(chrono);
	var time_actors = []
	for actor in actors:
		# broken time crystals being in stacks was messing up the just_moved gravity code,
		# and nothing related to time passage effects time crystals anyway, so just eject them here
		if actor.is_crystal:
			continue;
		
		#AD06: Characters are Purple, other actors are Gray. (But with time colours you can make your own arbitrary rules!
#		Red: Time passes only when red moves forward.
#		Blue: Time passes only when blue moves forward.
#		Purple: The default unrendered colour of characters. Time passes except when I am undoing.
#		Gray: The default unrendered colour of non-character actors. Time passes when a character moves forward and doesn't when a character undoes.
#		Green: Time always passes, AND undo events are not generated/stored for this actor, AND if a green character takes a turn and no events are made, turn is not incremented. (So, having actor be green is equivalent to a no-time-shenanigans version of Entwined Time where time just always moves forward and you need to meta-undo to claw it back.) (Alternatively, I might have turns work as normal but there's a sentinel value for 'no turns, no timeline' like 100, since -1 actually will mean something)
#		Void: Time passes every real time second, AND undo events AND meta undo events are not generated/stored for this actor, AND if a void actor takes a turn and no events are made, turn/meta-turn is not incremented. (In the main campaign this will probably only be used for the void cuckoo clock in the final level.)
#		Magenta: Time always passes.
#		Orange: Time passes if Red is moving or undoing.
#		Cyan: Time passes if Blue is moving or undoing.
#		Yellow: Time passes if a character is undoing.
		if actor.time_colour == TimeColour.Gray:
			if (chrono == Chrono.MOVE):
				time_actors.push_back(actor);
		elif actor.time_colour == TimeColour.Purple:
			if (chrono == Chrono.MOVE):
				time_actors.push_back(actor);
			else:
				if (heavy_selected && actor == light_actor) || (!heavy_selected && actor == heavy_actor):
					time_actors.push_back(actor);
		elif actor.time_colour == TimeColour.Red:
			if chrono == Chrono.MOVE and heavy_selected:
				time_actors.push_back(actor);
		elif actor.time_colour == TimeColour.Blue:
			if chrono == Chrono.MOVE and !heavy_selected:
				time_actors.push_back(actor);
		elif actor.time_colour == TimeColour.Green:
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
		if !actor.broken and terrain.has(Tiles.HeavyFire) and actor.durability <= Durability.FIRE and actor.actorname != "light":
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		if !actor.broken and terrain.has(Tiles.LightFire) and actor.durability <= Durability.FIRE and actor.actorname != "heavy":
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
		if actor.ticks < 10000 and !actor.broken:
			clock_ticks(actor, -1, chrono);
	
func void_cuckoo_clocks_time_passes() -> void:
	for actor in void_cuckoo_clocks:
		if actor.in_night:
			continue;
		if actor.ticks < 10000 and !actor.broken:
			clock_ticks(actor, -1, Chrono.META_UNDO);
	
func bottom_up(a, b) -> bool:
	# TODO: make this tiebreak by x, then by layer or id, so I can use it as a stable sort in general?
	return a.pos.y > b.pos.y;
	
func replay_interval() -> float:
	if unit_test_mode:
		return 0.01;
	if meta_undo_a_restart_mode:
		return 0.01;
	return replay_interval;
	
func toggle_replay() -> void:
	meta_undo_a_restart_mode = false;
	unit_test_mode = false;
	if (doing_replay):
		end_replay();
		return;
	doing_replay = true;
	restart();
	replay_turn = 0;
	next_replay = replay_timer + replay_interval();
	unit_test_mode = OS.is_debug_build() and Input.is_action_pressed(("shift"));
	
func do_one_replay_turn() -> void:
	if (!doing_replay):
		return;
	if replay_turn >= level_replay.length():
		if (unit_test_mode and won and level_number < (level_list.size() - 1)):
			doing_replay = true;
			load_level(1);
			replay_turn = 0;
			next_replay = replay_timer + replay_interval();
			return;
		else:
			if (unit_test_mode):
				floating_text("Tested up to level: " + str(level_number));
			end_replay();
			return;
	next_replay = replay_timer+replay_interval();
	var replay_char = level_replay[replay_turn];
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
	
func end_replay() -> void:
	doing_replay = false;
	update_level_label();
	
func update_level_label() -> void:
	var levelnumberastext = ""
	if (level_number < 0):
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
			levellabel.text += " (F9/F10 ADJUST SPEED)";
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
	
	#TODO: for level_number 2, 3 and 4, dynamically change colours based on which character is selected
	
	if (level_number >= 2 and level_number <= 4):
		if (heavy_selected):
			tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("#7FC9FF", "#FF7459");
		else:
			tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("#FF7459", "#7FC9FF");
	
#	if level_number == 1:
#		if meta_turn >= 24 or heavy_actor.broken or light_actor.broken:
#			tutoriallabel.text = "Arrows: Move Character\nX: Swap Character\nZ: Undo Character\nR: Restart";
#
#	if level_number == 0:
#		if meta_turn >= 12 or heavy_actor.broken or light_actor.broken:
#			tutoriallabel.text = "Arrows: Move Character\nX: Swap Character\nZ: Undo Character\nR: Restart";
#		elif meta_turn < 3:
#			tutoriallabel.text = "Arrows: Move Character";
#		elif meta_turn < 6:
#			tutoriallabel.text = "Arrows: Move Character\nX: Swap Character";
#		else:
#			tutoriallabel.text = "Arrows: Move Character\nX: Swap Character\nZ: Undo Character";

func animation_substep(chrono: int) -> void:
	animation_substep += 1;
	add_undo_event([Undo.animation_substep], chrono);

func add_to_animation_server(actor: ActorBase, animation: Array) -> void:
	while animation_server.size() <= animation_substep:
		animation_server.push_back([]);
	animation_server[animation_substep].push_back([actor, animation]);

func handle_global_animation(animation: Array) -> void:
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
				sprite.frame = 8;
			elif animation[1] == TimeColour.Magenta:
				sprite.frame = 16;
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

func start_specific_replay(replay: String) -> void:
	var replay_parts = replay.split("$");
	replay = replay_parts[replay_parts.size()-1];
	replay = replay.strip_edges();
	replay = replay.to_lower();
	for letter in replay:
		pass
		if !(letter in "wasdzxc"):
			pass
			floating_text("Ctrl+V: Invalid replay");
			return;
	end_replay();
	toggle_replay();
	level_replay = replay;

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

func afterimage(actor: Actor) -> void:
	if undo_effect_color == Color.transparent:
		return;
	# ok, we're mid undo.
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.initialize(actor, undo_effect_color);
	underactorsparticles.add_child(afterimage);
	
func afterimage_terrain(texture: Texture, position: Vector2, color: Color) -> void:
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.initialize(null, color);
	afterimage.texture = texture;
	afterimage.position = position;
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
	
func _process(delta: float) -> void:
	sounds_played_this_frame.clear();
	
	replay_timer += delta;
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
		if (void_cuckoo_clocks.size() > 0 and !won and !lost):
			void_cuckoo_clock_timer += delta;
			if (void_cuckoo_clock_timer > void_cuckoo_clock_timer_max):
				void_cuckoo_clock_timer -= void_cuckoo_clock_timer_max;
				void_cuckoo_clocks_time_passes();
		
		if (doing_replay and replay_timer > next_replay):
			do_one_replay_turn();
			update_info_labels();
		
		if (won and Input.is_action_just_pressed("ui_accept")):
			end_replay();
			if last_level_of_section():
				escape();
			else:
				load_level(1);
		
		if (Input.is_action_just_pressed("mute")):
			toggle_mute();
			
		if (Input.is_action_just_pressed("speedup_replay")):
			if (Input.is_action_pressed("shift")):
				replay_interval = 0.015;
			elif replay_interval > 0:
				replay_interval *= (2.0/3.0);
		if (Input.is_action_just_pressed("slowdown_replay")):
			if (Input.is_action_pressed("shift")):
				replay_interval = 0.5;
			elif replay_interval > 0:
				replay_interval /= (2.0/3.0);
		if (Input.is_action_just_pressed("start_saved_replay")):
			if (Input.is_action_pressed("shift")):
				if (won):
					save_file["levels"][level_name]["replay"] = annotate_replay(user_replay);
					save_game();
					floating_text("Shift+F11: Replay force saved!");
			else:
				start_saved_replay();
				update_info_labels();
		if (Input.is_action_just_pressed("start_replay")):
			toggle_replay();
			update_info_labels();
			
		if (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("paste")):
			replay_from_clipboard();
		
		var dir = Vector2.ZERO;
		
		#mouse click to switch characters
#		if (Input.is_mouse_button_just_pressed(BUTTON_LEFT)):
#			var mouse_position = get_parent().get_global_mouse_position();
#			var heavy_rect = heavy_actor.get_rect();
#			var light_rect = light_actor.get_rect();
#			heavy_rect.position += actorsfolder.position;
#			light_rect.position += actorsfolder.position;
#			if !heavy_selected and heavy_rect.has_point(mouse_position):
#				end_replay();
#				character_switch();
#				update_info_labels();
#			elif heavy_selected and light_rect.has_point(mouse_position):
#				end_replay();
#				character_switch();
#				update_info_labels();
		
		if (Input.is_action_just_pressed("character_undo")):
			end_replay();
			character_undo();
			update_info_labels();
		elif (Input.is_action_just_pressed("meta_undo")):
			if Input.is_action_pressed("ctrl"):
				OS.set_clipboard(annotate_replay(user_replay));
				floating_text("Ctrl+C: Replay copied");
			else:
				end_replay();
				meta_undo();
				update_info_labels();
		elif (Input.is_action_just_pressed("restart")):
			end_replay();
			restart();
			update_info_labels();
		elif (Input.is_action_just_pressed("escape")):
			#end_replay(); #done in escape();
			escape();
		elif (Input.is_action_just_pressed("previous_level")):
			end_replay();
			load_level(-1);
		elif (Input.is_action_just_pressed("next_level")):
			end_replay();
			load_level(1);
		elif (Input.is_action_just_pressed("character_switch")):
			end_replay();
			character_switch();
			update_info_labels();
		else:
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
