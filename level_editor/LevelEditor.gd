extends Node2D
class_name LevelEditor

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	custom_string = gamelogic.serialize_current_level();
	var level = gamelogic.deserialize_custom_level(custom_string);
	menubutton.connect("pressed", self, "_menubutton_pressed");
	tilemaps.add_child(level);
	level_info = level.get_node("LevelInfo");
	gamelogic.tile_changes(true);
	change_pen_tile();

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

func _menubutton_pressed() -> void:
	var a = preload("res://level_editor/LevelEditorMenu.tscn").instance();
	add_child(a);
	gamelogic.ui_stack.push_back(a);

func destroy() -> void:
	gamelogic.tile_changes(false);
	self.queue_free();
	gamelogic.ui_stack.erase(self);

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
