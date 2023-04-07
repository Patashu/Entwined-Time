extends Node
class_name GameLogic

var debug_prints = false;

onready var levelscene : Node2D = get_node("/root/LevelScene");
onready var actorsfolder : Node2D = levelscene.get_node("ActorsFolder");
onready var ghostsfolder : Node2D = levelscene.get_node("GhostsFolder");
onready var levelfolder : Node2D = levelscene.get_node("LevelFolder");
onready var terrainmap : TileMap = levelfolder.get_node("TerrainMap");
onready var controlslabel : Label = levelscene.get_node("ControlsLabel");
onready var levellabel : Label = levelscene.get_node("LevelLabel");
onready var winlabel : Label = levelscene.get_node("WinLabel");
onready var heavyinfolabel : Label = levelscene.get_node("HeavyInfoLabel");
onready var lightinfolabel : Label = levelscene.get_node("LightInfoLabel");
onready var metainfolabel : Label = levelscene.get_node("MetaInfoLabel");
onready var targeter : Sprite = levelscene.get_node("Targeter")
onready var heavytimeline : Node2D = levelscene.get_node("HeavyTimeline");
onready var lighttimeline : Node2D = levelscene.get_node("LightTimeline");

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
	FEEBLE
	LIGHT
	HEAVY
	GRAVITY
}

# distinguish between different heaviness. Light is IRON and Heavy is STEEL.
enum Heaviness {
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
	move,
	set_actor_var,
	heavy_turn,
	light_turn,
	heavy_undo_event_add,
	light_undo_event_add,
	heavy_undo_event_remove,
	light_undo_event_remove,
}

# and same for animations
enum Animation {
	move,
	bump,
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
var map_x_max : int = 0;
var map_y_max : int = 0;
var map_x_max_max : int = 21;
var map_y_max_max : int = 10; # is this cramped?, if it is then I can just add screen scrolling

# information about the actors and their state
var heavy_actor : Actor = null
var light_actor : Actor = null
var actors = []
var heavy_turn = 0;
var heavy_undo_buffer : Array = [];
var light_turn = 0;
var light_undo_buffer : Array = [];
var meta_turn = 0;
var meta_undo_buffer : Array = [];
var heavy_selected = true;

# for undo trail ghosts
var ghosts = []

# song-and-dance state
var timer = 0;
var sounds = {}
var speakers = [];
var muted = false;
var won = false;
var cell_size = 24;
var undo_effect_strength = 0;
var undo_effect_per_second = 0;
var undo_effect_color = Color(0, 0, 0, 0);
var heavy_color = Color(1.0, 0, 0, 1);
var light_color = Color(0, 0.58, 1.0, 1);
var meta_color = Color(0.5, 0.5, 0.5, 1);
var ui_stack = [];

#replay system
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
var chapter_standard_starting_levels = [];
var chapter_advanced_starting_levels = [];

func _ready() -> void:
	# Call once when the game is booted up.
	initialize_level_list();
	prepare_audio();
	assert_tile_enum();
	
	# Load the first map.
	load_level(0);
	
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
	level_list.push_back(preload("res://levels/Initiation.tscn"));
	level_list.push_back(preload("res://levels/Orientation.tscn"));
	level_list.push_back(preload("res://levels/Wall.tscn"));
	level_list.push_back(preload("res://levels/Tall.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPit.tscn"));	
	level_list.push_back(preload("res://levels/CallACab.tscn"));
	level_list.push_back(preload("res://levels/ShouldveCalledaCab.tscn"));
	level_list.push_back(preload("res://levels/Pachinko.tscn"));
	level_list.push_back(preload("res://levels/Roommates.tscn"));
	level_list.push_back(preload("res://levels/UncabYourself.tscn"));
	level_list.push_back(preload("res://levels/Downhill.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/Spelunking.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPitEx.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPitEx2.tscn"));
	level_list.push_back(preload("res://levels/Graduation.tscn"));
	
	chapter_names.push_back("Hazards");
	chapter_standard_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/SnakePit.tscn"));
	level_list.push_back(preload("res://levels/Firewall.tscn"));
	level_list.push_back(preload("res://levels/UnderDestination.tscn"));
	level_list.push_back(preload("res://levels/UnderDestinationEx.tscn"));
	level_list.push_back(preload("res://levels/Acrobatics.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/SnakePitEx.tscn"));
	level_list.push_back(preload("res://levels/SnakePitEx2.tscn"));
	level_list.push_back(preload("res://levels/FirewallEx.tscn"));
	level_list.push_back(preload("res://levels/FirewallEx2.tscn"));
	level_list.push_back(preload("res://levels/AcrobaticsEx.tscn"));
	
	chapter_names.push_back("Platforming");
	chapter_standard_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/PeekaBoo.tscn"));
	level_list.push_back(preload("res://levels/SecurityDoor.tscn"));
	level_list.push_back(preload("res://levels/Jail.tscn"));
	level_list.push_back(preload("res://levels/Upstream.tscn"));
	level_list.push_back(preload("res://levels/EventHorizon.tscn"));
	level_list.push_back(preload("res://levels/LadderWorld.tscn"));
	level_list.push_back(preload("res://levels/LadderLattice.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinet.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/SecurityDoorEx.tscn"));
	level_list.push_back(preload("res://levels/JailEx.tscn"));
	level_list.push_back(preload("res://levels/JailEx2.tscn"));
	level_list.push_back(preload("res://levels/FirewallEx3.tscn"));
	level_list.push_back(preload("res://levels/LadderLatticeEx.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinetEx.tscn"));
	level_list.push_back(preload("res://levels/TrophyCabinetEx2.tscn"));
	level_list.push_back(preload("res://levels/HawkingRadiation.tscn"));
	
	chapter_names.push_back("Iron Crates");
	chapter_standard_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/SteppingStool.tscn"));
	level_list.push_back(preload("res://levels/TheSecondPit.tscn"));
	level_list.push_back(preload("res://levels/OverDestination.tscn"));
	level_list.push_back(preload("res://levels/Landfill.tscn"));
	level_list.push_back(preload("res://levels/SnakeChute.tscn"));
	
	chapter_advanced_starting_levels.push_back(level_list.size());
	level_list.push_back(preload("res://levels/OverDestinationEx.tscn"));
	level_list.push_back(preload("res://levels/TheSecondPitEx.tscn"));
	level_list.push_back(preload("res://levels/SteppingStoolEx.tscn"));
	level_list.push_back(preload("res://levels/LandfillEx.tscn"));
	level_list.push_back(preload("res://levels/TheSecondPitEx2.tscn"));
	level_list.push_back(preload("res://levels/AcrobatsEscape.tscn"));
	level_list.push_back(preload("res://levels/AcrobatsEscapeEx.tscn"));
	
	# sentinel to make overflow checks easy
	chapter_standard_starting_levels.push_back(level_list.size());
	chapter_advanced_starting_levels.push_back(level_list.size());
	
	# WORLD 4 - Tools of the Trade
	# WORLD 5 - There are many Colours
	# WORLD 6 - What is This?
	# WORLD X - Trial of your Peers (custom levels world)
	#level_list.push_back(preload("res://levels/Levitation.tscn"));
	
	for level_prototype in level_list:
		var level = level_prototype.instance();
		level_names.push_back(level.get_child(0).level_name);

func ready_map() -> void:
	for actor in actors:
		actor.queue_free();
	actors.clear();
	for ghost in ghosts:
		ghost.queue_free();
	ghosts.clear();
	heavy_turn = 0;
	heavy_undo_buffer.clear();
	light_turn = 0;
	light_undo_buffer.clear();
	meta_turn = 0;
	meta_undo_buffer.clear();
	heavy_selected = true;
	user_replay = "";
	
	level_name = terrainmap.get_child(0).level_name;
	level_author = terrainmap.get_child(0).level_author;
	level_replay = terrainmap.get_child(0).level_replay;
	heavy_max_moves = terrainmap.get_child(0).heavy_max_moves;
	light_max_moves = terrainmap.get_child(0).light_max_moves;
	calculate_map_size();
	make_actors();
	
	finish_animations();
	update_info_labels();
	check_won();
	
	initialize_timeline_viewers();
	
func initialize_timeline_viewers() -> void:
	heavytimeline.is_heavy = true;
	lighttimeline.is_heavy = false;
	heavytimeline.max_moves = heavy_max_moves;
	lighttimeline.max_moves = light_max_moves;
	heavytimeline.reset();
	lighttimeline.reset();

func make_actors() -> void:
	# find heavy and light and turn them into actors
	var heavy_id = terrainmap.tile_set.find_tile_by_name("HeavyIdle");
	var heavy_tile = terrainmap.get_used_cells_by_id(heavy_id)[0];
	terrainmap.set_cellv(heavy_tile, -1);
	heavy_actor = make_actor("heavy", heavy_tile);
	heavy_actor.heaviness = Heaviness.STEEL;
	heavy_actor.strength = Strength.HEAVY;
	heavy_actor.durability = Durability.FIRE;
	heavy_actor.fall_speed = 2;
	heavy_actor.climbs = true;
	heavy_actor.is_character = true;
	heavy_actor.color = heavy_color;
	heavy_actor.powered = heavy_max_moves != 0;
	heavy_actor.update_graphics();
	var light_id = terrainmap.tile_set.find_tile_by_name("LightIdle");
	var light_tile = terrainmap.get_used_cells_by_id(light_id)[0];
	terrainmap.set_cellv(light_tile, -1);
	light_actor = make_actor("light", light_tile);
	light_actor.heaviness = Heaviness.IRON;
	light_actor.strength = Strength.LIGHT;
	light_actor.durability = Durability.SPIKES;
	light_actor.fall_speed = 1;
	light_actor.climbs = true;
	light_actor.is_character = true;
	light_actor.color = light_color;
	light_actor.powered = light_max_moves != 0;
	light_actor.update_graphics();
	
	# other actors
	extract_actors("IronCrate", "iron_crate", Heaviness.IRON, Strength.FEEBLE, Durability.FIRE, -1, false, Color(0.5, 0.5, 0.5, 1));
	extract_actors("SteelCrate", "steel_crate", Heaviness.STEEL, Strength.FEEBLE, Durability.PITS, -1, false, Color(0.25, 0.25, 0.25, 1));
	
func extract_actors(tilename: String, actorname: String, heaviness: int, strength: int, durability: int, fall_speed: int, climbs: bool, color: Color) -> void:
	var id = terrainmap.tile_set.find_tile_by_name(tilename);
	var tiles = terrainmap.get_used_cells_by_id(id);
	for tile in tiles:
		terrainmap.set_cellv(tile, -1);
		var actor = make_actor(actorname, tile);
		actor.heaviness = heaviness;
		actor.strength = strength;
		actor.durability = durability;
		actor.fall_speed = fall_speed;
		actor.climbs = climbs;
		actor.is_character = false;
		actor.color = color;
		actor.update_graphics();
	
func calculate_map_size() -> void:
	map_x_max = 0;
	map_y_max = 0;
	var tiles = terrainmap.get_used_cells();
	for tile in tiles:
		if tile.x > map_x_max:
			map_x_max = tile.x;
		if tile.y > map_y_max:
			map_y_max = tile.y;
	terrainmap.position.x = (map_x_max_max-map_x_max)*(cell_size/2)-8; # no idea why -16
	terrainmap.position.y = (map_y_max_max-map_y_max)*(cell_size/2); # will adjust after timeline UI is in
	actorsfolder.position = terrainmap.position;
	ghostsfolder.position = terrainmap.position;
		
func update_targeter() -> void:
	if (heavy_selected and heavy_actor != null):
		targeter.position = heavy_actor.position + terrainmap.position;
	elif (light_actor != null):
		targeter.position = light_actor.position + terrainmap.position;
		
func prepare_audio() -> void:
	# TODO: I could automate this if I can iterate the folder
	# TODO: replace this with an enum and assert on startup like tiles
	sounds["bump"] = preload("res://sfx/bump.ogg");
	sounds["dig"] = preload("res://sfx/dig.ogg");
	sounds["fly"] = preload("res://sfx/fly.ogg");
	sounds["getgreenality"] = preload("res://sfx/getgreenality.ogg");
	sounds["greeninteract"] = preload("res://sfx/greeninteract.ogg");
	sounds["greenplayer"] = preload("res://sfx/greenplayer.ogg");
	sounds["greensmall"] = preload("res://sfx/greensmall.ogg");
	sounds["key"] = preload("res://sfx/key.ogg");
	sounds["kill"] = preload("res://sfx/kill.ogg");
	sounds["metarestart"] = preload("res://sfx/metarestart.ogg");
	sounds["metaundo"] = preload("res://sfx/metaundo.ogg");
	sounds["pickup"] = preload("res://sfx/pickup.ogg");
	sounds["restart"] = preload("res://sfx/restart.ogg");
	sounds["step"] = preload("res://sfx/step.ogg");
	sounds["switch"] = preload("res://sfx/switch.ogg");
	sounds["undo"] = preload("res://sfx/undo.ogg");
	sounds["unlock"] = preload("res://sfx/unlock.ogg");
	sounds["usegreenality"] = preload("res://sfx/usegreenality.ogg");
	sounds["wingreen"] = preload("res://sfx/wingreen.ogg");
	sounds["winnormal"] = preload("res://sfx/winnormal.ogg");
	sounds["winpickaxe"] = preload("res://sfx/winpickaxe.ogg");
	sounds["winwings"] = preload("res://sfx/winwings.ogg");
	
	for i in range (8):
		var speaker = AudioStreamPlayer.new();
		self.add_child(speaker);
		speakers.append(speaker);

func cut_sound() -> void:
	for speaker in speakers:
		speaker.stop();

func play_sound(sound: String) -> void:
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	for speaker in speakers:
		if !speaker.playing:
			speaker.stream = sounds[sound];
			speaker.play();
			return;

func toggle_mute() -> void:
	muted = !muted;
	cut_sound();

func make_actor(actorname: String, pos: Vector2, chrono: int = Chrono.TIMELESS) -> Actor:
	var actor = Actor.new();
	actor.actorname = actorname;
	actor.offset = Vector2(cell_size/2, cell_size/2);
	actors.append(actor);
	actorsfolder.add_child(actor);
	move_actor_to(actor, pos, chrono, false, false);
	if (chrono < Chrono.META_UNDO):
		print("TODO")
	return actor;
	
func move_actor_relative(actor: Actor, dir: Vector2, chrono: int, hypothetical: bool, is_gravity: bool, is_retro: bool = false, pushers_list: Array = []) -> int:
	if (chrono == Chrono.GHOSTS):
		var ghost = get_ghost_that_hasnt_moved(actor);
		ghost.ghost_dir = -dir;
		ghost.pos = ghost.previous_ghost.pos + dir;
		ghost.position = terrainmap.map_to_world(ghost.pos);
		return Success.Yes;
	
	return move_actor_to(actor, actor.pos + dir, chrono, hypothetical, is_gravity, is_retro, pushers_list);
	
func move_actor_to(actor: Actor, pos: Vector2, chrono: int, hypothetical: bool, is_gravity: bool, is_retro: bool = false, pushers_list: Array = []) -> int:
	var dir = pos - actor.pos;
	
	var success = try_enter(actor, dir, chrono, true, hypothetical, is_gravity, is_retro, pushers_list);
	if (success == Success.Yes and !hypothetical):
		add_undo_event([Undo.move, actor, dir], chrono);
		actor.pos = pos;
		actor.animations.push_back([Animation.move, dir]);
		# Sticky top: When Heavy moves non-up at Chrono.MOVE, an actor on top of it will try to move too afterwards.
		#(AD03: Chrono.CHAR_UNDO will sticky top green things but not the other character because I don't like the spring effect it'd cause)
		#(AD05: apparently I decided the sticky top can't move things you can't push, which is... valid ig?)
		if actor.actorname == "heavy" and chrono == Chrono.MOVE and dir.y >= 0:
			var sticky_actors = actors_in_tile(actor.pos - dir + Vector2.UP);
			for sticky_actor in sticky_actors:
				if (strength_check(actor.strength, sticky_actor.heaviness)):
					move_actor_relative(sticky_actor, dir, chrono, hypothetical, false);
		return success;
	elif (success != Success.Yes and !hypothetical):
		actor.animations.push_back([Animation.bump, dir]);
	return success;
		
func adjust_turn(is_heavy: bool, amount: int, chrono : int) -> void:
	if (is_heavy):
		if (amount > 0):
			heavytimeline.add_turn(heavy_undo_buffer[heavy_turn]);
		else:
			var color = heavy_color;
			if (chrono >= Chrono.META_UNDO):
				color = meta_color;
			heavytimeline.remove_turn(color);
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
			lighttimeline.add_turn(light_undo_buffer[light_turn]);
		else:
			var color = light_color;
			if (chrono >= Chrono.META_UNDO):
				color = meta_color;
			lighttimeline.remove_turn(color);
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
	
func terrain_in_tile(pos: Vector2) -> int:
	return terrainmap.get_cellv(pos);

func terrain_is_solid(actor: Actor, pos: Vector2, dir: Vector2, is_gravity: bool, is_retro: bool = false) -> bool:
	var id = terrain_in_tile(pos);
	if id == Tiles.Wall || id == Tiles.LockClosed || id == Tiles.Spikeball:
		return true;
	if id == Tiles.NoHeavy:
		return actor.actorname == "heavy";
	if (id == Tiles.NoLight):
		return actor.actorname == "light";
	if id == Tiles.Grate:
		return actor.is_character;
	if id == Tiles.OnewayEastGreen:
		return dir == Vector2.LEFT;
	if id == Tiles.OnewayWestGreen:
		return dir == Vector2.RIGHT;
	if id == Tiles.OnewayNorthGreen:
		return dir == Vector2.DOWN;
	if id == Tiles.OnewaySouthGreen:
		return dir == Vector2.UP;
	if (!is_retro):
		if id == Tiles.OnewayEast:
			return dir == Vector2.LEFT;
		if id == Tiles.OnewayWest:
			return dir == Vector2.RIGHT;
		if id == Tiles.OnewayNorth:
			return dir == Vector2.DOWN;
		if id == Tiles.OnewaySouth:
			return dir == Vector2.UP;
	else:
		# when moving retrograde, it would have been valid to come out of a oneway, but not to have gone THROUGH one.
		# so check that.
		var retro_id = terrain_in_tile(pos - dir);
		if retro_id == Tiles.OnewayEast:
			return dir == Vector2.RIGHT;
		if retro_id == Tiles.OnewayWest:
			return dir == Vector2.LEFT;
		if retro_id == Tiles.OnewayNorth:
			return dir == Vector2.UP;
		if retro_id == Tiles.OnewaySouth:
			return dir == Vector2.DOWN;
	if id == Tiles.LadderPlatform || id == Tiles.WoodenPlatform:
		return dir == Vector2.DOWN and is_gravity;
	return false;
	
func is_suspended(actor: Actor):
	#PERF: could try caching this and only updating it when an actor moves or breaks
	if (!actor.climbs()):
		return false;
	var id = terrain_in_tile(actor.pos);
	return id == Tiles.Ladder || id == Tiles.LadderPlatform;

func terrain_is_hazardous(actor: Actor, pos: Vector2) -> bool:
	if (pos.y > map_y_max and actor.durability <= Durability.PITS):
		return true;
	var id = terrain_in_tile(pos);
	if (id == Tiles.Spikeball and actor.durability <= Durability.SPIKES):
		return true;
	return false;
	
func strength_check(strength: int, heaviness: int) -> bool:
	if (heaviness == Heaviness.WOODEN):
		return strength >= Strength.FEEBLE;
	if (heaviness == Heaviness.IRON):
		return strength >= Strength.LIGHT;
	if (heaviness == Heaviness.STEEL):
		return strength >= Strength.HEAVY;
	if (heaviness == Heaviness.SUPERHEAVY):
		return strength >= Strength.GRAVITY;
	return false;
	
func try_enter(actor: Actor, dir: Vector2, chrono: int, can_push: bool, hypothetical: bool, is_gravity: bool, is_retro: bool = false, pushers_list: Array = []) -> int:
	var dest = actor.pos + dir;
	if (chrono >= Chrono.META_UNDO):
		# assuming no bugs, if it was overlapping in the meta-past, then it must have been valid to reach then
		return Success.Yes;
	if (terrain_is_hazardous(actor, dest)):
		# AD04: being broken makes you immune to breaking :D
		if (!hypothetical and !actor.broken):
			set_actor_var(actor, "broken", true, chrono);
		return Success.Surprise;
	if (terrain_is_solid(actor, dest, dir, is_gravity, is_retro)):
		return Success.No;
	var actors_there = actors_in_tile(dest);
	var pushables_there = [];
	var tiny_pushables_there = [];
	for actor in actors_there:
		if actor.tiny_pushable():
			tiny_pushables_there.push_back(actor);
		elif actor.pushable():
			pushables_there.push_back(actor);
	if (actors_there.size() > 0):
		if (!can_push):
			return Success.No;
		# check if the current actor COULD push the next actor, then give them a push and return the result
		# TODO: add logic for multi-push scenarios as they come up. for now, ban it
		if (pushers_list.size() > 0):
			return Success.No;
		pushers_list.append(actor);
		for actor_there in pushables_there:
			if !strength_check(actor.strength, actor_there.heaviness):
				pushers_list.pop_front();
				return Success.No;
		var result = Success.Yes;
		# TODO: add logic for keys. I think this whole thing needs to do one hypothetical pass, and then if it succeeds we do the real push
		# + try to push keys?
		for actor_there in pushables_there:
			# surprise takes precedent over no takes precedent over yes
			result = max(result, move_actor_relative(actor_there, dir, chrono, hypothetical, is_gravity, false, pushers_list));
		pushers_list.pop_front();
		return result;
	return Success.Yes;

func set_actor_var(actor: Actor, prop: String, value, chrono: int) -> void:
	var old_value = actor.get(prop);
	if (chrono < Chrono.GHOSTS):
		add_undo_event([Undo.set_actor_var, actor, prop, old_value, value], chrono);
		actor.set(prop, value);
		actor.update_graphics();
	else:
		var ghost = get_ghost_that_hasnt_moved(actor);
		ghost.set(prop, value);
		ghost.update_graphics();

func add_undo_event(event: Array, chrono: int = Chrono.MOVE) -> void:
	#if (debug_prints and chrono < Chrono.META_UNDO):
	#	print("add_undo_event", " ", event, " ", chrono);
	if chrono == Chrono.MOVE:
		if (heavy_selected):
			while (heavy_undo_buffer.size() <= heavy_turn):
				heavy_undo_buffer.append([]);
			heavy_undo_buffer[heavy_turn].push_front(event);
			add_undo_event([Undo.heavy_undo_event_add, heavy_turn], Chrono.CHAR_UNDO);
		else:
			while (light_undo_buffer.size() <= light_turn):
				light_undo_buffer.append([]);
			light_undo_buffer[light_turn].push_front(event);
			add_undo_event([Undo.light_undo_event_add, light_turn], Chrono.CHAR_UNDO);
	
	if (chrono == Chrono.MOVE || chrono == Chrono.CHAR_UNDO):
		while (meta_undo_buffer.size() <= meta_turn):
			meta_undo_buffer.append([]);
		meta_undo_buffer[meta_turn].push_front(event);

func character_undo(is_silent: bool = false) -> bool:
	if (won): return false;
	user_replay += "z";
	finish_animations();
	if (heavy_selected):
		if (heavy_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var events = heavy_undo_buffer.pop_at(heavy_turn - 1);
		for event in events:
			undo_one_event(event, Chrono.CHAR_UNDO);
			add_undo_event([Undo.heavy_undo_event_remove, heavy_turn, event], Chrono.CHAR_UNDO);
		time_passes(Chrono.CHAR_UNDO);
		adjust_meta_turn(1);
		if (!is_silent):
			play_sound("undo");
			undo_effect_strength = 0.12; #yes stronger on purpose. it doesn't show up as well.
			undo_effect_per_second = undo_effect_strength*(1/0.4);
			undo_effect_color = heavy_color;
		return true;
	else:
		if (light_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var events = light_undo_buffer.pop_at(light_turn - 1);
		for event in events:
			undo_one_event(event, Chrono.CHAR_UNDO);
			add_undo_event([Undo.light_undo_event_remove, light_turn, event], Chrono.CHAR_UNDO);
		time_passes(Chrono.CHAR_UNDO);
		adjust_meta_turn(1);
		if (!is_silent):
			play_sound("undo");
			undo_effect_strength = 0.08;
			undo_effect_per_second = undo_effect_strength*(1/0.4);
			undo_effect_color = light_color;
		return true;

func get_ghost_that_hasnt_moved(actor : Actor) -> Actor:
	while actor.next_ghost != null:
		actor = actor.next_ghost;
	if (actor.is_ghost and actor.ghost_dir == Vector2.ZERO):
		return actor;
	var ghost = clone_actor_but_dont_add_it(actor);
	ghost.is_ghost = true;
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
	new.actorname = actor.actorname;
	new.texture = actor.texture;
	new.offset = actor.offset;
	new.position = terrainmap.map_to_world(actor.pos);
	new.pos = actor.pos;
	new.state = actor.state.duplicate();
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
	return new;

func finish_animations() -> void:
	for actor in actors:
		actor.animation_timer = 0;
		actor.animations.clear();
		actor.position = terrainmap.map_to_world(actor.pos);
		# TODO: handle sprite/state changes as well not even sure how I wanna do that yet

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
	meta_turn += amount;
	#if (debug_prints):
	#	print("=== IT IS NOW META TURN " + str(meta_turn) + " ===");
	update_ghosts();
	check_won();
	
func check_won() -> void:
	if (!light_actor.broken and !heavy_actor.broken and terrain_in_tile(heavy_actor.pos) == Tiles.HeavyGoal and terrain_in_tile(light_actor.pos) == Tiles.LightGoal):
		won = true;
	else:
		won = false;
	winlabel.visible = won;
	
func undo_one_event(event: Array, chrono : int) -> void:
	#if (debug_prints):
	#	print("undo_one_event", " ", event, " ", chrono);
		
	# undo events that should create undo trails
		
	if (event[0] == Undo.move):
		move_actor_relative(event[1], -event[2], chrono, false, false, true);
	elif (event[0] == Undo.set_actor_var):
		set_actor_var(event[1], event[2], event[3], chrono);
		
	# undo events that should not
		
	if (chrono >= Chrono.GHOSTS):
		return;
		
	elif (event[0] == Undo.heavy_turn):
		adjust_turn(true, -event[1], chrono);
	elif (event[0] == Undo.light_turn):
		adjust_turn(false, -event[1], chrono);
	if (event[0] == Undo.heavy_undo_event_add):
		heavy_undo_buffer[event[1]].pop_front();
	elif (event[0] == Undo.light_undo_event_add):
		light_undo_buffer[event[1]].pop_front();
	elif (event[0] == Undo.heavy_undo_event_remove):
		# meta undo an undo creates a char undo event but not a meta undo event, it's special!
		while (heavy_undo_buffer.size() <= event[1]):
			heavy_undo_buffer.append([]);
		heavy_undo_buffer[event[1]].push_front(event[2]);
	elif (event[0] == Undo.light_undo_event_remove):
		while (light_undo_buffer.size() <= event[1]):
			light_undo_buffer.append([]);
		light_undo_buffer[event[1]].push_front(event[2]);

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
	user_replay += "c";
	finish_animations();
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
		play_sound("metaundo");
	undo_effect_strength = 0.08;
	undo_effect_per_second = undo_effect_strength*(1/0.2);
	undo_effect_color = meta_color;
	finish_animations();
	return true;
	
func character_switch() -> void:
	heavy_selected = !heavy_selected;
	user_replay += "x";
	update_ghosts();
	play_sound("switch")

func restart(is_silent: bool = false) -> void:
	load_level(0);
	play_sound("restart");
	undo_effect_strength = 0.5;
	undo_effect_per_second = undo_effect_strength*(1/0.5);
	undo_effect_color = meta_color;
	finish_animations();
	
func escape() -> void:
	var levelselect = preload("res://LevelSelect.tscn").instance();
	ui_stack.push_back(levelselect);
	levelscene.add_child(levelselect);
	
func load_level_direct(new_level: int) -> void:
	var impulse = new_level - self.level_number;
	load_level(impulse);
	
func load_level(impulse: int) -> void:
	if (impulse != 0):
		user_replay_before_restarts.clear();
	elif user_replay.length() > 0:
		user_replay_before_restarts.push_back(user_replay);
	level_number += impulse;
	level_number = posmod(int(level_number), level_list.size());
	var level = level_list[level_number].instance();
	levelfolder.remove_child(terrainmap);
	terrainmap.queue_free();
	levelfolder.add_child(level);
	terrainmap = level;
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
	if (won): return false;
	if (dir == Vector2.UP):
		user_replay += "w";
	elif (dir == Vector2.DOWN):
		user_replay += "s";
	elif (dir == Vector2.LEFT):
		user_replay += "a";
	elif (dir == Vector2.RIGHT):
		user_replay += "d";
	finish_animations();
	var result = false;
	if heavy_selected:
		if (heavy_actor.broken or (heavy_turn >= heavy_max_moves and heavy_max_moves >= 0)):
			play_sound("bump");
			return false;
		if (!valid_voluntary_airborne_move(heavy_actor, dir)):
			result = Success.Surprise;
		else:
			result = move_actor_relative(heavy_actor, dir, Chrono.MOVE, false, false);
	else:
		if (light_actor.broken or (light_turn >= light_max_moves and light_max_moves >= 0)):
			play_sound("bump");
			return false;
		if (!valid_voluntary_airborne_move(light_actor, dir)):
			result = Success.Surprise;
		else:
			result = move_actor_relative(light_actor, dir, Chrono.MOVE, false, false);
	if (result == Success.Yes):
		play_sound("step")
		if (dir == Vector2.UP):
			if heavy_selected and !is_suspended(heavy_actor):
				set_actor_var(heavy_actor, "airborne", 2, Chrono.MOVE);
			elif !heavy_selected and !is_suspended(light_actor):
				set_actor_var(light_actor, "airborne", 2, Chrono.MOVE);
		elif (dir == Vector2.LEFT):
			if (heavy_selected and !heavy_actor.facing_left):
				set_actor_var(heavy_actor, "facing_left", true, Chrono.MOVE);
			elif (!heavy_selected and !light_actor.facing_left):
				set_actor_var(light_actor, "facing_left", true, Chrono.MOVE);
		elif (dir == Vector2.RIGHT):
			if (heavy_selected and heavy_actor.facing_left):
				set_actor_var(heavy_actor, "facing_left", false, Chrono.MOVE);
			elif (!heavy_selected and light_actor.facing_left):
				set_actor_var(light_actor, "facing_left", false, Chrono.MOVE);
	if (result != Success.No):
		time_passes(Chrono.MOVE);
		if heavy_selected:
			adjust_turn(true, 1, Chrono.MOVE);
			adjust_meta_turn(1);
		else:
			adjust_turn(false, 1, Chrono.MOVE);
			adjust_meta_turn(1);
	if (result != Success.Yes):
		play_sound("bump")
	return result;

func time_passes(chrono: int) -> void:
	if (chrono >= Chrono.META_UNDO):
		return
	var time_actors = []
	for actor in actors:
		# current rules:
		# MOVE: time passes for everyone
		# CHAR_UNDO: AD06: time passes for things 'green relative to us' (the other character, green actors)
		if (chrono == Chrono.MOVE):
			time_actors.push_back(actor);
		else:
			if (heavy_selected && actor == light_actor) || (!heavy_selected && actor == heavy_actor):
				time_actors.push_back(actor);
	
	# Decrement airborne by one (min zero).
	# AD02: Maybe this should be a +1/-1 instead of a set. Haven't decided yet. Doesn't seem to matter until strange matter.
	var has_fallen = {};
	for actor in time_actors:
		has_fallen[actor] = 0;
		if actor.airborne > 0 and actor.fall_speed() != 0:
			set_actor_var(actor, "airborne", actor.airborne - 1, chrono);
			
	# GRAVITY
	# For each actor in the list, in order of lowest down to highest up, repeat the following loop until nothing happens:
	# * If airborne is -1 and it COULD push-move down, set airborne to (1 for light, 0 for heavy).
	# * If airborne is 0, push-move down (unless this actor is light and already has this loop). If the push-move fails, set airborne to -1.
	time_actors.sort_custom(self, "bottom_up");
	var something_happened = true;
	var tries = 99;
	while (something_happened and tries > 0):
		tries -= 1;
		something_happened = false;
		for actor in time_actors:
			if (actor.fall_speed() >= 0 and has_fallen[actor] >= actor.fall_speed()):
				continue;
			if actor.airborne == -1 and !is_suspended(actor):
				var could_fall = try_enter(actor, Vector2.DOWN, chrono, true, true, true);
				# we'll say that falling due to gravity onto spikes/a pressure plate makes you airborne so we try to do it, but only once
				if (could_fall != Success.No and (could_fall == Success.Yes or has_fallen[actor] <= 0)):
					if actor.fall_speed() == 1:
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
					has_fallen[actor] += 1;
				if (did_fall != Success.Yes):
					set_actor_var(actor, "airborne", -1, chrono);
	
	# NEW (as part of AD07) post-gravity cleanups: If an actor is airborne 1 and would be grounded next fall,
	# land.
	# It was vaguely tolerable for Light but I don't know if it was ever a mechanic I was like 'whoo' about,
	#and now it definitely sucks.
	for actor in time_actors:
		if (actor.airborne == 0):
			if is_suspended(actor):
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
			var could_fall = try_enter(actor, Vector2.DOWN, chrono, true, true, true);
			if (could_fall == Success.No):
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
				
	# AFTER-GRAVITY TILE ARRIVAL
	for actor in time_actors:
		var terrain = terrain_in_tile(actor.pos);
		# Things in fire break.
		if !actor.broken and terrain == Tiles.Fire and actor.durability <= Durability.FIRE:
			set_actor_var(actor, "broken", true, chrono);
	
		# Things on checkpoints are set back to turn 0 (losing their undo buffer).
		# TODO: Horribly broken and it's not immediately obvious why. My basic idea is to 'defer' it to the end of turn so it can happen last.
		if actor == light_actor and (terrain == Tiles.CheckpointBlue or terrain == Tiles.Checkpoint):
			while light_turn > 0:
				var events = light_undo_buffer.pop_at(light_turn - 1);
				for event in events:
					add_undo_event([Undo.light_undo_event_remove, light_turn, event], Chrono.CHAR_UNDO);
				adjust_turn(false, -1, chrono);
		if actor == heavy_actor and (terrain == Tiles.CheckpointRed or terrain == Tiles.Checkpoint):
			while heavy_turn > 0:
				var events = heavy_undo_buffer.pop_at(heavy_turn - 1);
				for event in events:
					add_undo_event([Undo.heavy_undo_event_remove, heavy_turn, event], Chrono.CHAR_UNDO);
				adjust_turn(true, -1, chrono);
	
func bottom_up(a, b) -> bool:
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
	next_replay = timer + replay_interval();
	unit_test_mode = OS.is_debug_build() and Input.is_action_pressed(("shift"));
	
func do_one_replay_turn() -> void:
	if (!doing_replay):
		return;
	if replay_turn >= level_replay.length():
		if (unit_test_mode and won and level_number < (level_list.size() - 1)):
			doing_replay = true;
			load_level(1);
			replay_turn = 0;
			next_replay = timer + replay_interval();
			return;
		else:
			if (unit_test_mode):
				floating_text("Tested up to level: " + str(level_number));
			end_replay();
			return;
	next_replay = timer+replay_interval();
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
		levelnumberastext = str(chapter) + "-" + str(level_in_chapter);
	if (level_is_extra):
		levelnumberastext += "X";
	levellabel.text = levelnumberastext + " - " + level_name;
	if (level_author != "" and level_author != "Patashu"):
		levellabel.text += " (By " + level_author + ")"
	if (doing_replay):
		levellabel.text += " (REPLAY) (F9/F10 ADJUST SPEED)"
	
func update_info_labels() -> void:	
	heavyinfolabel.text = "Heavy" + "\n" + str(heavy_turn);
	if heavy_max_moves >= 0:
		heavyinfolabel.text += "/" + str(heavy_max_moves);
	
	lightinfolabel.text = "Light" + "\n" + str(light_turn);
	if light_max_moves >= 0:
		lightinfolabel.text += "/" + str(light_max_moves);
	
	metainfolabel.text = "(Meta-Turn: " + str(meta_turn) + ")"

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	levelscene.add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = get_viewport().size.x/2;
	label.rect_position.y = get_viewport().size.y/4-16;
	label.text = text;

func replay_from_clipboard() -> void:
	var replay = OS.get_clipboard();
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

func _process(delta: float) -> void:
	timer += delta;
	
	if ui_stack.size() == 0:
		if (doing_replay and timer > next_replay):
			do_one_replay_turn();
			update_info_labels();
		
		if (won and Input.is_action_just_pressed("ui_accept")):
			end_replay();
			load_level(1);
		
		if (Input.is_action_just_pressed("mute")):
			toggle_mute();
			
		if (Input.is_action_just_pressed("speedup_replay")):
			replay_interval *= 0.8;
		if (Input.is_action_just_pressed("slowdown_replay")):
			replay_interval /= 0.8;
		if (Input.is_action_just_pressed("start_replay")):
			toggle_replay();
			update_info_labels();
			
		if (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("paste")):
			replay_from_clipboard();
		
		if (Input.is_action_just_pressed("character_undo")):
			end_replay();
			character_undo();
			update_info_labels();
		if (Input.is_action_just_pressed("meta_undo")):
			if Input.is_action_pressed("ctrl"):
				OS.set_clipboard(user_replay);
				floating_text("Ctrl+C: Replay copied");
			else:
				end_replay();
				meta_undo();
				update_info_labels();
		if (Input.is_action_just_pressed("character_switch")):
			end_replay();
			character_switch();
			update_info_labels();
		if (Input.is_action_just_pressed("restart")):
			end_replay();
			restart();
			update_info_labels();
		if (Input.is_action_just_pressed("escape")):
			end_replay();
			escape();
		if (Input.is_action_just_pressed("previous_level")):
			end_replay();
			load_level(-1);
		if (Input.is_action_just_pressed("next_level")):
			end_replay();
			load_level(1);
		
		var dir = Vector2.ZERO;
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
