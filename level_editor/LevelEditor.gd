extends Node2D
class_name LevelEditor

# keep in sync with GameLogic
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

onready var gamelogic = get_tree().get_root().find_node("LevelScene", true, false).gamelogic;
onready var menubutton : Button = get_node("MenuButton");
onready var tilemaps : Node2D = get_node("TileMaps");
onready var pen : Sprite = get_node("Pen");
onready var pickerbackground : ColorRect = get_node("PickerBackground");
onready var picker : TileMap = get_node("Picker");
onready var pickertooltip : Node2D = get_node("PickerTooltip");
onready var layerlabel : Label = get_node("LayerLabel");
onready var searchbox : LineEdit = get_node("Picker/SearchBox");
var custom_string = "";
var level_info : LevelInfo = null;
var pen_tile = Tiles.Wall;
var pen_layer = 0;
var terrain_layers = [];
var pen_xy = Vector2.ZERO;
var picker_mode = false;
var picker_array = [];
var just_picked = false;
var show_tooltips = false;
var searchbox_has_mouse = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menubutton.connect("pressed", self, "_menubutton_pressed");
	searchbox.connect("focus_entered", self, "_searchbox_focus_entered");
	searchbox.connect("focus_exited", self, "_searchbox_focus_exited");
	searchbox.connect("text_changed", self, "_searchbox_text_changed");
	searchbox.connect("text_entered", self, "_searchbox_text_entered");
	searchbox.connect("mouse_entered", self, "_searchbox_mouse_entered");
	searchbox.connect("mouse_exited", self, "_searchbox_mouse_exited");
	
	gamelogic.tile_changes(true);
	
	if (gamelogic.test_mode):
		custom_string = gamelogic.custom_string;
		gamelogic.test_mode = false;
	else:
		custom_string = gamelogic.serialize_current_level();
	deserialize_custom_level(custom_string);
	if (gamelogic.test_mode):
		var test_level_info = gamelogic.terrainmap.get_node_or_null("LevelInfo");
		if (test_level_info != null and test_level_info.level_replay != null and test_level_info.level_replay != ""):
			level_info.level_replay = test_level_info.level_replay;
			
	change_pen_tile(); # must happen after level setup
	
	initialize_picker_array();
	pickertooltip.squish_mode();
	
	for sl in pickertooltip.shadow_labels:
		sl.add_color_override("font_color_shadow", Color(0, 0, 0, 1));
		sl.add_constant_override("shadow_offset_x", 1)
		sl.add_constant_override("shadow_offset_y", 1)
	
func _searchbox_focus_entered() -> void:
	searchbox.text = "";
	searchbox.editable = true;
	gamelogic.no_mute_pwease = true;
	search_picker("");
	
func _searchbox_focus_exited() -> void:
	searchbox.text = "Search...";
	searchbox.editable = false;
	gamelogic.no_mute_pwease = false;
	search_picker("");
	
func _searchbox_text_changed(new_text: String) -> void:
	if (searchbox.editable):
		search_picker(searchbox.text);
	else:
		search_picker("");
	
func search_picker(text: String) -> void:
	text = text.to_lower();
	for i in range(picker_array.size()):
		var x = i % 21;
		var y = i / 21;
		var tile = picker_array[i];
		if ((text == "") or text in tooltip_for_tile(tile).to_lower()):
			picker.set_cellv(Vector2(x, y), tile);
		else:
			picker.set_cellv(Vector2(x, y), -1);
	picker.update_bitmask_region();
	
func _searchbox_text_entered(new_text: String) -> void:
	pass
	
func _searchbox_mouse_entered() -> void:
	searchbox_has_mouse = true;

func _searchbox_mouse_exited() -> void:
	searchbox_has_mouse = false;
	
func initialize_picker_array() -> void:
	# always true now
	show_tooltips = true;
	var puzzles = gamelogic.puzzles_completed;
	if gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]:
		puzzles += 99999;
	elif gamelogic.save_file["levels"].has("Chrono Lab Reactor") and gamelogic.save_file["levels"]["Chrono Lab Reactor"].has("won") and gamelogic.save_file["levels"]["Chrono Lab Reactor"]["won"]:
		puzzles += 99999;
		
	picker_array.append(-1);
	picker_array.append(Tiles.HeavyIdle);
	picker_array.append(Tiles.LightIdle);
	picker_array.append(Tiles.HeavyGoal);
	picker_array.append(Tiles.LightGoal);
	picker_array.append(Tiles.Wall);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[1]):
		picker_array.append(Tiles.Spikeball);
		picker_array.append(Tiles.Fire);
		picker_array.append(Tiles.HeavyFire);
		picker_array.append(Tiles.LightFire);
		picker_array.append(Tiles.NoHeavy);
		picker_array.append(Tiles.NoLight);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[3]):
		picker_array.append(Tiles.OnewayEast);
		picker_array.append(Tiles.OnewayNorth);
		picker_array.append(Tiles.OnewaySouth);
		picker_array.append(Tiles.OnewayWest);
		picker_array.append(Tiles.OnewayEastGreen);
		picker_array.append(Tiles.OnewayNorthGreen);
		picker_array.append(Tiles.OnewaySouthGreen);
		picker_array.append(Tiles.OnewayWestGreen);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[4]):
		picker_array.append(Tiles.Ladder);
		picker_array.append(Tiles.WoodenPlatform);
		picker_array.append(Tiles.LadderPlatform);
		picker_array.append(Tiles.OnewayEastPurple);
		picker_array.append(Tiles.OnewayNorthPurple);
		picker_array.append(Tiles.OnewaySouthPurple);
		picker_array.append(Tiles.OnewayWestPurple);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[5]):
		picker_array.append(Tiles.IronCrate);
		picker_array.append(Tiles.CrateGoal);
		picker_array.append(Tiles.NoCrate);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[6]):
		picker_array.append(Tiles.ColourRed);
		picker_array.append(Tiles.ColourBlue);
		picker_array.append(Tiles.ColourGray);
		picker_array.append(Tiles.ColourMagenta);
		picker_array.append(Tiles.WoodenCrate);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[7]):
		picker_array.append(Tiles.GlassBlock);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[8]):
		picker_array.append(Tiles.ColourGreen);
		picker_array.append(Tiles.GreenSpikeball);
		picker_array.append(Tiles.GreenFire);
		picker_array.append(Tiles.GreenGlassBlock);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[9]):
		picker_array.append(Tiles.Fuzz);
		picker_array.append(Tiles.OneUndo);
		picker_array.append(Tiles.NoUndo);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[10]):
		picker_array.append(Tiles.TimeCrystalGreen);
		picker_array.append(Tiles.TimeCrystalMagenta);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[11]):
		picker_array.append(Tiles.CuckooClock);
		picker_array.append(Tiles.TheNight);
		picker_array.append(Tiles.TheStars);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[12]):
		picker_array.append(Tiles.SteelCrate);
		picker_array.append(Tiles.PowerCrate);
		picker_array.append(Tiles.ColourVoid);
		picker_array.append(Tiles.ColourCyan);
		picker_array.append(Tiles.ColourOrange);
		picker_array.append(Tiles.ColourYellow);
		picker_array.append(Tiles.ColourPurple);
		picker_array.append(Tiles.ColourBlurple);
		picker_array.append(Tiles.ColourWhite);
		picker_array.append(Tiles.ColourNative)
		picker_array.append(Tiles.ChronoHelixBlue);
		picker_array.append(Tiles.ChronoHelixRed);
		picker_array.append(Tiles.HeavyGoalJoke);
		picker_array.append(Tiles.LightGoalJoke);
		picker_array.append(Tiles.PowerSocket);
		picker_array.append(Tiles.GreenPowerSocket);
		picker_array.append(Tiles.VoidPowerSocket);
		picker_array.append(Tiles.VoidSpikeball);
		picker_array.append(Tiles.VoidGlassBlock);
		picker_array.append(Tiles.GlassBlockCracked);
		picker_array.append(Tiles.PhaseWallBlue)
		picker_array.append(Tiles.PhaseWallRed)
		picker_array.append(Tiles.PhaseWallGray)
		picker_array.append(Tiles.PhaseWallPurple)
		picker_array.append(Tiles.PhaseLightningBlue)
		picker_array.append(Tiles.PhaseLightningRed)
		picker_array.append(Tiles.PhaseLightningGray)
		picker_array.append(Tiles.PhaseLightningPurple)
		picker_array.append(Tiles.OnewayEastLose)
		picker_array.append(Tiles.OnewayNorthLose)
		picker_array.append(Tiles.OnewaySouthLose)
		picker_array.append(Tiles.OnewayWestLose)
		picker_array.append(Tiles.Checkpoint)
		picker_array.append(Tiles.CheckpointRed)
		picker_array.append(Tiles.CheckpointBlue)
		picker_array.append(Tiles.GreenFog)
		picker_array.append(Tiles.Floorboards)
		picker_array.append(Tiles.MagentaFloorboards)
		picker_array.append(Tiles.GreenFloorboards)
		picker_array.append(Tiles.VoidFloorboards)
		picker_array.append(Tiles.Hole)
		picker_array.append(Tiles.GreenHole)
		picker_array.append(Tiles.VoidHole)
		picker_array.append(Tiles.BoostPad)
		picker_array.append(Tiles.GreenBoostPad)
		picker_array.append(Tiles.SlopeNW)
		picker_array.append(Tiles.SlopeNE)
		picker_array.append(Tiles.SlopeSE)
		picker_array.append(Tiles.SlopeSW)
		picker_array.append(Tiles.Boulder)
		picker_array.append(Tiles.PhaseWallGreenEven)
		picker_array.append(Tiles.PhaseWallGreenOdd)
		picker_array.append(Tiles.NudgeEast)
		picker_array.append(Tiles.NudgeNorth)
		picker_array.append(Tiles.NudgeSouth)
		picker_array.append(Tiles.NudgeWest)
		picker_array.append(Tiles.NudgeEastGreen)
		picker_array.append(Tiles.NudgeNorthGreen)
		picker_array.append(Tiles.NudgeSouthGreen)
		picker_array.append(Tiles.NudgeWestGreen)
		picker_array.append(Tiles.Grate)
		picker_array.append(Tiles.AntiGrate)
		picker_array.append(Tiles.GhostPlatform)
		picker_array.append(Tiles.Propellor)
		picker_array.append(Tiles.FallOne)
		picker_array.append(Tiles.FallInf)
		picker_array.append(Tiles.DurPlus)
		picker_array.append(Tiles.DurMinus)
		picker_array.append(Tiles.HvyPlus)
		picker_array.append(Tiles.HvyMinus)
		picker_array.append(Tiles.StrPlus)
		picker_array.append(Tiles.StrMinus)
		picker_array.append(Tiles.RepairStation)
		picker_array.append(Tiles.RepairStationGray)
		picker_array.append(Tiles.RepairStationGreen)
		picker_array.append(Tiles.ZombieTile)
		picker_array.append(Tiles.HeavyMimic)
		picker_array.append(Tiles.LightMimic)
		picker_array.append(Tiles.GhostFog)
		picker_array.append(Tiles.PurpleFog)
		picker_array.append(Tiles.Eclipse)
		picker_array.append(Tiles.PhaseBoardRed)
		picker_array.append(Tiles.PhaseBoardBlue)
		picker_array.append(Tiles.PhaseBoardGray)
		picker_array.append(Tiles.PhaseBoardPurple)
		picker_array.append(Tiles.PhaseBoardVoid)
		picker_array.append(Tiles.PhaseBoardDeath)
		picker_array.append(Tiles.PhaseBoardLife)
		picker_array.append(Tiles.PhaseBoardHeavy)
		picker_array.append(Tiles.PhaseBoardLight)
		picker_array.append(Tiles.PhaseBoardCrate)
		picker_array.append(Tiles.SpiderWeb)
		picker_array.append(Tiles.SpiderWebGreen)
		picker_array.append(Tiles.NoPush)
		picker_array.append(Tiles.NoPushGreen)
		picker_array.append(Tiles.YesPush)
		picker_array.append(Tiles.YesPushGreen)
		picker_array.append(Tiles.NoLeft)
		picker_array.append(Tiles.NoLeftGreen)
		picker_array.append(Tiles.OnewayEastGray)
		picker_array.append(Tiles.OnewayNorthGray)
		picker_array.append(Tiles.OnewaySouthGray)
		picker_array.append(Tiles.OnewayWestGray)
		picker_array.append(Tiles.PinkJelly)
		picker_array.append(Tiles.CyanJelly)
		picker_array.append(Tiles.Spotlight)
		picker_array.append(Tiles.Continuum)
		picker_array.append(Tiles.GateOfEternity)
		picker_array.append(Tiles.GateOfDemise)
		picker_array.append(Tiles.VoidSingularity)
		picker_array.append(Tiles.VoidWall)
		picker_array.append(Tiles.VoidFire)
		picker_array.append(Tiles.VoidStars)
		picker_array.append(Tiles.VoidFog)
		picker_array.append(Tiles.NoRising)
		picker_array.append(Tiles.NoFalling)
		picker_array.append(Tiles.NoGrounded)
		picker_array.append(Tiles.PhaseBoardEast)
		picker_array.append(Tiles.PhaseBoardNorth)
		picker_array.append(Tiles.PhaseBoardSouth)
		picker_array.append(Tiles.PhaseBoardWest)
		picker_array.append(Tiles.RepairStationBumper)
		picker_array.append(Tiles.Fence)
		picker_array.append(Tiles.Fan)
		picker_array.append(Tiles.Bumper)
		picker_array.append(Tiles.Passage)
		picker_array.append(Tiles.GreenPassage)
	
	for i in range(picker_array.size()):
		var x = i % 21;
		var y = i / 21;
		picker.set_cellv(Vector2(x, y), picker_array[i]);
	picker.update_bitmask_region();

func deserialize_custom_level(custom_string: String) -> void:
	var level = gamelogic.deserialize_custom_level(custom_string);
	if (level == null):
		floating_text("Invalid level")
		return;
	
	for child in tilemaps.get_children():
		tilemaps.remove_child(child);
		child.queue_free();
	terrain_layers.clear();
	
	tilemaps.add_child(level);
	level_info = level.get_node("LevelInfo");
	
	if (level_info.map_x_max > gamelogic.map_x_max_max or level_info.map_y_max > gamelogic.map_y_max_max+2):
		if (tilemaps.scale == Vector2(1, 1)):
			toggle_zoom();

	terrain_layers.append(level);
	for child in level.get_children():
		if child is TileMap:
			terrain_layers.push_front(child);
			level.remove_child(child);
			tilemaps.add_child(child);
	change_layer(0);

func serialize_current_level() -> String:
	# keep in sync with GameLogic.gd serialize_current_level()
	
	# 0) change to layer 0 just in case of weirdness
	change_layer(0);
	
	# 1) trim empty layers
	#var new_array = [];
	var empties = [];
	for layer in terrain_layers:
		if layer.get_used_cells().size() > 0:
			#new_array.append(layer);
			pass
		else:
			empties.append(layer);
	if (empties.size() == terrain_layers.size()):
		floating_text("It's empty, Jim.")
		return "";
	for layer in empties:
		terrain_layers.erase(layer);
		layer.get_parent().remove_child(layer);
		layer.queue_free();
	
	# 2) trim tiles at negative co-ordinates
	for layer in terrain_layers:
		var cells = layer.get_used_cells();
		for cell in cells:
			if cell.x < 0 or cell.y < 0:
				layer.set_cellv(cell, -1);
	
	# 3) squash horizontally and vertically
	var min_x = 999999;
	var min_y = 999999;
	for layer in terrain_layers:
		var rect = layer.get_used_rect();
		min_x = min(rect.position.x, min_x);
		min_y = min(rect.position.y, min_y);
	shift_all_layers(Vector2(-min_x, -min_y));
	
	# 4) set map_x_max and map_y_max
	level_info.map_x_max = 0;
	level_info.map_y_max = 0;
	for layer in terrain_layers:
		var rect = layer.get_used_rect();
		level_info.map_x_max = max(level_info.map_x_max, rect.size.x + rect.position.x - 1);
		level_info.map_y_max = max(level_info.map_y_max, rect.size.y + rect.position.y - 1);

	var result = "EntwinedTimePuzzleStart: " + level_info.level_name + " by " + level_info.level_author + "\n";
	var level_metadata = {};
	var metadatas = ["level_name", "level_author", "level_replay", "heavy_max_moves", "light_max_moves",
	"clock_turns", "map_x_max", "map_y_max", "target_track", "setup_replay" #"target_sky"
	];
	for metadata in metadatas:
		level_metadata[metadata] = level_info.get(metadata);
	level_metadata["target_sky"] = level_info.target_sky.to_html(false);
		
	var layers = terrain_layers;
			
	level_metadata["layers"] = layers.size();
			
	result += to_json(level_metadata);
	
	for i in layers.size():
		result += "\nLAYER " + str(i) + ":\n";
		var layer = layers[layers.size() - 1 - i];
		for y in range(level_metadata["map_y_max"]+1):
			for x in range(level_metadata["map_x_max"]+1):
				if (x > 0):
					result += ",";
				var tile = layer.get_cell(x, y);
				if tile >= 0 and tile <= 9:
					result += "0" + str(tile);
				else:
					result += str(tile);
			result += "\n";
	
	result += "EntwinedTimePuzzleEnd"
	return result.split("\n").join("`\n");

func copy_level() -> void:
	var result = serialize_current_level();
	if (result != ""):
		floating_text("Ctrl+C: Level copied to clipboard!");
		OS.set_clipboard(result);
		
func save_as_tscn() -> void:
	var a = serialize_current_level();
	if (a != ""):
		var deserialized = gamelogic.deserialize_custom_level(a);
		for node in deserialized.get_children():
			node.owner = deserialized
			
		var scene = PackedScene.new();
		var result = scene.pack(deserialized)
		
		if result == OK:
			var path = "res://levels/custom/" + level_info.level_name.replace("?", "-").replace(":", "-") + ".tscn";
			var error = ResourceSaver.save(path, scene);
			if error != OK:
				floating_text("An error occurred while saving the scene to disk.")
			else:
				floating_text("Saved to " + path);
		deserialized.queue_free();
	
func paste_level() -> void:
	var clipboard = OS.get_clipboard();
	if (!gamelogic.looks_like_level(clipboard)):
		floating_text("Ctrl+V: Invalid level");
		return
	else:
		deserialize_custom_level(clipboard);
		floating_text("Ctrl+V: Level pasted from clipboard!");

func new_level() -> void:
	change_layer(0);
	for layer in terrain_layers:
		layer.clear();
	floating_text("Level reset");

func shift_all_layers(shift: Vector2) -> void:
	for layer in terrain_layers:
		shift_layer(layer, shift);
		
func shift_layer(layer: TileMap, shift: Vector2) -> void:
	var rect = null;
	# do x shift
	
	if (shift.x < 0):
		rect = layer.get_used_rect();
		for i in range(rect.size.x):
			var x = rect.position.x + i;
			for j in range(rect.size.y):
				var y = rect.position.y + j;
				layer.set_cellv(Vector2(x+shift.x, y), layer.get_cellv(Vector2(x, y)));
				layer.update_bitmask_area(Vector2(x+shift.x, y));
				layer.set_cellv(Vector2(x, y), -1);
				layer.update_bitmask_area(Vector2(x, y));
	elif (shift.x > 0):
		rect = layer.get_used_rect();
		for i in range(rect.size.x):
			var x = rect.position.x + rect.size.x - 1 - i;
			for j in range(rect.size.y):
				var y = rect.position.y + j;
				layer.set_cellv(Vector2(x+shift.x, y), layer.get_cellv(Vector2(x, y)));
				layer.update_bitmask_area(Vector2(x+shift.x, y));
				layer.set_cellv(Vector2(x, y), -1);
				layer.update_bitmask_area(Vector2(x, y));
	
	# do y shift
	if (shift.y < 0):
		rect = layer.get_used_rect();
		for i in range(rect.size.x):
			var x = rect.position.x + i;
			for j in range(rect.size.y):
				var y = rect.position.y + j;
				layer.set_cellv(Vector2(x, y+shift.y), layer.get_cellv(Vector2(x, y)));
				layer.update_bitmask_area(Vector2(x, y+shift.y));
				layer.set_cellv(Vector2(x, y), -1);
				layer.update_bitmask_area(Vector2(x, y));
	elif (shift.y > 0):	
		rect = layer.get_used_rect();
		for i in range(rect.size.x):
			var x = rect.position.x + i;
			for j in range(rect.size.y):
				var y = rect.position.y + rect.size.y - 1 - j;
				layer.set_cellv(Vector2(x, y+shift.y), layer.get_cellv(Vector2(x, y)));
				layer.update_bitmask_area(Vector2(x, y+shift.y));
				layer.set_cellv(Vector2(x, y), -1);
				layer.update_bitmask_area(Vector2(x, y));

func layer_index() -> int:
	return terrain_layers.size() - 1 - pen_layer;

func change_pen_tile() -> void:
	var tile_set = tilemaps.get_child(0).tile_set;
	if (pen_tile >= 0):
		pen.texture = tile_set.tile_get_texture(pen_tile);
		pen.offset = Vector2.ZERO;
	else:
		pen.texture = preload("res://assets/targeter.png");
		pen.offset = Vector2(-1, -1);
	# handle auto-tile wall icon
	if (pen_tile == Tiles.Wall):
		var coord = tile_set.autotile_get_icon_coordinate(pen_tile);
		pen.region_enabled = true;
		pen.region_rect = Rect2(coord*gamelogic.cell_size, Vector2(gamelogic.cell_size, gamelogic.cell_size));
	else:
		pen.region_enabled = false;

func picker_click() -> void:
	if searchbox_has_mouse:
		return;
	
	pen_tile = picker.get_cellv(pen_xy);
	change_pen_tile();
	toggle_picker_mode();
	just_picked = true;

func lmb() -> void:
	if (picker_mode):
		picker_click();
		return;
		
	if (just_picked):
		return;
	
	terrain_layers[layer_index()].set_cellv(pen_xy, pen_tile);
	terrain_layers[layer_index()].update_bitmask_area(pen_xy);
	if (level_info.map_x_max < pen_xy.x):
		level_info.map_x_max = pen_xy.x;
	if (level_info.map_y_max < pen_xy.y):
		level_info.map_y_max = pen_xy.y;

func rmb() -> void:
	if (picker_mode):
		picker_click();
		return;
		
	if (just_picked):
		return;
	
	pen_tile = terrain_layers[layer_index()].get_cellv(pen_xy);
	change_pen_tile();

func _menubutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://level_editor/LevelEditorMenu.tscn").instance();
	gamelogic.add_to_ui_stack(a, self);

func destroy() -> void:
	gamelogic.no_mute_pwease = false;
	gamelogic.tile_changes(false);
	self.queue_free();
	gamelogic.ui_stack.erase(self);

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	var existing_labels = 0;
	for i in self.get_children():
		if i is FloatingText:
			existing_labels += 1;
	self.add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = gamelogic.pixel_width;
	label.rect_position.y = gamelogic.pixel_height/2-16 + 8*existing_labels;
	label.text = text;
	
func generate_layer() -> void:
	var layer = TileMap.new();
	layer.tile_set = terrain_layers[0].tile_set;
	layer.cell_size = terrain_layers[0].cell_size;
	terrain_layers.push_front(layer);
	tilemaps.add_child(layer);
	
func change_layer(layer: int) -> void:
	pen_layer = layer;
	while (terrain_layers.size() < (pen_layer + 1)):
		generate_layer();
	for i in range(terrain_layers.size()):
		if i == layer_index():
			terrain_layers[i].modulate = Color(1, 1, 1, 1);
		else:
			terrain_layers[i].modulate = Color(1, 1, 1, 0.5);
	layerlabel.text = "Layer: " + str(pen_layer);

func toggle_picker_mode() -> void:
	if !picker_mode:
		picker_mode = true;
		pickerbackground.visible = true;
		picker.visible = true;
		pickertooltip.visible = show_tooltips;
		searchbox.grab_focus();
	else:
		picker_mode = false;
		pickerbackground.visible = false;
		picker.visible = false;
		pickertooltip.visible = false;

func picker_cycle(impulse: int) -> void:
	var current_index = picker_array.find(pen_tile);
	if (current_index == -1):
		current_index = 0;
	current_index += impulse;
	if (current_index < 0):
		current_index += picker_array.size();
	elif (current_index >= picker_array.size()):
		current_index -= picker_array.size();
	pen_tile = picker_array[current_index];
	change_pen_tile();
	
func tooltip_for_tile(tile: int) -> String:
	var text = "";
	match tile:
		-1:
			text = "";
		Tiles.HeavyIdle:
			text = "Heavy: Actor. Character. Heaviness: Steel. Strength: Steel. Durability: Spikes. Fall speed: 2.  Native Time Colour: Purple. Doesn't float (immediately starts falling when ungrounded or moving down onto a non-ladder, no air control when falling). Climbs. Sticky top: After making a forward move, anything that was in the tile above it mimics the move. (Only the first Heavy in layer-then-reading-order will be real. The rest will be inert. Inert robots don't activate time crystals, goals, checkpoints and don't care about one rewind/no rewind/fuzz.)"
		Tiles.LightIdle:
			text = "Light: Actor. Character. Heaviness: Iron. Strength: Iron. Durability: Nothing. Fall speed: 1. Native Time Colour: Blurple. Floats (if grounded and could fall, enters rising state. When moving down, remains grounded. Has air control while falling.) Climbs. Clumsy (loses one strength when indirectly pushed). (Only the first Heavy in layer-then-reading-order will be real. The rest will be inert. Inert robots don't activate time crystals, goals, checkpoints and don't care about one rewind/no rewind/fuzz.)"
		Tiles.HeavyGoal:
			text = "Heavy Goal: At end of turn, if unbroken Heavy is on a Heavy Goal and unbroken Light is on a Light Goal, you win."
		Tiles.LightGoal:
			text = "Light Goal: At end of turn, if unbroken Heavy is on a Heavy Goal and unbroken Light is on a Light Goal, you win."
		Tiles.Wall:
			text = "Wall: Solid."
		Tiles.Spikeball:
			text = "Spikeball: Solid. Surprise: If the actor doesn't have Spikes or greater Durability, it breaks. (Surprises trigger on failure to enter, and aren't stable ground if they'd do something.)"
		Tiles.Fire:
			text = "Fire: When an actor experiences time, after gravity, if it's on Fire and doesn't have Fire or greater Durability, it breaks."
		Tiles.HeavyFire:
			text = "Heavy Fire: Fire, but it can't break Light."
		Tiles.LightFire:
			text = "Light Fire: Fire, but it deals Spikes level damage."
		Tiles.NoHeavy:
			text = "No Heavy: Solid to Heavy."
		Tiles.NoLight:
			text = "No Light: Solid to Light."
		Tiles.OnewayEast:
			text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
		Tiles.OnewayNorth:
			text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
		Tiles.OnewaySouth:
			text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
		Tiles.OnewayWest:
			text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
		Tiles.OnewayEastGreen:
			text = "Green One Way: Solid to moves entering its tile."
		Tiles.OnewayNorthGreen:
			text = "Green One Way: Solid to moves entering its tile."
		Tiles.OnewaySouthGreen:
			text = "Green One Way: Solid to moves entering its tile."
		Tiles.OnewayWestGreen:
			text = "Green One Way: Solid to moves entering its tile."
		Tiles.Ladder:
			text = "Ladder: Actors that can climb and aren't broken are supported in this tile (they become and remain grounded)."
		Tiles.WoodenPlatform:
			text = "Trapdoor: Solid to gravity moves."
		Tiles.LadderPlatform:
			text = "Ladder + Trapdoor: Combines the properties of the two tiles. (I made it before layers existed.)"
		Tiles.OnewayEastPurple:
			text = "Purple One Way: Solid to retroactive moves entering its tile."
		Tiles.OnewayNorthPurple:
			text = "Purple One Way: Solid to retroactive moves entering its tile."
		Tiles.OnewaySouthPurple:
			text = "Purple One Way: Solid to retroactive moves entering its tile."
		Tiles.OnewayWestPurple:
			text = "Purple One Way: Solid to retroactive moves entering its tile."
		Tiles.IronCrate:
			text = "Iron Crate: Actor. Heaviness: Iron. Strength: Wood. Durability: Spikes. Fall speed: Infinite. Native Time Colour: Gray."
		Tiles.CrateGoal:
			text = "Crate Goal: If you would win due to Light and Heavy being on Goals: You do not unless every Crate Goal has an unbroken non-Character actor on its tile."
		Tiles.NoCrate:
			text = "No Crate: Solid to non-Character actors."
		Tiles.ColourRed:
			text = "Red: Colour. (Attaches to the first actor to enter or start in its tile it can modify.) Experiences time when Heavy moves."
		Tiles.ColourBlue:
			text = "Blue: Colour. (Attaches to the first actor to enter or start in its tile it can modify.) Experiences time when Light moves."
		Tiles.ColourGray:
			text = "Gray: Colour. (Attaches to the first actor to enter or start in its tile it can modify.) Experiences time during moves."
		Tiles.ColourMagenta:
			text = "Magenta: Colour. (Attaches to the first actor to enter or start in its tile it can modify.) Always experiences time."
		Tiles.WoodenCrate:
			text = "Wooden Crate: Actor. Heaviness: Wood. Strength: Wood. Durability: Nothing. Fall speed: Infinite. Native Time Colour: Gray. When unbroken Light fails to push an unstacked Wooden Crate, Light tries again by pushing it up instead. When unbroken Heavy fails to push an unstacked Wooden Crate, Heavy tries again by breaking it instead (failing if the Wooden Crate has Durability of Spikes or higher)."
		Tiles.GlassBlock:
			text = "Glass Block: Solid to moves entering or exiting its tile. Surprise: If the actor is Iron weight or greater, the Glass Block breaks. When a Glass Block unbreaks, it breaks any actors that don't have Unbreakable durability."
		Tiles.ColourGreen:
			text = "Green: Colour. Always experiences time. Doesn't create rewind events."
		Tiles.GreenSpikeball:
			text = "Green Spikeball: A Spikeball that does not create rewind events."
		Tiles.GreenFire:
			text = "Green Fire: A Fire that activates after regular Fires even for actors not experiencing time and does not create rewind events."
		Tiles.GreenGlassBlock:
			text = "Green Glass Block: A Glass Block that does not create rewind events."
		Tiles.Fuzz:
			text = "Fuzz: When a character rewinds while inside Fuzz, the Fuzz is consumed, the rewind happens but is not consumed, and time does not pass."
		Tiles.OneUndo:
			text = "One Rewind: When a character rewinds while inside One Rewind, one of them is replaced with a No Rewind. (In-game, the number of purple dots shows the number of remaining One Rewinds. The open eye is effectively 'zero'.)"
		Tiles.NoUndo:
			text = "No Rewind: When a character rewinds while inside No Rewind and on no One Rewind, it is prevented and nothing happens. (In-game, the number of purple dots shows the number of remaining One Rewinds. The open eye is effectively 'zero'.)"
		Tiles.TimeCrystalGreen:
			text = "Green Time Crystal: Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Green. Time Crystals existing locks goals. When consumed by an unbroken Cuckoo Clock: Increase ticks by 1. When consumed by a Character: If the character has no locked moves: Increase turn limit by 1. Else, unlock the most recently locked move and place it on the end of the character's filled timeline. (Crystals breaking never makes a rewind event, broken crystals are banished from the map.)"
		Tiles.TimeCrystalMagenta:
			text = "Magenta Time Crystal: Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Green. Time Crystals existing locks goals. When consumed by an unbroken Cuckoo Clock: Decrease ticks by 1. When consumed by a Character: If the character's turn limit is 0: You lose. Else, if the character is filling a timeline slot: Lock it. Else, if the character has a filled timeline slot: Lock the highest numbered one. Else, lock an empty timeline slot. (Crystals breaking never makes a rewind event, broken crystals are banished from the map.)"
		Tiles.CuckooClock:
			text = "Cuckoo Clock: Actor. Heaviness: Wooden. Strength: Wooden. Durability: Nothing. Fall speed: 1. Native Time Colour: Gray. To start a puzzle with ticks: Fill out Clock Turns field with a comma separated list, and turns will be assigned to clocks in layer+reading order. When experiencing time, after green fire, if it has ticks and isn't broken, decrease ticks by 1. When a cuckoo clock strikes exactly 0, and isn't broken, and it's not during a fuzz undo: You lose."
		Tiles.TheNight:
			text = "Night: Actors inside Night don't experience time passing (except for being burned by fire and green fire)."
		Tiles.TheStars:
			text = "Stars: Actors inside Stars are immune to rewind events."
		Tiles.SteelCrate:
			text = "Steel Crate: Actor. Heaviness: Steel. Strength: Iron. Durability: Fire. Fall speed: Infinite. Native Time Colour: Gray. When a unbroken Steel Crate fails to move into an unstacked unbroken Light or Cuckoo Clock, the target first breaks."
		Tiles.PowerCrate:
			text = "Power Crate: Actor. Heaviness: Wooden. Strength: Steel. Durability: Spikes. Fall speed: Infinite. Native Time Colour: Gray."
		Tiles.ColourVoid:
			text = "Void: Colour. (Void coloured actors can't be given other colours.) (Turning Void causes the actor to experience a 'void banish'. See Void Singularity tooltip for more information.) Always experiences time, INCLUDING after undos. Void actors don't create rewind events OR undo events. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.ColourCyan:
			text = "Cyan: Colour. Experiences time when Light moves or rewinds."
		Tiles.ColourOrange:
			text = "Orange: Colour. Experiences time when Heavy moves or rewinds."
		Tiles.ColourYellow:
			text = "Yellow: Colour. Experiences time during rewinds."
		Tiles.ColourPurple:
			text = "Purple: Colour. Experiences time except when Heavy rewinds."
		Tiles.ColourBlurple:
			text = "Blurple: Colour. Experiences time except when Light rewinds."
		Tiles.ColourWhite:
			text = "White: Colour. Never experiences time."
		Tiles.VoidSpikeball:
			text = "Void Spikeball: A Spikeball that does not create rewind OR undo events. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.VoidGlassBlock:
			text = "Void Glass Block: A Glass Block that does not create rewind OR undo events. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.ChronoHelixBlue:
			text = "Chrono Helix Blue: Actor. Heaviness: Iron. Strength: Steel. Durability: Unbreakable. Fall speed: 1. Native Time Colour: Gray. When experiencing time, after gravity and before fire, if 8-way adjacent to a Chrono Helix Red, both move away from each other. When bumped with a Chrono Helix Red, you win."
		Tiles.ChronoHelixRed:
			text = "Chrono Helix Red: Actor. Heaviness: Iron. Strength: Steel. Durability: Unbreakable. Fall speed: 1. Native Time Colour: Gray. When experiencing time, after gravity and before fire, if 8-way adjacent to a Chrono Helix Blue, both move away from each other. When bumped with a Chrono Helix Blue, you win."
		Tiles.HeavyGoalJoke:
			text = "Heavy Goal (Joke): Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Gray. Not solid. Counts as a Heavy Goal. Phases through terrain and actors."
		Tiles.LightGoalJoke:
			text = "Light Goal (Joke): Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Gray. Not solid. Counts as a Light Goal. Phases through terrain and actors."
		Tiles.PowerSocket:
			text = "Power Socket: A Spikeball with the same strength as a Bottomless Pit. (Put a No Heavy/Light/Crate on top if you want it to avoid some actors.)"
		Tiles.GreenPowerSocket:
			text = "Green Power Socket: A Power Socket that does not create rewind events."
		Tiles.VoidPowerSocket:
			text = "Void Power Socket: A Power Socket that does not create rewind OR undo events. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.GlassBlockCracked:
			text = "Cracked Glass Block: A Glass Block without the weight requirement. Additionally, actors can break out of a Cracked Glass Block by attempting a non-gravity move."
		Tiles.PhaseWallBlue:
			text = "Phase Wall Blue: Solid during Light moves and rewinds."
		Tiles.PhaseWallRed:
			text = "Phase Wall Red: Solid during Heavy moves and rewinds."
		Tiles.PhaseWallGray:
			text = "Phase Wall Gray: Solid during character moves."
		Tiles.PhaseWallPurple:
			text = "Phase Wall Purple: Solid during character rewinds."
		Tiles.PhaseLightningBlue:
			text = "Phase Lightning Blue: After Light moves and rewinds, when time passes, before gravity, ALL actors on this tile that don't have Fire or greater Durability break."
		Tiles.PhaseLightningRed:
			text = "Phase Lightning Red: After Heavy moves and rewinds, when time passes, before gravity, ALL actors on this tile that don't have Fire or greater Durability break."
		Tiles.PhaseLightningGray:
			text = "Phase Lightning Gray: After moves, when time passes, before gravity, ALL actors on this tile that don't have Fire or greater Durability break."
		Tiles.PhaseLightningPurple:
			text = "Phase Lightning Purple: After rewinds, when time passes, before gravity, ALL actors on this tile that don't have Fire or greater Durability break."
		Tiles.OnewayEastLose:
			text = "Green Zappy One Way: A Green One Way that acts like a Green Power Socket when bumped."
		Tiles.OnewayNorthLose:
			text = "Green Zappy One Way: A Green One Way that acts like a Green Power Socket when bumped."
		Tiles.OnewaySouthLose:
			text = "Green Zappy One Way: A Green One Way that acts like a Green Power Socket when bumped."
		Tiles.OnewayWestLose:
			text = "Green Zappy One Way: A Green One Way that acts like a Green Power Socket when bumped."
		Tiles.Checkpoint:
			text = "Checkpoint: At end of turn, Heavy or Light on this tile has its timeline cleared."
		Tiles.CheckpointRed:
			text = "Heavy Checkpoint: At end of turn, Heavy on this tile has its timeline cleared."
		Tiles.CheckpointBlue:
			text = "Light Checkpoint: At end of turn, Light on this tile has its timeline cleared."
		Tiles.GreenFog:
			text = "Green Fog: Actors in Green Fog don't create rewind events."
		Tiles.Floorboards:
			text = "Floorboards: Existence of lower layer terrain in this tile is ignored, including Holes. When an Actor leaves a tile with Floorboards using a non-retro move: The Floorboards is destroyed. In a stack of Floorboards, only the topmost one is considered."
		Tiles.MagentaFloorboards:
			text = "Magenta Floorboards: A Floorboards that can be destroyed also by retroactive moves."
		Tiles.GreenFloorboards:
			text = "Green Floorboards: A Floorboards that can be destroyed also by retroactive moves, and that does not create rewind events."
		Tiles.VoidFloorboards:
			text = "Void Floorboards: A Floorboards that can be destroyed also by retroactive moves and undos, and that does not create rewind OR undo events. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.Hole:
			text = "Hole: Actor. Heaviness: Infinite. Strength: None. Durabilty: Unbreakable. Fall Speed: 0. Native Time Color: Gray. Not solid. When a non-Unbreakable actor enters an unbroken Hole, it breaks. If that actor was an unbroken crate or boulder, the Hole breaks. Holes (broken or unbroken) are solid to moves of broken actors exiting its tile, including itself. Holes get disabled by Floorboards on their tile."
		Tiles.GreenHole:
			text = "Green Hole: A Hole, but when it breaks an actor it does not create a rewind event. Also has Native Time Color: Green."
		Tiles.VoidHole:
			text = "Void Hole: A hole that doesn't create rewind OR undo events. Also has Native Time Colour: Void. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.BoostPad:
			text = "Boost Pad: Forward movements leaving this tile happen one additional time."
		Tiles.GreenBoostPad:
			text = "Green Boost Pad: ALL movements leaving this tile happen one additional time."
		Tiles.SlopeNW:
			text = "Slope: If a non-retro move enters a slope, then for the original move to succeed, it also has to be able to eject perpendicularly out of the slope. If that fails, it also tries to leave parallely. If that fails too, the move fails. (The second movement can't be the direction you came from.) If a slope makes a grounded robot or any other actor move up, it becomes rising.  When time passes, before clocks tick, the 'slope cleanup step' happens - ALL actors still in slope attempt to be ejected (first sideways, then vertically, then if all of that fails we break for infinite damage). This continues recursively until nothing changes. If we loop 100 times: Lose (infinite loop). (Btw, if multiple slopes are in a tile, they're checked in layer order.)"
		Tiles.SlopeNE:
			text = "Slope: If a non-retro move enters a slope, then for the original move to succeed, it also has to be able to eject perpendicularly out of the slope. If that fails, it also tries to leave parallely. If that fails too, the move fails. (The second movement can't be the direction you came from.) If a slope makes a grounded robot or any other actor move up, it becomes rising.  When time passes, before clocks tick, the 'slope cleanup step' happens - ALL actors still in slope attempt to be ejected (first sideways, then vertically, then if all of that fails we break for infinite damage). This continues recursively until nothing changes. If we loop 100 times: Lose (infinite loop). (Btw, if multiple slopes are in a tile, they're checked in layer order.)"
		Tiles.SlopeSE:
			text = "Slope: If a non-retro move enters a slope, then for the original move to succeed, it also has to be able to eject perpendicularly out of the slope. If that fails, it also tries to leave parallely. If that fails too, the move fails. (The second movement can't be the direction you came from.) If a slope makes a grounded robot or any other actor move up, it becomes rising.  When time passes, before clocks tick, the 'slope cleanup step' happens - ALL actors still in slope attempt to be ejected (first sideways, then vertically, then if all of that fails we break for infinite damage). This continues recursively until nothing changes. If we loop 100 times: Lose (infinite loop). (Btw, if multiple slopes are in a tile, they're checked in layer order.)"
		Tiles.SlopeSW:
			text = "Slope: If a non-retro move enters a slope, then for the original move to succeed, it also has to be able to eject perpendicularly out of the slope. If that fails, it also tries to leave parallely. If that fails too, the move fails. (The second movement can't be the direction you came from.) If a slope makes a grounded robot or any other actor move up, it becomes rising.  When time passes, before clocks tick, the 'slope cleanup step' happens - ALL actors still in slope attempt to be ejected (first sideways, then vertically, then if all of that fails we break for infinite damage). This continues recursively until nothing changes. If we loop 100 times: Lose (infinite loop). (Btw, if multiple slopes are in a tile, they're checked in layer order.)"
		Tiles.Boulder:
			text = "Boulder: Actor. Heaviness: Iron. Strength: Wood. Durability: Spikes. Fall speed: 1. Native Time Colour: Gray. Boulders can fill holes. If a non-broken Boulder makes a non-retro move with a horizontal component: Its momentum becomes Left or Right. (This is a timeline event.) When time passes, after nudges and before gravity: A non-broken boulder with momentum will attempt to move in that direction, and its momentum will become Zero if the move fails. Boulders rolling under their own momentum can push with +1 strength, but will remain stationary (and thus lose their momentum). (Boulders with a Propellor can have vertical momentum.)"
		Tiles.PhaseWallGreenEven:
			text = "Phase Wall Green Even: Solid during even Turns. (Turn increments at the end of a turn.)"
		Tiles.PhaseWallGreenOdd:
			text = "Phase Wall Green Odd: Solid during odd Turns. (Turn increments at the end of a turn.)"
		Tiles.NudgeEast:
			text = "Nudge: When time passes, before gravity, attempt to move in this direction."
		Tiles.NudgeNorth:
			text = "Nudge: When time passes, before gravity, attempt to move in this direction."
		Tiles.NudgeSouth:
			text = "Nudge: When time passes, before gravity, attempt to move in this direction."
		Tiles.NudgeWest:
			text = "Nudge: When time passes, before gravity, attempt to move in this direction."
		Tiles.NudgeEastGreen:
			text = "Green Nudge: When time passes, before gravity, ALL actors on this tile attempt to move in this direction."
		Tiles.NudgeNorthGreen:
			text = "Green Nudge: When time passes, before gravity, ALL actors on this tile attempt to move in this direction."
		Tiles.NudgeSouthGreen:
			text = "Green Nudge: When time passes, before gravity, ALL actors on this tile attempt to move in this direction."
		Tiles.NudgeWestGreen:
			text = "Green Nudge: When time passes, before gravity, ALL actors on this tile attempt to move in this direction."
		Tiles.Grate:
			text = "Grate: Solid to unbroken actors."
		Tiles.AntiGrate:
			text = "Anti-Grate: Solid to broken actors."
		Tiles.GhostPlatform:
			text = "Ghost Platform: Solid to gravity moves of non-Character actors."
		Tiles.Propellor:
			text = "Propellor: Hat. (Attaches to an actor entering or starting in the tile below.) That actor doesn't experience gravity, ever."
		Tiles.DurPlus:
			text = "Durability Plus: Modifier. (Attaches to an actor entering or starting in this tile.) On level start, attaches to an actor in this tile. That actor gains +1 Durability. Starting at 0, the Durabilities are: Nothing, Spikes, Fire, Unbreakable."
		Tiles.DurMinus:
			text = "Durability Minus: Modifier. (Attaches to an actor entering or starting in this tile.) That actor gains -1 Durability. Starting at 0, the Durabilities are: Nothing, Spikes, Fire, Unbreakable."
		Tiles.HvyPlus:
			text = "Heaviness Plus: Modifier. (Attaches to an actor entering or starting in this tile.) That actor gains +1 Heaviness. Starting at 0, the Heavinesses are: None, Crystal, Wooden, Iron, Steel, Superheavy, Infinite."
		Tiles.HvyMinus:
			text = "Heaviness Minus: Modifier. (Attaches to an actor entering or starting in this tile.) That actor gains -1 Heaviness. Starting at 0, the Heavinesses are: None, Crystal, Wooden, Iron, Steel, Superheavy, Infinite."
		Tiles.StrPlus:
			text = "Strength Plus: Modifier. (Attaches to an actor entering or starting in this tile.) That actor gains +1 Strength. Starting at 0, the Strengths are: None, Crystal, Wooden, Iron, Steel, Gravity."
		Tiles.StrMinus:
			text = "Strength Minus: Modifier. (Attaches to an actor entering or starting in this tile.) That actor gains -1 Strength. Starting at 0, the Strengths are: None, Crystal, Wooden, Iron, Steel, Gravity."
		Tiles.FallInf:
			text = "Fall Speed Infinite: Modifier. (Attaches to an actor entering or starting in this tile.) That actor's Fall Speed is set to Infinite."
		Tiles.FallOne:
			text = "Fall Speed 1: Modifier. (Attaches to an actor entering or starting in this tile.) That actor's Fall Speed is set to 1. (Additionally, if it's Light, it loses Floating.)"
		Tiles.ColourNative:
			text = "Native Colour: A Colour that will change actors back to their native Time Colour. (For example, a Crate would become Gray, and Light would become Blurple.)";
		Tiles.RepairStation:
			text = "Repair Station: When time passes, after clocks tick, repair an unbroken actor experiencing time in this tile, consuming this."
		Tiles.RepairStationGray:
			text = "Repair Station: When time passes following a move, after clocks tick, repair an unbroken actor in this tile, consuming this."
		Tiles.RepairStationGreen:
			text = "Repair Station: When time passes, after clocks tick, repair an unbroken actor in this tile (greenly), consuming this (greenly)."
		Tiles.ZombieTile:
			text = "Zombie Tile: Broken robots can make moves from this tile."
		Tiles.HeavyMimic:
			text = "Heavy Mimic:  Hat. (Attaches to an actor entering or starting in the tile below.) After Heavy moves, all Heavy Mimics attempt the same move too. (Mimics don't activate time crystals, goals, checkpoints and don't care about one rewind/no rewind/fuzz.)"
		Tiles.LightMimic:
			text = "Light Mimic:  Hat. (Attaches to an actor entering or starting in the tile below.) After Light moves, all Light Mimics attempt the same move too. (Mimics don't activate time crystals, goals, checkpoints and don't care about one rewind/no rewind/fuzz.)"
		Tiles.GhostFog:
			text = "Ghost Fog: If an Actor fails to (not due to gravity) push into this tile, the Actor still moves (thus merging with any Actors already on this tile)."
		Tiles.Eclipse:
			text = "Eclipse: If you make a move or rewind from this tile, time does not pass."
		Tiles.PhaseBoardRed:
			text = "Phase Board Red: A non-destroyable floorboard that exists during Heavy moves and rewinds."
		Tiles.PhaseBoardBlue:
			text = "Phase Board Blue: A non-destroyable floorboard that exists during Light moves and rewinds."
		Tiles.PhaseBoardGray:
			text = "Phase Board Gray: A non-destroyable floorboard that exists during character moves."
		Tiles.PhaseBoardPurple:
			text = "Phase Board Purple: A non-destroyable floorboard that exists during character rewinds."
		Tiles.PhaseBoardDeath:
			text = "Phase Board Death: A non-destroyable floorboard that exists whenever one or both characters are broken. (Mimics and inerts don't count.)"
		Tiles.PhaseBoardLife:
			text = "Phase Board Life: A non-destroyable floorboard that exists whenever both characters are unbroken. (Mimics and inerts don't count.)"
		Tiles.PhaseBoardHeavy:
			text = "Phase Board Heavy: A non-destroyable floorboard that exists whenever the real Heavy is asking."
		Tiles.PhaseBoardLight:
			text = "Phase Board Light: A non-destroyable floorboard that exists whenever the real Light is asking."
		Tiles.PhaseBoardCrate:
			text = "Phase Board Crate: A non-destroyable floorboard that exists whenever any actor besides the real Heavy/Light is asking."
		Tiles.SpiderWeb:
			text = "Spider Web: Solid to non-retro moves exiting this tile if the actor has already non-retro moved 1 or more times this turn.  (+1 for each other Spider Web in this tile.)"
		Tiles.SpiderWebGreen:
			text = "Green Spider Web: Solid to moves exiting this tile if the actor has already moved 1 or more times this turn.  (+1 for each other Green Spider Web in this tile.)"
		Tiles.NoPush:
			text = "No Push: Solid to non-retro pushes."
		Tiles.NoPushGreen:
			text = "Green No Push: Solid to pushes/unpushes."
		Tiles.YesPush:
			text = "Yes Push: Solid to non-retro non-pushes."
		Tiles.YesPushGreen:
			text = "Yes Push Green: Solid to non-(pushes/unpushes)."
		Tiles.NoLeft:
			text = "No Left: Solid to robots that are facing left during non-retro moves."
		Tiles.NoLeftGreen:
			text = "No Left Green: Solid to robots that are facing left."
		Tiles.PhaseBoardVoid:
			text = "Phase Board Void: A non-destroyable floorboard that exists during undos. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.OnewayEastGray:
			text = "Gray One Way: Solid to non-retro moves entering its tile."
		Tiles.OnewayNorthGray:
			text = "Gray One Way: Solid to non-retro moves entering its tile."
		Tiles.OnewaySouthGray:
			text = "Gray One Way: Solid to non-retro moves entering its tile."
		Tiles.OnewayWestGray:
			text = "Gray One Way: Solid to non-retro moves entering its tile."
		Tiles.PinkJelly:
			text = "Pink Jelly: Solid unless this actor has already moved 1 or more times this turn. (+1 for each other Pink Jelly in this tile.)"
		Tiles.CyanJelly:
			text = "Cyan Jelly: Solid unless this actor has already moved and/or bumped 1 or more times this turn. (+1 for each other Cyan Jelly in this tile.)"
		Tiles.PurpleFog:
			text = "Purple Fog: If an actor retro moves into this tile, they phase into any actors on that tile."
		Tiles.Continuum:
			text = "Continuum: If you make a move from this tile at turn 1 or greater, you don't start a new turn but still record all rewind events made. Then, the Continuum is consumed greenly."
		Tiles.Spotlight:
			text = "Spotlight: If you rewind from this tile, the rewind happens as though it were a move (including recording all rewind events made). Then, the Spotlight is consumed greenly."
		Tiles.GateOfEternity:
			text = "Gate of Eternity: Solid. If the game is lost (for example, a Cuckoo Clock chimes): Gates of Eternity become Void and open voidly. (Puzzles containing 'Void' will record undos in their replays.)";
		Tiles.GateOfDemise:
			text = "Gate of Demise: Solid. When a robot is permanently broken (no broken rewind events for that robot or repair stations exist in the puzzle or in any timeline): Gates of Demise become Void and open voidly. (Puzzles containing 'Void' will record undos in their replays.)";
		Tiles.VoidSingularity:
			text = "Void Singularity: When time pases, after repair stations, actors experiencing time here experience a void banish (all undo events for this actor about position, state changes, clock ticking, time colour changes and stat modifiers are erased. Notably, all other kinds of undo events, rewind events, timeline modifications, and changes to tiles caused by this actor are NOT erased.) (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.VoidWall:
			text = "Void Wall: Solid to undo events. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.VoidFire:
			text = "Void Fire: Green Fire, but it breaks voidly, and also activates when time passes following an undo. (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.VoidStars:
			text = "Void Stars: Actors in this tile are immune to banishable undo events (see Void Singularity tooltip). (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.VoidFog:
			text = "Void Fog: Actors in this tile don't create banishable undo events (see Void Singularity tooltip). (Puzzles containing 'Void' will record undos in their replays.)"
		Tiles.NoRising:
			text = "No Rising: Solid to actors in the rising state."
		Tiles.NoFalling:
			text = "No Falling: Solid to actors in the falling state."
		Tiles.NoGrounded:
			text = "No Grounded: Solid to actors in the grounded state."
		Tiles.PhaseBoardEast:
			text = "Phase Board One Way: A non-destroyable floorboard that exists when an actor is attempting to leave or enter this tile by this direction."
		Tiles.PhaseBoardNorth:
			text = "Phase Board One Way: A non-destroyable floorboard that exists when an actor is attempting to leave or enter this tile by this direction."
		Tiles.PhaseBoardSouth:
			text = "Phase Board One Way: A non-destroyable floorboard that exists when an actor is attempting to leave or enter this tile by this direction."
		Tiles.PhaseBoardWest:
			text = "Phase Board One Way: A non-destroyable floorboard that exists when an actor is attempting to leave or enter this tile by this direction."
		Tiles.RepairStationBumper:
			text = "Repair Station Bumper: Solid. Surprise: If the actor is broken, repair it."
		Tiles.Fence:
			text = "Fence: Solid. Surprise: If the actor isn't grounded, it becomes grounded."
		Tiles.Fan:
			text = "Fan: Solid. Surprise: The actor becomes rising."
		Tiles.Bumper:
			text = "Bumper: Solid. Surprise: If the actor can move in the opposite direction, it does."
		Tiles.Passage:
			text = "Passage: Solid. Surprise: If the actor can move again past this (and any subsequent Passages), it does (creating a single rewind event)."
		Tiles.GreenPassage:
			text = "Green Passage: Solid. Surprise: If the actor can move again past this (and any subsequent Green Passages), it does (greenly)."
	return text;
	
func picker_tooltip() -> void:
	var tile = picker.get_cellv(pen_xy);
	var text = tooltip_for_tile(tile);
	pickertooltip.set_rect_size(Vector2(200, 0));
	pickertooltip.change_text(text);
	
	pickertooltip.set_rect_position(gamelogic.adjusted_mouse_position() + Vector2(8, 8));
	pickertooltip.set_rect_size(Vector2(200, pickertooltip.get_rect_size().y));
	if (pickertooltip.get_rect_position().x + 200 > 512):
		pickertooltip.set_rect_size(Vector2(max(100, 512 - pickertooltip.get_rect_position().x), pickertooltip.get_rect_size().y));
	if (pickertooltip.get_rect_position().x + 100 > 512):
		pickertooltip.set_rect_position(Vector2(512-100, pickertooltip.get_rect_position().y));
	if (pickertooltip.get_rect_position().y + pickertooltip.get_rect_size().y > 300):
		pickertooltip.set_rect_position(Vector2(pickertooltip.get_rect_position().x, 300-pickertooltip.get_rect_size().y));
	
func test_level() -> void:
	var result = serialize_current_level();
	if (result != ""):
		gamelogic.end_replay();
		gamelogic.load_custom_level(result);
		gamelogic.test_mode = true;
	destroy();

func toggle_zoom() -> void:
	if (tilemaps.scale == Vector2(1, 1)):
		tilemaps.scale = Vector2(0.5, 0.5);
	else:
		tilemaps.scale = Vector2(1, 1);
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (level_info != null):
		$ColorRect.color = level_info.target_sky;
	
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		if (picker_mode and searchbox.editable):
			menubutton.grab_focus();
		else:
			_menubutton_pressed();
		
	var mouse_position = gamelogic.adjusted_mouse_position();
	if (picker_mode):
		pen.scale = Vector2(1, 1);
	else:
		pen.scale = tilemaps.scale;
	var cell_size = gamelogic.cell_size*pen.scale.x;
	mouse_position.x = cell_size*round((mouse_position.x-cell_size/2)/float(cell_size));
	mouse_position.y = cell_size*round((mouse_position.y-cell_size/2)/float(cell_size));
	pen.position = mouse_position;
	pen_xy = Vector2(round(mouse_position.x/float(cell_size)), round(mouse_position.y/float(cell_size)));
	
	if (picker_mode and searchbox_has_mouse):
		pen.visible = false;
	else:
		pen.visible = true;
	
	if (picker_mode and show_tooltips):
		picker_tooltip();
		
	if (picker_mode and !searchbox.editable):
		if (Input.is_action_just_pressed("start_search")):
			searchbox.visible = true;
			searchbox.grab_focus();
	
	var over_menu_button = false;
	var draw_mode = menubutton.get_draw_mode();
	if (draw_mode == 1 or draw_mode == 3 or draw_mode == 4):
		over_menu_button = true;
	if (!Input.is_mouse_button_pressed(1) and !Input.is_mouse_button_pressed(2)):
		just_picked = false;
	if (Input.is_mouse_button_pressed(1)):
		if !over_menu_button:
			lmb();
	if (Input.is_mouse_button_pressed(2)):
		if !over_menu_button:
			rmb();
	if (Input.is_action_just_released("mouse_wheel_up")):
		picker_cycle(-1);
	if (Input.is_action_just_released("mouse_wheel_down")):
		picker_cycle(1);
		
	if (Input.is_action_just_pressed("tab") and !Input.is_mouse_button_pressed(1) and !Input.is_mouse_button_pressed(2)):
		toggle_picker_mode();
		
	if (!picker_mode):
		if (Input.is_action_just_pressed("copy") and Input.is_action_pressed("ctrl")):
			copy_level();
		if (Input.is_action_just_pressed("paste") and Input.is_action_pressed("ctrl")):
			paste_level();
		if (Input.is_action_just_pressed("test_level")):
			test_level();
		if (Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("nonaxis_left")):
			if (Input.is_action_pressed("shift")):
				shift_layer(terrain_layers[layer_index()], Vector2.LEFT);
			else:
				shift_all_layers(Vector2.LEFT);
		if (Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("nonaxis_right")):
			if (Input.is_action_pressed("shift")):
				shift_layer(terrain_layers[layer_index()], Vector2.RIGHT);
			else:
				shift_all_layers(Vector2.RIGHT);
		if (Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("nonaxis_up")):
			if (Input.is_action_pressed("shift")):
				shift_layer(terrain_layers[layer_index()], Vector2.UP);
			else:
				shift_all_layers(Vector2.UP);
		if (Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("nonaxis_down")):
			if (Input.is_action_pressed("shift")):
				shift_layer(terrain_layers[layer_index()], Vector2.DOWN);
			else:
				shift_all_layers(Vector2.DOWN);
		if (Input.is_action_just_pressed("0")):
			change_layer(9);
		if (Input.is_action_just_pressed("1")):
			change_layer(0);
		if (Input.is_action_just_pressed("2")):
			change_layer(1);
		if (Input.is_action_just_pressed("3")):
			change_layer(2);
		if (Input.is_action_just_pressed("4")):
			change_layer(3);
		if (Input.is_action_just_pressed("5")):
			change_layer(4);
		if (Input.is_action_just_pressed("6")):
			change_layer(5);
		if (Input.is_action_just_pressed("7")):
			change_layer(6);
		if (Input.is_action_just_pressed("8")):
			change_layer(7);
		if (Input.is_action_just_pressed("9")):
			change_layer(8);
		if (Input.is_action_just_pressed("zoom")):
			toggle_zoom();
