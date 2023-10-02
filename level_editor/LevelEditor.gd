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
}

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var menubutton : Button = get_node("MenuButton");
onready var tilemaps : Node2D = get_node("TileMaps");
onready var pen : Sprite = get_node("Pen");
onready var pickerbackground : ColorRect = get_node("PickerBackground");
onready var picker : TileMap = get_node("Picker");
onready var pickertooltip : Node2D = get_node("PickerTooltip");
onready var layerlabel : Label = get_node("LayerLabel");
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menubutton.connect("pressed", self, "_menubutton_pressed");
	
	gamelogic.tile_changes(true);
	
	if (gamelogic.test_mode):
		custom_string = gamelogic.custom_string;
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
	
func initialize_picker_array() -> void:
	var puzzles = gamelogic.puzzles_completed;
	if gamelogic.save_file.has("unlock_everything") and gamelogic.save_file["unlock_everything"]:
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
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[10]):
		picker_array.append(Tiles.TimeCrystalGreen);
		picker_array.append(Tiles.TimeCrystalMagenta);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[11]):
		picker_array.append(Tiles.CuckooClock);
		picker_array.append(Tiles.TheNight);
		picker_array.append(Tiles.TheStars);
	if (puzzles >= gamelogic.chapter_standard_unlock_requirements[12]):
		show_tooltips = true;
		picker_array.append(Tiles.SteelCrate);
		picker_array.append(Tiles.PowerCrate);
		picker_array.append(Tiles.OneUndo);
		picker_array.append(Tiles.NoUndo);
		picker_array.append(Tiles.ColourVoid);
		picker_array.append(Tiles.ColourCyan);
		picker_array.append(Tiles.ColourOrange);
		picker_array.append(Tiles.ColourYellow);
		picker_array.append(Tiles.ColourPurple);
		picker_array.append(Tiles.ColourBlurple);
		picker_array.append(Tiles.ColourWhite);
		picker_array.append(Tiles.VoidSpikeball);
		picker_array.append(Tiles.VoidGlassBlock);
		picker_array.append(Tiles.ChronoHelixBlue);
		picker_array.append(Tiles.ChronoHelixRed);
		picker_array.append(Tiles.HeavyGoalJoke);
		picker_array.append(Tiles.LightGoalJoke);
		picker_array.append(Tiles.PowerSocket);
		picker_array.append(Tiles.GreenPowerSocket);
		picker_array.append(Tiles.VoidPowerSocket);
		picker_array.append(Tiles.GlassBlockCracked);
	
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
	"clock_turns", "map_x_max", "map_y_max", "target_track" #"target_sky"
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
			var path = "res://levels/custom/" + level_info.level_name + ".tscn";
			var error = ResourceSaver.save(path, scene);
			if error != OK:
				floating_text("An error occurred while saving the scene to disk.")
			else:
				floating_text("Saved to " + path);
		deserialized.queue_free();
	
func paste_level() -> void:
	if (!gamelogic.clipboard_contains_level()):
		floating_text("Ctrl+V: Invalid level");
		return
	else:
		deserialize_custom_level(OS.get_clipboard());
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
	
func picker_tooltip() -> void:
	var tile = picker.get_cellv(pen_xy);
	var text = "";
	if (tile == -1):
		text = "";
	elif (tile == Tiles.HeavyIdle):
		text = "Heavy: Actor. Character. Heaviness: Steel. Strength: Steel. Durability: Spikes. Fall speed: 2.  Native Time Colour: Purple. Doesn't float (immediately starts falling when ungrounded or moving down onto a non-ladder, no air control when falling). Climbs. Sticky top: After making a forward move, anything that was in the tile above it mimics the move."
	elif (tile == Tiles.LightIdle):
		text = "Light: Actor. Character. Heaviness: Iron. Strength: Iron. Durability: Nothing. Fall speed: 1. Native Time Colour: Blurple. Floats (if grounded and could fall, enters rising state. When moving down, remains grounded. Has air control while falling.) Climbs. Clumsy (loses one strength when indirectly pushed)."
	elif (tile == Tiles.HeavyGoal):
		text = "Heavy Goal: At end of turn, if unbroken Heavy is on a Heavy Goal and unbroken Light is on a Light Goal, you win."
	elif (tile == Tiles.LightGoal):
		text = "Light Goal: At end of turn, if unbroken Heavy is on a Heavy Goal and unbroken Light is on a Light Goal, you win."
	elif (tile == Tiles.Wall):
		text = "Wall: Solid."
	elif (tile == Tiles.Spikeball):
		text = "Spikeball: Solid. Surprise: If the actor doesn't have Spikes or greater Durability, it breaks. (Surprises trigger on failure to enter, and aren't stable ground if they'd do something.)"
	elif (tile == Tiles.Fire):
		text = "Fire: When an actor experiences time, after gravity, if it's on Fire and doesn't have Fire or greater Durability, it breaks."
	elif (tile == Tiles.HeavyFire):
		text = "Heavy Fire: Fire, but it can only break Heavy."
	elif (tile == Tiles.LightFire):
		text = "Light Fire: Fire, but it can only break Light."
	elif (tile == Tiles.NoHeavy):
		text = "No Heavy: Solid to Heavy."
	elif (tile == Tiles.NoLight):
		text = "No Light: Solid to Light."
	elif (tile == Tiles.OnewayEast):
		text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
	elif (tile == Tiles.OnewayNorth):
		text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
	elif (tile == Tiles.OnewaySouth):
		text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
	elif (tile == Tiles.OnewayWest):
		text = "One Way: Solid to forward moves entering its tile, solid to retroactive moves exiting its tile."
	elif (tile == Tiles.OnewayEastGreen):
		text = "Green One Way: Solid to moves entering its tile."
	elif (tile == Tiles.OnewayNorthGreen):
		text = "Green One Way: Solid to moves entering its tile."
	elif (tile == Tiles.OnewaySouthGreen):
		text = "Green One Way: Solid to moves entering its tile."
	elif (tile == Tiles.OnewayWestGreen):
		text = "Green One Way: Solid to moves entering its tile."
	elif (tile == Tiles.Ladder):
		text = "Ladder: Actors that can climb and aren't broken are supported in this tile (they become and remain grounded)."
	elif (tile == Tiles.WoodenPlatform):
		text = "Trapdoor: Solid to gravity moves."
	elif (tile == Tiles.LadderPlatform):
		text = "Ladder + Trapdoor: Combines the properties of the two tiles. (I made it before layers existed.)"
	elif (tile == Tiles.OnewayEastPurple):
		text = "Purple One Way: Solid to retroactive moves entering its tile."
	elif (tile == Tiles.OnewayNorthPurple):
		text = "Purple One Way: Solid to retroactive moves entering its tile."
	elif (tile == Tiles.OnewaySouthPurple):
		text = "Purple One Way: Solid to retroactive moves entering its tile."
	elif (tile == Tiles.OnewayWestPurple):
		text = "Purple One Way: Solid to retroactive moves entering its tile."
	elif (tile == Tiles.IronCrate):
		text = "Iron Crate: Actor. Heaviness: Iron. Strength: Wood. Durability: Spikes. Fall speed: Infinite. Native Time Colour: Gray."
	elif (tile == Tiles.CrateGoal):
		text = "Crate Goal: If you would win due to Light and Heavy being on Goals: You do not unless every Crate Goal has a non-Character actor on its tile."
	elif (tile == Tiles.NoCrate):
		text = "No Crate: Solid to non-Character actors."
	elif (tile == Tiles.ColourRed):
		text = "Red: Colour. (Place a Colour in the same tile as an actor to assign it to the first actor in reading order.) Experiences time when Heavy moves."
	elif (tile == Tiles.ColourBlue):
		text = "Blue: Colour. (Place a Colour in the same tile as an actor to assign it to the first actor in reading order.) Experiences time when Light moves."
	elif (tile == Tiles.ColourGray):
		text = "Gray: Colour. (Place a Colour in the same tile as an actor to assign it to the first actor in reading order.) Experiences time during moves."
	elif (tile == Tiles.ColourMagenta):
		text = "Magenta: Colour. (Place a Colour in the same tile as an actor to assign it to the first actor in reading order.) Always experiences time."
	elif (tile == Tiles.WoodenCrate):
		text = "Wooden Crate: Actor. Heaviness: Wood. Strength: Wood. Durability: Nothing. Fall speed: Infinite. Native Time Colour: Gray. When unbroken Light fails to push an unstacked Wooden Crate, Light tries again by pushing it up instead. When unbroken Heavy fails to push an unstacked Wooden Crate, Heavy tries again by breaking it instead."
	elif (tile == Tiles.GlassBlock):
		text = "Glass Block: Solid to moves entering or exiting its tile. Surprise: If the actor is Iron weight or greater, the Glass Block breaks. When a Glass Block unbreaks, it breaks any actors that don't have Unbreakable durability."
	elif (tile == Tiles.ColourGreen):
		text = "Green: Colour. Always experiences time. Immune to character undo events."
	elif (tile == Tiles.GreenSpikeball):
		text = "Green Spikeball: A Spikeball that does not create character undo events."
	elif (tile == Tiles.GreenFire):
		text = "Green Fire: A Fire that activates after regular Fires even for actors not experiencing time and does not create character undo events."
	elif (tile == Tiles.GreenGlassBlock):
		text = "Green Glass Block: A Glass Block that does not create character undo events."
	elif (tile == Tiles.Fuzz):
		text = "Fuzz: When a character undoes while inside Fuzz, the Fuzz is consumed (creating only a meta undo event), the undo happens but is not consumed, and time does not pass."
	elif (tile == Tiles.OneUndo):
		text = "One Undo: When a character undoes while inside One Undo, one of them is replaced with a No Undo (creating only a meta undo event)."
	elif (tile == Tiles.NoUndo):
		text = "No Undo: When a character undoes while inside No Undo and on no One Undos, it is prevented and nothing happens."
	elif (tile == Tiles.TimeCrystalGreen):
		text = "Green Time Crystal: Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Green. Time Crystals existing locks goals. When consumed by an unbroken Cuckoo Clock: Increase ticks by 1. When consumed by a Character: If the character has no locked moves: Increase turn limit by 1. Else, unlock the most recently locked move and place it on the end of the character's filled timeline."
	elif (tile == Tiles.TimeCrystalMagenta):
		text = "Magenta Time Crystal: Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Green. Time Crystals existing locks goals. When consumed by an unbroken Cuckoo Clock: Decrease ticks by 1. When consumed by a Character: If the character's turn limit is 0: You lose. Else, if the character is filling a timeline slot: Lock it. Else, if the character has a filled timeline slot: Lock the highest numbered one. Else, lock an empty timeline slot."
	elif (tile == Tiles.CuckooClock):
		text = "Cuckoo Clock: Actor. Heaviness: Wooden. Strength: Wooden. Durability: Nothing. Fall speed: 1. Native Time Colour: Gray. To start a puzzle with ticks: Fill out Clock Turns field with a comma separated list, and turns will be assigned to clocks in layer+reading order. When experiencing time, after green fire, if it has ticks and isn't broken, decrease ticks by 1. Whenever a cuckoo clock's ticks are 0: You lose."
	elif (tile == Tiles.TheNight):
		text = "Night: Actors inside Night don't experience time passing (except for being burned by fire and green fire)."
	elif (tile == Tiles.TheStars):
		text = "Stars: Actors inside Stars are immune to character undo events."
	elif (tile == Tiles.SteelCrate):
		text = "Steel Crate: Actor. Heaviness: Steel. Strength: Iron. Durability: Fire. Fall speed: Infinite. Native Time Colour: Gray. When a unbroken Steel Crate fails to move into an unstacked unbroken Light or Cuckoo Clock, the target first breaks."
	elif (tile == Tiles.PowerCrate):
		text = "Power Crate: Actor. Heaviness: Wooden. Strength: Steel. Durability: Spikes. Fall speed: Infinite. Native Time Colour: Gray."
	elif (tile == Tiles.ColourVoid):
		text = "Void: Colour. Always experiences time, INCLUDING after meta undos. Immune to character undo AND meta undo events. (Puzzles containing 'Void' will record meta-undos in their replays.)"
	elif (tile == Tiles.ColourCyan):
		text = "Cyan: Colour. Experiences time when Light moves or undoes."
	elif (tile == Tiles.ColourOrange):
		text = "Orange: Colour. Experiences time when Heavy moves or undoes."
	elif (tile == Tiles.ColourYellow):
		text = "Yellow: Colour. Experiences time during undos."
	elif (tile == Tiles.ColourPurple):
		text = "Purple: Colour. Experiences time except when Heavy undoes."
	elif (tile == Tiles.ColourBlurple):
		text = "Blurple: Colour. Experiences time except when Light undoes."
	elif (tile == Tiles.ColourWhite):
		text = "White: Colour. Never experiences time."
	elif (tile == Tiles.VoidSpikeball):
		text = "Void Spikeball: A Spikeball that does not create character undo OR meta undo events. (Puzzles containing 'Void' will record meta-undos in their replays.)"
	elif (tile == Tiles.VoidGlassBlock):
		text = "Void Glass Block: A Glass Block that does not create character undo OR meta undo events. (Puzzles containing 'Void' will record meta-undos in their replays.)"
	elif (tile == Tiles.ChronoHelixBlue):
		text = "Chrono Helix Blue: Actor. Heaviness: Iron. Strength: Steel. Durability: Unbreakable. Fall speed: 1. Native Time Colour: Gray. When experiencing time, after gravity and before fire, if 8-way adjacent to a Chrono Helix Red, both move away from each other. When bumped with a Chrono Helix Red, you win."
	elif (tile == Tiles.ChronoHelixRed):
		text = "Chrono Helix Red: Actor. Heaviness: Iron. Strength: Steel. Durability: Unbreakable. Fall speed: 1. Native Time Colour: Gray. When experiencing time, after gravity and before fire, if 8-way adjacent to a Chrono Helix Blue, both move away from each other. When bumped with a Chrono Helix Blue, you win."
	elif (tile == Tiles.HeavyGoalJoke):
		text = "Heavy Goal (Joke): Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Gray. Not solid. Counts as a Heavy Goal. Phases through terrain and actors."
	elif (tile == Tiles.LightGoalJoke):
		text = "Light Goal (Joke): Actor. Heaviness: Crystal. Strength: Crystal. Durability: Unbreakable. Fall speed: 0. Native Time Colour: Gray. Not solid. Counts as a Light Goal. Phases through terrain and actors."
	elif (tile == Tiles.PowerSocket):
		text = "Power Socket: A Spikeball that specifically breaks Characters."
	elif (tile == Tiles.GreenPowerSocket):
		text = "Green Power Socket: A Power Socket that does not create character undo events."
	elif (tile == Tiles.VoidPowerSocket):
		text = "Void Power Socket: A Power Socket that does not create character undo OR meta undo events. (Puzzles containing 'Void' will record meta-undos in their replays.)"
	elif (tile == Tiles.GlassBlockCracked):
		text = "Cracked Glass Block: A Glass Block without the weight requirement."
	else:
		text = "";
	pickertooltip.change_text(text);
	
	pickertooltip.set_rect_position(get_global_mouse_position() + Vector2(8, 8));
	pickertooltip.set_rect_size(Vector2(200, pickertooltip.get_rect_size().y));
	if (pickertooltip.get_rect_position().x + 200 > 512):
		pickertooltip.set_rect_size(Vector2(max(100, 512 - pickertooltip.get_rect_position().x), pickertooltip.get_rect_size().y));
	if (pickertooltip.get_rect_position().x + 100 > 512):
		pickertooltip.set_rect_position(Vector2(512-100, pickertooltip.get_rect_position().y));
	
func test_level() -> void:
	var result = serialize_current_level();
	if (result != ""):
		gamelogic.load_custom_level(result);
		gamelogic.test_mode = true;
	destroy();

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
	
	if (picker_mode and show_tooltips):
		picker_tooltip();
	
	var over_menu_button = false;
	if (Rect2(menubutton.rect_position, menubutton.rect_size).has_point(get_global_mouse_position())):
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
	if (Input.is_action_just_pressed("copy") and Input.is_action_pressed("ctrl")):
		copy_level();
	if (Input.is_action_just_pressed("paste") and Input.is_action_pressed("ctrl")):
		paste_level();
	if (Input.is_action_just_pressed("test_level")):
		test_level();
	if (Input.is_action_just_pressed("ui_left")):
		if (Input.is_action_pressed("shift")):
			shift_layer(terrain_layers[layer_index()], Vector2.LEFT);
		else:
			shift_all_layers(Vector2.LEFT);
	if (Input.is_action_just_pressed("ui_right")):
		if (Input.is_action_pressed("shift")):
			shift_layer(terrain_layers[layer_index()], Vector2.RIGHT);
		else:
			shift_all_layers(Vector2.RIGHT);
	if (Input.is_action_just_pressed("ui_up")):
		if (Input.is_action_pressed("shift")):
			shift_layer(terrain_layers[layer_index()], Vector2.UP);
		else:
			shift_all_layers(Vector2.UP);
	if (Input.is_action_just_pressed("ui_down")):
		if (Input.is_action_pressed("shift")):
			shift_layer(terrain_layers[layer_index()], Vector2.DOWN);
		else:
			shift_all_layers(Vector2.DOWN);
	if (Input.is_action_just_pressed("tab") and !Input.is_mouse_button_pressed(1) and !Input.is_mouse_button_pressed(2)):
		toggle_picker_mode();
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
		
