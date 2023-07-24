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
}

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var menubutton : Button = get_node("MenuButton");
onready var tilemaps : Node2D = get_node("TileMaps");
onready var pen : Sprite = get_node("Pen");
onready var PickerBackground : ColorRect = get_node("PickerBackground");
onready var Picker : TileMap = get_node("Picker");
var custom_string = "";
var level_info : LevelInfo = null;
var pen_tile = Tiles.Wall;
var pen_layer = 0;
var terrain_layers = [];
var pen_xy = Vector2.ZERO;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menubutton.connect("pressed", self, "_menubutton_pressed");
	
	gamelogic.tile_changes(true);
	
	custom_string = gamelogic.serialize_current_level();
	var level = gamelogic.deserialize_custom_level(custom_string);
	tilemaps.add_child(level);
	level_info = level.get_node("LevelInfo");

	terrain_layers.append(level);
	for child in level.get_children():
		if child is TileMap:
			terrain_layers.push_front(child);
			
	change_pen_tile(); # must happen after level setup

func serialize_current_level() -> String:
	# keep in sync with GameLogic.gd serialize_current_level()
	
	# TODO:
	# and it needs to do sanity checks and metadata setup like: squash layers down,
	# squash puzzles to the topleft, trim bottom right, trim negative x/y tiles
	var result = "EntwinedTimePuzzleStart\n";
	var level_metadata = {};
	var metadatas = ["level_name", "level_author", "level_replay", "heavy_max_moves", "light_max_moves",
	"clock_turns", "map_x_max", "map_y_max", #"target_sky"
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
	return result;

func copy_level() -> void:
	var result = serialize_current_level();
	floating_text("Ctrl+C: Level copied to clipboard!");
	OS.set_clipboard(result);

func change_pen_tile() -> void:
	var tile_set = tilemaps.get_child(0).tile_set;
	pen.texture = tile_set.tile_get_texture(pen_tile);
	# handle auto-tile wall icon
	if (pen_tile == Tiles.Wall):
		var coord = tile_set.autotile_get_icon_coordinate(pen_tile);
		pen.region_enabled = true;
		pen.region_rect = Rect2(coord*gamelogic.cell_size, Vector2(gamelogic.cell_size, gamelogic.cell_size));
	else:
		pen.region_enabled = false;
	
	if pen.texture == null:
		pen.texture = preload("res://assets/targeter.png");
		pen.offset = Vector2(-1, -1);
	else:
		pen.offset = Vector2.ZERO;

func lmb() -> void:
	terrain_layers[pen_layer].set_cellv(pen_xy, pen_tile);
	terrain_layers[pen_layer].update_bitmask_area(pen_xy);

func rmb() -> void:
	pen_tile = terrain_layers[pen_layer].get_cellv(pen_xy);
	change_pen_tile();

func _menubutton_pressed() -> void:
	var a = preload("res://level_editor/LevelEditorMenu.tscn").instance();
	add_child(a);
	gamelogic.ui_stack.push_back(a);

func destroy() -> void:
	gamelogic.tile_changes(false);
	self.queue_free();
	gamelogic.ui_stack.erase(self);

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	self.add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = gamelogic.pixel_width;
	label.rect_position.y = gamelogic.pixel_height/2-16;
	label.text = text;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		_menubutton_pressed();
		
	var mouse_position = get_global_mouse_position();
	# probably needs some offset, I'll do the math
	mouse_position.x = gamelogic.cell_size*round((mouse_position.x-gamelogic.cell_size/2)/float(gamelogic.cell_size));
	mouse_position.y = gamelogic.cell_size*round((mouse_position.y-gamelogic.cell_size/2)/float(gamelogic.cell_size));
	pen.position = mouse_position;
	pen_xy = Vector2(round(mouse_position.x/float(gamelogic.cell_size)), round(mouse_position.y/float(gamelogic.cell_size)));
	
	if (Input.is_mouse_button_pressed(1)):
		lmb();
	elif (Input.is_mouse_button_pressed(2)):
		rmb();
	elif (Input.is_action_just_pressed("copy") and Input.is_action_pressed("ctrl")):
		copy_level();
