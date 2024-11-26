extends Node
class_name GameLogic

var debug_prints : bool = false;

onready var levelscene : Node2D = get_node("/root/LevelScene"); #this one runs before SupercCaling so it's safe!
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
var replayturnsliderset : bool = false;
var replayspeedsliderset : bool = false;
onready var metaredobutton : Button = virtualbuttons.get_node("Verbs/MetaRedoButton");
onready var metaredobuttonlabel : Label = metaredobutton.get_node("MetaRedoLabel");

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
	heavy_turn, #2
	light_turn, #3
	heavy_undo_event_add, #4
	light_undo_event_add, #5
	heavy_undo_event_remove, #6
	light_undo_event_remove, #7
	animation_substep, #8
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
	time_bubble, #27
	sprite, #28
	spotlight_fix, #29
	heavy_surprise_abyss_chimed, #30
	light_surprise_abyss_chimed, #31
}

# and same for animations
enum Anim {
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
	lightning_strikes, #25
	heavy_timeline_finish_animations, #26
	light_timeline_finish_animations, #27
	intro_hop, #28
	stall, #29
	dust, #30
	time_bubble, #31
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
	PhaseWallBlue, #75
	PhaseWallRed, #76
	PhaseWallGray, #77
	PhaseWallPurple, #78
	PhaseLightningBlue, #79
	PhaseLightningRed, #80
	PhaseLightningGray, #81
	PhaseLightningPurple, #82
	OnewayEastLose, #83
	OnewayNorthLose, #84
	OnewaySouthLose, #85
	OnewayWestLose, #86
	GreenFog, #87
	Floorboards, #88
	GreenFloorboards, #89
	VoidFloorboards, #90
	Hole, #91
	GreenHole, #92
	VoidHole, #93
	BoostPad, #94
	GreenBoostPad, #95
	SlopeNW, #96
	SlopeNE, #97
	SlopeSE, #98
	SlopeSW, #99
	Boulder, #100
	PhaseWallGreenEven, #101
	PhaseWallGreenOdd, #102
	NudgeEast, #103
	NudgeNorth, #104
	NudgeSouth, #105
	NudgeWest, #106
	NudgeEastGreen, #107
	NudgeNorthGreen, #108
	NudgeSouthGreen, #109
	NudgeWestGreen, #110
	AntiGrate, #111
	MagentaFloorboards, #112
	GhostPlatform, #113
	Propellor, #114
	DurPlus, #115
	DurMinus, #116
	HvyPlus, #117
	HvyMinus, #118
	StrPlus, #119
	StrMinus, #120
	FallInf, #121
	FallOne, #122
	ColourNative, #123
	RepairStation, #124
	RepairStationGray, #125
	RepairStationGreen, #126
	ZombieTile, #127
	HeavyMimic, #128
	LightMimic, #129
	GhostFog, #130
	Eclipse, #131
	PhaseBoardRed, #132
	PhaseBoardBlue, #133
	PhaseBoardGray, #134
	PhaseBoardPurple, #135
	PhaseBoardDeath, #136
	PhaseBoardLife, #137
	PhaseBoardHeavy, #138
	PhaseBoardLight, #139
	PhaseBoardCrate, #140
	SpiderWeb, #141
	SpiderWebGreen, #142
	NoPush, #143
	NoPushGreen, #144
	YesPush, #145
	YesPushGreen, #146
	NoLeft, #147
	NoLeftGreen, #148
	PhaseBoardVoid, #149
	OnewayEastGray, #150
	OnewayNorthGray, #151
	OnewaySouthGray, #152
	OnewayWestGray, #153
	PinkJelly, #154
	CyanJelly, #155
	PurpleFog, #156
	Spotlight, #157
	Continuum, #158
	GateOfEternity, #159
	GateOfDemise, #160
	VoidSingularity, #161
	VoidWall, #162
	VoidFire, #163
	VoidStars, #164
	VoidFog, #165
	NoRising, #166
	NoFalling, #167
	NoGrounded, #168
	PhaseBoardEast, #169
	PhaseBoardNorth, #170
	PhaseBoardSouth, #171
	PhaseBoardWest, #172
	RepairStationBumper, #173
	Fence, #174
	Fan, #175
	Bumper, #176
	Passage, #177
	GreenPassage, #178
}
var voidlike_tiles : Array = [];

var achievements : Dictionary = {
	"NonStandardGameOver": "Non-Standard Game Over",
	"What": "What",
	"AlreadyFixed": "Already Fixed",
	"AlreadyBroken": "Already Broken",
	"Phantasmal": "Phantasmal",
	"SpaceProgram": "Space Program",
	"FarLands": "Far Lands",
	"VoidDiver": "Void Diver",
	"BuriedAlive": "Buried Alive",
	"ExceptionHandler": "Exception Handler",
	"InfiniteLoop": "Infinite Loop",
	"Paradox": "Paradox",
	"RepairsComplete": "Repairs Complete",
	"CommunityChampion": "Community Champion",
	# not going to add 0Standard etc until they're visible in-game
};

var achievements_unlocked : Dictionary = {};

var steam : Node = null;

# information about the level
var is_custom : bool = false;
var is_community_level : bool = false;
var test_mode : bool = false;
var custom_string : String = "";
var chapter : int = 0;
var level_in_chapter : int = 0;
var level_is_extra : bool = false;
var in_insight_level : bool = false;
var has_insight_level : bool = false;
var insight_level_scene = null;
var level_number : int = 0
var level_name : String = "Blah Blah Blah";
var level_replay : String = "";
var annotated_authors_replay : String = "";
var authors_replay : String = "";
var level_author : String = "";
var heavy_max_moves : int = -1;
var light_max_moves : int = -1;
var clock_turns : String = "";
var map_x_max : int = 0;
var map_y_max : int = 0;
var map_x_max_max : int = 21;
var map_y_max_max : int = 10; #TODO: screen scrolling/zoom
var terrain_layers : Array = []
var voidlike_puzzle : bool = false;

# information about the actors and their state
var heavy_actor : Actor = null
var light_actor : Actor = null
var actors : Array = []
var goals : Array = []
var heavy_turn : int = 0;
var heavy_undo_buffer : Array = [];
var heavy_filling_locked_turn_index : int = -1;
var heavy_filling_turn_actual : int = -1;
var heavy_locked_turns : Array = [];
var light_turn : int = 0;
var light_undo_buffer : Array = [];
var light_filling_locked_turn_index : int = -1;
var light_filling_turn_actual : int = -1;
var light_locked_turns : Array = [];
var meta_turn : int = 0;
var meta_undo_buffer : Array = [];
var heavy_selected : bool = true;

# for undo trail ghosts
var ghosts : Array = []

# for afterimages
var afterimage_server : Dictionary = {}

# save file, ooo!
var save_file : Dictionary = {}
var puzzles_completed : int = 0;
var advanced_puzzles_completed : int = 0;
var specific_puzzles_completed : Array = [];

# song-and-dance state
var sounds : Dictionary = {}
var music_tracks : Array = [];
var music_info : Array = [];
var music_db : Array = [];
var now_playing = null;
var nag_timer = null;
var speakers : Array = [];
var target_track : int = -1;
var current_track : int = -1;
var jukebox_track : int = -1;
var fadeout_timer : float = 0.0;
var fadeout_timer_max : float = 0.0;
var fanfare_duck_db : float = 0.0;
var music_discount : float = -10.0;
var music_speaker = null;
var lost_speaker = null;
var lost_speaker_volume_tween;
var won_speaker = null;
var sounds_played_this_frame : Dictionary = {};
var muted : bool = false;
var won : bool = false;
var nonstandard_won : bool = false;
var won_cooldown : float = 0.0;
var lost : bool = false;
var lost_void : bool = false;
var won_fade_started : bool = false;
var joke_portals_present : bool = false;
var cell_size : int = 24;
var undo_effect_strength : float = 0;
var undo_effect_per_second : float = 0;
var undo_effect_color : Color = Color(0, 0, 0, 0);
var heavy_color : Color = Color(1.0, 0, 0, 1);
var light_color : Color = Color(0, 0.58, 1.0, 1);
var meta_color : Color = Color(0.5, 0.5, 0.5, 1);
var fuzz_timer : float = 0;
var fuzz_timer_max : float = 0;
var ui_stack : Array = [];
var ready_done : bool = false;
var using_controller : bool = false;

#UI defaults
var HeavyInfoLabel_default_position : Vector2 = Vector2(0, 1);
var HeavyTimeline_default_position : Vector2 = Vector2(6, 26);
var LightInfoLabel_default_position : Vector2 = Vector2(478, 1);
var LightTimeline_default_position : Vector2 = Vector2(482, 26);
var win_label_default_y : float = 113.0;
var pixel_width : int = ProjectSettings.get("display/window/size/width"); #512
var pixel_height : int = ProjectSettings.get("display/window/size/height"); #300

# animation server
var animation_server : Array = []
var animation_substep : int = 0;
var animation_nonce_fountain : int = 0;

#replay system
var replay_timer : float = 0.0;
var user_replay : String  = "";
var user_replay_before_restarts : Array = [];
var meta_redo_inputs : String = "";
var preserving_meta_redo_inputs : bool = false;
var doing_replay : bool = false;
var replay_paused : bool = false;
var replay_turn : int = 0;
var replay_interval : float = 0.5;
var next_replay : float = -1.0;
var unit_test_mode : bool = false;
var meta_undo_a_restart_mode : bool = false;

# list of levels in the game
var level_list : Array = [];
var level_filenames : Array = [];
var level_names : Array = [];
var level_extraness : Array = [];
var has_remix : Dictionary = {};
var insight_level_names : Dictionary = {};
var chapter_names : Array = [];
var chapter_skies : Array = [];
var chapter_tracks : Array = [];
var chapter_replacements : Dictionary = {};
var level_replacements : Dictionary = {};
var target_sky : Color = Color("#223C52");
var old_sky : Color = Color("#223C52");
var current_sky : Color = Color("#223C52");
var sky_timer : float = 0.0;
var sky_timer_max : float = 0.0;
var chapter_standard_starting_levels : Array = [];
var chapter_advanced_starting_levels : Array = [];
var chapter_standard_unlock_requirements : Array = [];
var chapter_advanced_unlock_requirements : Array = [];
var custom_past_here : int = -1;
var custom_past_here_level_count : int = -1;
var save_file_string : String = "user://entwinedtime.sav";

var is_web : bool = false;

func save_game():
	var file = File.new()
	file.open(save_file_string, File.WRITE)
	file.store_line(to_json(save_file))
	file.close()
	if (heavy_actor != null):
		update_info_labels();

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
	if (!save_file.has("music_volume")):
		save_file["music_volume"] = 0.0;
	if (!save_file.has("sfx_volume")):
		save_file["sfx_volume"] = 0.0;
	if (!save_file.has("fanfare_volume")):
		save_file["fanfare_volume"] = 0.0;
	if (!save_file.has("master_volume")):
		save_file["master_volume"] = 0.0;
	if (!save_file.has("resolution")):
		var value = 2;
		if (save_file.has("pixel_scale")):
			value = save_file["pixel_scale"];
		save_file["resolution"] = str(pixel_width*value) + "x" + str(pixel_height*value);
		save_file.erase("pixel_scale");
	if (!save_file.has("fps")):
		save_file["fps"] = 60;
	if (!save_file.has("retro_timeline")):
		save_file["retro_timeline"] = false;
	if (!save_file.has("colourblind_mode")):
		save_file["colourblind_mode"] = false;

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
	var os_name = OS.get_name();
	if (os_name == "HTML5" or os_name == "Android" or os_name == "iOS"):
		is_web = true;
	
	# Call once when the game is booted up.
	menubutton.connect("pressed", self, "escape");
	levelstar.scale = Vector2(1.0/6.0, 1.0/6.0);
	winlabel.call_deferred("change_text", "You have won!\n\n[" + human_readable_input("ui_accept", 1) + "]: Continue\nWatch Replay: Menu -> Your Replay");
	connect_virtual_buttons();
	prepare_audio();
	call_deferred("adjust_winlabel");
	call_deferred("setup_gui_holder");
	load_game();
	initialize_level_list();
	tile_changes();
	initialize_shaders();
	if (OS.is_debug_build()):
		assert_tile_enum();
	prepare_voidlike_tiles();
	
	if (Engine.has_singleton("Steam") and ResourceLoader.exists("res://GodotSteam.gd")):
		steam = Node.new();
		steam.set_script(load("res://GodotSteam.gd"));
		self.add_child(steam);
	
	# Load the first map.
	load_level(0);
	ready_done = true;
	
	if (puzzles_completed > 0):
		play_sound("bootup");
		fadeout_timer = 0.0;
		fadeout_timer_max = 2.5;
	else:
		call_deferred("title_screen");

func prepare_voidlike_tiles() -> void:
	for i in range (Tiles.size()):
		var expected_tile_name = Tiles.keys()[i];
		if expected_tile_name.findn("void") >= 0:
			voidlike_tiles.append(i);

var GuiHolder : CanvasLayer;

func setup_gui_holder() -> void:
	GuiHolder = CanvasLayer.new();
	GuiHolder.name = "GuiHolder";
	get_parent().get_parent().add_child(GuiHolder);
	var ui_elements = [heavyinfolabel, lightinfolabel, levelstar, levellabel, replaybuttons, virtualbuttons, winlabel, tutoriallabel, metainfolabel, menubutton];
	for ui_element in ui_elements:
		ui_element.get_parent().remove_child(ui_element);
		GuiHolder.add_child(ui_element);

func add_to_ui_stack(node: Node, parent: Node = null) -> void:
	ui_stack.push_back(node);
	if (parent != null):
		parent.add_child(node);
	else:
		GuiHolder.add_child(node);

func connect_virtual_buttons() -> void:
	virtualbuttons.get_node("Verbs/UndoButton").connect("button_down", self, "_undobutton_pressed");
	virtualbuttons.get_node("Verbs/UndoButton").connect("button_up", self, "_undobutton_released");
	virtual_button_name_to_action["UndoButton"] = "character_undo";
	virtualbuttons.get_node("Verbs/SwapButton").connect("button_down", self, "_swapbutton_pressed");
	virtualbuttons.get_node("Verbs/SwapButton").connect("button_up", self, "_swapbutton_released");
	virtual_button_name_to_action["SwapButton"] = "character_switch";
	virtualbuttons.get_node("Verbs/MetaUndoButton").connect("button_down", self, "_metaundobutton_pressed");
	virtualbuttons.get_node("Verbs/MetaUndoButton").connect("button_up", self, "_metaundobutton_released");
	virtual_button_name_to_action["MetaUndoButton"] = "meta_undo";
	virtualbuttons.get_node("Verbs/MetaRedoButton").connect("button_down", self, "_metaredobutton_pressed");
	virtualbuttons.get_node("Verbs/MetaRedoButton").connect("button_up", self, "_metaredobutton_released");
	virtual_button_name_to_action["MetaRedoButton"] = "meta_redo";
	virtualbuttons.get_node("Dirs/LeftButton").connect("button_down", self, "_leftbutton_pressed");
	virtualbuttons.get_node("Dirs/LeftButton").connect("button_up", self, "_leftbutton_released");
	virtual_button_name_to_action["LeftButton"] = "ui_left";
	virtualbuttons.get_node("Dirs/DownButton").connect("button_down", self, "_downbutton_pressed");
	virtualbuttons.get_node("Dirs/DownButton").connect("button_up", self, "_downbutton_released");
	virtual_button_name_to_action["DownButton"] = "ui_down";
	virtualbuttons.get_node("Dirs/RightButton").connect("button_down", self, "_rightbutton_pressed");
	virtualbuttons.get_node("Dirs/RightButton").connect("button_up", self, "_rightbutton_released");
	virtual_button_name_to_action["RightButton"] = "ui_right";
	virtualbuttons.get_node("Dirs/UpButton").connect("button_down", self, "_upbutton_pressed");
	virtualbuttons.get_node("Dirs/UpButton").connect("button_up", self, "_upbutton_released");
	virtual_button_name_to_action["UpButton"] = "ui_up";
	virtualbuttons.get_node("Others/EnterButton").connect("button_down", self, "_enterbutton_pressed");
	virtualbuttons.get_node("Others/EnterButton").connect("button_up", self, "_enterbutton_released");
	replaybuttons.get_node("ReplaySpeed/F9Button").connect("button_down", self, "_f9button_pressed");
	replaybuttons.get_node("ReplaySpeed/F9Button").connect("button_up", self, "_f9button_released");
	virtual_button_name_to_action["F9Button"] = "slowdown_replay";
	replaybuttons.get_node("ReplaySpeed/F10Button").connect("button_down", self, "_f10button_pressed");
	replaybuttons.get_node("ReplaySpeed/F10Button").connect("button_up", self, "_f10button_released");
	virtual_button_name_to_action["F10Button"] = "speedup_replay";
	replaybuttons.get_node("ReplayTurn/PrevTurnButton").connect("button_down", self, "_prevturnbutton_pressed");
	replaybuttons.get_node("ReplayTurn/PrevTurnButton").connect("button_up", self, "_prevturnbutton_released");
	virtual_button_name_to_action["PrevTurnButton"] = "replay_back1";
	replaybuttons.get_node("ReplayTurn/NextTurnButton").connect("button_down", self, "_nextturnbutton_pressed");
	replaybuttons.get_node("ReplayTurn/NextTurnButton").connect("button_up", self, "_nextturnbutton_released");
	virtual_button_name_to_action["NextTurnButton"] = "replay_fwd1";
	replaybuttons.get_node("ReplayTurn/PauseButton").connect("button_down", self, "_pausebutton_pressed");
	replaybuttons.get_node("ReplayTurn/PauseButton").connect("button_up", self, "_pausebutton_released");
	virtual_button_name_to_action["PauseButton"] = "replay_pause";
	replaybuttons.get_node("ReplayTurn/ReplayTurnSlider").connect("value_changed", self, "_replayturnslider_value_changed");
	replaybuttons.get_node("ReplayTurn/ReplayTurnSlider").connect("drag_started", self, "_replayturnslider_drag_started");
	replaybuttons.get_node("ReplayTurn/ReplayTurnSlider").connect("drag_ended", self, "_replayturnslider_drag_ended");
	replaybuttons.get_node("ReplaySpeed/ReplaySpeedSlider").connect("value_changed", self, "_replayspeedslider_value_changed");
	
func virtual_button_pressed(action: String) -> void:
	if (ui_stack.size() > 0 and ui_stack[ui_stack.size() - 1] != self):
		return;
	Input.action_press(action);
	menubutton.grab_focus();
	menubutton.release_focus();
	if (virtual_button_held_dict.has(action)):
		virtual_button_held_dict[action] = true;
	
func virtual_button_released(action: String) -> void:
	if (ui_stack.size() > 0 and ui_stack[ui_stack.size() - 1] != self):
		return;
	Input.action_release(action);
	menubutton.grab_focus();
	menubutton.release_focus();
	if (virtual_button_held_dict.has(action)):
		virtual_button_held_dict[action] = false;
	
func _undobutton_pressed() -> void:
	virtual_button_pressed("character_undo");
	
func _swapbutton_pressed() -> void:
	virtual_button_pressed("character_switch");
	
func _metaundobutton_pressed() -> void:
	virtual_button_pressed("meta_undo");
	
func _metaredobutton_pressed() -> void:
	virtual_button_pressed("meta_redo");
	
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
	
func _metaredobutton_released() -> void:
	virtual_button_released("meta_redo");
	
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
	
var replayturnslider_in_drag : bool = false;
func _replayturnslider_drag_started() -> void:
	replayturnslider_in_drag = true;
	
func _replayturnslider_drag_ended(_value_changed: bool) -> void:
	replayturnslider_in_drag = false;
	
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
	if (save_file.has("puzzle_checkerboard") and save_file["puzzle_checkerboard"] == true):
		checkerboard.visible = true;
	else:
		checkerboard.visible = false;
	setup_colourblind_mode();
	call_deferred("setup_resolution");
	setup_volume();
	setup_animation_speed();
	setup_virtual_buttons();
	deserialize_bindings();
	setup_deadzone();
	refresh_puzzles_completed();
	
var actions = ["ui_accept", "ui_cancel", "escape", "ui_left", "ui_right", "ui_up", "ui_down",
"character_undo", "meta_undo", "meta_redo", "character_switch", "restart",
"next_level", "previous_level", "mute",
"gain_insight", "level_select",
"toggle_replay", "start_replay", "start_saved_replay",
"speedup_replay", "slowdown_replay", "replay_pause", "replay_back1", "replay_fwd1"];
	
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
			if (save_file["keyboard_bindings"].has(action)):
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
			if (save_file["controller_bindings"].has(action)):
				var events = InputMap.get_action_list(action);
				for event in events:
					if (event is InputEventJoypadButton):
						InputMap.action_erase_event(action, event);
				for new_event_int in save_file["controller_bindings"][action]:
					var new_event = InputEventJoypadButton.new();
					new_event.button_index = new_event_int;
					InputMap.action_add_event(action, new_event);
					
	setup_udlr();

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
		if (action.find("nonaxis") >= 0):
			pass
		var events = InputMap.get_action_list(action);
		save_file["keyboard_bindings"][action] = [];
		save_file["controller_bindings"][action] = [];
		for event in events:
			if (event is InputEventKey):
				save_file["keyboard_bindings"][action].append(str(event.scancode) + "," +str(event.physical_scancode));
			elif (event is InputEventJoypadButton):
				save_file["controller_bindings"][action].append(event.button_index);
				
	setup_udlr();
	
func setup_udlr() -> void:
	if !save_file.has("keyboard_bindings") or  !save_file.has("controller_bindings"):
		serialize_bindings();
	
	var a = ["ui_left", "ui_right", "ui_up", "ui_down"];
	var b = ["nonaxis_left", "nonaxis_right", "nonaxis_up", "nonaxis_down"];
	for i in range(4):
		var ia = a[i];
		var ib = b[i];
		var events = InputMap.get_action_list(ib);
		for event in events:
			InputMap.action_erase_event(ib, event);
		for new_event_str in save_file["keyboard_bindings"][ia]:
			var parts = new_event_str.split(",");
			var new_event = InputEventKey.new();
			new_event.scancode = int(parts[0]);
			new_event.physical_scancode = int(parts[1]);
			InputMap.action_add_event(ib, new_event);
		for new_event_int in save_file["controller_bindings"][ia]:
			var new_event = InputEventJoypadButton.new();
			new_event.button_index = new_event_int;
			InputMap.action_add_event(ib, new_event);
	
func setup_virtual_buttons() -> void:
	var value = 0;
	if (save_file.has("virtual_buttons")):
		value = int(save_file["virtual_buttons"]);
	if (value > 0):
		for folder in virtualbuttons.get_children():
			for button in folder.get_children():
				button.disabled = false;
		virtualbuttons.visible = true;
		match value:
			1:
				virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
				virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
				replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
				replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
			2:
				virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
				virtualbuttons.get_node("Dirs").position = Vector2(-108, 0);
				replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
				replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
			3:
				virtualbuttons.get_node("Verbs").position = Vector2(128, 0);
				virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
				replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
				replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
			4:
				virtualbuttons.get_node("Verbs").position = Vector2(128, 0);
				virtualbuttons.get_node("Dirs").position = Vector2(-108, 0);
				replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
				replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
			5:
				virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
				virtualbuttons.get_node("Dirs").position = Vector2(-300, 0);
				replaybuttons.get_node("ReplayTurn").position = Vector2(160, 0);
				replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
			6:
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
	if (heavy_actor != null):
		update_info_labels();

var is_steam_deck: bool = false;
func steam_deck_check() -> bool:
	if is_steam_deck:
		return true;
	if OS.get_name() == "X11":
		if get_largest_monitor().x == 1280:
			is_steam_deck = true;
			save_file["resolution"] = "1280x800";
			save_file["fullscreen"] = true;
			#setup_resolution(); #will be called by startup
			controller_hrns[0] = "A";
			controller_hrns[1] = "B";
			controller_hrns[2] = "X";
			controller_hrns[3] = "Y";
			return true;
	return false;

func get_largest_monitor() -> Vector2:
	var result = Vector2(-1, -1);
	var monitors = OS.get_screen_count();
	for i in range(monitors):
		var monitor = OS.get_screen_size(i);
		if (result.x < monitor.x):
			result.x = monitor.x;
		if (result.y < monitor.y):
			result.y = monitor.y;
	return result;

#https://gist.github.com/hiulit/772b8784436898fd7f942750ad99e33e
func get_all_files(path: String, file_ext := "", files := []):
	var dir = Directory.new()

	if dir.open(path) == OK:
		dir.list_dir_begin(true, true)

		var file_name = dir.get_next()

		while file_name != "":
			if dir.current_is_dir():
				files = get_all_files(dir.get_current_dir().plus_file(file_name), file_ext, files)
			else:
				if file_ext and file_name.get_extension() != file_ext:
					file_name = dir.get_next()
					continue

				files.append(dir.get_current_dir().plus_file(file_name))

			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)

	return files

var SuperScaling = null;

func move_viewport() -> void:
	var viewport = get_parent().get_parent();
	var root = get_tree().get_root();
	root.move_child(viewport, 0);

func filter_all_sprites(yes: bool) -> void:	
	if (SuperScaling != null):
		var viewport = get_parent().get_parent();
		var root = get_tree().get_root();
		for node in viewport.get_children():
			viewport.remove_child(node);
			root.add_child(node);
		SuperScaling.get_parent().remove_child(SuperScaling);
		SuperScaling.queue_free();
		viewport.queue_free();
		SuperScaling = null;
	
	if (yes and SuperScaling == null):
		SuperScaling = load("res://SuperScaling/SuperScaling.tscn").instance();
		SuperScaling.enable_on_play = true;
		SuperScaling.ui_nodes = [get_parent().get_path_to(GuiHolder)] #path must be ../GuiHolder
		SuperScaling.usage = 1; #2D
		SuperScaling.shadow_atlas = 1;
		SuperScaling.scale_factor = 2.0;
		SuperScaling.smoothness = 0.25;
		self.get_parent().get_parent().add_child(SuperScaling);
		call_deferred("move_viewport");
	else:
		pass
	load("res://standardfont.tres").use_filter = yes; #still need to filter this or it looks gross lol
	
func setup_resolution() -> void:
	steam_deck_check();
	
	Engine.target_fps = int(save_file["fps"]);
	if (is_web):
		return;
	if (save_file.has("fullscreen")):
		OS.window_fullscreen = save_file["fullscreen"];
	if (save_file.has("resolution")):
		var value = save_file["resolution"];
		value = value.split("x");
		var size = Vector2(int(value[0]), int(value[1]));
		var monitor = get_largest_monitor();
		if (monitor.x > 0 and size.x > monitor.x):
			size.x = monitor.x;
		if (monitor.y > 0 and size.y > monitor.y):
			size.y = monitor.y;
		if (OS.get_window_size() != size):
			OS.set_window_size(size);
			OS.center_window();
	var size = OS.get_window_size();
	if (float(size.x) / float(pixel_width) != round(float(size.x) / float(pixel_width))):
		call_deferred("filter_all_sprites", true);
	else:
		call_deferred("filter_all_sprites", false);

	if (save_file.has("vsync_enabled")):
		OS.vsync_enabled = save_file["vsync_enabled"];
		
func setup_volume() -> void:
	var master_volume = save_file["master_volume"];
	if (save_file.has("sfx_volume")):
		var value = save_file["sfx_volume"];
		for speaker in speakers:
			speaker.volume_db = value + master_volume;
	if (save_file.has("music_volume")):
		var value = save_file["music_volume"];
		music_speaker.volume_db = value + master_volume;
		music_speaker.volume_db = music_speaker.volume_db + music_discount;
	if (save_file.has("fanfare_volume")):
		var value = save_file["fanfare_volume"];
		won_speaker.volume_db = value + master_volume;
	
func setup_animation_speed() -> void:
	if (save_file.has("animation_speed")):
		var value = save_file["animation_speed"];
		Engine.time_scale = value;
		
func setup_colourblind_mode() -> void:
	var value = save_file["colourblind_mode"];
	if (!ready_done and !value):
		# just booted up and we're not in colourblind mode - everything is already correct
		return;
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
		terrainmap.tile_set.tile_set_texture(Tiles.ColourRed, preload("res://assets/colour_red_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourBlue, preload("res://assets/colour_blue_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourGray, preload("res://assets/colour_gray_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourGreen, preload("res://assets/colour_green_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourMagenta, preload("res://assets/colour_magenta_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourVoid, preload("res://assets/colour_void_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourPurple, preload("res://assets/colour_purple_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourBlurple, preload("res://assets/colour_blurple_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourCyan, preload("res://assets/colour_cyan_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourOrange, preload("res://assets/colour_orange_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourYellow, preload("res://assets/colour_yellow_colourblind.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourWhite, preload("res://assets/colour_white_colourblind.png"))
	else:
		terrainmap.tile_set.tile_get_texture(Tiles.GreenFire).fps = 5;
		terrainmap.tile_set.tile_get_texture(Tiles.GreenSpikeball).fps = 5;
		terrainmap.tile_set.tile_get_texture(Tiles.OnewayEastGreen).fps = 10;
		terrainmap.tile_set.tile_get_texture(Tiles.OnewayWestGreen).fps = 10;
		terrainmap.tile_set.tile_get_texture(Tiles.OnewayNorthGreen).fps = 10;
		terrainmap.tile_set.tile_get_texture(Tiles.OnewaySouthGreen).fps = 10;
		terrainmap.tile_set.tile_set_texture(Tiles.ColourRed, preload("res://assets/colour_red.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourBlue, preload("res://assets/colour_blue.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourGray, preload("res://assets/colour_gray.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourGreen, preload("res://assets/colour_green.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourMagenta, preload("res://assets/colour_magenta.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourVoid, preload("res://assets/colour_void.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourPurple, preload("res://assets/colour_purple.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourBlurple, preload("res://assets/colour_blurple.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourCyan, preload("res://assets/colour_cyan.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourOrange, preload("res://assets/colour_orange.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourYellow, preload("res://assets/colour_yellow.png"))
		terrainmap.tile_set.tile_set_texture(Tiles.ColourWhite, preload("res://assets/colour_white.png"))
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
	terrainmap.tile_set.tile_set_modulate(Tiles.GreenFog, Color(1, 1, 1, 0.8));
	# hide light and heavy goal sprites when in-game and not in-editor
	if (!level_editor):
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, null);
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, null);
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoalJoke, null);
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoalJoke, null);
		terrainmap.tile_set.tile_set_modulate(Tiles.GlassBlock, Color(1, 1, 1, 0.8));
		terrainmap.tile_set.tile_set_modulate(Tiles.GlassBlockCracked, Color(1, 1, 1, 0.8));
		terrainmap.tile_set.tile_set_texture(Tiles.NoUndo, preload("res://assets/one_undo.png"));
	else:
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, preload("res://assets/light_goal.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, preload("res://assets/heavy_goal.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.LightGoalJoke, preload("res://assets/light_goal_joke.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoalJoke, preload("res://assets/heavy_goal_joke.png"));
		terrainmap.tile_set.tile_set_modulate(Tiles.GlassBlock, Color(1, 1, 1, 1));
		terrainmap.tile_set.tile_set_modulate(Tiles.GlassBlockCracked, Color(1, 1, 1, 1));
		terrainmap.tile_set.tile_set_texture(Tiles.NoUndo, preload("res://assets/no_undo.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardRed, preload("res://assets/phase_board_red.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardBlue, preload("res://assets/phase_board_blue.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardGray, preload("res://assets/phase_board_gray.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardPurple, preload("res://assets/phase_board_purple.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardLife, preload("res://assets/phase_board_life.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardDeath, preload("res://assets/phase_board_death.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardVoid, preload("res://assets/phase_board_void.png"));
	
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
	
func achievement_get(id: String, custom_achievement: bool = false) -> void:
	if (is_custom and !custom_achievement):
		return
	if (achievements_unlocked.has(id) and achievements_unlocked[id]):
		return
	if (steam != null and steam.check_achievement(id)):
		achievements_unlocked[id] = true;
		return
	achievements_unlocked[id] = true;
	print("Achievement: " + id);
	if (achievements.has(id)):
		floating_text("Achievement: " + achievements[id]);
	if (steam != null):
		steam.set_achievement(id);
	
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
	level_filenames.push_back("SteppingStone")
	level_filenames.push_back("PushingIt")
	level_filenames.push_back("Wall")
	level_filenames.push_back("Tall")
	level_filenames.push_back("Braid")
	level_filenames.push_back("TheFirstPit")
	level_filenames.push_back("CallACab")
	level_filenames.push_back("Pachinko")
	level_filenames.push_back("CarryingIt")
	level_filenames.push_back("Knot")
	level_filenames.push_back("Roommates")
	level_filenames.push_back("U-Turn")
	level_filenames.push_back("Downhill")
	level_filenames.push_back("Uphill")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_filenames.push_back("Spelunking")
	level_filenames.push_back("RoommatesEx")
	level_filenames.push_back("TheFirstPitEx")
	level_filenames.push_back("TheFirstPitEx2")
	level_filenames.push_back("CarryingItEx")
	level_filenames.push_back("ShouldveCalledaCab")
	level_filenames.push_back("UncabYourself")
	level_filenames.push_back("BraidEx")
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
	level_filenames.push_back("OrbitalDrop")
	level_filenames.push_back("FireInTheSky")
	level_filenames.push_back("HopscorchEx")
	
	chapter_names.push_back("Secrets of Space-Time");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(10);
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
	level_filenames.push_back("Eruption")
	level_filenames.push_back("SecurityDoor")
	level_filenames.push_back("Upstream")
	level_filenames.push_back("Downstream")
	level_filenames.push_back("Jail")
	level_filenames.push_back("BoosterSeat")
	level_filenames.push_back("TheOneWayPit")
	level_filenames.push_back("EventHorizon")
	level_filenames.push_back("PushingItSequel")
	level_filenames.push_back("Daredevils")
	level_filenames.push_back("FlowControl")
	level_filenames.push_back("FootWiggle")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(24);
	level_filenames.push_back("SolidPuzzle")
	level_filenames.push_back("JailEx")
	level_filenames.push_back("RemoteVoyage")
	level_filenames.push_back("SecurityDoorEx")
	level_filenames.push_back("TheOneWayPitEx")
	level_filenames.push_back("HawkingRadiation")
	level_filenames.push_back("TheSpikePitEx2")
	level_filenames.push_back("TheSpikePitEx3")
	level_filenames.push_back("Heaven")
	level_filenames.push_back("OneWayToBurn")
	level_filenames.push_back("UnfinishedBridge")
	level_filenames.push_back("TheOneWayPitEx2")
	
	chapter_names.push_back("Trap Doors and Ladders");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(24);
	chapter_tracks.push_back(4);
	chapter_skies.push_back(Color("#3B3F1A"));
	level_filenames.push_back("Down")
	level_filenames.push_back("LadderWorld")
	level_filenames.push_back("LadderLattice")
	level_filenames.push_back("StairwayToHell")
	level_filenames.push_back("Mole")
	level_filenames.push_back("PurpleOneWays")
	level_filenames.push_back("TheUnderworld")
	level_filenames.push_back("Dive")
	level_filenames.push_back("LadderDither")
	level_filenames.push_back("TrophyCabinet")
	level_filenames.push_back("DoubleJump")
	level_filenames.push_back("FirefightersNew")
	level_filenames.push_back("HighsAndLows")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(32);
	level_filenames.push_back("SecretPassage")
	level_filenames.push_back("CheekyPurpleTricks")
	level_filenames.push_back("TrophyCabinetEx")
	level_filenames.push_back("Bonfire")
	level_filenames.push_back("TrophyCabinetEx2")
	level_filenames.push_back("TripleJump")
	level_filenames.push_back("FootWiggleEx")
	level_filenames.push_back("FootWiggleEx2")
	level_filenames.push_back("RocketEngine")
	level_filenames.push_back("JetEngine")
	level_filenames.push_back("PhotonDrive")
	level_filenames.push_back("CarEngine")
	level_filenames.push_back("Firefighters (ladder shortage)")
	
	chapter_names.push_back("Iron Crates");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(32);
	chapter_tracks.push_back(5);
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
	level_filenames.push_back("FlamingCoronation")
	level_filenames.push_back("TheCratePit")
	level_filenames.push_back("PrecariousSituation")
	level_filenames.push_back("PressEveryKey")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(40);
	level_filenames.push_back("Weakness")
	level_filenames.push_back("Third Roommate [VAR1]")
	level_filenames.push_back("QuantumEntanglement")
	level_filenames.push_back("Levitation")
	level_filenames.push_back("Bring the Rope")
	level_filenames.push_back("InstantDefeat")
	level_filenames.push_back("InevitableDemise")
	level_filenames.push_back("ShippingSolutions")
	level_filenames.push_back("TheTower")
	level_filenames.push_back("InvisibleBridgeCrate")
	level_filenames.push_back("Jenga")
	
	chapter_names.push_back("There Are Many Colours");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(40);
	chapter_tracks.push_back(6);
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
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(48);
	level_filenames.push_back("LevelNotFoundEx2")
	level_filenames.push_back("Freedom")
	level_filenames.push_back("LevelNotFoundEx")
	level_filenames.push_back("Freedom [VAR1]")
	level_filenames.push_back("BlueAndRedEx")
	level_filenames.push_back("TheMagentaPitEx")
	level_filenames.push_back("TheGrayPitEx")
	level_filenames.push_back("PaperPlanesEx")
	level_filenames.push_back("Towerplex")
	level_filenames.push_back("TheMagentaPitEx2")
	level_filenames.push_back("InvisibleBridgeLMagenta")
	level_filenames.push_back("TheMagentaPitEx3")
	
	chapter_names.push_back("Change");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(48);
	chapter_tracks.push_back(7);
	chapter_skies.push_back(Color("#446570"));
	level_filenames.push_back("Ahhh")
	level_filenames.push_back("Eeep")
	level_filenames.push_back("LetMeIn")
	level_filenames.push_back("LadderWorldGlass")
	level_filenames.push_back("DemolitionSquad")
	level_filenames.push_back("Interleave")
	level_filenames.push_back("SpelunkingGlass")
	level_filenames.push_back("DoubleGlazed")
	level_filenames.push_back("TheGlassPit")
	level_filenames.push_back("The Glass Pit-")
	level_filenames.push_back("Aquarium")
	level_filenames.push_back("TreasureHunt")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(56);
	level_filenames.push_back("LetMeInEx")
	level_filenames.push_back("DoubleGlazedEx")
	level_filenames.push_back("HeavyMovingServiceGlass")
	level_filenames.push_back("IcyHot")
	level_filenames.push_back("TheGlassPitEx")
	level_filenames.push_back("Campfrost")
	level_filenames.push_back("SpelunkingGlassEx")
	level_filenames.push_back("TheRace")
	level_filenames.push_back("Glass Monolith")
	level_filenames.push_back("Deconstruct")
	
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
	level_filenames.push_back("Mundane")
	level_filenames.push_back("TheFuture")
	level_filenames.push_back("FasterThanLight")
	level_filenames.push_back("ColourQuest")
	level_filenames.push_back("LeadPlanes")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(64);
	level_filenames.push_back("LightHurtingService")
	level_filenames.push_back("LightHurtingServiceEx")
	level_filenames.push_back("DragonsGate")
	level_filenames.push_back("HelpYourselfEx")
	level_filenames.push_back("Skip")
	level_filenames.push_back("Impossible")
	level_filenames.push_back("LightHurtingServiceEx2")
	level_filenames.push_back("GreenGrass")
	level_filenames.push_back("SpikesGreenEx")
	level_filenames.push_back("CampfireGreenEx")
	level_filenames.push_back("Airdodging")
	
	chapter_names.push_back("Exotic Matter");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(64);
	chapter_tracks.push_back(8);
	chapter_skies.push_back(Color("#351731"));
	level_filenames.push_back("TheFuzz")
	level_filenames.push_back("DoubleFuzz")
	level_filenames.push_back("PushingItFurther")
	level_filenames.push_back("Elevator")
	level_filenames.push_back("Stuck")
	level_filenames.push_back("PingPong")
	level_filenames.push_back("FuzzyTrick")
	level_filenames.push_back("LimitedUndo")
	level_filenames.push_back("TimeStop")
	level_filenames.push_back("KingCrimson")
	level_filenames.push_back("Nomadic")
	level_filenames.push_back("AsTheWorldTurns")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(72);
	level_filenames.push_back("PingPongEx")
	level_filenames.push_back("ImaginaryMoves")
	level_filenames.push_back("DontLookDown")
	level_filenames.push_back("Durability")
	level_filenames.push_back("UnfathomableGlass")
	level_filenames.push_back("PushingItFurtherEx")
	level_filenames.push_back("KingCrimsonEx")
	level_filenames.push_back("Heavy Fuzzing Service")
	
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
	level_filenames.push_back("Remembrance")
	level_filenames.push_back("PushingItCrystal")
	level_filenames.push_back("Conservation")
	level_filenames.push_back("Accumulation")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(80);
	level_filenames.push_back("Elementary")
	level_filenames.push_back("BlockageEx")
	level_filenames.push_back("The Time Crystal Pits")
	level_filenames.push_back("Crystal Removing Service")
	level_filenames.push_back("Smuggler")
	level_filenames.push_back("Frangible")
	level_filenames.push_back("Switcheroo")
	level_filenames.push_back("StairwayToHeaven")
	
	chapter_names.push_back("Deadline");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(80);
	chapter_skies.push_back(Color("#2D0E07"));
	chapter_tracks.push_back(9);
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
	level_filenames.push_back("Permify")
	level_filenames.push_back("CelestialNavigation")
	level_filenames.push_back("Chronofrag")
	level_replacements[level_filenames.size()] = "Ω";
	level_filenames.push_back("ChronoLabReactor")
	
	chapter_names.push_back("Phase Blocks");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(96);
	chapter_replacements[chapter_names.size() - 1] = "[-]";
	chapter_skies.push_back(Color("#2F2B56"));
	chapter_tracks.push_back(6);
	level_filenames.push_back("The Red Phase Pit")
	level_filenames.push_back("Heavy Footing")
	level_filenames.push_back("The Blue Phase Pit")
	level_filenames.push_back("Pushing It Phases")
	level_filenames.push_back("The Gray Phase Pit")
	level_filenames.push_back("Safety Glass")
	level_filenames.push_back("The Purple Phase Pit")
	level_filenames.push_back("Just 3 Steps")
	level_filenames.push_back("The Purple Phase Pit [VAR1]")
	level_filenames.push_back("Phase Lightning")
	level_filenames.push_back("Lethal Rewind")
	level_filenames.push_back("Bunnyhop")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(4);
	level_filenames.push_back("The Red Phase Pit [VAR1]")
	level_filenames.push_back("The Blue Phase Pit [VAR1]")
	level_filenames.push_back("The Gray Phase Pit [VAR1]")
	level_filenames.push_back("Safety Glass [Safety Shortage]")
	level_filenames.push_back("Hopscorch-")
	level_filenames.push_back("Purple Safety Pit")
	level_filenames.push_back("The Phase Lightning Pit")
	
	chapter_names.push_back("Floorboards");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(128);
	chapter_replacements[chapter_names.size() - 1] = "A";
	chapter_skies.push_back(Color("#363C3F"));
	chapter_tracks.push_back(7);
	level_filenames.push_back("Boarding School")
	level_filenames.push_back("Simple Diffusion")
	level_filenames.push_back("Slippery Glass")
	level_filenames.push_back("Double Dose")
	level_filenames.push_back("Hardtack")
	level_filenames.push_back("Pushing It Magenta")
	level_filenames.push_back("Simultaneous Smuggle")
	level_filenames.push_back("Bunker Door")
	level_filenames.push_back("Miracle Switch")
	level_filenames.push_back("Cement Pit")
	level_filenames.push_back("Phantom Heist")
	level_filenames.push_back("The Floorboard Pit")
	level_filenames.push_back("Green Cement Pit")
	level_filenames.push_back("Green Adventure")
	level_filenames.push_back("Return Path")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_filenames.push_back("Green Adventure [VAR1]")
	level_filenames.push_back("Board Ring A")
	level_filenames.push_back("Gain Leverage")
	level_filenames.push_back("Verdant Crossroads")
	level_filenames.push_back("Cement Pit [VAR1]")
	level_filenames.push_back("Blackberry Bush")
	level_filenames.push_back("Triple Boarded")
	level_filenames.push_back("Phantom Heist [Low Power]")
	level_filenames.push_back("Slippery Glass [VAR1]")
	level_filenames.push_back("Hidden Potential")
	level_filenames.push_back("Duplication")
	level_filenames.push_back("Bridge Building")
	
	chapter_names.push_back("Afterlife");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(144);
	chapter_replacements[chapter_names.size() - 1] = "B";
	chapter_skies.push_back(Color("#28442A"));
	chapter_tracks.push_back(1);
	level_filenames.push_back("Life After Death")
	level_filenames.push_back("Hospital")
	level_filenames.push_back("Grate Access")
	level_filenames.push_back("Permafrost")
	level_filenames.push_back("Integrity Checker")
	level_filenames.push_back("Electrical Education")
	level_filenames.push_back("Sewer Crawl")
	level_filenames.push_back("Antigrated")
	level_filenames.push_back("Iron Barbecue")
	level_filenames.push_back("Zombie Mode")
	level_filenames.push_back("The Zombie Pit")
	level_filenames.push_back("Island of Stability")
	level_filenames.push_back("Undying Army (Type A)")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_filenames.push_back("Undying Army (Type B)")
	level_filenames.push_back("Toggle Latch")
	level_filenames.push_back("Three-Grate Monte")
	level_filenames.push_back("Hookjump")
	level_filenames.push_back("Death Smiles")
	level_filenames.push_back("Insurance Fraud")
	level_filenames.push_back("Stable Loop")
	level_filenames.push_back("Integrity Checker [VAR1]")
	level_filenames.push_back("Electrical Education [VAR1]")
	level_filenames.push_back("Timelock")
	level_filenames.push_back("Alternating Staircase")	
	level_filenames.push_back("Grate Catch.")
	level_filenames.push_back("Truly Unbounded Skies")
	level_filenames.push_back("Truly Unbounded Skies [VAR1]")
	
	chapter_names.push_back("Even More Crates");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(160);
	chapter_replacements[chapter_names.size() - 1] = "C";
	chapter_skies.push_back(Color("#514025"));
	chapter_tracks.push_back(5);
	level_filenames.push_back("Wooden Crates Tutorial")
	level_filenames.push_back("TimelessBridge")
	level_filenames.push_back("Wooden Gate")
	level_filenames.push_back("Drop Stop")
	level_filenames.push_back("Spare Door.")
	level_filenames.push_back("Forklift Certified")
	level_filenames.push_back("Power Crates Tutorial")
	level_filenames.push_back("Pushing It Power")
	level_filenames.push_back("PezDispenser")
	level_filenames.push_back("Donk")
	level_filenames.push_back("DonkEx")
	level_filenames.push_back("Steel Crates Tutorial")
	level_filenames.push_back("Clocksmasher")
	level_filenames.push_back("Simple Hierarchy")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_filenames.push_back("TheoryOfEverythingA")
	level_filenames.push_back("TheoryOfEverythingB")
	level_filenames.push_back("Woodskip")
	level_filenames.push_back("Unstacking Station")
	level_filenames.push_back("Wooden Glass")
	level_filenames.push_back("Donk [VAR2]")
	level_filenames.push_back("Bunker Door [VAR1]")
	level_filenames.push_back("One at a Time [VAR1]")
	level_filenames.push_back("Low Ceiling")
	level_filenames.push_back("Woodskip [VAR2]")
	
	chapter_names.push_back("Rocky Nudges");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(176);
	chapter_replacements[chapter_names.size() - 1] = "D";
	chapter_skies.push_back(Color("#324351"));
	chapter_tracks.push_back(3);
	level_filenames.push_back("Rushing Rivers")
	level_filenames.push_back("Sinkhole")
	level_filenames.push_back("The Nudge Pit")
	level_filenames.push_back("Gutter")
	level_filenames.push_back("Downwards Momentum")
	level_filenames.push_back("Conveyor")
	level_filenames.push_back("Constant Pushback")
	level_filenames.push_back("Boulder Tutorial")
	level_filenames.push_back("Newton's Cradle")
	level_filenames.push_back("when boulders fly")
	level_filenames.push_back("Surge Surfer")
	level_filenames.push_back("Centrism")
	level_filenames.push_back("Chain Reaction")
	
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(8);
	level_filenames.push_back("Springlock System")
	level_filenames.push_back("Costly Rewinds") #or banish to community
	level_filenames.push_back("Lead the way")
	level_filenames.push_back("Against The Flow")
	level_filenames.push_back("Conveyor [VAR1]")
	level_filenames.push_back("Sudden Stop")
	level_filenames.push_back("Vertical Catalyst")
	level_filenames.push_back("Boulder Moving Service")
	
	chapter_names.push_back("Victory Lap");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(256, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "-1";
	level_filenames.push_back("CliffsL2")
	level_filenames.push_back("CliffsL2Ex")
	level_filenames.push_back("RoommatesExL2")
	level_filenames.push_back("SpelunkingL2")
	level_filenames.push_back("UphillL2")
	level_filenames.push_back("DownhillL2")
	level_filenames.push_back("RoommatesL2")
	level_filenames.push_back("KnotL2")
	level_filenames.push_back("CarryingItL2")
	level_filenames.push_back("PachinkoL2")
	level_filenames.push_back("PachinkoL2Ex")
	level_filenames.push_back("PachinkoL2Ex2")
	level_filenames.push_back("TheFirstPitL2")
	level_filenames.push_back("TheFirstPitL2Ex")
	level_filenames.push_back("BraidL2")
	level_filenames.push_back("TallL2")
	level_filenames.push_back("TallL2Ex")
	level_filenames.push_back("WallL2")
	level_filenames.push_back("WallL2Ex")
	level_filenames.push_back("PushingItL2")
	level_filenames.push_back("PushingItL2Ex")
	level_filenames.push_back("OrientationL2")
	level_filenames.push_back("OrientationL2Ex")
	level_filenames.push_back("OrientationL2Ex2")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(level_filenames.size());
	level_replacements[level_filenames.size()] = "-1";
	level_filenames.push_back("Joke")
	
	custom_past_here = chapter_names.size();
	custom_past_here_level_count = level_filenames.size();
	
	chapter_names.push_back("Voices from the Void");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(36, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("No Strings Attached")
	level_filenames.push_back("Small Miracle")
	level_filenames.push_back("Wheelbarrow")
	level_filenames.push_back("Waterslide")
	level_filenames.push_back("Wall of Force")
	level_filenames.push_back("Pure Vertical")
	level_filenames.push_back("Beyond Even Gravity")
	level_filenames.push_back("Luxury Flight")
	level_filenames.push_back("Friendship Paradox")
	level_filenames.push_back("Proxy Timeline")
	level_filenames.push_back("Kinematic Stability")
	level_filenames.push_back("Spacetime Oven")
	level_filenames.push_back("Out of Service")
	level_filenames.push_back("Pittance")
	level_filenames.push_back("Second Wind")
	level_filenames.push_back("Ionic Capacitor")
	level_filenames.push_back("Mail-In Parasite")
	level_filenames.push_back("Lightspeed Quarry")
	level_filenames.push_back("Locke's Conjecture")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("The Cutting Room Floor (Unused Puzzles)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Hot Soup")
	level_filenames.push_back("Rise As One")
	level_filenames.push_back("Jello Kiddie Pool")
	level_filenames.push_back("Jello Kiddie Pool [VAR1]")
	level_filenames.push_back("Noisemaker")
	level_filenames.push_back("Doomsday Clock")
	level_filenames.push_back("Time Travel")
	level_filenames.push_back("Green Sokoban")
	level_filenames.push_back("Void Sokoban")
	level_filenames.push_back("Clockwork-")
	level_filenames.push_back("Consecutive Normal Pits")
	level_filenames.push_back("Soft Landing")
	level_filenames.push_back("Skippity")
	level_filenames.push_back("Skippity [VAR1]")
	level_filenames.push_back("Yet Another Crate Pit")
	level_filenames.push_back("Yet Another Crate Pit [VAR1]")
	level_filenames.push_back("Grounded Downhill")
	level_filenames.push_back("Grounded Uphill")
	level_filenames.push_back("Tiny Roast")
	level_filenames.push_back("Jewellery Theft")
	level_filenames.push_back("Tres Crates")
	level_filenames.push_back("The Glass Pit- [VAR1]")
	level_filenames.push_back("The Glass Pit- [VAR2]")
	level_filenames.push_back("Hot Soup [VAR1]")
	level_filenames.push_back("Hot Soup [VAR2]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("The Cutting Room Floor (Variants and Buffs)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Pushing It")
	level_filenames.push_back("Trust Fall [VAR2]")
	level_filenames.push_back("The Boundless Sky (Already Falling)")
	level_filenames.push_back("Coyote Time")
	level_filenames.push_back("Acrobatics but it's forced")
	level_filenames.push_back("Hell [VAR2]")
	level_filenames.push_back("Daredevils [VAR1]")
	level_filenames.push_back("Broken Bridge [VAR1]")
	level_filenames.push_back("TimelessBridgeEx")
	level_filenames.push_back("Light Moooving Service [VAR1]")
	level_filenames.push_back("Booster Seat [VAR1]")
	level_filenames.push_back("Down [VAR1]")
	level_filenames.push_back("World's Tiniest Pit")
	level_filenames.push_back("Firewall (Loop 2)")
	level_filenames.push_back("Leap of Faith [Space Program]")
	level_filenames.push_back("Heavy Moving Service [VAR1]")
	level_filenames.push_back("Heavy Moving Service [VAR2]")
	level_filenames.push_back("Heavy Moving Service [VAR3]")
	level_filenames.push_back("Light Moving Service [VAR1]")
	level_filenames.push_back("Light Moving Service [VAR2]")
	level_filenames.push_back("Glass Monolith (glass shortage)")
	level_filenames.push_back("Engine Room [VAR1]")
	level_filenames.push_back("Collectathon [VAR1]")
	level_filenames.push_back("Firefighters (ladder shortage) [VAR1]")
	level_filenames.push_back("Joke--")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Formless Exploration (Best Of)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Clockwork")
	level_filenames.push_back("Microstatic")
	level_filenames.push_back("Tiny Outpost")
	level_filenames.push_back("Firewalkers")
	level_filenames.push_back("Inexorable Destruction-")
	level_filenames.push_back("Sandra's Magic Trick")
	level_filenames.push_back("Osmosis")
	level_filenames.push_back("Soulcrates")
	level_filenames.push_back("In Defiance of Time-")
	level_filenames.push_back("Circle Dance-")
	level_filenames.push_back("In Defiance of Time [VAR1]")
	level_filenames.push_back("Unpacking")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Formless Exploration (Page 1)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Floor Change")
	level_filenames.push_back("[SPEEDRUN] - Shattered Sky")
	level_filenames.push_back("Limitations of Love.")
	level_filenames.push_back("Window of Oppertunity")
	level_filenames.push_back("Grate Expectations")
	level_filenames.push_back("Stepping Stone [Loop 2]")
	level_filenames.push_back("Eau de Null")
	level_filenames.push_back("Friction")
	level_filenames.push_back("Convergence")
	level_filenames.push_back("[Troll] - Light Instantly Dies.")
	level_filenames.push_back("Liquidation")
	level_filenames.push_back("Sandra's Idea")
	level_filenames.push_back("Smooth Sailing")
	level_filenames.push_back("Combination Lockdown")
	level_filenames.push_back("King Crimson-")
	level_filenames.push_back("Airstall")
	level_filenames.push_back("Logging Out")
	level_filenames.push_back("Logging Out [VAR1]")
	level_filenames.push_back("In Defiance of Time")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Formless Exploration (Page 2)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Red Replica")
	level_filenames.push_back("Too Many Roommates")
	level_filenames.push_back("Jumpless Jack")
	level_filenames.push_back("Simple Uphill")
	level_filenames.push_back("Self Care")
	level_filenames.push_back("Self Sacrifice")
	level_filenames.push_back("Anonymous Delivery")
	level_filenames.push_back("Stealing from Fort Knex")
	level_filenames.push_back("Erase [VAR1]")
	level_filenames.push_back("Curveball")
	level_filenames.push_back("Superpush")
	level_filenames.push_back("Fuzzy Patch")
	level_filenames.push_back("Portal Repairing Crew (Insight)")
	level_filenames.push_back("Circle Dance")
	level_filenames.push_back("Spacetime Launch")
	level_filenames.push_back("Spacetime Launch-")
	level_filenames.push_back("Flamepatch")
	level_filenames.push_back("Fragile Victory")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Formless Exploration (Page 3)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Remote Controlled Cobblestone")
	level_filenames.push_back("Spitroast")
	level_filenames.push_back("Compact Complex")
	level_filenames.push_back("Blast Furnace")
	level_filenames.push_back("Roofing Services")
	level_filenames.push_back("Mini Geode")
	level_filenames.push_back("Inexorable Destruction")
	level_filenames.push_back("Survival Section")
	level_filenames.push_back("Crate Expectations-")
	level_filenames.push_back("Flow Control-")
	level_filenames.push_back("No(Thing) Left")
	level_filenames.push_back("Sacrificial Ditch")
	level_filenames.push_back("Clock Storage Solutions.")
	level_filenames.push_back("Revenge of an Old Future")
	level_filenames.push_back("Roast-")
	level_filenames.push_back("The Split")
	level_filenames.push_back("Mini Way In-")
	level_filenames.push_back("Minidane")
	level_filenames.push_back("Mini Cascade")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Formless Exploration (Page 4)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Super Basic Sokoban")
	level_filenames.push_back("Sandra Embraces The Void")
	level_filenames.push_back("Selfie")
	level_filenames.push_back("Give me a Break")
	level_filenames.push_back("Another Light-")
	level_filenames.push_back("Lost Height")
	level_filenames.push_back("Green Glass [VAR1.1]")
	level_filenames.push_back("Bounce Castle")
	level_filenames.push_back("Passing Through Matter")
	level_filenames.push_back("Lego Tower")
	level_filenames.push_back("Monochrome")
	level_filenames.push_back("Clockwork 3- Metallic Boogaloo")
	level_filenames.push_back("Ventriloquy")
	level_filenames.push_back("Brutalist Absurdism")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Slabdrill's World (Best Of)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Light Bridge")
	level_filenames.push_back("Death's Door")
	level_filenames.push_back("Meet Heavy (Loop 2)")
	level_filenames.push_back("Limitations of Love. [VAR1]")
	level_filenames.push_back("Nomadic [VAR1]")
	level_filenames.push_back("Jungle Gym")
	level_filenames.push_back("Side Shuffle")
	level_filenames.push_back("Fire In The Sky [REV1]")
	level_filenames.push_back("Death's Door [VAR1]")
	level_filenames.push_back("Phantom Push [VAR1]")
	level_filenames.push_back("The Withering Pit")
	level_filenames.push_back("Downfall")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	level_filenames.push_back("Quantum Entanglement [VAR2]")
	level_filenames.push_back("Acrobat's Escape [VAR3]")
	level_filenames.push_back("Invisible Bridge (for Heavy) [VAR3]")
	level_filenames.push_back("Heavy Fuzzing Service [VAR1]")
	level_filenames.push_back("Void Recovery")
	level_filenames.push_back("Heavy Fuzzing Service [VAR2]")
	level_filenames.push_back("Foot Wiggle [VAR3]")
	level_filenames.push_back("Foot Wiggle [VAR4]")
	level_filenames.push_back("Graduation [VAR3]")
	level_filenames.push_back("Spelunking-- [VAR2]")
	level_filenames.push_back("Pittance [VAR1]")
	
	chapter_names.push_back("Slabdrill's World (Only Pits)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("The White Pit")
	level_filenames.push_back("The Checkpoint Pit")
	level_filenames.push_back("The Greenish Pit")
	level_filenames.push_back("The Voidish Pit")
	level_filenames.push_back("The Yellow Pit")
	level_filenames.push_back("The Crate Pit-")
	level_filenames.push_back("Bad Widget Pit")
	level_filenames.push_back("The Falling Pit")
	level_filenames.push_back("The Grounded Pit")
	level_filenames.push_back("Consecutive Normal Pits [VAR1]")
	level_filenames.push_back("Look It's Another Pit")
	level_filenames.push_back("The RGB Pit")
	level_filenames.push_back("The Last Pit [VAR3]")
	level_filenames.push_back("The Joke Pit")
	level_filenames.push_back("The Left Pit")
	level_filenames.push_back("The Solo Pit")
	level_filenames.push_back("The Steel Crate Pit")
	level_filenames.push_back("The Green Fire Pit")
	level_filenames.push_back("The Glass Pit [VAR2]")
	level_filenames.push_back("The Half-Magenta Pit")
	level_filenames.push_back("The Half-Magenta Pit [VAR1]")
	level_filenames.push_back("The Crate Pit- [VAR1]")
	level_filenames.push_back("The Eclipse Pit")
	level_filenames.push_back("The Magenta Pit [VAR4]")
	level_filenames.push_back("The Magenta Pit [VAR5]")
	level_filenames.push_back("The Twin Pit")
	level_filenames.push_back("Consecutive Normal Pits [VAR2]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Slabdrill's World (Page 1 - easiest)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Fuzzy Parkour [VAR1]")
	level_filenames.push_back("Invisible Void Bridge")
	level_filenames.push_back("Collaborative Motion")
	level_filenames.push_back("Quantum Entanglement [VAR1]")
	level_filenames.push_back("Rise As One [VAR1]")
	level_filenames.push_back("Magenta Flight")
	level_filenames.push_back("Wall (Insight) [VAR1]")
	level_filenames.push_back("Hopscorch [VAR2]")
	level_filenames.push_back("Timeless Bridge [VAR2]")
	level_filenames.push_back("Slippery Glass [VAR2]")
	level_filenames.push_back("Crate Moving Service")
	level_filenames.push_back("Over-Destination [VAR1]")
	level_filenames.push_back("Spelunking-- [VAR3]")
	level_filenames.push_back("Rapid Ascent")
	level_filenames.push_back("Tile Selector")
	level_filenames.push_back("Heavy Vertical")
	level_filenames.push_back("Parity Drive")
	level_filenames.push_back("Unaliving Service")
	level_filenames.push_back("Elevator Pitch")
	level_filenames.push_back("Green Glass [VAR2]")
	level_filenames.push_back("Top Security")
	level_filenames.push_back("Rocket Engine-")
	level_filenames.push_back("Campfrost [VAR2]")
	level_filenames.push_back("Graduation [VAR1]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Slabdrill's World (Page 2)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Downwards Momentum [VAR1]")
	level_filenames.push_back("Tile Selector [VAR1]")
	level_filenames.push_back("Heaven [REV1]")
	level_filenames.push_back("Rough Terrain [VAR1]")
	level_filenames.push_back("Acrobatics 3- Metallic Boogaloo")
	level_filenames.push_back("Inexorable Destruction- [VAR1]")
	level_filenames.push_back("Snake Chute [VAR1]")
	level_filenames.push_back("Invisible Bridge (for Heavy) [VAR1]")
	level_filenames.push_back("Ankh [VAR2]")
	level_filenames.push_back("Crystalformer")
	level_filenames.push_back("Elementary [VAR1]")
	level_filenames.push_back("Island of Stability [VAR1]")
	level_filenames.push_back("Flaming Coronation [VAR1]")
	level_filenames.push_back("Phantom Push")
	level_filenames.push_back("Light Boots")
	level_filenames.push_back("Spontaneous Combustion- [VAR1]")
	level_filenames.push_back("Elevator Pitch 2")
	level_filenames.push_back("Elevator Pitch 3")
	level_filenames.push_back("Elevator Pitch 3 [VAR1]")
	level_filenames.push_back("Downfall 2")
	level_filenames.push_back("Undying Army (Type C)")
	level_filenames.push_back("Unaliving Service [VAR1]")
	level_filenames.push_back("Anonymous Delivery [VAR1]")
	level_filenames.push_back("Bonfire (Insight) [VAR1]")
	level_filenames.push_back("Falling Uphill")
	level_filenames.push_back("Grounded Uphill [VAR1]")
	level_filenames.push_back("Invisible Bridge (for Heavy) Magenta")
	level_filenames.push_back("Underflow")
	level_filenames.push_back("Woodskip [VAR1]")
	level_filenames.push_back("Steel Crates Tutorial [VAR1]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Slabdrill's World (Page 3)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Jet Engine [VAR1]")
	level_filenames.push_back("Impostor Syndrome")
	level_filenames.push_back("Lunar Gravity [VAR1]")
	level_filenames.push_back("Delay Circuit")
	level_filenames.push_back("Acrobatics but it's forced [VAR1]")
	level_filenames.push_back("Voidly Moving Service")
	level_filenames.push_back("Ankh [VAR1]")
	level_filenames.push_back("Down [VAR2]")
	level_filenames.push_back("Fragile Victory [VAR1]")
	level_filenames.push_back("Stack Split")
	level_filenames.push_back("One-Way Bridge")
	level_filenames.push_back("Rough Terrain [VAR2]")
	level_filenames.push_back("Durability-")
	level_filenames.push_back("Combination Lock")
	level_filenames.push_back("Firemaze")
	level_filenames.push_back("Jello Partition")
	level_filenames.push_back("Separated Escape")
	level_filenames.push_back("In Defiance of Time [VAR1] [VAR1]")
	level_filenames.push_back("Collaborative Motion (Floor Shortage)")
	level_filenames.push_back("Remote Voyage [VAR1]")
	level_filenames.push_back("Underflow [VAR1]")
	level_filenames.push_back("Light's Way In")
	level_filenames.push_back("Acrobatics (Loop 2)")
	level_filenames.push_back("Orbital Drop [VAR1]")
	level_filenames.push_back("Orbital Drop [VAR2]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Slabdrill's World (Page 4 - hardest)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Jenga-")
	level_filenames.push_back("Crate Tunneling")
	level_filenames.push_back("Truly Unbounded Skies [VAR2]")
	level_filenames.push_back("Compact Transport")
	level_filenames.push_back("Compact Transport [VAR1]")
	level_filenames.push_back("Bunnyhop [VAR1]")
	level_filenames.push_back("Rough Terrain [VAR3]")
	level_filenames.push_back("Invisible Bridge (for Heavy) [VAR2]")
	level_filenames.push_back("Foot Wiggle [VAR5]")
	level_filenames.push_back("Engine Room [VAR2]")
	level_filenames.push_back("Friendship Paradox [VAR2]")
	level_filenames.push_back("Leap of Faith [Space Program] [VAR1]")
	level_filenames.push_back("Elevator Pitch [VAR1]")
	level_filenames.push_back("Void Harness")
	level_filenames.push_back("Void Harness [VAR1]")
	level_filenames.push_back("Void Harness [VAR2]")
	level_filenames.push_back("Inverse Nudge Chain")
	level_filenames.push_back("Crate Sorting Facility")
	level_filenames.push_back("Impossible Chime")
	level_filenames.push_back("Joke-")
	level_filenames.push_back("[SPEEDRUN] A Way In-")
	level_filenames.push_back("Entropy Extractor")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("dead0ne's World");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Third Roommate [VAR-]")
	level_filenames.push_back("Second Wind [VAR1]")
	level_filenames.push_back("Friendship Paradox [VAR1]")
	level_filenames.push_back("Purest Verticalest")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Green's World (Page 1)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Cascade [VAR1]")
	level_filenames.push_back("Zipper")
	level_filenames.push_back("True Micro Puzzle")
	level_filenames.push_back("True Micro Puzzle 2")
	level_filenames.push_back("Graduation [VAR2]")
	level_filenames.push_back("[SPEEDRUN] Collaborative Motion")
	level_filenames.push_back("Limited Rewind [VAR1]")
	level_filenames.push_back("Skip [VAR1]")
	level_filenames.push_back("Wither [VAR1]")
	level_filenames.push_back("As The World Turns [VAR1]")
	level_filenames.push_back("Waterslide (Waterslide Shortage)")
	level_filenames.push_back("Cement Pit [VAR2]")
	level_filenames.push_back("Rock Glider")
	level_filenames.push_back("Rock Slider")
	level_filenames.push_back("Wooden Gate [VAR1]")
	level_filenames.push_back("Skipping Stone")
	level_filenames.push_back("Skipping Stone [VAR1]")
	level_filenames.push_back("Spring Boots")
	level_filenames.push_back("Springlock System [VAR1]")
	level_filenames.push_back("Not Enough Nothing")
	level_filenames.push_back("Yesclip")
	level_filenames.push_back("Orientation (Loop 2) [VAR1] [VAR1]")
	level_filenames.push_back("Revenge of an Old Future [VAR1]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Green's World (Page 2)");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Remote Voyage [VAR2]")
	level_filenames.push_back("The Grounded Pit [VAR1]")
	level_filenames.push_back("The Rising Pit")
	level_filenames.push_back("Down [VAR3]")
	level_filenames.push_back("Magic Hat")
	level_filenames.push_back("Shared Brain Cells")
	level_filenames.push_back("The Imaginary Pit")
	level_filenames.push_back("Graduation [VAR4]")
	level_filenames.push_back("Invisible Void Bridge [VAR1]")
	level_filenames.push_back("[SPEEDRUN] Erase")
	level_filenames.push_back("[SPEEDRUN] Lego Tower")
	level_filenames.push_back("[SPEEDRUN] One at a Time [VAR1]")
	level_filenames.push_back("Reflections [VAR1]")
	level_filenames.push_back("[SPEEDRUN] Pathology")
	level_filenames.push_back("[SPEEDRUN] Midnight Parkour")
	level_filenames.push_back("Void Fire (Void Fire Shortage)")
	level_filenames.push_back("Void Harness [VAR3]")
	level_filenames.push_back("Graduation [VAR5]")
	level_filenames.push_back("Proxy Timeline-")
	level_filenames.push_back("Newton's Cradle [VAR1]")
	level_filenames.push_back("Switcheroo [VAR1]")
	level_filenames.push_back("[SPEEDIERRUN] A Way In-")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Onatron's World");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Power Bar")
	level_filenames.push_back("Halfpipe")
	level_filenames.push_back("Roommates [VAR1] [VAR1]")
	level_filenames.push_back("Spontaneous Combustion [VAR1]")
	level_filenames.push_back("Roast- [VAR1]")
	level_filenames.push_back("Roast- [VAR2]")
	level_filenames.push_back("Bungee Jumping")
	level_filenames.push_back("Fickle Flooring")
	level_filenames.push_back("Hopscorch [VAR3]")
	level_filenames.push_back("Ceiling Sockets")
	level_filenames.push_back("Ceiling Sockets [VAR1]")
	level_filenames.push_back("Chrono Engine")
	level_filenames.push_back("Halfpipe [VAR1]")
	level_filenames.push_back("Green Campfire [VAR1]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Mikan Hako's World");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Boulder Moving Service [VAR1]")
	level_filenames.push_back("Grate Catch. [VAR1]")
	level_filenames.push_back("Quantum Entanglement [VAR2] [Low Power]")
	level_filenames.push_back("[MORESPEEDIERRUN] A Way In-")
	level_filenames.push_back("[SPEEDRUN] Third Roommate [VAR1]")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Limits of the Game");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("booster tutorial")
	level_filenames.push_back("green booster tutorial")
	level_filenames.push_back("SO LONG GAY HOLE")
	level_filenames.push_back("The Wall (alpha build)")
	level_filenames.push_back("Cannon")
	level_filenames.push_back("sudden drop and a crash")
	level_filenames.push_back("The begging of the dark")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	chapter_names.push_back("Bug Gallery");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(min(24, level_filenames.size()));
	chapter_skies.push_back(Color("#223C52"));
	chapter_tracks.push_back(0);
	chapter_replacements[chapter_names.size() - 1] = "CUSTOM";
	level_filenames.push_back("Noclip")
	level_filenames.push_back("Playing Dead")
	level_filenames.push_back("Light Trolling")
	level_filenames.push_back("Light Trolling [VAR1]")
	level_filenames.push_back("Light Trolling [VAR2]")
	level_filenames.push_back("Light Trolln't")
	level_filenames.push_back("Light Trolln't [VAR1]")
	level_filenames.push_back("Crystal Stack")
	level_filenames.push_back("Crystals Tack")
	level_filenames.push_back("Angry Chomper")
	level_filenames.push_back("(Cry)Stall")
	level_filenames.push_back("Negativity")
	level_filenames.push_back("Cut And Paste")
	level_filenames.push_back("Repeat Customer")
	level_filenames.push_back("phaseboard phasetrough")
	level_filenames.push_back("Violent pushback")
	level_filenames.push_back("time crash")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);
	
	# sentinel to make overflow checks easy
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_advanced_starting_levels.push_back(level_filenames.size());

#	if (OS.is_debug_build()):
#		OS.set_clipboard(str(level_filenames));

	var current_standard_index = 0;
	var current_advanced_index = 0;
	var currently_extra = false;
	var next_flip = chapter_advanced_starting_levels[current_advanced_index];
	for i in range(level_filenames.size()):
		if (i >= next_flip):
			if currently_extra:
				currently_extra = false;
				current_advanced_index += 1;
				next_flip = chapter_advanced_starting_levels[current_advanced_index];
			else:
				currently_extra = true;
				current_standard_index += 1;
				next_flip = chapter_standard_starting_levels[current_standard_index];
		level_extraness.push_back(currently_extra);
	
	for level_filename in level_filenames:
		level_list.push_back(load("res://levels/" + level_filename + ".tscn"));
	
	for level_prototype in level_list:
		var level = level_prototype.instance();
		var level_name = level.get_node("LevelInfo").level_name;
		if (OS.is_debug_build()):
			if (level_names.has(level_name)):
				print("DUPLICATE NAME: ", level_name);
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
			if (insight_level_name.find("(Insight)")) >= 0:
				pass
			elif insight_level_name.find("(Remix)") >= 0 or insight_level_name.find("World's Smallest Puzzle") >= 0 or insight_level_name.find("Theory of Everything") >= 0 or insight_level_name.find("Board Ring B") >= 0:
				has_remix[level_name] = true;
				has_remix[insight_level_name] = true;
			insight_level_names[level_name] = insight_level_name;
			if (OS.is_debug_build()):
				if (level_names.has(insight_level_name)):
					print("DUPLICATE NAME: ", insight_level_name);
			insight_level.queue_free();
		
	refresh_puzzles_completed();
		
func refresh_puzzles_completed() -> void:
	puzzles_completed = 0;
	advanced_puzzles_completed = 0;
	specific_puzzles_completed = [];
	for i in range(level_list.size()):
		var level_name = level_names[i];
		if save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]:
			specific_puzzles_completed.push_back(true);
			if (i >= custom_past_here_level_count):
				continue;
			puzzles_completed += 1;
			if (level_extraness[i]):
				advanced_puzzles_completed += 1;
		else:
			specific_puzzles_completed.push_back(false);

var falling_bug : bool = false;
var falling_bug_2 : bool = false;
var has_crate_goals : bool = false;
var has_phase_walls : bool = false;
var has_phase_lightning : bool = false;
var has_checkpoints : bool = false;
var has_green_fog : bool = false;
var has_floorboards : bool = false;
var has_phaseboards : bool = false;
var has_holes : bool = false;
var has_boost_pads : bool = false;
var has_slopes : bool = false;
var has_boulders : bool = false;
var has_nudges : bool = false;
var has_limited_undo : bool = false;
var has_repair_stations : bool = false;
var has_eclipses : bool = false;
var has_night_or_stars : bool = false;
var has_ghost_fog : bool = false;
var has_spotlights : bool = false;
var has_continuums : bool = false;
var has_void_gates : bool = false;
var has_singularities : bool = false;
var has_void_fires : bool = false;
var has_void_walls : bool = false;
var has_void_fog : bool = false;
var has_void_stars : bool = false;
var has_mimics : bool = false;
var limited_undo_sprites = {};

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
	for whatever in underterrainfolder.get_children():
		whatever.queue_free();
	for whatever in actorsfolder.get_children():
		whatever.queue_free();
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
	timeline_activation_change();
	user_replay = "";
	meta_redo_inputs = "";
	preserving_meta_redo_inputs = false;
	
	var level_info = terrainmap.get_node_or_null("LevelInfo");
	if (level_info != null): # might be a custom puzzle
		level_name = level_info.level_name;
		level_author = level_info.level_author;
		annotated_authors_replay = level_info.level_replay;
		if ("$" in annotated_authors_replay):
			var authors_replay_parts = annotated_authors_replay.split("$");
			authors_replay = authors_replay_parts[authors_replay_parts.size()-1];
		else:
			authors_replay = annotated_authors_replay;
		heavy_max_moves = int(level_info.heavy_max_moves);
		light_max_moves = int(level_info.light_max_moves);
		clock_turns = level_info.clock_turns;
	
	has_insight_level = false;
	insight_level_scene = null;
	if (!is_custom or is_community_level):
		var insight_path = "res://levels/insight/" + level_filenames[level_number] + "Insight.tscn";
		if (ResourceLoader.exists(insight_path)):
			has_insight_level = true;
			insight_level_scene = load(insight_path);
	
	if (is_custom):
		is_community_level = false;
	elif (chapter >= custom_past_here):
		is_custom = true;
		is_community_level = true;
	else:
		is_community_level = false;
		
	#compat flags
	falling_bug = false;
	if (level_name.find("Light Trolling") >= 0 or level_name.find("Crystal Stack") >= 0 or level_name.find("(Cry)Stall") >= 0):
		floating_text("Compat flag: Early gravity end bug enabled.");
		falling_bug = true;
		
	falling_bug_2 = false;
	if (level_name.find("phaseboard phasetrough") >= 0 or level_name.find("Light Trolling") >= 0 or level_name.find("Light Trolln't") >= 0 or level_name.find("Crystal Stack") >= 0 or level_name.find("Crystals Tack") >= 0):
		floating_text("Compat flag: Falling into stack bug enabled.");
		falling_bug_2 = true;
	
	# if any of these become non-custom, then I can always check them or remove the boolean
	has_crate_goals = false;
	has_phase_walls = false;
	has_phase_lightning = false;
	has_checkpoints = false;
	has_green_fog = false;
	has_floorboards = false;
	has_phaseboards = false;
	has_holes = false;
	has_boost_pads = false;
	has_slopes = false;
	has_boulders = false;
	has_nudges = false;
	has_limited_undo = false;
	has_repair_stations = false;
	has_night_or_stars = false;
	has_ghost_fog = false;
	has_spotlights = false;
	has_continuums = false;
	has_void_gates = false;
	has_singularities = false;
	has_void_fires = false;
	has_void_walls = false;
	has_void_fog = false;
	has_void_stars = false;
	has_mimics = false;
	limited_undo_sprites.clear();
	
	if (any_layer_has_this_tile(Tiles.CrateGoal)):
		has_crate_goals = true;
		
	if (any_layer_has_this_tile(Tiles.TheNight) or any_layer_has_this_tile(Tiles.TheStars)):
		has_night_or_stars = true;
	
	if (any_layer_has_this_tile(Tiles.NoUndo)):
		has_limited_undo = true;
	elif (any_layer_has_this_tile(Tiles.OneUndo)):
		has_limited_undo = true;
	
	if (is_custom or chapter >= 12):
		# note: if I add Superpush to ch9, I would need to move this up top
		if (any_layer_has_this_tile(Tiles.Fuzz)):
			fuzz_rotation();
		
		if (any_layer_has_this_tile(Tiles.Floorboards)):
			has_floorboards = true;
		elif (any_layer_has_this_tile(Tiles.GreenFloorboards)):
			has_floorboards = true;
		elif (any_layer_has_this_tile(Tiles.VoidFloorboards)):
			has_floorboards = true;
		elif (any_layer_has_this_tile(Tiles.MagentaFloorboards)):
			has_floorboards = true;
			
		if (has_floorboards):
			floorboards_rotation();
			
		if (any_layer_has_this_tile(Tiles.PhaseWallBlue)):
			has_phase_walls = true;
		elif (any_layer_has_this_tile(Tiles.PhaseWallRed)):
			has_phase_walls = true;
		elif (any_layer_has_this_tile(Tiles.PhaseWallGray)):
			has_phase_walls = true;
		elif (any_layer_has_this_tile(Tiles.PhaseWallPurple)):
			has_phase_walls = true;
			
		if (any_layer_has_this_tile(Tiles.PhaseLightningBlue)):
			has_phase_lightning = true;
		elif (any_layer_has_this_tile(Tiles.PhaseLightningRed)):
			has_phase_lightning = true;
		elif (any_layer_has_this_tile(Tiles.PhaseLightningGray)):
			has_phase_lightning = true;
		elif (any_layer_has_this_tile(Tiles.PhaseLightningPurple)):
			has_phase_lightning = true;
			
		if (any_layer_has_this_tile(Tiles.RepairStation)):
			has_repair_stations = true;
		elif (any_layer_has_this_tile(Tiles.RepairStationGray)):
			has_repair_stations = true;
		elif (any_layer_has_this_tile(Tiles.RepairStationGreen)):
			has_repair_stations = true;
		elif (any_layer_has_this_tile(Tiles.RepairStationBumper)):
			has_repair_stations = true;
			
		if (any_layer_has_this_tile(Tiles.Boulder)):
			has_boulders = true;
			
		if (any_layer_has_this_tile(Tiles.NudgeEast)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeNorth)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeSouth)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeWest)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeEastGreen)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeNorthGreen)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeSouthGreen)):
			has_nudges = true;
		elif (any_layer_has_this_tile(Tiles.NudgeWestGreen)):
			has_nudges = true;
	
	if (is_custom):
		if (any_layer_has_this_tile(Tiles.Checkpoint)):
			has_checkpoints = true;
		elif (any_layer_has_this_tile(Tiles.CheckpointBlue)):
			has_checkpoints = true;
		elif (any_layer_has_this_tile(Tiles.CheckpointRed)):
			has_checkpoints = true;
			
		if (any_layer_has_this_tile(Tiles.GreenFog)):
			has_green_fog = true;
			
		if (any_layer_has_this_tile(Tiles.Hole)):
			has_holes = true;
		elif (any_layer_has_this_tile(Tiles.GreenHole)):
			has_holes = true;
		elif (any_layer_has_this_tile(Tiles.VoidHole)):
			has_holes = true;
			
		if (any_layer_has_this_tile(Tiles.BoostPad)):
			has_boost_pads = true;
		elif (any_layer_has_this_tile(Tiles.GreenBoostPad)):
			has_boost_pads = true;
			
		if (any_layer_has_this_tile(Tiles.SlopeNE)):
			has_slopes = true;
		elif (any_layer_has_this_tile(Tiles.SlopeNW)):
			has_slopes = true;
		elif (any_layer_has_this_tile(Tiles.SlopeSE)):
			has_slopes = true;
		elif (any_layer_has_this_tile(Tiles.SlopeSW)):
			has_slopes = true;
			
		if (any_layer_has_this_tile(Tiles.Eclipse)):
			has_eclipses = true;
			
		if (any_layer_has_this_tile(Tiles.PhaseBoardRed)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardBlue)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardGray)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardPurple)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardDeath)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardLife)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardHeavy)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardLight)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardCrate)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardVoid)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardEast)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardNorth)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardSouth)):
			has_floorboards = true;
			has_phaseboards = true;
		elif (any_layer_has_this_tile(Tiles.PhaseBoardWest)):
			has_floorboards = true;
			has_phaseboards = true;
			
		if (has_phaseboards):
			phaseboards_rotation();
			
		if (any_layer_has_this_tile(Tiles.GhostFog)):
			has_ghost_fog = true;
		elif (any_layer_has_this_tile(Tiles.PurpleFog)):
			has_ghost_fog = true;
			
		if (any_layer_has_this_tile(Tiles.Spotlight)):
			has_spotlights = true;
			
		if (any_layer_has_this_tile(Tiles.Continuum)):
			has_continuums = true;
			
		if (any_layer_has_this_tile(Tiles.GateOfDemise)):
			has_void_gates = true;
		elif (any_layer_has_this_tile(Tiles.GateOfEternity)):
			has_void_gates = true;
			
		if (any_layer_has_this_tile(Tiles.VoidSingularity)):
			has_singularities = true;
			
		if (any_layer_has_this_tile(Tiles.VoidFire)):
			has_void_fires = true;
			
		if (any_layer_has_this_tile(Tiles.VoidWall)):
			has_void_walls = true;
			
		if (any_layer_has_this_tile(Tiles.VoidFog)):
			has_void_fog = true;
			
		if (any_layer_has_this_tile(Tiles.VoidStars)):
			has_void_stars = true;
			
		if (any_layer_has_this_tile(Tiles.HeavyMimic)):
			has_mimics = true;
		elif (any_layer_has_this_tile(Tiles.LightMimic)):
			has_mimics = true;
	
	calculate_map_size();
	make_actors();
	
	#have to do it now so it layers on top of other actors
	if (has_limited_undo):
		setup_limited_undo_sprites();
	
	#have to do it now when underterrainfolder is positioned
	if (level_name == "Chrono Lab Reactor"):
		# maintain cutscene music if it's playing
		if (current_track == 14):
			target_track = 14;
			fadeout_timer_max = 0.0;
			fadeout_timer = 0.0;
		var bg = Sprite.new();
		bg.texture = load("res://assets/cutscenes/reactor_bg.png");
		bg.centered = false;
		bg.modulate = Color(1, 1, 1, 0.5);
		bg.position = Vector2(-underterrainfolder.position.x, -underterrainfolder.position.y);
		underterrainfolder.add_child(bg);
	
	initialize_timeline_viewers(); # has to be before setup_replay
	
	if (level_info.setup_replay != ""):
		setup_replay(level_info.setup_replay);
	
	finish_animations(Chrono.TIMELESS);
	update_info_labels();
	check_won(Chrono.TIMELESS);
	
	for goal in goals:
		goal.instantly_reach_scalify();
	
	ready_tutorial();
	update_level_label();
	maybe_update_phaseboards(Chrono.MOVE);
	intro_hop();
	
func setup_limited_undo_sprites() -> void:
	var poses = get_used_cells_by_id_one_array(Tiles.NoUndo);
	var more_poses = get_used_cells_by_id_one_array(Tiles.OneUndo);
	poses.append_array(more_poses);
	for pos in poses:
		if !limited_undo_sprites.has(pos):
			var sprite = Sprite.new();
			sprite.set_script(preload("res://OneTimeSprite.gd"));
			sprite.texture = preload("res://assets/undo_dice.png");
			sprite.position = terrainmap.map_to_world(pos);
			sprite.vframes = 1;
			sprite.hframes = 6;
			sprite.frame = 0;
			sprite.centered = false;
			sprite.frame_timer_max = 1e100;
			sprite.frame_max = 99;
			actorsfolder.add_child(sprite);
			limited_undo_sprites[pos] = sprite;
	
	for pos in limited_undo_sprites:
		update_limited_undo_sprite(pos);
	
func update_limited_undo_sprite(pos: Vector2) -> void:
	var sprite = limited_undo_sprites[pos];
	var terrain = terrain_in_tile(pos, null, Chrono.TIMELESS, true);
	var count = 0;
	for id in terrain:
		if id == Tiles.OneUndo:
			count += 1;
	
	if count > 6:
		count = 6;
	
	if count == 0 and sprite.texture != preload("res://assets/undo_eye.png"):
		sprite.texture = preload("res://assets/undo_eye.png");
		sprite.hframes = 5;
		sprite.frame = 0;
		sprite.frame_timer = 0.0;
		sprite.frame_timer_max = 0.1;
		sprite.frame_max = 99;
	else:
		sprite.texture = preload("res://assets/undo_dice.png");
		sprite.hframes = 6;
		sprite.frame = count - 1;
		sprite.frame_timer_max = 1e100;
		sprite.frame_max = 99;
	
func intro_hop() -> void:
	if (!ready_done):
		return;
	var dur = 0.5;
	heavy_actor.modulate.a = 0.0;
	add_to_animation_server(heavy_actor, [Anim.fade, 0.0, 1.0, dur]);
	if (heavy_max_moves > 0):
		add_to_animation_server(heavy_actor, [Anim.stall, dur/2]);
		add_to_animation_server(heavy_actor, [Anim.intro_hop]);
	light_actor.modulate.a = 0.0;
	add_to_animation_server(light_actor, [Anim.fade, 0.0, 1.0, dur]);
	if (light_max_moves > 0):
		add_to_animation_server(light_actor, [Anim.stall, dur/2]);
		add_to_animation_server(light_actor, [Anim.intro_hop]);
	#heavy warp
	var sprite = Sprite.new();
	sprite.set_script(preload("res://GoalParticle.gd"));
	sprite.set_texture(preload("res://assets/BigPortalRed.png"));
	sprite.position = heavy_actor.position + Vector2(cell_size/2, cell_size/2);
	sprite.rotate_magnitude = 4.0;
	sprite.scale = Vector2(0.0, 0.0);
	sprite.fadeout_timer_max = dur;
	sprite.alpha_max = 0.5;
	var tween = Tween.new();
	sprite.add_child(tween);
	tween.interpolate_property(sprite, "scale", Vector2(0.0, 0.0), Vector2(0.5, 0.5), sprite.fadeout_timer_max/2,
	Tween.TRANS_QUART, Tween.EASE_OUT);
	tween.interpolate_property(sprite, "scale", Vector2(0.5, 0.5), Vector2(0.0, 0.0), sprite.fadeout_timer_max/2,
	Tween.TRANS_QUART, Tween.EASE_IN, sprite.fadeout_timer_max/2);
	overactorsparticles.add_child(sprite);
	tween.start();
	#light warp
	sprite = Sprite.new();
	sprite.set_script(preload("res://GoalParticle.gd"));
	sprite.set_texture(preload("res://assets/BigPortalBlue.png"));
	sprite.position = light_actor.position + Vector2(cell_size/2, cell_size/2);
	sprite.rotate_magnitude = -4.0;
	sprite.scale = Vector2(0.0, 0.0);
	sprite.fadeout_timer_max = dur;
	sprite.alpha_max = 0.5;
	tween = Tween.new();
	sprite.add_child(tween);
	tween.interpolate_property(sprite, "scale", Vector2(0.0, 0.0), Vector2(0.375, 0.375), sprite.fadeout_timer_max/2,
	Tween.TRANS_QUART, Tween.EASE_OUT);
	tween.interpolate_property(sprite, "scale", Vector2(0.375, 0.375), Vector2(0.0, 0.0), sprite.fadeout_timer_max/2,
	Tween.TRANS_QUART, Tween.EASE_IN, sprite.fadeout_timer_max/2);
	overactorsparticles.add_child(sprite);
	tween.start();

func nag_label_start() -> void:
	if (!ready_done):
		call_deferred("nag_label_start");
		return
	if (nag_timer != null):
		if !nag_timer.is_stopped():
			return;
	nag_timer = Timer.new();
	nag_timer.name = "NagTimer";
	nag_timer.connect("timeout", self, "nag_label_end");
	self.get_parent().add_child(nag_timer);
	nag_timer.wait_time = 60*10; #10 minutes
	nag_timer.one_shot = true;
	nag_timer.start();
	
func nag_label_end() -> void:
	if (ui_stack.size() == 0):
		var label = Label.new();
		label.script = preload("res://NagLabel.gd");
		label.theme = preload("res://DefaultTheme.tres");
		actorsfolder.add_child(label);
		label.text = "Stuck? Try Menu > Gain Insight.";
		label.rect_position = Vector2(182,260)-actorsfolder.position;
		label.flash();
		if (nag_timer != null):
			nag_timer.queue_free();
			nag_timer = null;
	else:
		if (nag_timer != null):
			nag_timer.wait_time = 60; # wait 1 more minute and try again
			nag_timer.start();

func ready_tutorial() -> void:
	if (winlabel.visible):
		return;
	
	# start a timer for 10 minutes to suggest Gain Insight if:
	# we're in chapter 0
	# we're not in an insight (or remix)
	# we have an insight (and not a remix)
	# we haven't beaten this puzzle yet
	# we've never used gain insight
	# additionally, stop/restart it if we change puzzles, but don't stop/restart it if we restart
	if (chapter == 0):
		if (save_file.has("gain_insight") and save_file["gain_insight"] == true):
			if (nag_timer != null):
				nag_timer.queue_free();
				nag_timer = null;
		elif in_insight_level or !has_insight_level or has_remix.has(level_name):
			if (nag_timer != null):
				nag_timer.queue_free();
				nag_timer = null;
		else:
			var levels_save_data = save_file["levels"];
			if (!levels_save_data.has(level_name)):
				nag_label_start();
			else:
				var level_save_data = levels_save_data[level_name];
				if (level_save_data.has("won") and level_save_data["won"]):
					if (nag_timer != null):
						nag_timer.queue_free();
						nag_timer = null;
				else:
					nag_label_start();
	
	virtualbuttons.get_node("Verbs/SwapButton").visible = true;
	virtualbuttons.get_node("Verbs/MetaUndoButton").visible = true;
	
	if is_custom:
		metainfolabel.visible = true;
		tutoriallabel.visible = false;
		downarrow.visible = false;
		leftarrow.visible = false;
		rightarrow.visible = false;
		return;
	
	if level_number > 5:
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
		tutoriallabel.rect_position = Vector2(0, 72);
		match level_number:
			0:
				virtualbuttons.get_node("Verbs/SwapButton").visible = false;
				virtualbuttons.get_node("Verbs/MetaUndoButton").visible = false;
				tutoriallabel.bbcode_text = "$MOVE: Move\n$UNDO: Rewind\n$RESTART: Restart";
				if (in_insight_level):
					tutoriallabel.rect_position.y -= 24;
				
				
				for a in actorsfolder.get_children():
					if (a.name == "Pictogram" or a.name == "Pictogram2"):
						a.queue_free();
				var sprite = Sprite.new();
				sprite.name = "Pictogram";
				sprite.texture = preload("res://assets/light_goal_tutorial.png");
				actorsfolder.add_child(sprite);
				sprite.position = Vector2(84, 84);
				if (in_insight_level):
					sprite.position.y += 48;
			
			1:
				virtualbuttons.get_node("Verbs/SwapButton").visible = false;
				virtualbuttons.get_node("Verbs/MetaUndoButton").visible = false;
				tutoriallabel.bbcode_text = "$MOVE: Move\n$UNDO: Rewind\n$RESTART: Restart";
				
				for a in actorsfolder.get_children():
					if (a.name == "Pictogram" or a.name == "Pictogram2"):
						a.queue_free();
				var sprite = Sprite.new();
				sprite.name = "Pictogram";
				sprite.texture = preload("res://assets/light_goal_tutorial.png");
				actorsfolder.add_child(sprite);
				sprite.position = Vector2(84, 84);
				sprite = Sprite.new();
				sprite.name = "Pictogram2";
				sprite.texture = preload("res://assets/heavy_goal_tutorial.png");
				actorsfolder.add_child(sprite);
				sprite.position = Vector2(84, 84+24);
			2:
				virtualbuttons.get_node("Verbs/MetaUndoButton").visible = false;
				tutoriallabel.rect_position.y -= 24;
				tutoriallabel.bbcode_text = "$MOVE: Move [color=#FF7459]Heavy[/color]\n$SWAP: Swap [color=#7FC9FF]To Light[/color]\n$UNDO: Rewind [color=#FF7459]Heavy[/color]\n$RESTART: Restart";
			3:
				virtualbuttons.get_node("Verbs/MetaUndoButton").visible = false;
				tutoriallabel.rect_position.y -= 24;
				tutoriallabel.bbcode_text = "$SWAP: Swap [color=#7FC9FF]To Light[/color]\n$UNDO: Rewind [color=#FF7459]Heavy[/color]\n$RESTART: Restart";
			4:
				virtualbuttons.get_node("Verbs/MetaUndoButton").visible = false;
				tutoriallabel.rect_position.y -= 24;
				tutoriallabel.bbcode_text = "$UNDO: Rewind [color=#FF7459]Heavy[/color]\n$RESTART: Restart";
			5:
				virtualbuttons.get_node("Verbs/MetaUndoButton").visible = false;
				tutoriallabel.rect_position.y -= 24;
				tutoriallabel.bbcode_text = "$UNDO: Rewind [color=#FF7459]Heavy[/color]\n$RESTART: Restart";
			6:
				tutoriallabel.rect_position.y -= 48;
				tutoriallabel.bbcode_text = "$META-UNDO: [color=#A9F05F]Undo[/color]\n$RESTART: Restart\n([color=#A9F05F]Undo[/color] undoes your last Move or Rewind.)";
			7:
				tutoriallabel.rect_position.y -= 48;
				tutoriallabel.bbcode_text = "$META-UNDO: [color=#A9F05F]Undo[/color]\n$RESTART: Restart\n(If you Restart by mistake, you can [color=#A9F05F]Undo[/color] that too!)";
		tutoriallabel.bbcode_text = "[center]" + tutoriallabel.bbcode_text + "[/center]";
		translate_tutorial_inputs();
			
	if level_name == "Snake Pit":
		tutoriallabel.visible = true;
		tutoriallabel.rect_position = Vector2(0, 69);
		tutoriallabel.rect_position.y -= 48;
		tutoriallabel.bbcode_text = "[center]Visualize your current attempt as a Replay:\n$TOGGLE-REPLAY: Toggle Replay\nAlso, you can make Checkpoints by doing:\nCtrl+C: Copy Replay\nCtrl+V: Paste Replay[/center]";
		translate_tutorial_inputs();
		
func translate_tutorial_inputs() -> void:
	if (level_number >= 2 and level_number <= 5):
		if (heavy_selected):
			pass
		else:
			tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("[color=#FF7459]Heavy[/color]", "[color=#7FC9FF]Light[/color]");
			tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("[color=#7FC9FF]To Light[/color]", "[color=#FF7459]To Heavy[/color]");
			
	if tutoriallabel.visible:
		if (meta_redo_inputs != "" and (level_number == 6 or level_number == 7)):
			tutoriallabel.bbcode_text = "$META-UNDO: [color=#A9F05F]Undo[/color]\n$RESTART: Restart\n$META-REDO: [color=#A9F05F]Redo[/color]";
			tutoriallabel.bbcode_text = "[center]" + tutoriallabel.bbcode_text + "[/center]";
		
		if using_controller:
			tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$MOVE", "D-Pad/Either Stick");
		else:
			tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$MOVE", "Arrows");
		tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$SWAP", human_readable_input("character_switch"));
		tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$UNDO", human_readable_input("character_undo"));
		tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$META-UNDO", human_readable_input("meta_undo"));
		tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$META-REDO", human_readable_input("meta_redo"));
		tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$RESTART", human_readable_input("restart"));
		tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("$TOGGLE-REPLAY", human_readable_input("toggle_replay"));
	
var controller_hrns = [
	"Bottom Face Button",
	"Right Face Button",
	"Left Face Button",
	"Top Face Button",
	"LB",
	"RB",
	"LT",
	"RT",
	"L3",
	"R3",
	"Select",
	"Start",
	"Up",
	"Down",
	"Left",
	"Right",
	"Home",
	"Share",
	"Paddle 1",
	"Paddle 2",
	"Paddle 3",
	"Paddle 4",
	"Touchpad",
];
	
func human_readable_input(action: String, entries: int = 3) -> String:
	var result = "";
	var events = InputMap.get_action_list(action);
	var entry = 0;
	for event in events:
		if ((!using_controller and event is InputEventKey) or (using_controller and event is InputEventJoypadButton)):
			entry += 1;
			if (result != ""):
				result += " or ";
			if (event is InputEventKey):
				result += event.as_text();
			else:
				if (event.button_index < controller_hrns.size()):
					result += controller_hrns[event.button_index];
				else:
					result += event.as_text();
		if (entry >= entries):
			return result;
	if (result == ""):
		result = "[UNBOUND]";
	return result;
	
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

func update_retro_timeline() -> void:
	heavytimeline.update_retro_timeline();
	lighttimeline.update_retro_timeline();

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

func any_layer_has_this_tile(id: int) -> bool:
	for layer in terrain_layers:
		if (layer.get_used_cells_by_id(id).size() > 0):
			return true;
	return false;

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
	find_goals();
	
	var where_are_actors = {};
	
	# find heavy and light and turn them into actors
	# as a you-fucked-up backup, put them in 0,0 if there seems to be none
	heavy_actor = null;
	var layers_tiles = get_used_cells_by_id_all_layers(Tiles.HeavyIdle);
	var found_one = false;
	var count = 0;
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
			var old_heavy_actor = heavy_actor;
			heavy_actor = make_actor(Actor.Name.Heavy, Vector2(-99, -99), true, i);
			where_are_actors[heavy_actor] = heavy_tile;
			heavy_actor.heaviness = Heaviness.STEEL;
			heavy_actor.strength = Strength.HEAVY;
			heavy_actor.durability = Durability.FIRE;
			heavy_actor.fall_speed = 2;
			heavy_actor.climbs = true;
			heavy_actor.color = heavy_color;
			tint_actor(heavy_actor, count);
			heavy_actor.powered = heavy_max_moves != 0;
			if (heavy_tile.x > (map_x_max / 2)):
				heavy_actor.facing_left = true;
			if (has_mimics and old_heavy_actor != null):
				var terrain = terrain_in_tile(heavy_tile + Vector2.UP);
				if (terrain.has(Tiles.HeavyMimic) or terrain.has(Tiles.LightMimic)):
					var mimic = heavy_actor;
					heavy_actor = old_heavy_actor;
					mimic.update_graphics();
			heavy_actor.update_graphics();
			count += 1;
	
	light_actor = null;
	layers_tiles = get_used_cells_by_id_all_layers(Tiles.LightIdle);
	found_one = false;
	count = 0;
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
			var old_light_actor = light_actor;
			light_actor = make_actor(Actor.Name.Light, Vector2(-99, -99), true, i);
			where_are_actors[light_actor] = light_tile;
			light_actor.heaviness = Heaviness.IRON;
			light_actor.strength = Strength.LIGHT;
			light_actor.durability = Durability.SPIKES;
			light_actor.fall_speed = 1;
			light_actor.climbs = true;
			light_actor.floats = true;
			light_actor.color = light_color;
			tint_actor(light_actor, count);
			light_actor.powered = light_max_moves != 0;
			if (light_tile.x > (map_x_max / 2)):
				light_actor.facing_left = true;
			if (has_mimics and old_light_actor != null):
				var terrain = terrain_in_tile(light_tile + Vector2.UP);
				if (terrain.has(Tiles.HeavyMimic) or terrain.has(Tiles.LightMimic)):
					var mimic = light_actor;
					light_actor = old_light_actor;
					mimic.update_graphics();
			light_actor.update_graphics();
			count += 1;
	
	# HACK: move actors to where they are, so now that is_main_character and so on is determined,
	# they correctly ding/don't ding different kinds of goals
	for actor in where_are_actors.keys():
		move_actor_to(actor, where_are_actors[actor], Chrono.TIMELESS, false, false);
	
	# crates
	extract_actors(Tiles.IronCrate, Actor.Name.IronCrate, Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 99, false, Color(0.5, 0.5, 0.5, 1));
	extract_actors(Tiles.SteelCrate, Actor.Name.SteelCrate, Heaviness.STEEL, Strength.LIGHT, Durability.PITS, 99, false, Color(0.4, 0.4, 0.4, 1));
	extract_actors(Tiles.PowerCrate, Actor.Name.PowerCrate, Heaviness.WOODEN, Strength.HEAVY, Durability.FIRE, 99, false, Color(1, 0.2, 0.86, 1));
	extract_actors(Tiles.WoodenCrate, Actor.Name.WoodenCrate, Heaviness.WOODEN, Strength.WOODEN, Durability.SPIKES, 99, false, Color(0.7, 0.5, 0, 1));
	
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
	
	# holes
	if (has_holes):
		extract_actors(Tiles.Hole, Actor.Name.Hole, Heaviness.INFINITE, Strength.NONE, Durability.NOTHING, 0, false, Color("404040"));
		extract_actors(Tiles.GreenHole, Actor.Name.GreenHole, Heaviness.INFINITE, Strength.NONE, Durability.NOTHING, 0, false, Color("A9F05F"));
		extract_actors(Tiles.VoidHole, Actor.Name.VoidHole, Heaviness.INFINITE, Strength.NONE, Durability.NOTHING, 0, false, Color("202020"));
	
	# boulders
	if (has_boulders):
		extract_actors(Tiles.Boulder, Actor.Name.Boulder, Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.75, 0.75, 0.75, 1));
	
	find_colours();
	find_modifiers();
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
	
func find_goals() -> void:
	var layers = get_used_cells_by_id_all_layers(Tiles.HeavyGoal);
	for i in range(layers.size()):
		var heavy_goal_tiles = layers[i];
		for tile in heavy_goal_tiles:
			var goal = Goal.new();
			goal.gamelogic = self;
			goal.actorname = Actor.Name.HeavyGoal;
			goal.texture = preload("res://assets/BigPortalRed.png");
			goal.centered = true;
			goal.pos = tile;
			goal.position = terrainmap.map_to_world(goal.pos) + Vector2(cell_size/2, cell_size/2);
			goal.modulate = Color(1, 1, 1, 0.8);
			goals.append(goal);
			add_actor_or_goal_at_appropriate_layer(goal, i);
			goal.update_graphics();
	
	layers = get_used_cells_by_id_all_layers(Tiles.LightGoal);
	for i in range(layers.size()):
		var light_goal_tiles = layers[i];
		for tile in light_goal_tiles:
			var goal = Goal.new();
			goal.gamelogic = self;
			goal.actorname = Actor.Name.LightGoal;
			goal.texture = preload("res://assets/BigPortalBlue.png");
			goal.centered = true;
			goal.pos = tile;
			goal.position = terrainmap.map_to_world(goal.pos) + Vector2(cell_size/2, cell_size/2);
			goal.modulate = Color(1, 1, 1, 0.8);
			goal.rotate_magnitude = -1;
			goals.append(goal);
			add_actor_or_goal_at_appropriate_layer(goal, i);
			goal.update_graphics();
	
func add_actor_or_goal_at_appropriate_layer(thing: ActorBase, i: int) -> void:
	# backwards compatibility, so actors in the top layer of a custom puzzle/in any vanilla puzzle
	# draw correctly wrt underactorsparticles/overactorsparticles, but
	# actors in other layers of a custom pzuzle can layer with terrain arbitrariliy
	# in the future, goals can be moved
	# and also the concept of 'adding to overactors/underactors particles'
	# can be generalized to
	# 'if it's a custom puzzle, put particles in the appropriate place amongst terrain layers too'
	if ((is_custom or chapter >= 12) and i > 0):
		terrain_layers[i].add_child(thing);
		if (i == terrain_layers.size() - 1):
			terrain_layers[i].move_child(thing, terrain_layers[i-1].get_index());
	else:
		actorsfolder.add_child(thing);
		
var tints = [[1.0, 1.0, 1.0], [0.8, 0.8, 0.8], [0.7, 1.0, 1.0], [1.0, 0.7, 0.7], [1.3, 1.3, 1.3]];

func tint_actor(actor: Actor, count: int):
	var tint = tints[count % tints.size()];
	actor.color.r *= tint[0];
	actor.color.g *= tint[1];
	actor.color.b *= tint[2];

func extract_actors(id: int, actorname: int, heaviness: int, strength: int, durability: int, fall_speed: int, climbs: bool, color: Color) -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	var count = 0;
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			terrain_layers[i].set_cellv(tile, -1);
			var actor = make_actor(actorname, tile, false, i);
			actor.heaviness = heaviness;
			actor.strength = strength;
			actor.durability = durability;
			actor.fall_speed = fall_speed;
			actor.climbs = climbs;
			actor.is_character = false;
			actor.color = color;
			tint_actor(actor, count);
			actor.update_graphics();
			count += 1;
			
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
				goals.append(goal);
				goal.update_graphics();
				actor.joke_goal = goal;
				actor.add_child(goal);

var colours_list = [Tiles.ColourRed,
Tiles.ColourBlue,
Tiles.ColourMagenta,
Tiles.ColourGray,
Tiles.ColourGreen,
Tiles.ColourVoid,
Tiles.ColourPurple,
Tiles.ColourBlurple,
Tiles.ColourCyan,
Tiles.ColourOrange,
Tiles.ColourYellow,
Tiles.ColourWhite];
var colours_dictionary = {Tiles.ColourRed: TimeColour.Red,
Tiles.ColourBlue: TimeColour.Blue,
Tiles.ColourMagenta: TimeColour.Magenta,
Tiles.ColourGray: TimeColour.Gray,
Tiles.ColourGreen: TimeColour.Green,
Tiles.ColourVoid: TimeColour.Void,
Tiles.ColourPurple: TimeColour.Purple,
Tiles.ColourBlurple: TimeColour.Blurple,
Tiles.ColourCyan: TimeColour.Cyan,
Tiles.ColourOrange: TimeColour.Orange,
Tiles.ColourYellow: TimeColour.Yellow,
Tiles.ColourWhite: TimeColour.White,
Tiles.ColourNative: -1
}
var loose_colours = false;
var loose_modifiers = false;

func find_colours() -> void:
	loose_colours = false;
	var n = 5;
	if (is_custom):
		n = colours_list.size();
	for i in range(n):
		var id = colours_list[i];
		find_colour(id, colours_dictionary[id]);
	
func find_colour(id: int, time_colour : int) -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			var found = false;
			# get first actor with the same pos and native colour and change their time_colour
			for actor in actors:
				if actor.pos == tile and actor.is_native_colour():
					actor.time_colour = time_colour;
					actor.update_time_bubble();
					terrain_layers[i].set_cellv(tile, -1);
					break;
				if (!found):
					loose_colours = true;
	
func find_modifiers() -> void:
	loose_modifiers = false;
	if (is_custom):
		for id in range(Tiles.Propellor, Tiles.FallOne + 1):
			find_modifier(id);
		find_modifier(Tiles.HeavyMimic);
		find_modifier(Tiles.LightMimic);

func find_modifier(id: int) -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			var found = false;
			for actor in actors:
				var condition = false;
				if (id == Tiles.Propellor):
					condition = (actor.pos == tile + Vector2.DOWN) and actor.propellor == null;
				elif (id == Tiles.HeavyMimic):
					condition = (actor.pos == tile + Vector2.DOWN) and actor.heavy_mimic == null;
				elif (id == Tiles.LightMimic):
					condition = (actor.pos == tile + Vector2.DOWN) and actor.light_mimic == null;
				else:
					condition = actor.pos == tile;
				if condition:
					attach_modifier(actor, i, tile, id, Chrono.TIMELESS);
					found = true;
					break;
			if (!found):
				loose_modifiers = true;

func attach_modifier(actor, i, tile, id, chrono):
	var sprite = Sprite.new();
	actor.add_child(sprite);
	sprite.texture = terrainmap.tile_set.tile_get_texture(id);
	sprite.centered = false;
	match id:
		Tiles.Propellor:
			set_actor_var(actor, "propellor", sprite, chrono);
			sprite.position += Vector2(0, -cell_size);
			if (actor.airborne != -1):
				set_actor_var(actor, "airborne", -1, chrono);
		Tiles.HeavyMimic:
			set_actor_var(actor, "heavy_mimic", sprite, chrono);
			sprite.position += Vector2(0, -cell_size);
		Tiles.LightMimic:
			set_actor_var(actor, "light_mimic", sprite, chrono);
			sprite.position += Vector2(0, -cell_size);
		Tiles.DurPlus:
			set_actor_var(actor, "durability", actor.durability + 1, chrono);
		Tiles.DurMinus:
			set_actor_var(actor, "durability", actor.durability - 1, chrono);
		Tiles.HvyPlus:
			set_actor_var(actor, "heaviness", actor.heaviness + 1, chrono);
		Tiles.HvyMinus:
			set_actor_var(actor, "heaviness", actor.heaviness - 1, chrono);
		Tiles.StrPlus:
			set_actor_var(actor, "strength", actor.strength + 1, chrono);
		Tiles.StrMinus:
			set_actor_var(actor, "strength", actor.strength - 1, chrono);
		Tiles.FallInf:
			set_actor_var(actor, "fall_speed", 99, chrono);
		Tiles.FallOne:
			set_actor_var(actor, "fall_speed", 1, chrono);
			set_actor_var(actor, "floats", false, chrono);
	if (chrono == Chrono.TIMELESS):
		terrain_layers[i].set_cellv(tile, -1);
	else:
		maybe_change_terrain(actor, tile, i, false, Greenness.Green, chrono, -1);
	return sprite;

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
	if ((is_custom or (chapter == custom_past_here -1)) and (map_x_max > map_x_max_max or map_y_max > map_y_max_max+2)):
		terrainmap.scale = Vector2(0.5, 0.5);
	else:
		terrainmap.scale = Vector2(1.0, 1.0);
	underterrainfolder.scale = terrainmap.scale;
	actorsfolder.scale = terrainmap.scale;
	ghostsfolder.scale = terrainmap.scale;
	underactorsparticles.scale = terrainmap.scale;
	overactorsparticles.scale = terrainmap.scale;
	checkerboard.rect_scale = terrainmap.scale;
	targeter.scale = terrainmap.scale;
	if (terrainmap.scale == Vector2(0.5, 0.5)):
		terrainmap.position.x = (map_x_max_max-map_x_max*0.5)*(cell_size/2)-8;
		terrainmap.position.y = (map_y_max_max-map_y_max*0.5)*(cell_size/2)+12;
	else:
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
		targeter.position = heavy_actor.position*terrainmap.scale + terrainmap.position + Vector2(12, 12)*terrainmap.scale;
	else:
		targeter.position = light_actor.position*terrainmap.scale + terrainmap.position + Vector2(12, 12)*terrainmap.scale;
	
	if (!downarrow.visible):
		return;
	
	downarrow.position = targeter.position + Vector2(-12, -36);
	
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
	sounds["bootup"] = preload("res://sfx/bootup.ogg");
	sounds["broken"] = preload("res://sfx/broken.ogg");
	sounds["bump"] = preload("res://sfx/bump.ogg");
	sounds["bumper"] = preload("res://sfx/bumper.ogg");
	sounds["continuum"] = preload("res://sfx/continuum.ogg");
	sounds["eclipse"] = preload("res://sfx/eclipse.ogg");
	sounds["exception"] = preload("res://sfx/exception.ogg");
	sounds["fall"] = preload("res://sfx/fall.ogg");
	sounds["fence"] = preload("res://sfx/fence.ogg");
	sounds["fuzz"] = preload("res://sfx/fuzz.ogg");
	sounds["greenfire"] = preload("res://sfx/greenfire.ogg");
	sounds["greentimecrystal"] = preload("res://sfx/greentimecrystal.ogg");
	sounds["heavycoyote"] = preload("res://sfx/heavycoyote.ogg");
	sounds["heavyland"] = preload("res://sfx/heavyland.ogg");
	sounds["heavystep"] = preload("res://sfx/heavystep.ogg");
	sounds["heavyuncoyote"] = preload("res://sfx/heavyuncoyote.ogg");
	sounds["heavyunland"] = preload("res://sfx/heavyunland.ogg");
	sounds["infloop"] = preload("res://sfx/infloop.ogg");
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
	sounds["metaredo"] = preload("res://sfx/metaredo.ogg");
	sounds["metarestart"] = preload("res://sfx/metarestart.ogg");
	sounds["metaundo"] = preload("res://sfx/metaundo.ogg");
	sounds["onemillionyears"] = preload("res://sfx/onemillionyears.ogg");
	sounds["push"] = preload("res://sfx/push.ogg");
	sounds["redfire"] = preload("res://sfx/redfire.ogg");
	sounds["rewindnoticed"] = preload("res://sfx/rewindnoticed.ogg");
	sounds["rewindstopped"] = preload("res://sfx/rewindstopped.ogg");
	sounds["remembertimecrystal"] = preload("res://sfx/remembertimecrystal.ogg");
	sounds["restart"] = preload("res://sfx/restart.ogg");	
	sounds["shatter"] = preload("res://sfx/shatter.ogg");
	sounds["shroud"] = preload("res://sfx/shroud.ogg");
	sounds["singularity"] = preload("res://sfx/singularity.ogg");
	sounds["spotlight"] = preload("res://sfx/spotlight.ogg");
	sounds["switch"] = preload("res://sfx/switch.ogg");
	sounds["switch2"] = preload("res://sfx/switch2.ogg");
	sounds["thejourneybegins"] = preload("res://sfx/thejourneybegins.ogg");
	sounds["tick"] = preload("res://sfx/tick.ogg");
	sounds["timesup"] = preload("res://sfx/timesup.ogg");
	sounds["unbroken"] = preload("res://sfx/unbroken.ogg");
	sounds["undostrong"] = preload("res://sfx/undostrong.ogg");
	sounds["unfall"] = preload("res://sfx/unfall.ogg");
	sounds["unlock"] = preload("res://sfx/unlock.ogg");
	sounds["unpush"] = preload("res://sfx/unpush.ogg");
	sounds["unshatter"] = preload("res://sfx/unshatter.ogg");
	sounds["untick"] = preload("res://sfx/untick.ogg");
	sounds["usegreenality"] = preload("res://sfx/usegreenality.ogg");
	sounds["voidundo"] = preload("res://sfx/voidundo.ogg");
	sounds["winentwined"] = preload("res://sfx/winentwined.ogg");
	sounds["winbadtime"] = preload("res://sfx/winbadtime.ogg");
	
	#used only in cutscenes
	sounds["noodling"] = preload("res://sfx/noodling.ogg");
	sounds["alert"] = preload("res://sfx/alert.ogg");
	sounds["alert2"] = preload("res://sfx/alert2.ogg");
	sounds["alert3"] = preload("res://sfx/alert3.ogg");
	sounds["intothewarp"] = preload("res://sfx/intothewarp.ogg");
	sounds["getgreenality"] = preload("res://sfx/getgreenality.ogg");
	sounds["fixit1"] = preload("res://sfx/fixit1.ogg");
	sounds["fixit2"] = preload("res://sfx/fixit2.ogg");
	sounds["fixit3"] = preload("res://sfx/fixit3.ogg");
	sounds["fixit4"] = preload("res://sfx/fixit4.ogg");
	sounds["helixfixed"] = preload("res://sfx/helixfixed.ogg");
	
	#unused except by custom elements
	sounds["step"] = preload("res://sfx/step.ogg"); #replaced by heavystep, now used by nudge
	sounds["undo"] = preload("res://sfx/undo.ogg"); #actually used by checkpoint but it should be a different sfx
	
	music_tracks.append(preload("res://music/New Bounds.ogg"));
	music_info.append("Patashu - New Bounds");
	music_db.append(0.30);
	music_tracks.append(preload("res://music/Effortless Existence.ogg"));
	music_info.append("Patashu - Effortless Existence");
	music_db.append(2.48);
	music_tracks.append(preload("res://music/Starblind.ogg"));
	music_info.append("Patashu - Starblind");
	music_db.append(1.44);
	music_tracks.append(preload("res://music/polygon remix.ogg"));
	music_info.append("Sota Fujimori - polygon (Patashu's Entwined Time Remix)");
	music_db.append(4.99);
	music_tracks.append(preload("res://music/Highs and Lows.ogg"));
	music_info.append("Patashu - Highs & Lows");
	music_db.append(8.21);
	music_tracks.append(preload("res://music/Nebulous Netherworld.ogg"));
	music_info.append("Patashu - Nebulous Netherworld");
	music_db.append(5.17);
	music_tracks.append(preload("res://music/Causal Conjugate.ogg"));
	music_info.append("Patashu - Causal Conjugate");
	music_db.append(2.63);
	music_tracks.append(preload("res://music/Critical Crystal.ogg"));
	music_info.append("Ryu* - Critical Crystal (Patashu's Entwined Time Remix)");
	music_db.append(1.73);
	music_tracks.append(preload("res://music/Mote in Eternity's Eye.ogg"));
	music_info.append("Patashu - Mote in Eternity's Eye");
	music_db.append(5.82);
	music_tracks.append(preload("res://music/1116.ogg"));
	music_info.append("Dustup - 1116 (Patashu's Entwined Time Remix)");
	music_db.append(-0.02);
	music_tracks.append(preload("res://music/Title Screen.ogg"));
	music_info.append("Patashu - Title Screen");
	music_db.append(5.0);
	music_tracks.append(preload("res://music/Cutscene A.ogg"));
	music_info.append("Patashu - Cutscene A");
	music_db.append(6.0);
	music_tracks.append(preload("res://music/Cutscene B.ogg"));
	music_info.append("Patashu - Cutscene B");
	music_db.append(6.0);
	music_tracks.append(preload("res://music/Cutscene C.ogg"));
	music_info.append("Patashu - Cutscene C");
	music_db.append(6.0);
	music_tracks.append(preload("res://music/Cutscene D.ogg"));
	music_info.append("Patashu - Cutscene D");
	music_db.append(6.0);
	music_tracks.append(preload("res://music/Cutscene E.ogg"));
	music_info.append("Patashu - Cutscene E");
	music_db.append(3.0);
	music_tracks.append(preload("res://sfx/lose.ogg"));
	music_info.append("Patashu - Abyss of the Lost");
	music_db.append(-3.0);
	music_tracks.append(preload("res://sfx/infloop.ogg"));
	music_info.append("Patashu - Memories Fade To Dreams");
	music_db.append(-3.0);
	music_tracks.append(preload("res://sfx/exception.ogg"));
	music_info.append("Patashu - Exception Handler");
	music_db.append(0.0);
	
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
	if (Shade.on):
		return;
	winlabel.visible = true;
	call_deferred("adjust_winlabel");
	Shade.on = true;
	
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	var db = save_file["fanfare_volume"];
	var master_volume = save_file["master_volume"];
	if (db <= -30 or master_volume <= -30):
		return;
	db += master_volume;
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
	if (save_file["sfx_volume"] <= -30 or save_file["master_volume"] <= -30):
		return;
	for speaker in speakers:
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
	if save_file["fanfare_volume"] <= -30 or save_file["master_volume"] <= -30:
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

func make_actor(actorname: int, pos: Vector2, is_character: bool, i: int, chrono: int = Chrono.TIMELESS) -> Actor:
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
	add_actor_or_goal_at_appropriate_layer(actor, i);
	actor.time_colour = actor.native_colour();
	move_actor_to(actor, pos, chrono, false, false);
	if (!is_web and (actor.actorname == Actor.Name.ChronoHelixRed or actor.actorname == Actor.Name.ChronoHelixBlue)):
		actor.material = load("res://outline_shadermaterial.tres").duplicate();
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
	
func slope_helper(id: int, dir: Vector2) -> Array:
	if id == Tiles.SlopeSW and dir.x != 0:
		return [Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN];
	elif id == Tiles.SlopeSW and dir.y != 0:
		return [Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.LEFT];
	elif id == Tiles.SlopeSE and dir.x != 0:
		return [Vector2.UP, Vector2.LEFT, Vector2.RIGHT, Vector2.DOWN];
	elif id == Tiles.SlopeSE and dir.y != 0:
		return [Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2.RIGHT];
	elif id == Tiles.SlopeNW and dir.x != 0:
		return [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP];
	elif id == Tiles.SlopeNW and dir.y != 0:
		return [Vector2.RIGHT, Vector2.DOWN, Vector2.UP, Vector2.LEFT];
	elif id == Tiles.SlopeNE and dir.x != 0:
		return [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2.UP];
	elif id == Tiles.SlopeNE and dir.y != 0:
		return [Vector2.LEFT, Vector2.DOWN, Vector2.UP, Vector2.RIGHT];
	return []; #unreachable
	
var infinite_loop_check : int = 0;
var slope_positions : Array = [];
	
func move_actor_relative(actor: Actor, dir: Vector2, chrono: int, hypothetical: bool, is_gravity: bool,
is_retro: bool = false, pushers_list: Array = [], was_fall = false, was_push = false,
phased_out_of = null, animation_nonce : int = -1, is_move: bool = false, can_push: bool = true,
boost_pad_reentrance: bool = false) -> int:
	if (chrono == Chrono.GHOSTS):
		var ghost = get_ghost_that_hasnt_moved(actor);
		ghost.ghost_dir = -dir;
		ghost.pos = ghost.previous_ghost.pos + dir;
		ghost.position = terrainmap.map_to_world(ghost.pos);
		return Success.Yes;
	
	return move_actor_to(actor, actor.pos + dir, chrono, hypothetical,
	is_gravity, is_retro, pushers_list, was_push, was_fall, phased_out_of, animation_nonce, is_move, can_push,
	boost_pad_reentrance);
	
func update_night_and_stars(actor: Actor, terrain: Array) -> void:
	var actor_was_in_night = actor.in_night;
	var actor_was_in_stars = actor.in_stars;
	actor.in_night = false;
	actor.in_stars = false;
	if terrain.has(Tiles.TheNight):
		actor.in_night = true;
		if (!actor_was_in_night):
			add_to_animation_server(actor, [Anim.grayscale, true]);
	if terrain.has(Tiles.TheStars):
		actor.in_stars = true;
	if (actor_was_in_night and !actor.in_night):
		add_to_animation_server(actor, [Anim.grayscale, false]);
	
func move_actor_to(actor: Actor, pos: Vector2, chrono: int, hypothetical: bool, is_gravity: bool,
is_retro: bool = false, pushers_list: Array = [], was_fall: bool = false, was_push: bool = false,
phased_out_of = null, animation_nonce: int = -1, is_move: bool = false, can_push: bool = true,
boost_pad_reentrance: bool = false) -> int:
	var dir = pos - actor.pos;
	var old_pos = actor.pos;
	
	var success = Success.No;
	
	# slopes 1) if an !is_retro move enters a slope, then for the original move to succeed,
	# it also has to be able to eject perpendicularly out of the slope. if that fails,
	# it tries to leave parallely. if that fails too, the move fails.
	# (This also means that if we're doing !hypothetical movement, we need to be hypothetical until
	# we've confirmed the whole sequence is OK, then we do !hypothetical finally.)
	# (UPDATE: Don't allow movement off of a slope to be the direction you came from.)
	# (TODO: May want to recursively check if there's a slope at the second destination
	# and keep trying hypotheticals until the whole thing is cleared as OK)
	var slope_next_dir = Vector2.ZERO;
	if (has_slopes and chrono < Chrono.META_UNDO and !is_retro):
		success = try_enter(actor, dir, chrono, can_push, true, is_gravity, was_push, is_retro, pushers_list,
	phased_out_of);
		var terrain_there = terrain_in_tile(pos, actor, chrono);
		var new_success = Success.Yes;
		for id in terrain_there:
			if id >= Tiles.SlopeNW and id <= Tiles.SlopeNW + 3:
				var next_dirs = slope_helper(id, dir);
				for j in range (2):
					slope_next_dir = next_dirs[j];
					if (slope_next_dir * -1 == dir):
						continue;
					actor.pos = pos;
					if (slope_positions.has(old_pos) and slope_positions.has(pos)):
						new_success = Success.Yes; #because it's an infinite loop
					else:
						slope_positions.append(pos);
						# recursively check...
						new_success = move_actor_to(actor, pos + slope_next_dir, chrono, true, is_gravity, is_retro, pushers_list,
						was_fall, was_push, phased_out_of, animation_nonce, is_move, can_push, boost_pad_reentrance);
						#new_success = try_enter(actor, slope_next_dir, chrono, can_push, true, is_gravity, is_retro, pushers_list, phased_out_of);
						slope_positions.pop_back();
					actor.pos = old_pos;
					if (new_success == Success.Yes):
						break;
				if (new_success == Success.Yes):
					break;
		if (new_success != Success.Yes):
			success = Success.No;
		else:
			if (!hypothetical):
				try_enter(actor, dir, chrono, can_push, false, is_gravity, was_push, is_retro, pushers_list, phased_out_of);
	else:
		success = try_enter(actor, dir, chrono, can_push, hypothetical, is_gravity, was_push, is_retro, pushers_list, phased_out_of);
	
	if (success == Success.Yes and !hypothetical):
		
		if (!is_retro):
			was_push = pushers_list.size() > 0;
			was_fall = is_gravity;
		actor.pos = pos;
		if (chrono < Chrono.TIMELESS and !actor.is_crystal):
			if (actor.is_character and dir.length() > 1 and chrono == Chrono.MOVE):
				achievement_get("What");
			if (pos.x <= -9 or pos.x >= map_x_max + 9):
				achievement_get("FarLands");
			if (pos.y <= -6):
				achievement_get("SpaceProgram");
			if (pos.y >= map_y_max + 2):
				achievement_get("VoidDiver", true);
		
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
				if actor.pushable(true) and actor.pos == old_pos:
					phased_out_of.append(actor);
		if (animation_nonce == -1):
			animation_nonce = animation_nonce_fountain_dispense();
			
		# do facing change now before move happens
		if (is_move and actor.is_character):
			if (dir == Vector2.LEFT):
				if (!actor.facing_left):
					set_actor_var(actor, "facing_left", true, Chrono.MOVE);
			elif (dir == Vector2.RIGHT):
				if (actor.facing_left):
					set_actor_var(actor, "facing_left", false, Chrono.MOVE);
		
		add_undo_event([Undo.move, actor, dir, was_push, was_fall, phased_out_of, animation_nonce],
		chrono_for_maybe_green_actor(actor, chrono));
		
		# hole check
		if (has_holes and chrono < Chrono.META_UNDO):
			var actors = actors_in_tile(pos);
			var terrain = terrain_in_tile(pos, actor, chrono);
			if (terrain.has(Tiles.Floorboards) or terrain.has(Tiles.MagentaFloorboards) or terrain.has(Tiles.GreenFloorboards) or terrain.has(Tiles.VoidFloorboards)):
				pass
			else:
				for actor_there in actors:
					if (actor_there.is_hole()):
						if (!actor.broken and (actor.actorname == Actor.Name.IronCrate
						or actor.actorname == Actor.Name.PowerCrate
						or actor.actorname == Actor.Name.WoodenCrate
						or actor.actorname == Actor.Name.SteelCrate
						or actor.actorname == Actor.Name.Boulder)):
							maybe_break_actor(actor_there, 9999, hypothetical, actor_there.actorname - Actor.Name.Hole, chrono);
						maybe_break_actor(actor, Durability.PITS, hypothetical, actor_there.actorname - Actor.Name.Hole, chrono);
		
		# floorboards check - happens now so it goes 'move off, then floorboards break' so as an undo 'floorboards come back, move is undone'
		if (has_floorboards and chrono < Chrono.TIMELESS):
			var old_terrain = terrain_in_tile(old_pos, actor, chrono);
			for i in range(old_terrain.size() - 1):
				var tile = old_terrain[i];
				match tile:
					Tiles.Floorboards:
						if (chrono < Chrono.META_UNDO and !is_retro):
							maybe_change_terrain(actor, old_pos, i, hypothetical, Greenness.Mundane, chrono, -1);
						break;
					Tiles.MagentaFloorboards:
						if (chrono < Chrono.META_UNDO):
							maybe_change_terrain(actor, old_pos, i, hypothetical, Greenness.Mundane, chrono, -1);
						break;
					Tiles.GreenFloorboards:
						if (chrono < Chrono.META_UNDO):
							maybe_change_terrain(actor, old_pos, i, hypothetical, Greenness.Green, chrono, -1);
						break;
					Tiles.VoidFloorboards:
						if (chrono < Chrono.TIMELESS):
							maybe_change_terrain(actor, old_pos, i, hypothetical, Greenness.Void, chrono, -1);
						break;
		
		# update night and stars state
		var terrain = terrain_in_tile(actor.pos, actor, chrono);
		if (has_night_or_stars):
			update_night_and_stars(actor, terrain);
		
		#do sound effects for special moves and their undoes
		if (was_push and is_retro):
			add_to_animation_server(actor, [Anim.sfx, "unpush"]);
		if (was_push and !is_retro):
			add_to_animation_server(actor, [Anim.sfx, "push"]);
		if (was_fall and is_retro):
			add_to_animation_server(actor, [Anim.sfx, "unfall"]);
		if (was_fall and !is_retro):
			add_to_animation_server(actor, [Anim.sfx, "fall"]);
		
		add_to_animation_server(actor, [Anim.move, dir, is_retro, animation_nonce]);
		
		#ding logic
		if (!actor.broken):
			var old_terrain = terrain_in_tile(actor.pos - dir, actor, chrono);
			if (!actor.is_main_character() and !actor.is_crystal):
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
		#(FIX: If Heavy is being pushed downwards, don't try to sticky top that thing down)
		#(FIX: Do allow a broken crate to be sticky top'd upwards since we wouldn't push it
		if actor.actorname == Actor.Name.Heavy and !is_retro:
			var sticky_actors = actors_in_tile(actor.pos - dir + Vector2.UP);
			for sticky_actor in sticky_actors:
				if (sticky_actor == actor):
					continue;
				if (dir.y <= -1 and sticky_actor.pushable()):
					continue;
				if (pushers_list.has(sticky_actor)):
					continue;
				if (strength_check(actor.strength, sticky_actor.heaviness)
				and (!sticky_actor.broken or !sticky_actor.is_crystal)):
					sticky_actor.just_moved = true;
					move_actor_relative(sticky_actor, dir, chrono, hypothetical, false, false, [actor]);
					# hack fix for 'heavy steps right, starts falling and pulls something down with it'
					# specifically, heavy would be stalled due to falling but the thing being pulled would not
					copy_one_from_animation_server(actor, Anim.stall, sticky_actor);
			for sticky_actor in sticky_actors:
				sticky_actor.just_moved = false;
				
		# boulder momentum
		if (actor.actorname == Actor.Name.Boulder and chrono < Chrono.TIMELESS and !is_retro and !actor.broken):
			if dir.x != 0 or actor.fall_speed() == 0:
				actor.boulder_moved_horizontally_this_turn = true;
				if (actor.momentum != dir):
					set_actor_var(actor, "momentum", dir, chrono);
		
		# loose colours/modifiers check
		if (chrono < Chrono.META_UNDO or (!is_retro and chrono < Chrono.TIMELESS)):
			if (loose_colours):
				for i in range(terrain.size()):
					var id = terrain[i];
					if colours_dictionary.has(id):
						var time_colour = colours_dictionary[id];
						if (time_colour == -1):
							time_colour = actor.native_colour();
						if (actor.time_colour != TimeColour.Void and actor.time_colour != time_colour):
							var old_time_colour = actor.time_colour;
							actor.time_colour = time_colour;
							add_undo_event([Undo.time_bubble, actor, old_time_colour],
								chrono_for_maybe_green_actor(actor, Chrono.CHAR_UNDO));
							add_to_animation_server(actor, [Anim.time_bubble, time_colour]);
							var greenness = Greenness.Green;
							if (time_colour == TimeColour.Void):
								greenness = Greenness.Void;
								if (level_name.find("Noclip") >= 0):
									floating_text("Compat flag: Void bug enabled.");
								else:
									void_banish(actor);
							maybe_change_terrain(actor, actor.pos, i, false, greenness, chrono, -1);
						break;
			if (loose_modifiers):
				var chrono_to_use = chrono;
				if (chrono_to_use < Chrono.CHAR_UNDO):
					chrono_to_use = Chrono.CHAR_UNDO;
				for i in range(terrain.size()):
					var id = terrain[i];
					if id >= Tiles.DurPlus and id <= Tiles.FallOne:
						var sprite = attach_modifier(actor, i, actor.pos, id, chrono_to_use);
						add_undo_event([Undo.sprite, actor, sprite], chrono_for_maybe_green_actor(actor, chrono_to_use));
				var terrain_above = terrain_in_tile(actor.pos + Vector2.UP, actor, chrono);
				for i in range(terrain_above.size()):
					var id = terrain_above[i];
					var attach = false;
					match (id):
						Tiles.Propellor:
							if (actor.propellor == null):
								attach = true;
						Tiles.HeavyMimic:
							if (actor.heavy_mimic == null):
								attach = true;
						Tiles.LightMimic:
							if (actor.light_mimic == null):
								attach = true;
					if (attach):
						var sprite = attach_modifier(actor, i, actor.pos + Vector2.UP, id, chrono_to_use);
						add_undo_event([Undo.sprite, actor, sprite], chrono_for_maybe_green_actor(actor, chrono_to_use));
		
		# slopes 2) then after the !is_retro first move succeeds and commits,
		# again we try to do the second moves in order, and take the first one that succeeds.
		# (actually, I seem to have retconned this into 'remember which move we think is the valid next one
		# and do that', which should be OK?
		# slopes 2b) also, if an actor moves upwards in this way, it immediately becomes 'rising',
		# like a robot deliberately pressing up.
		# (update: grounded robot or any other actor)
		if (slope_next_dir != Vector2.ZERO):
			if (infinite_loop_check >= 100):
				lose("Infinite loop.", null, true, "infloop");
				return Success.No;
			if (lost):
				return Success.No;
			infinite_loop_check += 1;
			move_actor_to(actor, actor.pos + slope_next_dir, chrono, hypothetical, false, false);
			infinite_loop_check -= 1;
			maybe_rise(actor, chrono, slope_next_dir);
				
		# boost pad check
		if (has_boost_pads and chrono < Chrono.META_UNDO and success == Success.Yes and !boost_pad_reentrance):
			var old_terrain = terrain_in_tile(actor.pos - dir, actor, chrono);
			if ((!is_retro and old_terrain.has(Tiles.BoostPad)) or old_terrain.has(Tiles.GreenBoostPad)):
				animation_substep(chrono);
				add_to_animation_server(actor, [Anim.sfx, "redfire"]);
				move_actor_to(actor, actor.pos + dir, chrono, hypothetical, false, false,
				[], false, false, null, -1, false, true,
				true);
				
				
		return success;
	elif (success != Success.Yes):
		# vanity bump goes here, even if it's hypothetical, muahaha
		if pushers_list.size() > 0 and actor.actorname == Actor.Name.Light:
			add_to_animation_server(actor, [Anim.fluster]);
		if (!hypothetical):
			# involuntary bump sfx
			if (pushers_list.size() > 0 or is_retro):
				if (actor.actorname == Actor.Name.Light):
					add_to_animation_server(actor, [Anim.sfx, "involuntarybumplight"], true);
				elif (actor.actorname == Actor.Name.Heavy):
					add_to_animation_server(actor, [Anim.sfx, "involuntarybump"], true);
				else:
					add_to_animation_server(actor, [Anim.sfx, "involuntarybumpother"], true);
		# bump animation always happens, I think?
		# ah, not if it's a 'null' gravity move (everything in the stack was already grounded)
		# and bumps are getting a bit ridiculous for slopes so let's tamp down on that
		if (infinite_loop_check == 0 and slope_positions.size() == 0):
			if (!is_gravity):
				add_to_animation_server(actor, [Anim.bump, dir, animation_nonce], true);
			else:
				if (actor.airborne == 0):
					add_to_animation_server(actor, [Anim.bump, dir, animation_nonce], true);
				else:
					for pusher in pushers_list:
						if pusher.airborne == 0:
							add_to_animation_server(actor, [Anim.bump, dir, animation_nonce], true);
							break;
	
	return success;

var void_banish_dict : Dictionary = {Undo.move: true, Undo.set_actor_var: true, Undo.sprite: true, Undo.time_bubble: true, Undo.tick: true};

func void_banish(actor: Actor) -> bool:
	var result = false;
	#https://discord.com/channels/1196234174005260328/1196234898751627415/1266547709486301269
	for j in range(meta_undo_buffer.size()):
		var buffer = meta_undo_buffer[j];
		for i in range(buffer.size() - 1, -1, -1):
			var event = buffer[i];
			if void_banish_dict.has(event[0]) and event[1] == actor:
				buffer.pop_at(i);
				result = true;
	return result;

func adjust_turn(is_heavy: bool, amount: int, chrono : int, adjust_current_move: bool, continuum: bool = false) -> void:
	if (is_heavy):
		if (amount > 0):
			if heavy_filling_locked_turn_index > -1:
				heavytimeline.add_turn(heavy_locked_turns[heavy_filling_locked_turn_index], continuum);
			elif heavy_filling_turn_actual > -1:
				heavytimeline.add_turn(heavy_undo_buffer[heavy_filling_turn_actual], continuum);
			elif heavy_turn > -1:
				heavytimeline.add_turn(heavy_undo_buffer[heavy_turn], continuum);
		else:
			var color = heavy_color;
			if (chrono >= Chrono.META_UNDO):
				color = meta_color;
			heavytimeline.remove_turn(color, heavy_filling_locked_turn_index, heavy_filling_turn_actual, adjust_current_move);
		if (heavy_turn + amount == heavy_max_moves):
			set_actor_var(heavy_actor, "powered", false, chrono);
		elif (!heavy_actor.powered):
			set_actor_var(heavy_actor, "powered", true, chrono);
		# if we just locked a turn that's functionally empty,
		# actually empty it, then add the turn changing event with Chrono.CHAR_UNDO
		# so later we agree that we're unlocking an empty turn.
		# (thought about trying to do this in anything_happened_char but let's see if this works)
		if (chrono == Chrono.MOVE and heavy_filling_locked_turn_index > -1):
			var buffer = heavy_locked_turns[heavy_filling_locked_turn_index];
			var were_good = false;
			for event in buffer:
				if event[0] != Undo.animation_substep:
					were_good = true;
					break;
			if (!were_good):
				buffer.clear();
				add_undo_event([Undo.heavy_turn, amount, false], Chrono.CHAR_UNDO);
			else:
				add_undo_event([Undo.heavy_turn, amount, true], chrono);
		else:
			add_undo_event([Undo.heavy_turn, amount, true], chrono);
		heavy_turn += amount;

		#if (debug_prints):
		#	print("=== IT IS NOW HEAVY TURN " + str(heavy_turn) + " ===");
	else:
		if (amount > 0):
			if light_filling_locked_turn_index > -1:
				lighttimeline.add_turn(light_locked_turns[light_filling_locked_turn_index], continuum);
			elif light_filling_turn_actual > -1:
				lighttimeline.add_turn(light_undo_buffer[light_filling_turn_actual], continuum);
			elif light_turn > -1:
				lighttimeline.add_turn(light_undo_buffer[light_turn], continuum);
		else:
			var color = light_color;
			if (chrono >= Chrono.META_UNDO):
				color = meta_color;
			lighttimeline.remove_turn(color, light_filling_locked_turn_index, light_filling_turn_actual, adjust_current_move);
		if (light_turn + amount == light_max_moves):
			set_actor_var(light_actor, "powered", false, chrono);
		elif (!light_actor.powered):
			set_actor_var(light_actor, "powered", true, chrono);
		if (chrono == Chrono.MOVE and light_filling_locked_turn_index > -1):
			var buffer = light_locked_turns[light_filling_locked_turn_index];
			var were_good = false;
			for event in buffer:
				if event[0] != Undo.animation_substep:
					were_good = true;
					break;
			if (!were_good):
				buffer.clear();
				add_undo_event([Undo.light_turn, amount, false], Chrono.CHAR_UNDO);
			else:
				add_undo_event([Undo.light_turn, amount, true], chrono);
		else:
			add_undo_event([Undo.light_turn, amount, true], chrono);
		light_turn += amount;

		#if (debug_prints):
		#	print("=== IT IS NOW LIGHT TURN " + str(light_turn) + " ===");
		
func check_checkpoints(chrono: int) -> void:
	if (heavy_turn > 0):
		var terrain = terrain_in_tile(heavy_actor.pos, heavy_actor, chrono);
		if (terrain.has(Tiles.Checkpoint) or terrain.has(Tiles.CheckpointRed)):
			add_to_animation_server(heavy_actor, [Anim.sfx, "undo"]);
			while (heavy_turn > 0):
				var old_heavy_turn = heavy_turn;
				var events = heavy_undo_buffer.pop_at(heavy_turn - 1);
				for event in events:
					if (event[0] == Undo.heavy_turn):
						undo_one_event(event, Chrono.CHAR_UNDO);
					elif (event[0] == Undo.change_terrain):
						var old_tile = event[4];
						if (old_tile == Tiles.RepairStation || old_tile == Tiles.RepairStationGreen || old_tile == Tiles.RepairStationGray):
							check_abyss_chimes();
					elif (event[0] == Undo.set_actor_var):
						if event[2] == "broken":
							check_abyss_chimes();
					add_undo_event([Undo.heavy_undo_event_remove, heavy_turn, event], Chrono.CHAR_UNDO);
				# failsafe
				if (old_heavy_turn == heavy_turn):
					heavy_turn -= 1;
			add_to_animation_server(heavy_actor, [Anim.heavy_timeline_finish_animations]);
	
	if (light_turn > 0):
		var terrain = terrain_in_tile(light_actor.pos, light_actor, chrono);
		if (terrain.has(Tiles.Checkpoint) or terrain.has(Tiles.CheckpointBlue)):
			add_to_animation_server(light_actor, [Anim.sfx, "undo"]);
			while (light_turn > 0):
				var old_light_turn = light_turn;
				var events = light_undo_buffer.pop_at(light_turn - 1);
				for event in events:
					if (event[0] == Undo.light_turn):
						undo_one_event(event, Chrono.CHAR_UNDO);
					elif (event[0] == Undo.change_terrain):
						var old_tile = event[4];
						if (old_tile == Tiles.RepairStation || old_tile == Tiles.RepairStationGreen || old_tile == Tiles.RepairStationGray):
							check_abyss_chimes();
					elif (event[0] == Undo.set_actor_var):
						if event[2] == "broken":
							check_abyss_chimes();
					add_undo_event([Undo.light_undo_event_remove, light_turn, event], Chrono.CHAR_UNDO);
				# failsafe
				if (old_light_turn == light_turn):
					light_turn -= 1;
			add_to_animation_server(heavy_actor, [Anim.light_timeline_finish_animations]);
		
func actors_in_tile(pos: Vector2) -> Array:
	var result = [];
	for actor in actors:
		if actor.pos == pos:
			result.append(actor);
	return result;

func phaseboard_active(pos: Vector2, actor: Actor, chrono: int, id: int) -> bool:
	match (id):
		Tiles.PhaseBoardRed:
			return heavy_selected;
		Tiles.PhaseBoardBlue:
			return !heavy_selected;
		Tiles.PhaseBoardGray:
			return chrono == Chrono.MOVE;
		Tiles.PhaseBoardPurple:
			return chrono == Chrono.CHAR_UNDO;
		Tiles.PhaseBoardVoid:
			return chrono == Chrono.META_UNDO;
		Tiles.PhaseBoardDeath:
			return heavy_actor.broken or light_actor.broken;
		Tiles.PhaseBoardLife:
			return !(heavy_actor.broken or light_actor.broken);
		Tiles.PhaseBoardHeavy:
			return actor == heavy_actor;
		Tiles.PhaseBoardLight:
			return actor == light_actor;
		Tiles.PhaseBoardCrate:
			return actor != heavy_actor and actor != light_actor;
		Tiles.PhaseBoardEast:
			return actor != null and actor.pos.x > pos.x;
		Tiles.PhaseBoardWest:
			return actor != null and actor.pos.x < pos.x;
		Tiles.PhaseBoardNorth:
			return actor != null and actor.pos.y < pos.y;
		Tiles.PhaseBoardSouth:
			return actor != null and actor.pos.y > pos.y;
	return false;

func terrain_in_tile(pos: Vector2, actor: Actor = null, chrono: int = Chrono.TIMELESS, xray: bool = false) -> Array:
	var result = [];
	for layer in terrain_layers:
		result.append(layer.get_cellv(pos));
	if (has_floorboards and !xray):
		var found = false;
		for i in range(result.size()):
			if found:
				result[i] = -99;
			elif floorboards_dict.has(result[i]):
				found = true;
			elif phaseboards_dict.has(result[i]) and phaseboard_active(pos, actor, chrono, result[i]):
				found = true;
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
	if (has_green_fog):
		var terrain = terrain_in_tile(actor.pos, actor, chrono);
		if (terrain.has(Tiles.GreenFog)):
			add_to_animation_server(actor, [Anim.sfx, "greenfire"]);
			return Chrono.CHAR_UNDO;
	return chrono;
	
func floorboards_rotation() -> void:
	all_rotation(floorboards_ids);
	
func phaseboards_rotation() -> void:
	all_rotation(rotateable_phaseboards_ids);	

func fuzz_rotation() -> void:
	all_rotation([Tiles.Fuzz]);
	
func all_rotation(candidates: Array) -> void:
	var floorboard_counts = {};
	for i in range(terrain_layers.size()-1, -1, -1):
		var layer = terrain_layers[i];
		for id in candidates:
			var tiles = layer.get_used_cells_by_id(id);
			for tile in tiles:
				if floorboard_counts.has(tile):
					var count = floorboard_counts[tile] + 1;
					floorboard_counts[tile] = count;
					layer.set_cellv(tile, id, count % 2 == 1, (count / 2) % 2 == 1, (count / 4) % 2 == 1);
				else:
					floorboard_counts[tile] = 0;

var floorboards_ids = [Tiles.Floorboards, Tiles.MagentaFloorboards, Tiles.GreenFloorboards, Tiles.VoidFloorboards];
var floorboards_dict = {Tiles.Floorboards: true, Tiles.MagentaFloorboards: true, Tiles.GreenFloorboards: true, Tiles.VoidFloorboards: true};
var rotateable_phaseboards_ids = [Tiles.PhaseBoardRed, Tiles.PhaseBoardBlue, Tiles.PhaseBoardGray, Tiles.PhaseBoardVoid, Tiles.PhaseBoardPurple, Tiles.PhaseBoardDeath, Tiles.PhaseBoardLife];
var phaseboards_dict = {Tiles.PhaseBoardRed: true, Tiles.PhaseBoardBlue: true, Tiles.PhaseBoardGray: true, Tiles.PhaseBoardVoid: true, Tiles.PhaseBoardPurple: true, Tiles.PhaseBoardDeath: true, Tiles.PhaseBoardLife: true, Tiles.PhaseBoardHeavy: true, Tiles.PhaseBoardLight: true, Tiles.PhaseBoardCrate: true, Tiles.PhaseBoardEast: true, Tiles.PhaseBoardNorth: true, Tiles.PhaseBoardSouth: true, Tiles.PhaseBoardWest: true};

func set_cellv_maybe_rotation(id: int, tile: Vector2, layer: int) -> void:
	if id in floorboards_ids:
		set_cellv_rotation(id, tile, layer, floorboards_ids);
	elif id == Tiles.Fuzz:
		set_cellv_rotation(id, tile, layer, [Tiles.Fuzz]);
	else:
		terrain_layers[layer].set_cellv(tile, id);

func set_cellv_rotation(id: int, tile: Vector2, layer: int, candidates: Array) -> void:
	var terrain = terrain_in_tile(tile, null, Chrono.TIMELESS, true);
	var count = 0;
	for i in range(terrain.size()):
		if terrain[i] in candidates:
			count += 1;
	terrain_layers[layer].set_cellv(tile, id, count % 2 == 1, (count / 2) % 2 == 1, (count / 4) % 2 == 1);
	
func maybe_break_actor(actor: Actor, hazard: int, hypothetical: bool, green_terrain: int, chrono: int) -> int:
	# AD04: being broken makes you immune to breaking :D
	if (!actor.broken and actor.durability <= hazard):
		if (!hypothetical):
			actor.post_mortem = hazard;
			if (green_terrain == Greenness.Green and chrono < Chrono.CHAR_UNDO):
				chrono = Chrono.CHAR_UNDO;
			if (green_terrain == Greenness.Void and chrono < Chrono.META_UNDO):
				chrono = Chrono.META_UNDO;
			if (actor.is_crystal and chrono < Chrono.CHAR_UNDO):
				chrono = Chrono.CHAR_UNDO;
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
	# new layer will have to be at the back (first child, last terrain_layer), so I don't desync existing memories of layers.
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
			var ghost = make_ghost_here_with_texture(pos, preload("res://timeline/timeline-unterrain-12.png"));
			ghost.position -= Vector2(cell_size/2, cell_size/2);
			ghost.scale = Vector2(2, 2);
		return Success.Surprise;
	
	if (!hypothetical):
		var terrain_layer = terrain_layers[layer];
		var old_tile = terrain_layer.get_cellv(pos);
		if (assumed_old_tile != -2 and assumed_old_tile != old_tile):
			# desync (probably due to fuzz doubled glass mechanic). find or create the first layer where assumed_old_tile is correct.
			layer = find_or_create_layer_having_this_tile(pos, assumed_old_tile);
			terrain_layer = terrain_layers[layer];
			# set old_tile again (I guess it'll always be -1 at this point but just to be explicit about it)
			old_tile = terrain_layer.get_cellv(pos);
		set_cellv_maybe_rotation(new_tile, pos, layer);
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
			add_to_animation_server(actor, [Anim.unshatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
			if (chrono < Chrono.META_UNDO):
				for actor in actors:
					# time crystal/glass chronofrag interaction: it isn't. that's my decision for now.
					if actor.pos == pos and !actor.broken and actor.durability <= Durability.PITS:
						actor.post_mortem = Durability.PITS;
						set_actor_var(actor, "broken", true, chrono);
		elif new_tile == Tiles.Floorboards or new_tile == Tiles.MagentaFloorboards or new_tile == Tiles.RepairStation or new_tile == Tiles.RepairStationGray:
			add_to_animation_server(actor, [Anim.unshatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
		else:
			if (old_tile == Tiles.Fuzz):
				play_sound("fuzz");
			elif (old_tile == Tiles.OneUndo):
				play_sound("rewindnoticed");
			elif (colours_dictionary.has(old_tile) or (old_tile >= Tiles.Propellor and old_tile <= Tiles.FallOne) or (old_tile == Tiles.HeavyMimic or old_tile == Tiles.LightMimic)):
				pass;
			elif (old_tile == Tiles.Continuum || old_tile == Tiles.Spotlight):
				pass
			else:
				add_to_animation_server(actor, [Anim.shatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
			
			if (old_tile == Tiles.OneUndo or new_tile == Tiles.OneUndo):
				update_limited_undo_sprite(pos);
				
		# if floorboards were made or destroyed here, have to update night/stars state
		if (has_night_or_stars):
			for actor in actors:
				if actor.pos == pos:
					update_night_and_stars(actor, terrain_in_tile(pos, actor, chrono));
		
	return Success.Surprise;

func maybe_rise(actor: Actor, chrono: int, dir: Vector2, care_about_falling : bool = true):
	if (dir.y < 0 and !is_suspended(actor, chrono) and actor.fall_speed() != 0 and (!care_about_falling or actor.airborne == -1 or !actor.is_character)):
		set_actor_var(actor, "airborne", 2, chrono);

func current_tile_is_solid(actor: Actor, dir: Vector2, is_gravity: bool, is_retro: bool, chrono: int, hypothetical: bool) -> bool:
	# This is a hack for directional phaseboards.
	var old_pos = actor.pos;
	actor.pos += dir;
	var terrain = terrain_in_tile(old_pos, actor, chrono);
	actor.pos = old_pos;
	var blocked = Success.Yes;
	flash_terrain = -1;
	
	# hole check
	if (actor.broken and has_holes):
		var actors_there = actors_in_tile(actor.pos);
		for actor_there in actors_there:
			if (actor_there.actorname == Actor.Name.Hole or actor_there.actorname == Actor.Name.GreenHole or actor_there.actorname == Actor.Name.VoidHole):
				return Success.No;
	
	# when moving retrograde, it would have been valid to come out of a oneway, but not to have gone THROUGH one.
	# so check that.
	# besides that, glass blocks prevent exit.
	for i in range(terrain.size()):
		var id = terrain[i];
		match id:
			Tiles.OnewayEast:
				blocked = no_if_true_yes_if_false(is_retro and dir == Vector2.RIGHT);
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayWest:
				blocked  = no_if_true_yes_if_false(is_retro and dir == Vector2.LEFT);
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayNorth:
				blocked = no_if_true_yes_if_false(is_retro and dir == Vector2.UP);
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewaySouth:
				blocked  = no_if_true_yes_if_false(is_retro and dir == Vector2.DOWN);
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.GlassBlock:
				blocked = Success.No;
				if (!is_gravity and chrono == Chrono.MOVE and actor.is_character):
					achievement_get("BuriedAlive");
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.GlassBlockCracked:
				if (is_gravity):
					return Success.No;
				else:
					blocked = maybe_change_terrain(actor, actor.pos, i, hypothetical, Greenness.Mundane, chrono, -1);
			Tiles.GreenGlassBlock:
				blocked = Success.No;
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.VoidGlassBlock:
				blocked = Success.No;
				if (blocked == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.SpiderWeb:
				if (!is_retro):
					var found: int = 0;
					var required: int = terrain.count(Tiles.SpiderWeb);
					while animation_server.size() <= animation_substep:
						animation_server.push_back([]);
					for a in range (animation_substep+1):
						for anim in animation_server[a]:
							if anim[0] == actor and anim[1][0] == Anim.move and !anim[1][2]:
								found += 1;
								if (found >= required):
									flash_terrain = id;
									flash_colour = no_foo_flash;
									return Success.No;
			Tiles.SpiderWebGreen:
				var found: int = 0;
				var required: int = terrain.count(Tiles.SpiderWebGreen);
				while animation_server.size() <= animation_substep:
					animation_server.push_back([]);
				for a in range (animation_substep+1):
					for anim in animation_server[a]:
						if anim[0] == actor and anim[1][0] == Anim.move:
							found += 1;
							if (found >= required):
								flash_terrain = id;
								flash_colour = no_foo_flash;
								return Success.No;
		if blocked != Success.Yes:
			return blocked;
	return Success.Yes;

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
# infinite loop variable
var bumper_counter: int = 0;

func try_enter_terrain(actor: Actor, pos: Vector2, dir: Vector2, hypothetical: bool, is_gravity: bool, is_retro: bool, chrono: int, pushers_list: Array, was_push: bool) -> int:
	var result = Success.Yes;
	flash_terrain = -1;
	
	# check for bottomless pits
	if (pos.y > map_y_max):
		return maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Mundane, chrono);
	
	var terrain = terrain_in_tile(pos, actor, chrono);

	for i in range(terrain.size()):
		var id = terrain[i];
		match id:
			Tiles.Wall:
				result = Success.No;
			Tiles.GateOfEternity:
				result = Success.No;
			Tiles.GateOfDemise:
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
				result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Mundane, chrono);
			Tiles.GreenPowerSocket:
				result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Green, chrono);
			Tiles.VoidPowerSocket:
				result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Void, chrono);
			Tiles.RepairStationBumper:
				if actor.broken:
					if (!hypothetical):
						set_actor_var(actor, "broken", false, chrono);
					return Success.Surprise;
				else:
					return Success.No;
			Tiles.Fence:
				if (actor.airborne != -1):
					if (!hypothetical):
						add_to_animation_server(actor, [Anim.sfx, "fence"]);
						set_actor_var(actor, "airborne", -1, chrono);
					return Success.Surprise;
				else:
					return Success.No;
			Tiles.Fan:
				if (!hypothetical):
					if (actor.airborne < 1):
						set_actor_var(actor, "airborne", 2, chrono);
				return Success.Surprise;
			Tiles.Bumper:
				bumper_counter += 1;
				if (bumper_counter == 99):
					if (hypothetical):
						pass;
					else:
						lose("Infinite loop.", null, true, "infloop");
					bumper_counter -= 1;
					return Success.Surprise;
				if (move_actor_relative(actor, -dir, chrono, true, false) == Success.Yes):
					if (!hypothetical):
						add_to_animation_server(actor, [Anim.sfx, "bumper"]);
						move_actor_relative(actor, -dir, chrono, false, false);
						maybe_rise(actor, chrono, -dir, false);
					bumper_counter -= 1;
					return Success.Surprise;
				else:
					bumper_counter -= 1;
					return Success.No;
			Tiles.Passage:
				var factor = 2;
				while Tiles.Passage in terrain_in_tile(actor.pos + dir*factor, actor, chrono):
					factor += 1;
				if (move_actor_relative(actor, dir*factor, chrono, true, false) == Success.Yes):
					if (!hypothetical):
						add_to_animation_server(actor, [Anim.sfx, "unlock"]);
						move_actor_relative(actor, dir*factor, chrono, false, false)
						maybe_rise(actor, chrono, dir*factor, false);
					return Success.Surprise;
				else:
					return Success.No;
			Tiles.GreenPassage:
				var factor = 2;
				while Tiles.GreenPassage in terrain_in_tile(actor.pos + dir*factor, actor, chrono):
					factor += 1;
				if (move_actor_relative(actor, dir*factor, max(Chrono.CHAR_UNDO, chrono), true, false) == Success.Yes):
					if (!hypothetical):
						add_to_animation_server(actor, [Anim.sfx, "unlock"]);
						move_actor_relative(actor, dir*factor, max(Chrono.CHAR_UNDO, chrono), false, false)
						maybe_rise(actor, chrono, dir*factor, false);
					return Success.Surprise;
				else:
					return Success.No;
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
				result = no_if_true_yes_if_false(!actor.broken);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = no_foo_flash;
			Tiles.AntiGrate:
				result = no_if_true_yes_if_false(actor.broken);
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
			Tiles.OnewayEastGray:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.LEFT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayWestGray:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.RIGHT);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayNorthGray:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.DOWN);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewaySouthGray:
				result = no_if_true_yes_if_false(!is_retro and dir == Vector2.UP);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.OnewayEastLose:
				result = no_if_true_yes_if_false(dir == Vector2.LEFT);
				if (result == Success.No):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Green, chrono);
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewayWestLose:
				result = no_if_true_yes_if_false(dir == Vector2.RIGHT);
				if (result == Success.No):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Green, chrono);
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewayNorthLose:
				result = no_if_true_yes_if_false(dir == Vector2.DOWN);
				if (result == Success.No):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Green, chrono);
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.OnewaySouthLose:
				result = no_if_true_yes_if_false(dir == Vector2.UP);
				if (result == Success.No):
					result = maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Green, chrono);
					flash_terrain = id;
					flash_colour = oneway_green_flash;
			Tiles.LadderPlatform:
				result = no_if_true_yes_if_false(dir == Vector2.DOWN and is_gravity);
			Tiles.WoodenPlatform:
				result = no_if_true_yes_if_false(dir == Vector2.DOWN and is_gravity);
			Tiles.GhostPlatform:
				result = no_if_true_yes_if_false(!actor.is_character and dir == Vector2.DOWN and is_gravity);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
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
			Tiles.PhaseWallBlue:
				result = no_if_true_yes_if_false(!heavy_selected);
			Tiles.PhaseWallRed:
				result = no_if_true_yes_if_false(heavy_selected);
			Tiles.PhaseWallGray:
				result = no_if_true_yes_if_false(chrono == Chrono.MOVE);
			Tiles.PhaseWallPurple:
				result = no_if_true_yes_if_false(chrono == Chrono.CHAR_UNDO);
			Tiles.PhaseWallGreenEven:
				result = no_if_true_yes_if_false(meta_turn % 2 == 0);
			Tiles.PhaseWallGreenOdd:
				result = no_if_true_yes_if_false(meta_turn % 2 == 1);
			Tiles.NoPush:
				result = no_if_true_yes_if_false(!is_retro and pushers_list.size() > 0);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoPushGreen:
				result = no_if_true_yes_if_false(was_push or pushers_list.size() > 0);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.YesPush:
				result = no_if_true_yes_if_false(!is_retro and pushers_list.size() == 0);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.YesPushGreen:
				result = no_if_true_yes_if_false((is_retro and !was_push) or (!is_retro and pushers_list.size() == 0));
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoLeft:
				result = no_if_true_yes_if_false(!is_retro and actor.is_character and actor.facing_left);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoLeftGreen:
				result = no_if_true_yes_if_false(actor.is_character and actor.facing_left);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.PinkJelly:
				while animation_server.size() <= animation_substep:
					animation_server.push_back([]);
				var found: int = 0;
				var required: int = terrain.count(Tiles.PinkJelly);
				result = Success.No;
				for a in range (animation_substep+1):
					for anim in animation_server[a]:
						if anim[0] == actor and anim[1][0] == Anim.move:
							found += 1;
							if (found >= required):
								result = Success.Yes;
								break;
					if (result == Success.Yes):
						break;
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.CyanJelly:
				while animation_server.size() <= animation_substep:
					animation_server.push_back([]);
				var found: int = 0;
				var required: int = terrain.count(Tiles.CyanJelly);
				result = Success.No;
				for a in range (animation_substep+1):
					for anim in animation_server[a]:
						if anim[0] == actor and (anim[1][0] == Anim.move or anim[1][0] == Anim.bump):
							found += 1;
							if (found >= required):
								result = Success.Yes;
								break;
					if (result == Success.Yes):
						break;
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoRising:
				result = no_if_true_yes_if_false(actor.airborne >= 1);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoFalling:
				result = no_if_true_yes_if_false(actor.airborne == 0);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
			Tiles.NoGrounded:
				result = no_if_true_yes_if_false(actor.airborne == -1);
				if (result == Success.No):
					flash_terrain = id;
					flash_colour = oneway_flash;
		if result != Success.Yes:
			return result;
	return result;
	
func is_suspended(actor: Actor, chrono: int):
	if (actor.propellor != null):
		return true;
	if (!actor.climbs()):
		return false;
	var terrain = terrain_in_tile(actor.pos, actor, chrono);
	return terrain.has(Tiles.Ladder) || terrain.has(Tiles.LadderPlatform);

func terrain_is_hazardous(actor: Actor, pos: Vector2, chrono: int) -> int:
	if (pos.y > map_y_max and actor.durability <= Durability.PITS):
		return Durability.PITS;
	var terrain = terrain_in_tile(pos, actor, chrono);
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
	
func try_enter(actor: Actor, dir: Vector2, chrono: int, can_push: bool, hypothetical: bool, is_gravity: bool, was_push: bool, is_retro: bool = false, pushers_list: Array = [], phased_out_of = null) -> int:
	var dest = actor.pos + dir;
	if (chrono >= Chrono.TIMELESS):
		return Success.Yes;
	if (chrono >= Chrono.META_UNDO and is_retro):
		# assuming no bugs, if it was overlapping in the meta-past, then it must have been valid to reach then
		if (has_void_walls and chrono == Chrono.META_UNDO):
			return no_if_true_yes_if_false(terrain_in_tile(dest, actor, chrono).has(Tiles.VoidWall));
		else:
			return Success.Yes;
	
	# handle solidity in our tile, solidity in the tile over, hazards/surprises in the tile over
	if (!actor.phases_into_terrain()):
		var leave_attempt = current_tile_is_solid(actor, dir, is_gravity, is_retro, chrono, true)
		if (leave_attempt == Success.No):
			if (flash_terrain > -1 and (!hypothetical or !is_gravity)):
				add_to_animation_server(actor, [Anim.afterimage_at, terrainmap.tile_set.tile_get_texture(flash_terrain), terrainmap.map_to_world(actor.pos), flash_colour]);
			return Success.No;
		elif (leave_attempt == Success.Surprise):
			current_tile_is_solid(actor, dir, is_gravity, is_retro, chrono, false);
			return Success.Surprise;
		var solidity_check = try_enter_terrain(actor, dest, dir, hypothetical, is_gravity, is_retro, chrono, pushers_list, was_push);
		if (solidity_check != Success.Yes):
			if (flash_terrain > -1 and (!hypothetical or !is_gravity)):
				add_to_animation_server(actor, [Anim.afterimage_at, terrainmap.tile_set.tile_get_texture(flash_terrain), terrainmap.map_to_world(dest), flash_colour]);
			return solidity_check;
	
	# handle pushing
	var actors_there = actors_in_tile(dest);
	if (has_ghost_fog and is_retro and terrain_in_tile(dest).has(Tiles.PurpleFog)):
		actors_there = [];
	var pushables_there = [];
	#var tiny_pushables_there = [];
	for actor_there in actors_there:
		if (phased_out_of != null and phased_out_of.has(actor_there)):
			achievement_get("Phantasmal");
			continue
		#if actor_there.tiny_pushable():
		#	tiny_pushables_there.push_back(actor_there);
		elif (actor_there.is_hole()):
			continue;
		elif actor_there.pushable():
			pushables_there.push_back(actor_there);
	
	var boulder_cats_cradle_move = false;
	
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
					check_won(chrono);
					add_to_animation_server(actor_there, [Anim.bump, -dir, -1]);
					add_to_animation_server(actor, [Anim.move, dir/2, false, -1]);
					add_to_animation_server(actor_there, [Anim.move, -dir/2, false, -1]);
					add_to_animation_server(actor, [Anim.set_next_texture, actor.get_next_texture(), -1, actor.facing_left]);
					add_to_animation_server(actor_there, [Anim.set_next_texture, actor_there.get_next_texture(), -1, actor_there.facing_left]);
					return Success.No;
			elif (actor_there.actorname == Actor.Name.ChronoHelixBlue):
				if actor.actorname == Actor.Name.ChronoHelixRed:
					nonstandard_won = true;
					add_to_animation_server(actor_there, [Anim.bump, -dir, -1]);
					add_to_animation_server(actor, [Anim.move, dir/2, false, -1]);
					add_to_animation_server(actor_there, [Anim.move, -dir/2, false, -1]);
					add_to_animation_server(actor, [Anim.set_next_texture, actor.get_next_texture(), -1, actor.facing_left]);
					add_to_animation_server(actor_there, [Anim.set_next_texture, actor_there.get_next_texture(), -1, actor_there.facing_left]);
					check_won(chrono);
					return Success.No;
			
			# Strength Rule
			# Modified by the Light Clumsiness Rule: Light's strength is lowered by 1 when it's in the middle of a multi-push.
			if !strength_check(actor.strength + strength_modifier, actor_there.heaviness) and !can_eat(actor_there, actor):
				if (actor.phases_into_actors()):
					pushables_there.clear();
					break;
				else:
					# Boulders rolling under their own momentum can push with +1 strength, but will stop rolling in the process.
					if (actor.actorname == Actor.Name.Boulder and actor.momentum == dir and pushers_list.size() == 1 and !boulder_cats_cradle_move):
						boulder_cats_cradle_move = true;
						strength_modifier += 1;
						if !strength_check(actor.strength + strength_modifier, actor_there.heaviness):
							pushers_list.pop_back();
							return Success.No;
					else:
						pushers_list.pop_back();
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
				if (actor.phases_into_actors() or (has_ghost_fog and !is_gravity and terrain_in_tile(dest, actor, chrono).has(Tiles.GhostFog))):
					pushables_there.clear();
					result = Success.Yes;
					break;
				elif (!actor.broken and pushables_there.size() == 1 and actor_there.actorname == Actor.Name.WoodenCrate and actor.is_character and !is_gravity):
					# 'Wooden Crates special moves'
					# When making a non-gravity move, if the push fails, unbroken Heavy can break a solo Wooden Crate, unbroken Light can push a Wooden Crate upwards.
					# since wooden crate did a bump, robot needs to do a bump too to sync up animations
					# should be OK to have the nonce be -1 since the real thing will still happen?
					if actor.actorname == Actor.Name.Heavy and actor_there.durability <= Durability.SPIKES:
						add_to_animation_server(actor, [Anim.bump, dir, -1]);
						set_actor_var(actor_there, "broken", true, chrono);
					elif actor.actorname == Actor.Name.Light:
						add_to_animation_server(actor, [Anim.bump, dir, -1]);
						dir = Vector2.UP;
						# check again if we can push it up
						actor_there_result = move_actor_relative(actor_there, dir, chrono, true, is_gravity, false, pushers_list);
						if (actor_there_result == Success.No):
							pushers_list.pop_back();
							return Success.No;
						elif(actor_there_result == Success.Surprise):
							result = Success.Surprise;
							surprises.append(actor_there);
					else:
						pushers_list.pop_back();
						return Success.No;
				elif (!actor.broken and pushables_there.size() == 1 and actor.actorname == Actor.Name.SteelCrate and !actor_there.broken and (actor_there.actorname == Actor.Name.Light or actor_there.actorname == Actor.Name.CuckooClock)):
					# 'Steel Crates special moves'
					# If an unbroken steel crate tries to move into a solo unbroken Light or Cuckoo Clock for any reason, the target first breaks.
					# this also cancels the pusher's move which is janky but fuck it, I don't feel like fixing the jank for a non main campaign edge case
					result = Success.Surprise;
					add_to_animation_server(actor, [Anim.bump, dir, -1]);
					set_actor_var(actor_there, "broken", true, chrono);
				else:
					pushers_list.pop_back();
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
						# 'allow a power crate/chrono helix to be lifted up' clause.
						if (!actor_there.is_character and actor_there.fall_speed() != 0 and dir == Vector2.UP and strength_check(actor_there.strength, actor.heaviness)):
							set_actor_var(actor_there, "airborne", 2, chrono);
				for actor_there in pushables_there:
					actor_there.just_moved = false;
		
		pushers_list.pop_back();
		if (boulder_cats_cradle_move and result == Success.Yes):
			result = Success.Surprise;
		return result;
	
	return Success.Yes;

func can_eat(eater: Actor, eatee: Actor) -> bool:
	if !eatee.is_crystal:
		return false;
	# right, don't re-eat broken crystals if e.g. Heavy sticky tops them around
	# (I need to decide how sticky topping broken actors works later, but I don't have to right now <w<)
	if eatee.broken:
		return false;
	if (!eater.is_main_character()):
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
				add_to_animation_server(eatee, [Anim.sfx, "greentimecrystal"])
				# raw: just add a turn to the end
				if (!heavy_actor.powered):
					set_actor_var(heavy_actor, "powered", true, Chrono.CHAR_UNDO);
				add_undo_event([Undo.heavy_green_time_crystal_raw], Chrono.CHAR_UNDO);
				add_to_animation_server(eater, [Anim.heavy_green_time_crystal_raw, eatee]);
			else:
				add_to_animation_server(eatee, [Anim.sfx, "remembertimecrystal"])
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
					add_to_animation_server(eater, [Anim.heavy_green_time_crystal_unlock, eatee, -1]);
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
					add_to_animation_server(eater, [Anim.heavy_green_time_crystal_unlock, eatee, heavy_turn]);
		elif light_actor == eater:
			light_max_moves += 1;
			if (light_locked_turns.size() == 0):
				add_to_animation_server(eatee, [Anim.sfx, "greentimecrystal"])
				if (!light_actor.powered):
					set_actor_var(light_actor, "powered", true, Chrono.CHAR_UNDO);
				add_undo_event([Undo.light_green_time_crystal_raw], Chrono.CHAR_UNDO);
				add_to_animation_server(eater, [Anim.light_green_time_crystal_raw, eatee]);
			else:
				add_to_animation_server(eatee, [Anim.sfx, "remembertimecrystal"])
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
					add_to_animation_server(eater, [Anim.light_green_time_crystal_unlock, eatee, -1]);
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
					add_to_animation_server(eater, [Anim.light_green_time_crystal_unlock, eatee, light_turn]);
		else: #cuckoo clock
			clock_ticks(eater, 1, Chrono.CHAR_UNDO);
			add_to_animation_server(eatee, [Anim.sfx, "greentimecrystal"])
			add_to_animation_server(eater, [Anim.generic_green_time_crystal, eatee.color]);
	else: # magenta time crystal
		add_to_animation_server(eatee, [Anim.sfx, "magentatimecrystal"])
		var just_locked = false;
		var turn_moved = -1;
		if (heavy_actor == eater):
			# Lose (Paradox)
			if (heavy_max_moves <= 0):
				add_to_animation_server(eater, [Anim.heavy_magenta_time_crystal, eatee, -99]);
				lose("Paradox: A character can't have less than 0 moves.", heavy_actor)
				achievement_get("Paradox");
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
			add_to_animation_server(eater, [Anim.heavy_magenta_time_crystal, eatee, turn_moved]);
			
		elif (light_actor == eater):
			# Lose (Paradox)
			if (light_max_moves <= 0):
				add_to_animation_server(eater, [Anim.light_magenta_time_crystal, eatee, -99]);
				lose("Paradox: A character can't have less than 0 moves.", light_actor)
				achievement_get("Paradox");
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
			add_to_animation_server(eater, [Anim.light_magenta_time_crystal, eatee, turn_moved]);
		else: #cuckoo clock
			clock_ticks(eater, -1, Chrono.CHAR_UNDO);
			add_to_animation_server(eater, [Anim.generic_magenta_time_crystal, eatee.color]);

func clock_ticks(actor: ActorBase, amount: int, chrono: int, animation_nonce: int = -1) -> void:
	if (animation_nonce == -1):
		animation_nonce = animation_nonce_fountain_dispense();
	actor.update_ticks(actor.ticks + amount);
	var newly_lost = false;
	if (actor.ticks == 0 and !fuzzed and !actor.broken and (chrono < Chrono.META_UNDO or actor.time_colour == TimeColour.Void)):
		if actor.actorname == Actor.Name.CuckooClock and !lost:
			newly_lost = true;
			lose("You didn't make it back to the Chrono Lab Reactor in time.", actor);
	add_undo_event([Undo.tick, actor, amount, animation_nonce], chrono_for_maybe_green_actor(actor, chrono));
	add_to_animation_server(actor, [Anim.tick, amount, actor.ticks, newly_lost, animation_nonce]);

func open_doors(id: int) -> void:
	var found = false;
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	for layer in range(layers_tiles.size()):
		var tiles = layers_tiles[layer];
		for tile in tiles:
			found = true;
			terrain_layers[layer].set_cellv(tile, -1);
			# make dust
			for i in range(18):
				var sprite = Sprite.new();
				sprite.set_script(preload("res://FadingSprite.gd"));
				sprite.texture = preload("res://assets/dust.png")
				sprite.position = tile*Vector2(cell_size, cell_size)+Vector2(cell_size/2, cell_size*rng.randf_range(0.1, 0.9));
				sprite.fadeout_timer_max = 3;
				sprite.velocity = Vector2(rng.randf_range(48, 128), rng.randf_range(-16, 16))/6;
				if (i % 2 == 1):
					sprite.velocity.x *= -1;
				sprite.hframes = 7;
				sprite.frame = rng.randi_range(0, 6);
				sprite.centered = true;
				sprite.scale = Vector2(1, 1);
				var mod = rng.randf_range(0, 0.2);
				sprite.modulate = Color(mod, mod, mod);
				overactorsparticles.add_child(sprite);
	if (found):
		voidlike_puzzle = true;
		play_sound("onemillionyears");

func lose(reason: String, suspect: Actor, lose_instantly: bool = false, music: String = "lose") -> void:
	lost = true;
	if (suspect != null and suspect.time_colour == TimeColour.Void or lost_void):
		lost_void = true;
		winlabel.change_text(reason + "\n\nRestart to continue.")
	else:
		lost_void = false;
		winlabel.change_text(reason + "\n\nUndo or Restart to continue.")
	if (has_void_gates):
		open_doors(Tiles.GateOfEternity);
	if (music == "exception"):
		achievement_get("ExceptionHandler", true);
	elif (music == "infloop"):
		achievement_get("InfiniteLoop", true);
	lost_speaker.stream = sounds[music];
	if (lose_instantly):
		fade_in_lost();
	
func end_lose() -> void:
	lost = false;
	lost_void = false;
	lost_speaker.stop();
	winlabel.visible = false;
	Shade.on = false;
	if won_fade_started:
		won_fade_started = false;
		heavy_actor.modulate.a = 1;
		light_actor.modulate.a = 1;

func set_actor_var(actor: ActorBase, prop: String, value, chrono: int,
animation_nonce: int = -1, is_retro: bool = false, _retro_old_value = null) -> void:
	var old_value = actor.get(prop);
	if animation_nonce == -1:
		animation_nonce = animation_nonce_fountain_dispense();
	if (chrono < Chrono.GHOSTS):
		# sanity check: prevent, for example, spotlight from making a broken->broken event
		if (old_value == value):
			if (chrono == Chrono.CHAR_UNDO and prop == "broken"):
				if value == true:
					achievement_get("AlreadyBroken")
				else:
					achievement_get("AlreadyFixed")
			# but first, a copy of this because it's what flickers timeline symbols out of existence :B
			add_to_animation_server(actor, [Anim.set_next_texture, actor.get_next_texture(), animation_nonce, actor.facing_left])
			return
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
						add_to_animation_server(actor, [Anim.sfx, "heavyuncoyote"]);
						add_to_animation_server(actor, [Anim.dust, 3]);
					elif old_value == -1 and value != -1:
						add_to_animation_server(actor, [Anim.sfx, "heavyunland"]);
						add_to_animation_server(actor, [Anim.dust, 5]);
				else:
					if value >= 1 and old_value <= 0:
						add_to_animation_server(actor, [Anim.sfx, "heavycoyote"]);
						add_to_animation_server(actor, [Anim.dust, 0]);
					elif value == -1 and old_value != -1:
						add_to_animation_server(actor, [Anim.sfx, "heavyland"]);
						add_to_animation_server(actor, [Anim.dust, 2]);
			elif actor.actorname == Actor.Name.Light:
				if is_retro:
					if old_value >= 1 and value <= 0:
						add_to_animation_server(actor, [Anim.sfx, "lightuncoyote"]);
						add_to_animation_server(actor, [Anim.dust, 3]);
					elif old_value == -1 and value != -1:
						add_to_animation_server(actor, [Anim.sfx, "lightunland"]);
						add_to_animation_server(actor, [Anim.dust, 5]);
				else:
					if value >= 1 and old_value <= 0:
						add_to_animation_server(actor, [Anim.sfx, "lightcoyote"]);
						add_to_animation_server(actor, [Anim.dust, 0]);
					elif value == -1 and old_value != -1:
						add_to_animation_server(actor, [Anim.sfx, "lightland"]);
						add_to_animation_server(actor, [Anim.dust, 2]);
			else:
				#everyone gets landing dust
				if is_retro:
					if old_value == -1 and value != -1:
						add_to_animation_server(actor, [Anim.dust, 5]);
				else:
					if value == -1 and old_value != -1:
						add_to_animation_server(actor, [Anim.dust, 2]);
					
			#everyone gets falling dust
			if is_retro:
				if (old_value == 0 and value != 0):
					add_to_animation_server(actor, [Anim.dust, 4]);
			else:
				if value == 0 and old_value != 0:
					add_to_animation_server(actor, [Anim.dust, 1]);
		
		# special case - if we break or unbreak, we can ding or unding too
		# We also need to handle abysschime and meta-undoing it.
		# (I'll write that logic separately just so it's not a giant mess, the performance hit is miniscule.)
		if prop == "broken":
			if actor.is_main_character():
				#need to immediately update life/death phaseboards
				maybe_update_phaseboards(chrono, true);
				if value:
					if (!actor_has_broken_event_anywhere(actor)):
						if (!is_custom and chapter == 0):
							while animation_server.size() <= animation_substep:
								animation_server.push_back([]);
							for j in range(animation_substep+1):
								for i in range(animation_server[j].size()):
									var thing = animation_server[j][i];
									if thing[1][0] == Anim.lose:
										achievement_get("NonStandardGameOver");
						
						add_to_animation_server(actor, [Anim.lose]);
						if (has_void_gates):
							open_doors(Tiles.GateOfDemise);		
				else:
					if actor.actorname == Actor.Name.Heavy:
						heavytimeline.end_fade();
					else:
						lighttimeline.end_fade();
			
			#check goal lock when a crystal breaks or unbreaks
			if (actor.is_crystal):
				update_goal_lock();
			
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			if value == true:
				if (actor.actorname == Actor.Name.TimeCrystalGreen):
					pass #done in eat_crystal now
					#add_to_animation_server(actor, [Anim.sfx, "greentimecrystal"])
				elif (actor.actorname == Actor.Name.TimeCrystalMagenta):
					pass #done in eat_crystal now
					#add_to_animation_server(actor, [Anim.sfx, "magentatimecrystal"])
				else:
					add_to_animation_server(actor, [Anim.sfx, "broken"])
					add_to_animation_server(actor, [Anim.explode, true])
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
				add_to_animation_server(actor, [Anim.sfx, "unbroken"])
				add_to_animation_server(actor, [Anim.explode, false])
				if actor.is_character:
					if actor.actorname == Actor.Name.Heavy and heavy_goal_here(actor.pos, terrain):
						for goal in goals:
							if goal.actorname == Actor.Name.HeavyGoal and !goal.dinged:
								set_actor_var(goal, "dinged", true, chrono);
					if actor.actorname == Actor.Name.Light and light_goal_here(actor.pos, terrain):
						for goal in goals:
							if goal.actorname == Actor.Name.LightGoal and !goal.dinged:
								set_actor_var(goal, "dinged", true, chrono);
				elif !actor.is_crystal:
					if terrain.has(Tiles.CrateGoal):
						if !actor.dinged:
							set_actor_var(actor, "dinged", true, chrono);
		
		add_to_animation_server(actor, [Anim.set_next_texture, actor.get_next_texture(), animation_nonce, actor.facing_left])
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
			
	# stall certain animations
	if (prop == "airborne" and actor.is_character):
		if (value > 0 and old_value > 0):
			pass
		else:
			add_to_animation_server(actor, [Anim.stall, 0.07]);
	elif (prop == "broken"):
		add_to_animation_server(actor, [Anim.stall, 0.14]);
		
	#in custom puzzles, banish broken crystals to -9, -9 so they get out of the way
	if (is_custom and actor.is_crystal and !is_retro and actor.broken and prop == "broken" and !old_value and value):
		banished_time_crystals[actor] = chrono;

var banished_time_crystals = {};

func check_abyss_chimes(actor: Actor = null) -> bool:
	if (actor == null):
		var result_h = false;
		var result_l = false;
		if (heavy_actor.broken):
			result_h = check_abyss_chimes(heavy_actor);
			if (result_h):
				# note: this logic doesn't run for breaking an actor directly,
				# because an actor can be broken voidly, and 'the actor unbreaks'
				# is already sufficient to end the condition.
				# need to revisit this idea later if there ever becomes a void way
				# to forget an rewind event or delete a repair station.
				add_undo_event([Undo.heavy_surprise_abyss_chimed], Chrono.CHAR_UNDO);
		if (light_actor.broken):
			result_l = check_abyss_chimes(light_actor);
			if (result_l):
				add_undo_event([Undo.light_surprise_abyss_chimed], Chrono.CHAR_UNDO);
		return result_h || result_l;
	if (!actor_has_broken_event_anywhere(actor)):
		add_to_animation_server(actor, [Anim.lose]);
		if (has_void_gates):
			open_doors(Tiles.GateOfDemise);
		return true;
	return false;

func actor_has_broken_event_anywhere(actor: Actor) -> bool:
	if (has_repair_stations):
		# if any repair station exists, or any Undo.change_terrain will creare a repair station, there's still hope
		if (any_layer_has_this_tile(Tiles.RepairStation)):
			return true;
		if (any_layer_has_this_tile(Tiles.RepairStationGreen)):
			return true;
		if (any_layer_has_this_tile(Tiles.RepairStationGray)):
			return true;
		if (any_layer_has_this_tile(Tiles.RepairStationBumper)):
			return true;
		var buffers = [heavy_undo_buffer, light_undo_buffer, heavy_locked_turns, light_locked_turns];
		for buffer in buffers:
			for turn in buffer:
				for event in turn:
					if event[0] == Undo.change_terrain:
						var old_tile = event[4];
						if (old_tile == Tiles.RepairStation || old_tile == Tiles.RepairStationGreen || old_tile == Tiles.RepairStationGray):
							return true;
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
	return false;

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
		if (has_void_fog and event[0] in void_banish_dict):
			var actor = event[1];
			if terrain_in_tile(actor.pos, actor, chrono).has(Tiles.VoidFog):
				if (!currently_fast_replay()):
					call_deferred("play_sound", "greenfire");
				return;
		
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
		if (!preserving_meta_redo_inputs):
			meta_redo_inputs = "";
		user_replay += move;
	
func meta_undo_replay() -> bool:
	if (voidlike_puzzle):
		user_replay += "c";
	else:
		if !user_replay.ends_with("x"):
			if (heavy_selected):
				meta_redo_inputs += user_replay[user_replay.length() - 1];
			else:
				meta_redo_inputs += user_replay[user_replay.length() - 1].to_upper();
			user_replay = user_replay.left(user_replay.length() - 1);
			
		else:
			if (heavy_selected):
				meta_redo_inputs += user_replay[user_replay.length() - 2].to_upper();
			else:
				meta_redo_inputs += user_replay[user_replay.length() - 2];
			user_replay = user_replay.left(user_replay.length() - 2);
			append_replay("x");
	return true;

var fuzzed: bool = false;
func character_undo(is_silent: bool = false) -> bool:
	var eclipsed: bool = false;
	var chrono = Chrono.CHAR_UNDO;
	if (won or lost): return false;
	if (heavy_selected):
		# check if we can undo
		if (heavy_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var terrain = terrain_in_tile(heavy_actor.pos, heavy_actor, Chrono.CHAR_UNDO);
		if (terrain.has(Tiles.NoUndo) and !terrain.has(Tiles.OneUndo)):
			if !is_silent:
				play_sound("rewindstopped");
			add_to_animation_server(heavy_actor, [Anim.afterimage_at, preload("res://assets/undo_eye_final.png"), terrainmap.map_to_world(heavy_actor.pos), Color(1, 1, 1, 1)]);
			return false;
		if (has_spotlights and terrain.has(Tiles.Spotlight)):
			if !is_silent:
				play_sound("spotlight");
			add_undo_event([Undo.spotlight_fix], Chrono.CHAR_UNDO);
			chrono = Chrono.MOVE;
			var events = heavy_undo_buffer[heavy_turn-1];
			for event in events:
				if (event[0] == Undo.heavy_turn):
					events.erase(event);
			heavytimeline.current_move -= 1;
			maybe_change_terrain(heavy_actor, heavy_actor.pos, terrain.find(Tiles.Spotlight), false, true, Chrono.CHAR_UNDO, -1);
		
		# before undo effects
		finish_animations(Chrono.CHAR_UNDO);
		maybe_pulse_phase_blocks(chrono);
		if (terrain.has(Tiles.OneUndo)):
			maybe_change_terrain(heavy_actor, heavy_actor.pos, terrain.find(Tiles.OneUndo), false, true, Chrono.CHAR_UNDO, Tiles.NoUndo);
		
		if (has_eclipses and terrain.has(Tiles.Eclipse)):
			play_sound("eclipse");
			eclipsed = true;
			fuzzed = true;
		
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
				undo_one_event(event, chrono);
		else:
			var events = heavy_undo_buffer.pop_at(heavy_turn - 1);
			for event in events:
				undo_one_event(event, chrono);
				add_undo_event([Undo.heavy_undo_event_remove, heavy_turn, event], Chrono.CHAR_UNDO);
			
		if (fuzzed):
			time_passes(Chrono.TIMELESS);
		else:
			time_passes(chrono);
		
		append_replay("z");
		
		if (chrono == Chrono.MOVE):
			#have to add our own synthetic Undo.heavy_turn to the end
			add_undo_event([Undo.heavy_turn, 1, true], chrono);
			# delete the now empty buffer to shuffle everything around.
			heavy_undo_buffer.pop_at(heavy_turn-1);
			# now have to patch meta events so they refer to the correct turn
			# also have to erase the most recent heavy_turn meta-event
			var mevents = meta_undo_buffer[meta_undo_buffer.size() - 1];
			for event in mevents:
				if (event[0] == Undo.heavy_turn):
					mevents.erase(event);
					break; #need to do two loops since we're iterating something we deleted from
			for event in mevents:
				if (event[0] == Undo.heavy_undo_event_remove):
					event[1] -= 1;
				elif (event[0] == Undo.heavy_undo_event_add):
					event[1] -= 1;
			#need to also move all adds to the start ...
			for j in range(mevents.size() -1):
				var event = mevents[j];
				if (event[0] == Undo.heavy_undo_event_add):
					# can't use erase because all the events look identical
					mevents.pop_at(j);
					mevents.push_front(event);
				
			#and we need a synthetic timeline add_turn too
			heavytimeline.add_turn(heavy_undo_buffer[heavy_undo_buffer.size()-1]);
			
		adjust_meta_turn(1, chrono);
		
		if (!is_silent):
			if (!fuzzed or eclipsed):
				play_sound("undostrong");
			if (!currently_fast_replay()):
				if (fuzzed and !eclipsed):
					undo_effect_strength = 0.25;
					undo_effect_per_second = undo_effect_strength*(1/0.5);
					undo_effect_color = meta_color;
				else:
					undo_effect_strength = 0.12; #yes stronger on purpose. it doesn't show up as well.
					undo_effect_per_second = undo_effect_strength*(1/0.4);
					undo_effect_color = heavy_color;
		fuzzed = false;
		return true;
	else:
		
		# check if we can undo
		if (light_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var terrain = terrain_in_tile(light_actor.pos, light_actor, Chrono.CHAR_UNDO);
		if (terrain.has(Tiles.NoUndo) and !terrain.has(Tiles.OneUndo)):
			if !is_silent:
				play_sound("rewindstopped");
			add_to_animation_server(light_actor, [Anim.afterimage_at, terrainmap.tile_set.tile_get_texture(Tiles.NoUndo), terrainmap.map_to_world(light_actor.pos), Color(0, 0, 0, 1)]);
			return false;
		if (has_spotlights and terrain.has(Tiles.Spotlight)):
			if !is_silent:
				play_sound("spotlight");
			add_undo_event([Undo.spotlight_fix], Chrono.CHAR_UNDO);
			chrono = Chrono.MOVE;
			var events = light_undo_buffer[light_turn-1];
			for event in events:
				if (event[0] == Undo.light_turn):
					events.erase(event);
			lighttimeline.current_move -= 1;
			maybe_change_terrain(light_actor, light_actor.pos, terrain.find(Tiles.Spotlight), false, true, Chrono.CHAR_UNDO, -1);
			
		# before undo effects
		finish_animations(Chrono.CHAR_UNDO);
		maybe_pulse_phase_blocks(chrono);
		if (terrain.has(Tiles.OneUndo)):
			maybe_change_terrain(light_actor, light_actor.pos, terrain.find(Tiles.OneUndo), false, true, Chrono.CHAR_UNDO, Tiles.NoUndo);
		
		if (has_eclipses and terrain.has(Tiles.Eclipse)):
			play_sound("eclipse");
			fuzzed = true;
		
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
				undo_one_event(event, chrono);
		else:
			var events = light_undo_buffer.pop_at(light_turn - 1);
			for event in events:
				undo_one_event(event, chrono);
				add_undo_event([Undo.light_undo_event_remove, light_turn, event], Chrono.CHAR_UNDO);
		
		if (fuzzed):
			time_passes(Chrono.TIMELESS);
		else:
			time_passes(chrono);
			
		append_replay("z");
		
		if (chrono == Chrono.MOVE):
			#have to add our own synthetic Undo.light_turn to the end
			add_undo_event([Undo.light_turn, 1, true], chrono);
			# delete the now empty buffer to shuffle everything around.
			light_undo_buffer.pop_at(light_turn-1);
			# now have to patch meta events so they refer to the correct turn
			# also have to erase the most recent light_turn meta-event
			var mevents = meta_undo_buffer[meta_undo_buffer.size() - 1];
			for event in mevents:
				if (event[0] == Undo.light_turn):
					mevents.erase(event);
					break; #need to do two loops since we're iterating something we deleted from
			for event in mevents:
				if (event[0] == Undo.light_undo_event_remove):
					event[1] -= 1;
				elif (event[0] == Undo.light_undo_event_add):
					event[1] -= 1;
			#need to also move all adds to the start ...
			for j in range(mevents.size() -1):
				var event = mevents[j];
				if (event[0] == Undo.light_undo_event_add):
					# can't use erase because all the events look identical
					mevents.pop_at(j);
					mevents.push_front(event);
				
			#and we need a synthetic timeline add_turn too
			lighttimeline.add_turn(light_undo_buffer[light_undo_buffer.size()-1]);
		
		adjust_meta_turn(1, chrono);
		if (!is_silent):
			if (!fuzzed or eclipsed):
				play_sound("undostrong");
			if (!currently_fast_replay()):
				if (fuzzed and !eclipsed):
					undo_effect_strength = 0.25;
					undo_effect_per_second = undo_effect_strength*(1/0.5);
					undo_effect_color = meta_color;
				else:
					undo_effect_strength = 0.08;
					undo_effect_per_second = undo_effect_strength*(1/0.4);
					undo_effect_color = light_color;
		fuzzed = false;
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
	new.material = actor.material;
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
	
func adjust_meta_turn(amount: int, chrono: int) -> void:
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
	
	if (has_checkpoints and amount > 0):
		check_checkpoints(chrono);
	
	meta_turn += amount;
	#if (debug_prints):
	#	print("=== IT IS NOW META TURN " + str(meta_turn) + " ===");
	update_ghosts();
	check_won(chrono);
	
func check_won(chrono: int) -> void:
	won = false;
	var locked = false;
	
	if (lost):
		return
	Shade.on = false;
	
	#check crate goal satisfaction
	if (has_crate_goals):
		var crate_goals = get_used_cells_by_id_one_array(Tiles.CrateGoal);
		# would fix this O(n^2) with an actors_by_pos dictionary, but then I have to update it all the time.
		# maybe use DINGED?
		for crate_goal in crate_goals:
			# boarded crate goals don't have to be satisfied
			if (has_floorboards):
				if (!terrain_in_tile(crate_goal, null, chrono).has(Tiles.CrateGoal)):
					continue;
			
			var crate_goal_satisfied = false;
			for actor in actors:
				if actor.pos == crate_goal and !actor.is_main_character() and !actor.broken and !actor.is_crystal:
					crate_goal_satisfied = true;
					break;
			if (!crate_goal_satisfied):
				locked = true;
				won = false;
				for goal in goals:
					if !goal.locked2:
						goal.lock2();
				break;
		if (!locked):
			for goal in goals:
				if goal.locked2:
					goal.unlock2();
		
	#check time crystal goal lock:
	for goal in goals:
		if goal.locked:
			locked = true;
			won = false;
			break;
	
	# don't win the game during a undo unless this is a voidlike puzzle
	# (but we did want to get this far to update visual effects)
	if (chrono == Chrono.META_UNDO and !voidlike_puzzle):
		return;
	
	if (!locked and !light_actor.broken and !heavy_actor.broken
	and heavy_goal_here(heavy_actor.pos, terrain_in_tile(heavy_actor.pos, heavy_actor, chrono))
	and light_goal_here(light_actor.pos, terrain_in_tile(light_actor.pos, light_actor, chrono))) or nonstandard_won:
		won = true;
		if (won and test_mode):
			var level_info = terrainmap.get_node_or_null("LevelInfo");
			if (level_info != null):
				level_info.level_replay = annotate_replay(user_replay);
				if (custom_string != ""):
					#HACK: time to do surgery on a string lol
					custom_string = custom_string.replace("\"level_replay\":\"\"", "\"level_replay\":\"" + level_info.level_replay + "\"")
					custom_string = custom_string.replace(annotated_authors_replay, level_info.level_replay);
				floating_text("Test successful, recorded replay!");
		if (won == true and !doing_replay):
			if (level_name == "Joke"):
				play_won("winbadtime");
			elif (level_name == "A Way In?"):
				pass
			elif (level_name == "Chrono Lab Reactor"):
				pass
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
				if (!in_insight_level):
					if (!is_custom):
						puzzles_completed += 1;
						if (level_is_extra):
							advanced_puzzles_completed += 1;
					specific_puzzles_completed[level_number] = true;
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
		elif (level_name == "Chrono Lab Reactor" and !doing_replay and ui_stack.size() == 0):
			transition_to_ending_cutscene_2();
		elif (level_name == "A Way In?" and !doing_replay):
			target_track = -1;
			fadeout_timer_max = 3.0;
			fadeout_timer = 0.0;
			Shade.on = true;
			winlabel.change_text("You carefully enter the Chrono Lab Reactor...\n\n[" + human_readable_input("ui_accept", 1) + "]: Outro Cutscene\nWatch Replay: Menu -> Your Replay")
		elif !doing_replay:
			winlabel.change_text("You have won!\n\n[" + human_readable_input("ui_accept", 1) + "]: Continue\nWatch Replay: Menu -> Your Replay")
		elif doing_replay:
			winlabel.change_text("You have won!\n\n[" + human_readable_input("ui_accept", 1) + "]: Continue")
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
		
	if (has_void_stars and chrono == Chrono.META_UNDO and event[0] in void_banish_dict):
		var actor = event[1];
		if terrain_in_tile(actor.pos, actor, chrono).has(Tiles.VoidStars):
			if (!currently_fast_replay()):
				call_deferred("add_to_animation_server", actor, [Anim.undo_immunity, -1]);
			#add_to_animation_server(actor, [Anim.undo_immunity, event[6]]);
			#call_deferred("play_sound", "shroud");
			return;
		
	# undo events that should create undo trails
	
	match event[0]:
		Undo.move:
			#[Undo.move, actor, dir, was_push, was_fall]
			#func move_actor_relative(actor: Actor, dir: Vector2, chrono: int,
			#hypothetical: bool, is_gravity: bool, is_retro: bool = false,
			#pushers_list: Array = [], was_fall = false, was_push = false, phased_out_of: Array = null) -> int:
			var actor = event[1];
			var animation_nonce = event[6];
			if (chrono < Chrono.META_UNDO and actor.in_stars):
				add_to_animation_server(actor, [Anim.undo_immunity, event[6]]);
			else:
				move_actor_relative(actor, -event[2], chrono, false, false, true, [], event[3], event[4], event[5],
				animation_nonce);
		Undo.set_actor_var:
			var actor = event[1];
			var retro_old_value = event[4];
			var animation_nonce = event[5];
			var is_retro = true;
			if (chrono < Chrono.META_UNDO and actor.in_stars):
				add_to_animation_server(actor, [Anim.undo_immunity, animation_nonce]);
				if (event[2] == "broken"):
					check_abyss_chimes();
			else:
				#[Undo.set_actor_var, actor, prop, old_value, value, animation_nonce]
				
				set_actor_var(actor, event[2], event[3], chrono, animation_nonce, is_retro, retro_old_value);
		Undo.change_terrain:
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
	
	match event[0]:
		Undo.heavy_turn:
			adjust_turn(true, -event[1], chrono, event[2]);
		Undo.light_turn:
			adjust_turn(false, -event[1], chrono, event[2]);
		Undo.heavy_turn_direct:
			heavy_turn -= event[1];
		Undo.light_turn_direct:
			light_turn -= event[1];
		Undo.heavy_undo_event_add:
			while (heavy_undo_buffer.size() <= event[1]):
				heavy_undo_buffer.append([]);
			heavy_undo_buffer[event[1]].pop_front();
		Undo.light_undo_event_add:
			while (light_undo_buffer.size() <= event[1]):
				light_undo_buffer.append([]);
			light_undo_buffer[event[1]].pop_front();
		Undo.heavy_undo_event_add_locked:
			while (heavy_undo_buffer.size() <= event[1]):
				heavy_undo_buffer.append([]);
			heavy_locked_turns[event[1]].pop_front();
		Undo.light_undo_event_add_locked:
			while (light_undo_buffer.size() <= event[1]):
				light_undo_buffer.append([]);
			light_locked_turns[event[1]].pop_front();
		Undo.heavy_undo_event_remove:
			# 'Negativity' crash prevention
			if (event[1] < 0):
				lost_void = true;
				lose("What have you DONE", null, false, "exception");
				return;
			# meta undo an undo creates a char undo event but not a meta undo event, it's special!
			while (heavy_undo_buffer.size() <= event[1]):
				heavy_undo_buffer.append([]);
			heavy_undo_buffer[event[1]].push_front(event[2]);
		Undo.light_undo_event_remove:
			if (event[1] < 0):
				lost_void = true;
				lose("What have you DONE", null, false, "exception");
				return;
			while (light_undo_buffer.size() <= event[1]):
				light_undo_buffer.append([]);
			light_undo_buffer[event[1]].push_front(event[2]);
		Undo.animation_substep:
			# don't need to emit a new event as meta undoing and beyond is a teleport
			animation_substep += 1;
		Undo.heavy_green_time_crystal_raw:
			# don't need to emit a new event as this can't be char undone
			# (comment repeats for all other time crystal stuff)
			heavy_max_moves -= 1;
			heavytimeline.undo_add_max_turn();
			timeline_squish();
		Undo.light_green_time_crystal_raw:
			light_max_moves -= 1;
			lighttimeline.undo_add_max_turn();
			timeline_squish();
		Undo.heavy_max_moves:
			heavy_max_moves -= event[1];
			heavytimeline.undo_lock_turn();
		Undo.light_max_moves:
			light_max_moves -= event[1];
			lighttimeline.undo_lock_turn();
		Undo.heavy_filling_locked_turn_index:
			heavy_filling_locked_turn_index = event[1]; #the old value, event[2] is the new value
		Undo.light_filling_locked_turn_index:
			light_filling_locked_turn_index = event[1]; #the old value, event[2] is the new value
		Undo.heavy_turn_locked:
			# don't have to do turn adjustment as a separate undo event was emitted for it
			var locked_turn = heavy_locked_turns.pop_at(event[2]);
			# put it back if we locked an actual turn
			if event[1] == -1:
				pass
			else:
				heavy_undo_buffer.insert(event[1], locked_turn);
		Undo.light_turn_locked:
			# don't have to do turn adjustment as a separate undo event was emitted for it
			var locked_turn = light_locked_turns.pop_at(event[2]);
			# put it back if we locked an actual turn
			if event[1] == -1:
				pass
			else:
				light_undo_buffer.insert(event[1], locked_turn);
		Undo.heavy_filling_turn_actual:
			heavy_filling_turn_actual = event[1]; #the old value, event[2] is the new value
		Undo.light_filling_turn_actual:
			light_filling_turn_actual = event[1]; #the old value, event[2] is the new value
		Undo.heavy_turn_unlocked:
			# just lock it again ig
			var was_turn = event[1];
			if (was_turn == -1):
				heavy_locked_turns.append([]);
			else:
				heavy_locked_turns.append(heavy_undo_buffer.pop_at(was_turn));
			heavytimeline.undo_unlock_turn(event[1]);
			heavy_max_moves -= 1;
		Undo.light_turn_unlocked:
			var was_turn = event[1];
			if (was_turn == -1):
				light_locked_turns.append([]);
			else:
				light_locked_turns.append(light_undo_buffer.pop_at(was_turn));
			lighttimeline.undo_unlock_turn(event[1]);
			light_max_moves -= 1;
		Undo.tick:
			var actor = event[1];
			var amount = event[2];
			var animation_nonce = event[3];
			if (chrono < Chrono.META_UNDO and actor.in_stars):
				add_to_animation_server(actor, [Anim.undo_immunity, animation_nonce]);
			else:
				clock_ticks(actor, -amount, chrono, animation_nonce);
		Undo.time_bubble:
			var actor = event[1];
			var old_time_colour = event[2];
			actor.time_colour = old_time_colour;
			actor.update_time_bubble();
		Undo.sprite:
			var actor = event[1];
			var sprite = event[2];
			sprite.get_parent().remove_child(sprite);
			sprite.queue_free();
		Undo.spotlight_fix:
			if (heavy_selected):
				heavytimeline.current_move -= 1;
				heavytimeline.add_turn(heavy_undo_buffer[heavy_turn-1], true);
			else:
				lighttimeline.current_move -= 1;
				lighttimeline.add_turn(light_undo_buffer[light_turn-1], true);
		Undo.heavy_surprise_abyss_chimed:
			heavytimeline.end_fade();
		Undo.light_surprise_abyss_chimed:
			lighttimeline.end_fade();

func meta_undo_a_restart() -> bool:
	var meta_undo_a_restart_type = 2;
	if (save_file.has("meta_undo_a_restart")):
		meta_undo_a_restart_type = int(save_file["meta_undo_a_restart"]);
	if (meta_undo_a_restart_type == 4): #No
		return false;
	
	if (user_replay_before_restarts.size() > 0):
		user_replay = "";
		end_replay();
		toggle_replay();
		level_replay = user_replay_before_restarts.pop_back();
		cut_sound();
		play_sound("metarestart");
		match meta_undo_a_restart_type:
			0: # Yes
				meta_undo_a_restart_mode = true;
				replay_advance_turn(level_replay.length());
				end_replay();
				finish_animations(Chrono.TIMELESS);
				meta_undo_a_restart_mode = false;
			1: # Replay (Instant)
				meta_undo_a_restart_mode = true;
				replay_advance_turn(level_replay.length());
				finish_animations(Chrono.TIMELESS);
				meta_undo_a_restart_mode = false;
			2: # Replay (Fast)
				meta_undo_a_restart_mode = true;
				next_replay = -1;
			3: # Replay
				pass
		return true;
	return false;

func meta_undo(is_silent: bool = false) -> bool:
	preserving_meta_redo_inputs = true;
	if (lost and lost_void):
		play_sound("bump");
		preserving_meta_redo_inputs = false;
		return false;
	if (meta_turn <= 0):
		if (user_replay == ""):
			if !key_repeat_this_frame_dict["meta_undo"]:
				if (!doing_replay):
					if (meta_undo_a_restart()):
						#preserving_meta_redo_inputs = false; #done in ready_map()
						return true;
		if !is_silent:
			play_sound("bump");
		preserving_meta_redo_inputs = false;
		return false;
	
	end_lose();
	finish_animations(Chrono.MOVE);
	nonstandard_won = false;
	var events = meta_undo_buffer.pop_back();
	for event in events:
		undo_one_event(event, Chrono.META_UNDO);
	if (!is_silent):
		cut_sound();
		play_sound("metaundo");
	just_did_meta();
	adjust_meta_turn(-1, Chrono.META_UNDO);
	var result = meta_undo_replay();
	preserving_meta_redo_inputs = false;
	return result;

func just_did_meta() -> void:
	if (!currently_fast_replay()):
		undo_effect_strength = 0.08;
		undo_effect_per_second = undo_effect_strength*(1/0.2);
	for whatever in underactorsparticles.get_children():
		whatever.queue_free();
	for whatever in overactorsparticles.get_children():
		whatever.queue_free();
	finish_animations(Chrono.META_UNDO);
	undo_effect_color = meta_color;
	# void things experience time when you undo
	maybe_update_phaseboards(Chrono.META_UNDO);
	time_passes(Chrono.META_UNDO);

func meta_redo() -> bool:
	if (won or lost):
		return false;
	if (meta_redo_inputs == ""):
		if !key_repeat_this_frame_dict["meta_redo"]:
			play_sound("bump");
		return false;
	preserving_meta_redo_inputs = true;
	var letter = meta_redo_inputs[meta_redo_inputs.length() - 1];
	meta_redo_inputs = meta_redo_inputs.left(meta_redo_inputs.length() - 1);
	do_one_letter_case_sensitive(letter);
	#cut_sound();
	play_sound("metaredo");
	#just_did_meta();
	preserving_meta_redo_inputs = false;
	metaredobuttonlabel.visible = false;
	return true;
	
func gray_wait() -> void:
	var continuum = false;
	time_passes(Chrono.MOVE);
	if anything_happened_meta():
			if heavy_selected:
				if anything_happened_char():
					adjust_turn(true, 1, Chrono.MOVE, true, continuum);
			else:
				if anything_happened_char():
					adjust_turn(false, 1, Chrono.MOVE, true, continuum);
	adjust_meta_turn(1, Chrono.MOVE);
	
func purple_wait() -> void:
	time_passes(Chrono.CHAR_UNDO);
	adjust_meta_turn(1, Chrono.CHAR_UNDO);

func void_wait() -> void:
	time_passes(Chrono.META_UNDO);
	adjust_meta_turn(1, Chrono.META_UNDO);
	
func do_one_setup_letter(replay_char: String) -> void:
	match replay_char:
		"q":
			gray_wait();
		"e":
			purple_wait();
		"v":
			void_wait();
		_:
			do_one_letter(replay_char);
	
func do_one_letter(replay_char: String) -> void:
	match replay_char:
		"w":
			character_move(Vector2.UP);
		"a":
			character_move(Vector2.LEFT);
		"s":
			character_move(Vector2.DOWN);
		"d":
			character_move(Vector2.RIGHT);
		"z":
			character_undo();
		"x":
			character_switch();
		"c":
			meta_undo();
#		"y":
#			# buggy and difficult to make not-buggy since it requires redefining "v" properly.
#			# will leave as is, undocumented.
#			var old_doing_replay = doing_replay;
#			meta_redo();
#			doing_replay = old_doing_replay;
#			update_info_labels();
		
func do_one_letter_case_sensitive(replay_char: String) -> void:
#	if (replay_char == "v"):
#		var replay = user_replay;
#		load_level(0);
#		start_specific_replay(replay);
#		#hack to make the sounds not play
#		var old_muted = muted;
#		muted = true;
#		replay_advance_turn(replay.length() - 1);
#		end_replay();
#		muted = old_muted;
#		return;

	if (replay_char.to_upper() == replay_char and heavy_selected):
		character_switch();
	if (replay_char.to_lower() == replay_char and !heavy_selected):
		character_switch();
	do_one_letter(replay_char.to_lower());
	
func timeline_activation_change() -> void:
	heavytimeline.activate(heavy_selected);
	lighttimeline.activate(!heavy_selected);
	if (heavy_selected):
		heavyinfolabel.add_color_override("font_color", "#ff7459");
		lightinfolabel.add_color_override("font_color", light_color);
	else:
		heavyinfolabel.add_color_override("font_color", heavy_color);
		lightinfolabel.add_color_override("font_color", "#7fc9ff");
	
func character_switch() -> void:
	# no swapping characters in Meet Heavy or Meet Light, even if you know the button
	if (!is_custom and (level_number == 0 or level_number == 1)):
		return
	heavy_selected = !heavy_selected;
	timeline_activation_change();
	update_ghosts();
	if (heavy_selected):
		play_sound("switch2")
	else:
		play_sound("switch")
	if (!currently_fast_replay()):
		#targeter.scale = Vector2(2, 2);
		var tween = targeter.get_node("Tween");
		tween.interpolate_property(targeter, "scale",
		terrainmap.scale*Vector2(1.2, 1.2), terrainmap.scale*Vector2(1, 1), 0.2,
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT);
		tween.start();
	append_replay("x")
	maybe_update_phaseboards(Chrono.MOVE);

func restart(_is_silent: bool = false) -> void:
	load_level(0);
	cut_sound();
	play_sound("restart");
	undo_effect_strength = 0.3;
	undo_effect_per_second = undo_effect_strength*(1/0.5);
	finish_animations(Chrono.TIMELESS);
	undo_effect_color = meta_color;
	
func escape() -> void:
	if (test_mode and won):
		level_editor();
		test_mode = false;
		return;
	
	if (ui_stack.size() > 0):
		# can happen if we click the button directly
		var topmost_ui = ui_stack.pop_front();
		topmost_ui.queue_free();
		return;
	var a = preload("res://Menu.tscn").instance();
	add_to_ui_stack(a);
	
func title_screen() -> void:
	var a = preload("res://TitleScreen.tscn").instance();
	add_to_ui_stack(a);
	
func ending_cutscene_1() -> void:
	var a = preload("res://EndingCutscene1.tscn").instance();
	add_to_ui_stack(a);
	
func transition_to_ending_cutscene_2() -> void:
	# find position of bump
	var position_a = Vector2.ZERO;
	var position_b = Vector2.ZERO;
	for actor in actors:
		if (actor.actorname == Actor.Name.ChronoHelixRed):
			position_a = actor.position;
		elif (actor.actorname == Actor.Name.ChronoHelixBlue):
			position_b = actor.position;
	var position_c = terrainmap.position + (position_a + position_b)/2 + Vector2(cell_size/2, cell_size/2);
	var t = preload("res://TransitionToTheEnd.tscn").instance();
	t.position = position_c;
	add_to_ui_stack(t);
	
func ending_cutscene_2() -> void:
	var a = preload("res://EndingCutscene2.tscn").instance();
	add_to_ui_stack(a);
	
func level_editor() -> void:
	var a = preload("res://level_editor/LevelEditor.tscn").instance();
	add_to_ui_stack(a);
	
func level_select() -> void:
	if (test_mode):
		level_editor();
		return;
	
	if (ui_stack.size() > 0):
		# can happen if we click the button directly
		var topmost_ui = ui_stack.pop_front();
		topmost_ui.queue_free();
		return;
	var a = preload("res://LevelSelect.tscn").instance();
	add_to_ui_stack(a);
	
func how_many_standard_puzzles_are_solved_in_chapter(chapter: int) -> Array:
	if chapter >= custom_past_here:
		return [0, 0];
	var x = 0;
	var y = -1;
	var start = chapter_standard_starting_levels[chapter];
	var end = chapter_advanced_starting_levels[chapter];
	for i in range(start, end):
		y += 1;
		if (specific_puzzles_completed[i]):
			x += 1;
	if (y > 8):
		y = 8;
	return [x, y];
	
func trying_to_load_locked_level(level_number: int, is_custom: bool) -> bool:
	if (is_custom):
		return false;
	if save_file.has("unlock_everything") and save_file["unlock_everything"]:
		return false;
	if (level_names[level_number] == "Chrono Lab Reactor" and !save_file["levels"].has("Chrono Lab Reactor")):
		return true;
	
	# copied from setup_chapter_etc(), modified to use local instead of global variables
	var chapter = 0;
	var level_is_extra = false;
	var level_in_chapter;
	for i in range(chapter_names.size()):
		if level_number < chapter_standard_starting_levels[i + 1]:
			chapter = i;
			if level_number >= chapter_advanced_starting_levels[i]:
				level_is_extra = true;
				level_in_chapter = level_number - chapter_advanced_starting_levels[i];
			else:
				level_in_chapter = level_number - chapter_standard_starting_levels[i];
			break;
		
	var unlock_requirement = 0;
	var you_have = puzzles_completed;
	if (!level_is_extra):
		if (chapter == 2):
			you_have = advanced_puzzles_completed;
		unlock_requirement = chapter_standard_unlock_requirements[chapter];
	else:
		var a = how_many_standard_puzzles_are_solved_in_chapter(chapter);
		you_have = a[0];
		unlock_requirement = a[1];
	if you_have < unlock_requirement:
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
	var target_target_track = chapter_tracks[chapter]
	var target_target_sky = chapter_skies[chapter];
	if (chapter >= custom_past_here):
		var level_info = terrainmap.get_node_or_null("LevelInfo");
		if (level_info != null):
			target_target_sky = level_info.target_sky;
			target_target_track = level_info.target_track;
	if (target_sky != target_target_sky):
		sky_timer = 0;
		sky_timer_max = 3.0;
		old_sky = current_sky;
		target_sky = target_target_sky;
	if (target_track != target_target_track):
		target_track = target_target_track;
		if (jukebox_track == -1):
			if (current_track == -1):
				play_next_song();
			else:
				fadeout_timer = max(fadeout_timer, 0); #so if we're in the middle of a fadeout it doesn't reset
				fadeout_timer_max = 3.0;
	
func play_next_song() -> void:
	if (!ready_done):
		return;
	
	if (jukebox_track > -1):
		current_track = jukebox_track;
	else:
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
		var master_volume = save_file["master_volume"];
		if (value > -30 and master_volume > -30 and !muted): #music is not muted
			if (ui_stack.size() == 0 or (ui_stack[0].name != "TitleScreen" and ui_stack[0].name != "EndingCutscene1" and ui_stack[0].name != "EndingCutscene2")):
				now_playing = preload("res://NowPlaying.tscn").instance();
				GuiHolder.call_deferred("add_child", now_playing);
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
	load_level(impulse, true);
	
func load_level(impulse: int, ignore_locked: bool = false) -> void:
	if (is_community_level):
		is_custom = false;
	if (impulse != 0 and test_mode):
		level_editor();
		test_mode = false;
		return;
	
	if (impulse != 0):
		if (nag_timer != null):
			nag_timer.queue_free();
			nag_timer = null;
		is_custom = false; # at least until custom campaigns :eyes:
	level_number = posmod(int(level_number), level_list.size());
	
	if (impulse != 0):
		user_replay_before_restarts.clear();
	elif user_replay.length() > 0:
		user_replay_before_restarts.push_back(user_replay);
	
	if (impulse != 0):
		level_number += impulse;
		level_number = posmod(int(level_number), level_list.size());
	
	# we might try to F1/F2 onto a level we don't have access to. if so, back up then show level select.
	if impulse != 0 and !ignore_locked and trying_to_load_locked_level(level_number, is_custom):
		impulse *= -1;
		if (impulse == 0):
			impulse = -1;
		for _i in range(999):
			level_number += impulse;
			level_number = posmod(int(level_number), level_list.size());
			setup_chapter_etc();
			if !trying_to_load_locked_level(level_number, is_custom):
				break;
		# buggy if the game just loaded, for some reason, but I didn't want it anyway
		if (ready_done):
			level_select();
			
	if (impulse != 0):
		in_insight_level = false;
		save_file["level_number"] = level_number;
		level_replay = "";
		save_game();
	
	var level = null;
	if (is_custom and !is_community_level):
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
	
	setup_chapter_etc();
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

func try_move_mimic(actor: Actor, dir: Vector2) -> int:
	animation_substep(Chrono.MOVE);
	# TODO: refactor with character_move
	var result = Success.No;
	if actor.broken and !terrain_in_tile(actor.pos, actor, Chrono.MOVE).has(Tiles.ZombieTile):
		return Success.No;
	if (!valid_voluntary_airborne_move(actor, dir)):
		result = Success.Surprise;
	else:
		result = move_actor_relative(actor, dir, Chrono.MOVE,
			false, false, false, [], false, false, null, -1, true);
	if (result == Success.Yes):
		if (!heavy_selected):
			play_sound("lightstep")
		else:
			play_sound("heavystep")
		if (dir == Vector2.UP):
			if heavy_selected and !is_suspended(actor, Chrono.MOVE):
				set_actor_var(actor, "airborne", 2, Chrono.MOVE);
			elif !heavy_selected and !is_suspended(actor, Chrono.MOVE):
				set_actor_var(actor, "airborne", 2, Chrono.MOVE);
		elif (dir == Vector2.DOWN):
			if heavy_selected and !is_suspended(actor, Chrono.MOVE):
				set_actor_var(actor, "airborne", 0, Chrono.MOVE);
	return result;

func character_move(dir: Vector2) -> bool:
	if (won or lost): return false;
	var chr = "";
	var continuum = false;
	var seemingly_nothing_happened = false;
	match dir:
		Vector2.UP:
			chr = "w";
		Vector2.DOWN:
			chr = "s";
		Vector2.LEFT:
			chr = "a";
		Vector2.RIGHT:
			chr = "d";
	var result = false;
	if heavy_selected:
		var pos = heavy_actor.pos;
		if ((heavy_actor.broken and !terrain_in_tile(pos, heavy_actor, Chrono.MOVE).has(Tiles.ZombieTile)) or (heavy_turn >= heavy_max_moves and heavy_max_moves >= 0)):
			play_sound("bump");
			return false;
		finish_animations(Chrono.MOVE);
		maybe_pulse_phase_blocks(Chrono.MOVE);
		if (has_continuums and heavy_turn > 0 and terrain_in_tile(pos, heavy_actor, Chrono.MOVE).has(Tiles.Continuum)):
			heavy_turn -= 1;
			heavytimeline.current_move -= 1;
			continuum = true;
		if (!valid_voluntary_airborne_move(heavy_actor, dir)):
			result = Success.Surprise;
		else:
			result = move_actor_relative(heavy_actor, dir, Chrono.MOVE,
			false, false, false, [], false, false, null, -1, true);
		if (continuum):
			if (result != Success.No):
				var events = heavy_undo_buffer[heavy_turn]; # already adjusted by -1
				for event in events:
					if (event[0] == Undo.heavy_turn):
						events.erase(event);
				play_sound("continuum");
				maybe_change_terrain(heavy_actor, pos, terrain_in_tile(pos, heavy_actor, Chrono.MOVE).find(Tiles.Continuum), false, true, Chrono.CHAR_UNDO, -1);
			else:
				heavy_turn += 1;
				heavytimeline.current_move += 1;
		if (result != Success.No):
			if (has_eclipses and terrain_in_tile(pos, heavy_actor, Chrono.MOVE).has(Tiles.Eclipse)):
				fuzzed = true;
				play_sound("eclipse");
	else:
		var pos = light_actor.pos;
		if ((light_actor.broken and !terrain_in_tile(pos, heavy_actor, Chrono.MOVE).has(Tiles.ZombieTile)) or (light_turn >= light_max_moves and light_max_moves >= 0)):
			play_sound("bump");
			return false;
		finish_animations(Chrono.MOVE);
		maybe_pulse_phase_blocks(Chrono.MOVE);
		if (has_continuums and light_turn > 0 and terrain_in_tile(pos, light_actor, Chrono.MOVE).has(Tiles.Continuum)):
			light_turn -= 1;
			lighttimeline.current_move -= 1;
			continuum = true;
		if (!valid_voluntary_airborne_move(light_actor, dir)):
			result = Success.Surprise;
		else:
			result = move_actor_relative(light_actor, dir, Chrono.MOVE,
			false, false, false, [], false, false, null, -1, true);
		if (continuum):
			if (result != Success.No):
				var events = light_undo_buffer[light_turn]; # already adjusted by -1
				for event in events:
					if (event[0] == Undo.light_turn):
						events.erase(event);
				play_sound("continuum");
				maybe_change_terrain(light_actor, pos, terrain_in_tile(pos, light_actor, Chrono.MOVE).find(Tiles.Continuum), false, true, Chrono.CHAR_UNDO, -1);
			else:
				light_turn += 1;
				lighttimeline.current_move += 1;
		if (result != Success.No):
			if (has_eclipses and terrain_in_tile(pos, light_actor, Chrono.MOVE).has(Tiles.Eclipse)):
				fuzzed = true;
				play_sound("eclipse");
	if (result == Success.Yes):
		if (!heavy_selected):
			play_sound("lightstep")
		else:
			play_sound("heavystep")
		if (dir == Vector2.UP):
			if heavy_selected and !is_suspended(heavy_actor, Chrono.MOVE):
				set_actor_var(heavy_actor, "airborne", 2, Chrono.MOVE);
			elif !heavy_selected and !is_suspended(light_actor, Chrono.MOVE):
				set_actor_var(light_actor, "airborne", 2, Chrono.MOVE);
		elif (dir == Vector2.DOWN):
			if heavy_selected and !is_suspended(heavy_actor, Chrono.MOVE):
				set_actor_var(heavy_actor, "airborne", 0, Chrono.MOVE);
			#AD10: Light floats gracefully downwards
			#elif !heavy_selected and !is_suspended(light_actor, Chrono.MOVE):
			#	set_actor_var(light_actor, "airborne", 0, Chrono.MOVE);
			
		#mimics mimic
		if heavy_selected:
			for mimic in actors:
				if (mimic.heavy_mimic != null):
					try_move_mimic(mimic, dir);
		else:
			for mimic in actors:
				if (mimic.light_mimic != null):
					try_move_mimic(mimic, dir);
	if (result != Success.No or nonstandard_won):
		if (!nonstandard_won):
			if (fuzzed):
				time_passes(Chrono.TIMELESS);
			else:
				time_passes(Chrono.MOVE);
		if anything_happened_meta():
			if heavy_selected:
				if anything_happened_char():
					adjust_turn(true, 1, Chrono.MOVE, true, continuum);
					if (continuum):
						#now eliminate oldest turn change since it's not real
						var events = meta_undo_buffer[meta_undo_buffer.size() - 1];
						for event in events:
							if (event[0] == Undo.heavy_turn):
								events.erase(event);
								break;
			else:
				if anything_happened_char():
					adjust_turn(false, 1, Chrono.MOVE, true, continuum);
					if (continuum):
						#now eliminate oldest turn change since it's not real
						var events = meta_undo_buffer[meta_undo_buffer.size() - 1];
						for event in events:
							if (event[0] == Undo.light_turn):
								events.erase(event);
								break;
		else:
			seemingly_nothing_happened = true;
			result = Success.No;
	if (result != Success.No or nonstandard_won or voidlike_puzzle):
		append_replay(chr);
	if (result != Success.Yes):
		if (voidlike_puzzle and seemingly_nothing_happened):
			pass
		else:
			play_sound("bump")
	if (result != Success.No or nonstandard_won):
		adjust_meta_turn(1, Chrono.MOVE);
	elif (voidlike_puzzle):
		adjust_meta_turn(0, Chrono.MOVE);
	fuzzed = false;
	return result != Success.No;

func anything_happened_char(destructive: bool = true) -> bool:
	# time crystals fuck this logic up and obviously mean something happened, so just say 'yes' if they happened
	# (and hopefully this doesn't come bite me in the ass later)
	if (heavy_filling_locked_turn_index > -1 or light_filling_locked_turn_index > -1):
		return true;
	if (heavy_selected):
		var turn = heavy_turn;
		if (heavy_filling_turn_actual > -1):
			turn = heavy_filling_turn_actual;
		while (heavy_undo_buffer.size() <= turn):
			heavy_undo_buffer.append([]);
		for event in heavy_undo_buffer[turn]:
			if event[0] != Undo.animation_substep:
				return true;
		#clear out now unnecessary animation_substeps if nothing else happened
		if (destructive):
			heavy_undo_buffer.pop_at(turn);
			# if we remembered a locked move but nothing happened on our 'real' move,
			# then we need to find and adjust the related heavy_turn_unlocked event
			# by -1 so it's correct
			if (heavy_filling_turn_actual > -1):
				var buffer = meta_undo_buffer[meta_undo_buffer.size()-1];
				for i in range(buffer.size() - 1, -1, -1):
					var event = buffer[i];
					if event[0] == Undo.heavy_turn_unlocked:
						event[1] = max(event[1] - 1, -1);
						break;
	else:
		var turn = light_turn;
		if (light_filling_turn_actual > -1):
			turn = light_filling_turn_actual;
		while (light_undo_buffer.size() <= turn):
			light_undo_buffer.append([]);
		for event in light_undo_buffer[turn]:
			if event[0] != Undo.animation_substep:
				return true;
		if (destructive):
			light_undo_buffer.pop_at(turn);
			if (light_filling_turn_actual > -1):
				var buffer = meta_undo_buffer[meta_undo_buffer.size()-1];
				for i in range(buffer.size() - 1, -1, -1):
					var event = buffer[i];
					if event[0] == Undo.light_turn_unlocked:
						event[1] = max(event[1] - 1, -1);
						break;
	return false;
	
func anything_happened_meta() -> bool:
	if (lost == true or nonstandard_won == true):
		while (meta_undo_buffer.size() <= meta_turn):
			meta_undo_buffer.append([]);
		return true;
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

func banish_time_crystals() -> void:
	# in custom puzzles, banish broken crystals to -9, -9 so they get out of the way
	# do this now so we know it's not in the middle of any operation
	# also do it even if it's an undo or fuzz rewind
	# also directly set the properties so nothing else like push might override
	if (is_custom):
		for actor in banished_time_crystals.keys():
			var dir = Vector2(-9, -9) - actor.pos;
			actor.pos = Vector2(-9, -9);
			add_undo_event([Undo.move, actor, dir, false, false, null, -1],
			chrono_for_maybe_green_actor(actor, max(banished_time_crystals[actor], Chrono.CHAR_UNDO)));
		banished_time_crystals.clear();

func time_passes(chrono: int) -> void:
	animation_substep(chrono);
	
	banish_time_crystals();
	
	if (chrono >= Chrono.TIMELESS):
		# fix up airborne on our way out
		for actor in actors:
			if actor.airborne >= 2:
				set_actor_var(actor, "airborne", 1, chrono);
		# and boulders
		if (has_boulders):
			for actor in actors:
				if actor.actorname == Actor.Name.Boulder:
					actor.boulder_moved_horizontally_this_turn = false;
		return;
	
	var time_actors = []
	
	if chrono == Chrono.META_UNDO:
		for actor in actors:
			if actor.is_crystal and actor.broken:
				continue;
			if actor.time_colour == TimeColour.Void:
				time_actors.push_back(actor);
			
	elif chrono < Chrono.META_UNDO:
		for actor in actors:
			# eject broken time crystals, we should pretend they no longer exist
			if actor.is_crystal and actor.broken:
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
			match actor.time_colour:
				TimeColour.Gray:
					if (chrono == Chrono.MOVE):
						time_actors.push_back(actor);
				TimeColour.Purple:
					if (chrono == Chrono.MOVE):
						time_actors.push_back(actor);
					else:
						if (!heavy_selected):
							time_actors.push_back(actor);
				TimeColour.Blurple:
					if (chrono == Chrono.MOVE):
						time_actors.push_back(actor);
					else:
						if (heavy_selected):
							time_actors.push_back(actor);
				TimeColour.Red:
					if chrono == Chrono.MOVE and heavy_selected:
						time_actors.push_back(actor);
				TimeColour.Blue:
					if chrono == Chrono.MOVE and !heavy_selected:
						time_actors.push_back(actor);
				TimeColour.Green:
					time_actors.push_back(actor);
				TimeColour.Void:
					time_actors.push_back(actor);
				TimeColour.Magenta:
					time_actors.push_back(actor);
				TimeColour.Cyan:
					if !heavy_selected:
						time_actors.push_back(actor);
				TimeColour.Orange:
					if heavy_selected:
						time_actors.push_back(actor);
				TimeColour.Yellow:
					if (chrono == Chrono.CHAR_UNDO):
						time_actors.push_back(actor);
			# White: No
	
	# Flash time bubbles (Can add other effects here if I think of any).
	for actor in time_actors:
		add_to_animation_server(actor, [Anim.time_passes]);
	
	#Phase lightning strikes before gravity.
	if (has_phase_lightning and chrono < Chrono.META_UNDO):
		var red = heavy_selected;
		var blue = !heavy_selected;
		var gray = chrono == Chrono.MOVE;
		var purple = chrono == Chrono.CHAR_UNDO;
		add_to_animation_server(null, [Anim.lightning_strikes, red, blue, gray, purple]);
		for actor in actors:
			if (actor.broken):
				continue;
			if (actor.durability > Durability.FIRE):
				continue;
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			#terrain.has(Tiles.Fire)
			if (red and terrain.has(Tiles.PhaseLightningRed)):
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, chrono);
			elif (blue and terrain.has(Tiles.PhaseLightningBlue)):
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, chrono);
			elif (gray and terrain.has(Tiles.PhaseLightningGray)):
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, chrono);
			elif (purple and terrain.has(Tiles.PhaseLightningPurple)):
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, chrono);
		
	
	if (has_nudges):
		# Nudges activate
		var directions = [Vector2.RIGHT, Vector2.UP, Vector2.DOWN, Vector2.LEFT];
		for actor in time_actors:
			if (actor.in_night):
				continue;
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			for id in terrain:
				if id >= Tiles.NudgeEast and id <= Tiles.NudgeEast + 3:
					add_to_animation_server(actor, [Anim.sfx, "step"]);
					var dir = directions[id - Tiles.NudgeEast];
					var attempt = move_actor_relative(actor, dir, chrono, false, false);
					if (attempt == Success.Yes):
						# nudge up now sets airborne like slopes do
						maybe_rise(actor, chrono, dir);
						break;
		
		# Green nudges activate
		if chrono < Chrono.META_UNDO:
			for actor in actors:
				var terrain = terrain_in_tile(actor.pos, actor, chrono);
				for id in terrain:
					if id >= Tiles.NudgeEastGreen and id <= Tiles.NudgeEastGreen + 3:
						add_to_animation_server(actor, [Anim.sfx, "step"]);
						var dir = directions[id - Tiles.NudgeEastGreen];
						var attempt = move_actor_relative(actor, dir, chrono, false, false);
						if (attempt == Success.Yes):
							# nudge up now sets airborne like slopes do
							maybe_rise(actor, chrono, dir);
							break;
	
	# Boulders ride their momentum.
	if (has_boulders):
		for actor in time_actors:
			if (actor.in_night):
				continue;
			if actor.actorname == Actor.Name.Boulder and actor.momentum != Vector2.ZERO:
				if (actor.broken):
					set_actor_var(actor, "momentum", Vector2.ZERO, chrono);
				elif (!actor.boulder_moved_horizontally_this_turn):
					var old_pos = actor.pos;
					var rollin = move_actor_relative(actor, actor.momentum, chrono, false, false);
					# check for bumper/passages - if we moved then maintain the new surprise momentum
					if (rollin != Success.Yes and old_pos == actor.pos):
						set_actor_var(actor, "momentum", Vector2.ZERO, chrono);
	
	# Decrement airborne by one (min zero).
	# AD02: Maybe this should be a +1/-1 instead of a set. Haven't decided yet. Doesn't seem to matter until strange matter.
	var has_fallen = {};
	for actor in time_actors:
		has_fallen[actor] = 0;
		if !actor.in_night and actor.airborne > 0 and actor.fall_speed() != 0:
			var new_value = actor.airborne - 1;
			if (new_value == 0):
				var could_fall = move_actor_relative(actor, Vector2.DOWN, chrono, true, true);
				if (could_fall != Success.Yes):
					remove_one_from_animation_server(actor, Anim.bump);
					add_to_animation_server(actor, [Anim.sfx, "fall"]);
			set_actor_var(actor, "airborne", new_value, chrono);
			
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
			var skip = false;
			if (actor.fall_speed() >= 0 and has_fallen[actor] >= actor.fall_speed()):
				skip = true;
			elif (actor.in_night):
				skip = true;
			if (skip and falling_bug_2):
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
			
			if !skip and actor.airborne == -1 and !is_suspended(actor, chrono):
				var could_fall = move_actor_relative(actor, Vector2.DOWN, chrono, true, true);
				# we'll say that falling due to gravity onto spikes/a pressure plate makes you airborne so we try to do it, but only once
				if (could_fall != Success.No and (could_fall == Success.Yes or has_fallen[actor] <= 0)):
					if actor.floats():
						set_actor_var(actor, "airborne", 1, chrono);
					else:
						set_actor_var(actor, "airborne", 0, chrono);
					something_happened = true;
			
			if !skip and actor.airborne == 0:
				var old_pos = actor.pos;
				var did_fall = Success.No;
				if (is_suspended(actor, chrono)):
					did_fall = Success.No;
				else:
					did_fall = move_actor_relative(actor, Vector2.DOWN, chrono, false, true);
				
				if (did_fall != Success.No):
					something_happened = true;
					# so Heavy can break a glass block and not fall further, surprises break your fall immediately
					if (did_fall == Success.Surprise and old_pos == actor.pos):
						has_fallen[actor] += 999;
					else:
						has_fallen[actor] += 1;
				if (did_fall != Success.Yes and old_pos == actor.pos):
					actor.just_moved = false;
					# fan check
					if (actor.airborne == 0):
						set_actor_var(actor, "airborne", -1, chrono);
					# to make blue jelly consistent
					if (!falling_bug):
						something_happened = true;
						has_fallen[actor] += 1;
			
			if clear_just_moveds:
				clear_just_moveds = false;
				for a in just_moveds:
					a.just_moved = false;
				just_moveds.clear();
	
	#possible to leak this out the for loop
	for a in just_moveds:
		a.just_moved = false;
		
	if (tries == 0):
		lose("Infinite loop.", null, true, "infloop");
		banish_time_crystals();
		return;
	
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
			if is_suspended(actor, chrono):
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
			var could_fall = move_actor_relative(actor, Vector2.DOWN, chrono, true, true,
			false, [], false, false, null, -1, false,
			false) # can_push
			# Remove the vanity bump if we hypothetically hit a surprise.
			# (It actually looks pretty good as long as no one else is simultaneously falling,
			# but if someone IS, it looks awful, so that's reason enough to remove it)
			if (could_fall == Success.Surprise):
				remove_one_from_animation_server(actor, Anim.bump);
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
							if (diff.x == 0 and diff.y == 0):
								lose("What have you DONE", actor, false, "exception");
							else:
								add_to_animation_server(actor, [Anim.sfx, "fall"]);
								move_actor_relative(actor, diff, chrono, false, false);
								move_actor_relative(actor2, -diff, chrono, false, false);
			elif actor.actorname == Actor.Name.ChronoHelixBlue:
				for actor2 in actors:
					if actor2.actorname == Actor.Name.ChronoHelixRed:
						var diff = actor.pos - actor2.pos;
						if (abs(diff.x) <= 1 and abs(diff.y) <= 1):
							if (diff.x == 0 and diff.y == 0):
								lose("What have you DONE", actor, false, "exception");
							else:
								add_to_animation_server(actor, [Anim.sfx, "fall"]);
								move_actor_relative(actor, diff, chrono, false, false);
								move_actor_relative(actor2, -diff, chrono, false, false);
	
	# Things in fire break.
	# TODO: once colours exist this gets more complicated
	# might be sufficient to just check which of Heavy/Light are in time_actors, since that's really what matters
	if chrono <= Chrono.CHAR_UNDO or (has_void_fires and chrono <= Chrono.META_UNDO):
		var time_colour = TimeColour.Magenta;
		if (chrono == Chrono.META_UNDO):
			time_colour = TimeColour.Void;
		elif (heavy_selected and chrono == Chrono.CHAR_UNDO):
			time_colour = TimeColour.Blue;
		elif (!heavy_selected and chrono == Chrono.CHAR_UNDO):
			time_colour = TimeColour.Red;
		add_to_animation_server(null, [Anim.fire_roars, time_colour])
	for actor in time_actors:
		# Now that it's possible for Night to be conditional (boards), actors not experiencing time due to Night are now fire immune.
		if (actor.in_night):
			continue;
		var terrain = terrain_in_tile(actor.pos, actor, chrono);
		if !actor.broken and terrain.has(Tiles.Fire) and actor.durability <= Durability.FIRE:
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		if !actor.broken and terrain.has(Tiles.HeavyFire) and actor.durability <= Durability.FIRE and actor.actorname != Actor.Name.Light:
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		if !actor.broken and terrain.has(Tiles.LightFire) and actor.durability <= Durability.SPIKES:
			actor.post_mortem = Durability.FIRE;
			set_actor_var(actor, "broken", true, chrono);
		
	# Green fire happens after regular fire, so you can have that matter if you'd like it to :D	
	if chrono <= Chrono.CHAR_UNDO:
		for actor in actors:
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			if !actor.broken and terrain.has(Tiles.GreenFire) and actor.durability <= Durability.FIRE:
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, Chrono.CHAR_UNDO);
				
	# Then finally... Void fire
	if has_void_fires and chrono <= Chrono.META_UNDO:
		for actor in actors:
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			if !actor.broken and terrain.has(Tiles.VoidFire) and actor.durability <= Durability.FIRE:
				actor.post_mortem = Durability.FIRE;
				set_actor_var(actor, "broken", true, Chrono.META_UNDO);
				
	# slope cleanup step:
	# at the end of time_passes, ALL actors still in slopes attempt to be ejected
	# (first sideways, then vertically,
	# then if all of that fails we break for infinite damage).
	# this continues recursively until nothing changes. if we loop 100 times, lose (infinite loop).
	if (has_slopes and chrono < Chrono.META_UNDO):
		something_happened = true;
		var c = 0;
		while (something_happened and !lost):
			animation_substep(chrono);
			something_happened = false;
			c += 1;
			if (c >= 99):
				lose("Infinite loop.", null, true, "infloop");
				banish_time_crystals();
				return;
			for actor in actors:
				var found_a_slope = false;
				var slope_success = Success.No;
				var terrain = terrain_in_tile(actor.pos, actor, chrono);
				for id in terrain:
					if id >= Tiles.SlopeNW and id <= Tiles.SlopeNW + 3:
						found_a_slope = true;
						var next_dirs = slope_helper(id, Vector2.UP);
						for j in range(2):
							var slope_next_dir = next_dirs[j];
							slope_success = move_actor_relative(actor, slope_next_dir, chrono, false, false);
							if (slope_success != Success.No):
								something_happened = true;
								break;
					if (slope_success == Success.Yes):
						break;
				if (slope_success == Success.No and found_a_slope and !actor.broken):
					set_actor_var(actor, "broken", true, chrono);
					something_happened = true;
		
	# another airborne 2->1 since slope, bumper and fan can change airborneness
	for actor in actors:
		if actor.airborne >= 2:
			set_actor_var(actor, "airborne", 1, chrono);
	
	# Lucky last - clocks tick.
	for actor in time_actors:
		if actor.in_night:
			continue;
		if actor.ticks != 1000 and !actor.broken:
			clock_ticks(actor, -1, chrono);
		
	#Luckier laster - repair stations repair.
	if (has_repair_stations):
		for actor in time_actors:
			# same 'night is now conditional' point as for fires
			if (actor.in_night):
				continue;
			if (actor.broken):
				var terrain = terrain_in_tile(actor.pos, actor, chrono);
				if (terrain.has(Tiles.RepairStation)):
					set_actor_var(actor, "broken", false, chrono);
					maybe_change_terrain(actor, actor.pos, terrain.find(Tiles.RepairStation), false, false, chrono, -1);
					check_abyss_chimes();
		if (chrono == Chrono.MOVE):
			for actor in actors:
				if (actor.broken):
					var terrain = terrain_in_tile(actor.pos, actor, chrono);
					if (terrain.has(Tiles.RepairStationGray)):
						set_actor_var(actor, "broken", false, chrono);
						maybe_change_terrain(actor, actor.pos, terrain.find(Tiles.RepairStationGray), false, false, chrono, -1);
						check_abyss_chimes();
		if chrono < Chrono.META_UNDO:
			for actor in actors:
				if (actor.broken):
					var terrain = terrain_in_tile(actor.pos, actor, chrono);
					if (terrain.has(Tiles.RepairStationGreen)):
						set_actor_var(actor, "broken", false, max(Chrono.CHAR_UNDO, chrono));
						maybe_change_terrain(actor, actor.pos, terrain.find(Tiles.RepairStationGreen), false, true, chrono, -1);
						check_abyss_chimes();
						
	#Luckara lastara - Void Singularity void banish.
	if (has_singularities):
		for actor in time_actors:
			if (actor.in_night):
				continue;
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			if (terrain.has(Tiles.VoidSingularity)):
				if (void_banish(actor)):
					add_to_animation_server(actor, [Anim.sfx, "singularity"]);
					add_to_animation_server(actor, [Anim.generic_magenta_time_crystal, Color(0.1, 0.1, 0.1)])
	
	#Luckiest lastest - a final crystal banish.
	banish_time_crystals();
	# And boulder cleanup.
	if (has_boulders):
		for actor in actors:
			if actor.actorname == Actor.Name.Boulder:
				actor.boulder_moved_horizontally_this_turn = false;
	
func bottom_up(a, b) -> bool:
	# TODO: make this tiebreak by x, then by layer or id, so I can use it as a stable sort in general?
	# 29th Feb 2024: not actually sure I want 'tiebreak by x' because then the esoterica of 'does light or heavy fall first?' is now
	# horizontally asymmetric. tiebreak by id might be smart but idk if it ever desyncs to begin with.
	# tiebreak by layer is basically just 'you can reverse the esoterica order invisible to the player'
	# and I don't like that either.
	# so I think it stays as-is.
	return a.pos.y > b.pos.y;
	
func currently_fast_replay() -> bool:
	if (!doing_replay):
		return false;
	if (replayturnslider_in_drag):
		return true;
	if replay_interval() > 0.05:
		return false;
	if (replay_paused):
		return false;
	if (replay_turn >= (level_replay.length())):
		return false;
	return true;
	
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
				add_to_ui_stack(modal);
				return;
	
	toggle_replay();
	level_replay = authors_replay;
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
# puzzles that cause Godot errors in their replays, due to time crystal bugs I haven't fixed yet
var unit_test_blacklist = {"Cut And Paste": true, "(Cry)Stall": true}
	
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
						while (unit_test_blacklist.has(level_name)):
							load_level(1);
			else:
				if (has_insight_level and !in_insight_level):
					gain_insight();
				else:
					load_level(1);
					while (unit_test_blacklist.has(level_name)):
						load_level(1);
			replay_turn = 0;
			level_replay = authors_replay;
			next_replay = replay_timer + replay_interval();
			return;
		else:
			if (unit_test_mode):
				floating_text("Tested up to level: " + str(level_number) + " (This is 0 indexed lol)" );
				end_replay();
				if (level_number == level_filenames.size() - 1):
					load_level_direct(0); # Patashu anti-spoiler protection :3;
			return;
	next_replay = replay_timer+replay_interval();
	var replay_char = level_replay[replay_turn];
	var old_meta_turn = meta_turn;
	replay_turn += 1;
	do_one_letter(replay_char);
	if replay_char == "x":
		return
	elif old_meta_turn == meta_turn and !voidlike_puzzle:
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
			var old_replay_interval = replay_interval;
			replay_interval = 0.001;
			load_level(0);
			start_specific_replay(replay);
			for _i in range(target_turn):
				do_one_replay_turn();
			finish_animations(Chrono.TIMELESS);
			calm_down_timelines();
			replay_interval = old_replay_interval;
			muted = old_muted;
			# weaker and slower than meta-undo
			undo_effect_strength = 0.04;
			undo_effect_per_second = undo_effect_strength*(1/0.4);
			play_sound("voidundo");
			for child in levelscene.get_children():
				if child is FloatingText:
					child.queue_free();
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
			
func setup_replay(replay: String) -> void:
	# should be silent
	var old_muted = muted;
	muted = true;
	# strip annotation if any
	var annotated = replay.find_last("$");
	if (annotated >= 0):
		replay = replay.get_slice("$", 2); # it's got more performance!
	for chr in replay:
		do_one_setup_letter(chr);
		finish_animations(Chrono.MOVE); #doesn't help?
		calm_down_timelines(); #doesn't help?
	muted = old_muted;
	user_replay = "";
	meta_turn = 0;
	meta_undo_buffer = [];
	update_info_labels();
	calm_down_timelines(); #doesn't help?
			
func calm_down_timelines() -> void:
	heavytimeline.calm_down();
	lighttimeline.calm_down();

func point_at_broken_event(is_heavy: bool, slot: Sprite) -> void:
	if (chapter == 1 and level_in_chapter <= 4 and !level_is_extra and !is_custom):
		if (is_heavy):
			rightarrow.visible = true;
			rightarrow.position = slot.global_position - Vector2(24, 0);
		else:
			leftarrow.visible = true;
			leftarrow.position = slot.global_position + Vector2(24, 0);
	
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
	if (level_author != "" and (level_author != "Patashu" or is_custom)):
		levellabel.text += " (By " + level_author + ")"
	if (doing_replay):
		levellabel.text += " (REPLAY)"
		if using_controller:
			var info = "";
			for i in ["replay_fwd1", "replay_back1", "replay_pause", "speedup_replay", "slowdown_replay"]:
				var next_info = human_readable_input(i, 1);
				if (next_info != "[UNBOUND]"):
					if (info != ""):
						info += "|";
					info += next_info;
			levellabel.text += " (" + info + ")";
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
	
func do_all_stylebox_overrides(button: Button, stylebox: StyleBox) -> void:
	button.add_stylebox_override("hover", stylebox);
	button.add_stylebox_override("pressed", stylebox);
	button.add_stylebox_override("focus", stylebox);
	button.add_stylebox_override("disabled", stylebox);
	button.add_stylebox_override("normal", stylebox);
	
func update_info_labels() -> void:
	# also disable/enable and shade verb buttons here
	if (virtualbuttons.visible):
		var meta_undo_button = virtualbuttons.get_node("Verbs/MetaUndoButton");
		var meta_undo_a_restart_type = 2;
		if (save_file.has("meta_undo_a_restart")):
			meta_undo_a_restart_type = save_file["meta_undo_a_restart"];
		if (meta_turn == 0 and (user_replay != "" or user_replay_before_restarts.size() == 0 or meta_undo_a_restart_type >= 4)):
			meta_undo_button.modulate = Color(0.5, 0.5, 0.5, 1);
		else:
			meta_undo_button.modulate = Color(1, 1, 1, 1);
		var dirs = [virtualbuttons.get_node("Dirs/LeftButton"),
		virtualbuttons.get_node("Dirs/DownButton"),
		virtualbuttons.get_node("Dirs/RightButton"),
		virtualbuttons.get_node("Dirs/UpButton")];
		var undo_button = virtualbuttons.get_node("Verbs/UndoButton");
		var swap_button = virtualbuttons.get_node("Verbs/SwapButton");
		if (heavy_selected):
			for button in dirs:
				button.get_node("Label").add_color_override("font_color", Color("#ff7459"));
				do_all_stylebox_overrides(button, preload("res://heavy_styleboxtexture.tres"));
				if (heavy_actor.broken or heavy_turn >= heavy_max_moves):
					button.modulate = Color(0.5, 0.5, 0.5, 1);
				else:
					button.modulate = Color(1, 1, 1, 1);
			undo_button.get_node("Label").add_color_override("font_color", Color("#ff7459"));
			do_all_stylebox_overrides(undo_button, preload("res://heavy_styleboxtexture.tres"));
			if (heavy_turn == 0):
				undo_button.modulate = Color(0.5, 0.5, 0.5, 1);
			else:
				undo_button.modulate = Color(1, 1, 1, 1);
			swap_button.get_node("Label").add_color_override("font_color", Color("#7fc9ff"));
			do_all_stylebox_overrides(swap_button, preload("res://light_styleboxtexture.tres"));
		else:
			for button in dirs:
				button.get_node("Label").add_color_override("font_color", Color("#7fc9ff"));
				do_all_stylebox_overrides(button, preload("res://light_styleboxtexture.tres"));
				if (light_actor.broken or light_turn >= light_max_moves):
					button.modulate = Color(0.5, 0.5, 0.5, 1);
				else:
					button.modulate = Color(1, 1, 1, 1);
			undo_button.get_node("Label").add_color_override("font_color", Color("#7fc9ff"));
			do_all_stylebox_overrides(undo_button, preload("res://light_styleboxtexture.tres"));
			if (light_turn == 0):
				undo_button.modulate = Color(0.5, 0.5, 0.5, 1);
			else:
				undo_button.modulate = Color(1, 1, 1, 1);
			swap_button.get_node("Label").add_color_override("font_color", Color("#ff7459"));
			do_all_stylebox_overrides(swap_button, preload("res://heavy_styleboxtexture.tres"));
	
	metaredobutton.visible = meta_redo_inputs != "";
	
	#also do fuzz indicator here
	if terrain_in_tile(heavy_actor.pos, heavy_actor, Chrono.CHAR_UNDO).has(Tiles.Fuzz):
		heavytimeline.fuzz_on();
	else:
		heavytimeline.fuzz_off();
		
	if terrain_in_tile(light_actor.pos, light_actor, Chrono.CHAR_UNDO).has(Tiles.Fuzz):
		lighttimeline.fuzz_on();
	else:
		lighttimeline.fuzz_off();
	
	heavyinfolabel.text = "Heavy" + "\n" + str(heavy_turn);
	if heavy_max_moves >= 0:
		heavyinfolabel.text += "/" + str(heavy_max_moves);
	
	lightinfolabel.text = "Light" + "\n" + str(light_turn);
	if light_max_moves >= 0:
		lightinfolabel.text += "/" + str(light_max_moves);
	
	metainfolabel.text = "Turn: " + str(meta_turn)
	
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
		ready_tutorial();

func animation_substep(chrono: int) -> void:
	animation_substep += 1;
	add_undo_event([Undo.animation_substep], chrono);

func add_to_animation_server(actor: ActorBase, animation: Array, with_priority: bool = false) -> void:
	while animation_server.size() <= animation_substep:
		animation_server.push_back([]);
	if (with_priority):
		animation_server[animation_substep].push_front([actor, animation]);
	else:
		animation_server[animation_substep].push_back([actor, animation]);

func remove_one_from_animation_server(actor: ActorBase, event: int):
	for i in range(animation_server[animation_substep].size()):
		var thing = animation_server[animation_substep][i];
		if thing[0] == actor and thing[1][0] == event:
			animation_server[animation_substep].remove(i);
			return;
			
func copy_one_from_animation_server(actor: ActorBase, event: int, second_actor: ActorBase):
	for i in range(animation_server[animation_substep].size()):
		var thing = animation_server[animation_substep][i];
		if thing[0] == actor and thing[1][0] == event:
			add_to_animation_server(second_actor, thing[1], true);
			return;

func handle_global_animation(animation: Array) -> void:
	var redfire = false;
	var bluefire = false;
	var greenfire = false;
	var voidfire = false;
	if animation[0] == Anim.fire_roars:
		#void fire even firster :D
		if (has_void_fires):
			var void_fires = get_used_cells_by_id_one_array(Tiles.VoidFire);
			for fire in void_fires:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://OneTimeSprite.gd"));
				sprite.texture = preload("res://assets/void_fire_spritesheet.png");
				sprite.position = terrainmap.map_to_world(fire);
				sprite.vframes = 1;
				sprite.hframes = 8;
				sprite.frame = 0;
				sprite.centered = false;
				sprite.frame_max = sprite.frame + 8;
				underactorsparticles.add_child(sprite);
				voidfire = true;
		if (animation[1] != TimeColour.Void):
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
	if (greenfire or voidfire):
		play_sound("greenfire");
		
	if (animation[0] == Anim.lightning_strikes):
		var red = animation[1];
		var blue = animation[2];
		var gray = animation[3];
		var purple = animation[4];
		if (blue):
			var walls = get_used_cells_by_id_one_array(Tiles.PhaseLightningBlue);
			for wall in walls:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://PingPongSprite.gd"));
				sprite.texture = preload("res://assets/phase_lightning_blue_strikes.png");
				sprite.position = terrainmap.map_to_world(wall);
				sprite.hframes = 5;
				sprite.centered = false;
				sprite.frame_timer_max = 0.08;
				overactorsparticles.add_child(sprite);
		if (red):
			var walls = get_used_cells_by_id_one_array(Tiles.PhaseLightningRed);
			for wall in walls:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://PingPongSprite.gd"));
				sprite.texture = preload("res://assets/phase_lightning_red_strikes.png");
				sprite.position = terrainmap.map_to_world(wall);
				sprite.hframes = 5;
				sprite.centered = false;
				sprite.frame_timer_max = 0.08;
				overactorsparticles.add_child(sprite);
		if (gray):
			var walls = get_used_cells_by_id_one_array(Tiles.PhaseLightningGray);
			for wall in walls:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://PingPongSprite.gd"));
				sprite.texture = preload("res://assets/phase_lightning_gray_strikes.png");
				sprite.position = terrainmap.map_to_world(wall);
				sprite.hframes = 5;
				sprite.centered = false;
				sprite.frame_timer_max = 0.08;
				overactorsparticles.add_child(sprite);
		if (purple):
			var walls = get_used_cells_by_id_one_array(Tiles.PhaseLightningPurple);
			for wall in walls:
				var sprite = Sprite.new();
				sprite.set_script(preload("res://PingPongSprite.gd"));
				sprite.texture = preload("res://assets/phase_lightning_purple_strikes.png");
				sprite.position = terrainmap.map_to_world(wall);
				sprite.hframes = 5;
				sprite.centered = false;
				sprite.frame_timer_max = 0.08;
				overactorsparticles.add_child(sprite);

func update_animation_server(skip_globals: bool = false) -> void:
	# don't interrupt ongoing animations
	for actor in actors:
		if actor.animations.size() > 0:
			return;
	
	# look for new animations to playwon_fade_started
	while animation_server.size() > 0 and animation_server[0].size() == 0:
		animation_server.pop_front();
	if animation_server.size() == 0:
		# won_fade starts here
		if ((won or lost) and !won_fade_started):
			won_fade_started = true;
			if (lost):
				fade_in_lost();
			add_to_animation_server(heavy_actor, [Anim.fade, 1.0, 0.0, 3.0]);
			add_to_animation_server(light_actor, [Anim.fade, 1.0, 0.0, 3.0]);
			add_to_animation_server(heavy_actor, [Anim.intro_hop]);
			add_to_animation_server(light_actor, [Anim.intro_hop]);
		return;
	
	# we found new animations - give them to everyone at once
	var animations = animation_server.pop_front();
	for animation in animations:
		if animation[0] == null:
			if !skip_globals:
				handle_global_animation(animation[1]);
		else:
			animation[0].animations.push_back(animation[1]);

func maybe_update_phaseboards(chrono: int, life_death_only: bool = false) -> void:
	if (!has_phaseboards):
		return
		
	if (!life_death_only):
		if (heavy_selected):
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardRed, preload("res://assets/phase_board_red.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardBlue, preload("res://assets/phase_board_blue_unpowered.png"));
		else:
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardRed, preload("res://assets/phase_board_red_unpowered.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardBlue, preload("res://assets/phase_board_blue.png"));
			
		if (chrono == Chrono.CHAR_UNDO):
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardGray, preload("res://assets/phase_board_gray_unpowered.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardPurple, preload("res://assets/phase_board_purple.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardVoid, preload("res://assets/phase_board_void_unpowered.png"));
		elif (chrono == Chrono.META_UNDO):
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardGray, preload("res://assets/phase_board_gray_unpowered.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardPurple, preload("res://assets/phase_board_purple_unpowered.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardVoid, preload("res://assets/phase_board_void.png"));
		else: #MOVE or TIMELESS
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardGray, preload("res://assets/phase_board_gray.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardPurple, preload("res://assets/phase_board_purple_unpowered.png"));
			terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardVoid, preload("res://assets/phase_board_void_unpowered.png"));
			
	if (heavy_actor.broken or light_actor.broken):
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardLife, preload("res://assets/phase_board_life_unpowered.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardDeath, preload("res://assets/phase_board_death.png"));
	else:
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardLife, preload("res://assets/phase_board_life.png"));
		terrainmap.tile_set.tile_set_texture(Tiles.PhaseBoardDeath, preload("res://assets/phase_board_death_unpowered.png"));

	if (has_night_or_stars):
		for actor in actors:
			# hack fix: if an actor breaks, then we don't know the original chrono
			# (without modifying every caller)
			# so while this won't work properly for cases of a night/stars + life/death phaseboard + other phaseboard,
			# let's just leave that as a future me problem
			var terrain = terrain_in_tile(actor.pos, actor, chrono);
			if (!life_death_only or terrain.has(Tiles.PhaseBoardLife) or terrain.has(Tiles.PhaseBoardDeath)):
				update_night_and_stars(actor, terrain);

func maybe_pulse_phase_blocks(chrono: int) -> void:
	maybe_update_phaseboards(chrono);
	if (!has_phase_walls):
		return
	var pulse_red = heavy_selected;
	var pulse_blue = !heavy_selected;
	var pulse_gray = chrono == Chrono.MOVE;
	var pulse_purple = chrono == Chrono.CHAR_UNDO;
	if (pulse_blue):
		var walls = get_used_cells_by_id_one_array(Tiles.PhaseWallBlue);
		for wall in walls:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://PingPongSprite.gd"));
			sprite.texture = preload("res://assets/phase_wall_blue_strikes.png");
			sprite.position = terrainmap.map_to_world(wall);
			sprite.hframes = 6;
			sprite.centered = false;
			sprite.frame_timer_max = 0.04;
			overactorsparticles.add_child(sprite);
	if (pulse_red):
		var walls = get_used_cells_by_id_one_array(Tiles.PhaseWallRed);
		for wall in walls:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://PingPongSprite.gd"));
			sprite.texture = preload("res://assets/phase_wall_red_strikes.png");
			sprite.position = terrainmap.map_to_world(wall);
			sprite.hframes = 6;
			sprite.centered = false;
			sprite.frame_timer_max = 0.04;
			overactorsparticles.add_child(sprite);
	if (pulse_gray):
		var walls = get_used_cells_by_id_one_array(Tiles.PhaseWallGray);
		for wall in walls:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://PingPongSprite.gd"));
			sprite.texture = preload("res://assets/phase_wall_gray_strikes.png");
			sprite.position = terrainmap.map_to_world(wall);
			sprite.hframes = 6;
			sprite.centered = false;
			sprite.frame_timer_max = 0.04;
			overactorsparticles.add_child(sprite);
	if (pulse_purple):
		var walls = get_used_cells_by_id_one_array(Tiles.PhaseWallPurple);
		for wall in walls:
			var sprite = Sprite.new();
			sprite.set_script(preload("res://PingPongSprite.gd"));
			sprite.texture = preload("res://assets/phase_wall_purple_strikes.png");
			sprite.position = terrainmap.map_to_world(wall);
			sprite.hframes = 6;
			sprite.centered = false;
			sprite.frame_timer_max = 0.04;
			overactorsparticles.add_child(sprite);

func floating_text(text: String) -> void:
	if (!ready_done):
		return
	var label = preload("res://FloatingText.tscn").instance();
	var existing_labels = 0;
	for i in levelscene.get_children():
		if i is FloatingText:
			existing_labels += 1;
	levelscene.add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = pixel_width;
	label.rect_position.y = pixel_height/2-16 + 8*existing_labels;
	label.text = text;

func is_valid_replay(replay: String) -> bool:
	var replay_parts = replay.split("$");
	replay = replay_parts[replay_parts.size()-1];
	replay = replay.strip_edges();
	replay = replay.to_lower();
	if replay.length() <= 0:
		return false;
	for letter in replay:
		if !(letter in "wasdzxcy"):
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

func user_pressed_toggle_replay() -> void:
	meta_undo_a_restart_mode = false;
	unit_test_mode = false;
	if (doing_replay):
		end_replay();
		update_info_labels();
		return;
	if (!level_replay.begins_with(user_replay)):
		level_replay = user_replay;
	doing_replay = true;
	replaybuttons.visible = true;
	replay_paused = true;
	replay_turn = user_replay.length();
	update_info_labels();

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
	if (currently_fast_replay()):
		return;
	if undo_effect_color == Color.transparent:
		return;
	# ok, we're mid undo.
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.actor = actor;
	afterimage.set_material(get_afterimage_material_for(undo_effect_color));
	underactorsparticles.add_child(afterimage);
	
func afterimage_terrain(texture: Texture, position: Vector2, color: Color) -> void:
	if (currently_fast_replay()):
		return;
	var afterimage = preload("res://Afterimage.tscn").instance();
	afterimage.texture = texture;
	afterimage.position = position;
	afterimage.set_material(get_afterimage_material_for(color));
	overactorsparticles.add_child(afterimage);
		
func last_level_of_section() -> bool:
	var chapter_standard_starting_level = chapter_standard_starting_levels[chapter+1];
	var chapter_advanced_starting_level = chapter_advanced_starting_levels[chapter];
	if (level_number+1 == chapter_standard_starting_level or level_number+1 == chapter_advanced_starting_level):
		return true;
	return false;
		
func unwin() -> void:
	floating_text("Ctrl+F11: Unwin");
	if (save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]):
		puzzles_completed -= 1;
	if (save_file["levels"].has(level_name)):
		save_file["levels"][level_name]["won"] = false;
	save_game();
	update_level_label();
	
func adjusted_mouse_position() -> Vector2:
	var result = get_parent().get_global_mouse_position();
	if (SuperScaling != null):
		result.x *= 2*pixel_width/OS.get_window_size().x;
		result.y *= 2*pixel_height/OS.get_window_size().y;
	return result;

func any_ui_element_hovered(mouse_position: Vector2) -> bool:
	return any_ui_element_hovered_core(menubutton, mouse_position) or any_ui_element_hovered_core(replaybuttons, mouse_position) or any_ui_element_hovered_core(virtualbuttons, mouse_position);

func any_ui_element_hovered_core(node, mouse_position: Vector2) -> bool:
	if !node.visible:
		return false;
	if node is BaseButton or node is Range:
		var rect = Rect2(node.rect_global_position, node.rect_size);
		if rect.has_point(mouse_position):
			return true;
	for child in node.get_children():
		var result = any_ui_element_hovered_core(child, mouse_position);
		if (result):
			return true;
	return false;
	
func _input(event: InputEvent) -> void:
	if (ui_stack.size() > 0):
		return;
	
	if event is InputEventMouseButton:
		replayturnslider.release_focus();
		replayspeedslider.release_focus();
		
		var mouse_position = adjusted_mouse_position();
		var heavy_rect = heavy_actor.get_rect();
		var light_rect = light_actor.get_rect();
		heavy_rect.position += heavy_actor.global_position;
		light_rect.position += light_actor.global_position;
		if !heavy_selected and heavy_rect.has_point(mouse_position):
			if (!any_ui_element_hovered(mouse_position)):
				end_replay();
				character_switch();
				update_info_labels();
		elif heavy_selected and light_rect.has_point(mouse_position):
			if (!any_ui_element_hovered(mouse_position)):
				end_replay();
				character_switch();
				update_info_labels();
	elif event is InputEventKey:
		if (!is_web and event.alt and event.scancode == KEY_ENTER):
			if (!save_file.has("fullscreen") or !save_file["fullscreen"]):
				save_file["fullscreen"] = true;
			else:
				save_file["fullscreen"] = false;
			setup_resolution();
	
func gain_insight() -> void:
	if (ui_stack.size() > 0):
		return;
	
	if (has_insight_level and !unit_test_mode):
		if (!save_file.has("gain_insight") or save_file["gain_insight"] != true):
			var modal = preload("res://GainInsightModalPrompt.tscn").instance();
			add_to_ui_stack(modal);
			return;
	
	if (has_insight_level):
		if (in_insight_level):
			in_insight_level = false;
		else:
			in_insight_level = true;
		end_replay();
		level_replay = "";
		load_level(0);
		cut_sound();
		play_sound("usegreenality");
		undo_effect_strength = 0.5;
		undo_effect_per_second = undo_effect_strength*(1/0.5);
		finish_animations(Chrono.TIMELESS);
		undo_effect_color = Color("A9F05F");
	
func serialize_current_level() -> String:
	if (is_custom and !is_community_level):
		return custom_string;
	
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
	level_metadata["setup_replay"] = level_info.setup_replay;
	level_metadata["heavy_max_moves"] = int(level_info.heavy_max_moves);
	level_metadata["light_max_moves"] = int(level_info.light_max_moves);
		
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
	return result.split("\n").join("`\n");
	
func copy_level() -> void:
	var result = serialize_current_level();
	floating_text("Ctrl+Shift+C: Level copied to clipboard!");
	OS.set_clipboard(result);
	
func looks_like_level(custom: String) -> bool:
	custom = custom.strip_edges();
	if custom.find("EntwinedTimePuzzleStart") >= 0 and custom.find("EntwinedTimePuzzleEnd") >= 0:
		return true;
	return false;
	
func deserialize_custom_level(custom: String) -> Node:
	custom = custom.strip_edges();
	if custom.find("\n") >= 0:
		custom = custom.replace("`", "");
	else:
		custom = custom.replace("`", "\n");
	
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
	"clock_turns", "map_x_max", "map_y_max", "target_sky", "layers", "target_track", "setup_replay"];
	
	#datafix: old custom levels with missing fields
	if (!result.has("target_track")):
		result["target_track"] = target_track;
	if (!result.has("setup_replay")):
		result["setup_replay"] = "";
	
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
	
	in_insight_level = false;
	is_custom = true;
	is_community_level = false;
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
		if (target_track < -1 or target_track >= music_tracks.size()):
			target_track = -1;
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
	
func paste_level(clipboard: String) -> void:
	clipboard = clipboard.strip_edges();
	end_replay();
	load_custom_level(clipboard);
	
func adjust_next_replay_time(old_replay_interval: float) -> void:
	next_replay += replay_interval - old_replay_interval;
	
var virtual_button_name_to_action = {};
	
func shade_virtual_button(b: Button) -> void:
	var label = b.get_node_or_null("Label");
	if (label == null):
		return;
	if (b.name == "PauseButton"):
		if replay_paused:
			label.text = "|>";
		else:
			label.text = "||";
	if (Input.is_action_just_pressed(virtual_button_name_to_action[b.name])):
		label.modulate = Color(1.5, 1.5, 1.5, 1);
		return;
	elif (Input.is_action_pressed(virtual_button_name_to_action[b.name])):
		label.modulate = Color(0.8, 0.8, 0.8, 1);
		return;
	var draw_mode = b.get_draw_mode();
	if draw_mode == 0:
		label.modulate = Color(1, 1, 1, 1);
	elif draw_mode == 1 or draw_mode == 3:
		label.modulate = Color(0.5, 0.5, 0.5, 1);
	elif draw_mode == 2 or draw_mode == 4:
		if (Input.is_mouse_button_pressed(1)):
			label.modulate = Color(0.8, 0.8, 0.8, 1);
		else:
			label.modulate = Color(1.5, 1.5, 1.5, 1);
	
func shade_virtual_buttons() -> void:
	if (virtualbuttons.visible):
		for a in virtualbuttons.get_children():
			for b in a.get_children():
				if (b is Button):
					shade_virtual_button(b);
	if (replaybuttons.visible):
		for a in replaybuttons.get_children():
			for b in a.get_children():
				if (b is Button):
					shade_virtual_button(b);
	
var last_dir_release_times = [0, 0, 0, 0];
var key_repeat_timer_dict = {};
var key_repeat_timer_max_dict = {};
var virtual_button_held_dict = {"meta_undo": false, "meta_redo": false, "previous_level": false, "next_level": false, 
"replay_back1": false, "replay_fwd1": false, "speedup_replay": false, "slowdown_replay": false};
var key_repeat_this_frame_dict = {};
var covered_cooldown_timer = 0.0;
var no_mute_pwease = false;
	
func pressed_or_key_repeated(action: String) -> bool:
	return Input.is_action_just_pressed(action) or (key_repeat_this_frame_dict.has(action) and key_repeat_this_frame_dict[action]);
	
func _process(delta: float) -> void:
	#levellabel.text = "%3.2f,%3.2f,%3.2f,%3.2f" % [Input.get_action_raw_strength("ui_left"), Input.get_action_raw_strength("ui_right"), Input.get_action_raw_strength("ui_up"), Input.get_action_raw_strength("ui_down")]
	shade_virtual_buttons();
	
	# key repeat
	for action in virtual_button_held_dict.keys():
		if (Input.is_action_just_pressed(action)):
			key_repeat_timer_dict[action] = 0.0;
			key_repeat_timer_max_dict[action] = 0.5;
			key_repeat_this_frame_dict[action] = false;
		if Input.is_action_pressed(action) or virtual_button_held_dict[action]:
			key_repeat_this_frame_dict[action] = false;
			key_repeat_timer_dict[action] += delta;
			if (key_repeat_timer_dict[action] > key_repeat_timer_max_dict[action]):
				key_repeat_this_frame_dict[action] = true;
				key_repeat_timer_dict[action] -= key_repeat_timer_max_dict[action];
				if (key_repeat_timer_max_dict[action] == 0.5):
					key_repeat_timer_max_dict[action] = 0.20;
				else:
					key_repeat_timer_max_dict[action] = max(0.05, key_repeat_timer_max_dict[action] * 0.91);
		else:
			key_repeat_timer_dict[action] = 0.0;
			key_repeat_timer_max_dict[action] = 0.0;
			key_repeat_this_frame_dict[action] = false;
	
	if (Input.is_action_just_pressed("any_controller") or Input.is_action_just_pressed("any_controller_2")) and !using_controller:
		using_controller = true;
		menubutton.text = "Menu (" + human_readable_input("escape", 1).left(5) + ")";
		menubutton.rect_position.x = 222;
		update_info_labels();
	
	if Input.is_action_just_pressed("any_keyboard") and using_controller:
		using_controller = false;
		menubutton.text = "Menu (" + human_readable_input("escape", 1).left(3) + ")";
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
					#floating_text("get debounced " + str(int(current_time - last_dir_release_times[i])) + "ms");
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
	var master_volume = save_file["master_volume"];
	if (value <= -30 or master_volume <= -30):
		if (!music_speaker.stream_paused):
			music_speaker.stream_paused = true;
	elif !muted:
		if (music_speaker.stream_paused):
			music_speaker.stream_paused = false;
	music_speaker.volume_db = value + master_volume + music_discount;
	if (current_track >= 0):
		music_speaker.volume_db += music_db[current_track];
	if fadeout_timer < fadeout_timer_max:
		fadeout_timer += delta;
		if (fadeout_timer >= fadeout_timer_max):
			play_next_song();
			# recalculate this now because the current song just changed...
			music_speaker.volume_db = value + master_volume +music_discount;
			if (current_track >= 0):
				music_speaker.volume_db += music_db[current_track];
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
		
	# allow mute to happen even when in menus
	if (Input.is_action_just_pressed("mute") and !no_mute_pwease):
		# hack: no muting in LevelInfoEdit where the player might type M
		if (ui_stack.size() == 0 or ui_stack[ui_stack.size() -1].name != "LevelInfoEdit"):
			toggle_mute();
	
	if (ui_stack.size() > 0):
		covered_cooldown_timer = 2.0;
	elif covered_cooldown_timer > 0.0:
		covered_cooldown_timer -= 1.0;
	
	if ui_stack.size() == 0 and covered_cooldown_timer <= 0.0:
		var dir = Vector2.ZERO;
		
		if (doing_replay and replay_timer > next_replay and !replay_paused):
			do_one_replay_turn();
			update_info_labels();
		
		if (won and Input.is_action_just_pressed("ui_accept")):
			end_replay();
			if (in_insight_level):
				gain_insight();
			elif (level_name == "A Way In?" and !doing_replay):
				ending_cutscene_1();
			elif last_level_of_section():
				level_select();
			else:
				load_level(1);
		elif (Input.is_action_just_pressed("escape")):
			#end_replay(); #done in escape();
			escape();
		elif (pressed_or_key_repeated("previous_level")
		and (!using_controller or ((!doing_replay or won) and (!won or won_cooldown > 0.5)))):
			if (!using_controller or won or lost or meta_turn <= 0):
				end_replay();
				load_level(-1);
			else:
				play_sound("bump");
		elif (pressed_or_key_repeated("next_level")
		and (!using_controller or ((!doing_replay or won) and (!won or won_cooldown > 0.5)))):
			if (!using_controller or won or lost or meta_turn <= 0):
				end_replay();
				load_level(1);
			else:
				play_sound("bump");
		elif (Input.is_action_just_pressed("toggle_replay")):
			user_pressed_toggle_replay();
		elif (doing_replay and pressed_or_key_repeated("replay_back1")):
			replay_advance_turn(-1);
		elif (doing_replay and pressed_or_key_repeated("replay_fwd1")):
			replay_advance_turn(1);
		elif (doing_replay and Input.is_action_just_pressed("replay_pause")):
			pause_replay();
		elif (pressed_or_key_repeated("speedup_replay")):
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
		elif (pressed_or_key_repeated("slowdown_replay")):
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
				if (user_replay != ""):
					if (!save_file["levels"].has(level_name)):
						save_file["levels"][level_name] = {};
					save_file["levels"][level_name]["replay"] = annotate_replay(user_replay);
					save_game();
					floating_text("Shift+F11: Replay force saved!");
			elif (Input.is_action_pressed("ctrl")):
				unwin();
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
				if (len(user_replay) > 0):
					OS.set_clipboard(annotate_replay(user_replay));
					floating_text("Ctrl+C: Replay copied");
				else:
					floating_text("Ctrl+C: Make some moves first!");
		elif (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("paste")):
			# must be kept in sync with Menu
			var clipboard = OS.get_clipboard();
			if (looks_like_level(clipboard)):
				paste_level(clipboard);
			else:
				start_specific_replay(clipboard);
		elif (Input.is_action_just_pressed("character_undo")):
			end_replay();
			character_undo();
			update_info_labels();
		elif (pressed_or_key_repeated("meta_undo")):
			end_replay();
			meta_undo();
			update_info_labels();
		elif (pressed_or_key_repeated("meta_redo")):
			end_replay();
			meta_redo();
			update_info_labels();
		elif (Input.is_action_just_pressed("restart")):
			# must be kept in sync with Menu "restart"
			end_replay();
			restart();
			update_info_labels();
		elif (Input.is_action_just_pressed("level_select")):
			level_select();
		elif (Input.is_action_just_pressed("gain_insight")):
			gain_insight();
		elif (Input.is_action_just_pressed("character_switch")):
			end_replay();
			character_switch();
			update_info_labels();
		elif (Input.is_action_just_pressed("ui_accept")): #so enter can open the menu but only if it's closed
			#end_replay(); #done in escape();
			escape();
		elif (!get_debounced):
			# and !replayspeedslider.has_focus() and !replayturnslider.has_focus()
			# (not necessary right now as they auto-unfocus in _input)
			if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("nonaxis_left")):
				dir = Vector2.LEFT;
			if (Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("nonaxis_right")):
				dir = Vector2.RIGHT;
			if (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("nonaxis_up")):
				dir = Vector2.UP;
			if (Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("nonaxis_down")):
				dir = Vector2.DOWN;
				
			if dir != Vector2.ZERO:
				end_replay();
				character_move(dir);
				update_info_labels();
		
	update_targeter();
	update_animation_server();

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_FOCUS_OUT:
			if (save_file.has("mute_in_background") and save_file["mute_in_background"]):
				AudioServer.set_bus_mute(0, true) # 0 = master bus, probably
		NOTIFICATION_WM_FOCUS_IN:
			AudioServer.set_bus_mute(0, false)
