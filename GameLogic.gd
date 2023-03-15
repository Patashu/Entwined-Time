extends Node
class_name GameLogic

onready var levelscene : Node2D = get_node("/root/LevelScene");
onready var actorsfolder : Node2D = levelscene.get_node("ActorsFolder");
onready var terrainmap : TileMap = levelscene.get_node("TerrainMap");
onready var controlslabel : Label = levelscene.get_node("ControlsLabel");
onready var levellabel : Label = levelscene.get_node("LevelLabel");
onready var heavyinfolabel : Label = levelscene.get_node("HeavyInfoLabel");
onready var lightinfolabel : Label = levelscene.get_node("LightInfoLabel");
onready var targeter : Sprite = levelscene.get_node("Targeter")

# distinguish between temporal layers when a move or state change happens
enum Chrono {
	MOVE
	CHAR_UNDO
	META_UNDO
	TIMELESS
}

# information about the level and actors
var heavy_actor : Actor = null
var light_actor : Actor = null
var actors = []
# might move this into Actor.state or something
#var heavy_coyote_time = -1;
#var light_coyote_time = -1;
var heavy_turn = 0;
var heavy_undo_buffer : Array = [];
var light_turn = 0;
var light_undo_buffer : Array = [];
var meta_turn = 0;
var meta_undo_buffer : Array = [];
var heavy_max_moves = -1;
var light_max_moves = -1;
var map_x_max : int = 0; # 21
var map_y_max : int = 0; # 10, kind of cramped, if it is then I can just add screen scrolling
var heavy_selected = true;

# names to sprites, I'll think of a better way another time
var name_to_sprite = {};

# song-and-dance state
var timer = 0;
var sounds = {}
var speakers = [];
var muted = false;
var won = false;
var cell_size = 24;

func _ready() -> void:
	# Call once when the game is booted up.
	initialize_name_to_sprites();
	prepare_audio();
	
	# Call whenever a new map is loaded.
	ready_map();

func ready_map() -> void:
	calculate_map_size();
	
	# find heavy and light and turn them into actors
	var heavy_id = terrainmap.tile_set.find_tile_by_name("HeavyIdle");
	var heavy_tile = terrainmap.get_used_cells_by_id(heavy_id)[0];
	terrainmap.set_cellv(heavy_tile, -1);
	heavy_actor = make_actor("heavy", heavy_tile);
	var light_id = terrainmap.tile_set.find_tile_by_name("LightIdle");
	var light_tile = terrainmap.get_used_cells_by_id(light_id)[0];
	terrainmap.set_cellv(light_tile, -1);
	light_actor = make_actor("light", light_tile);

func initialize_name_to_sprites() -> void:
	name_to_sprite["heavy"] = preload("res://assets/heavy_idle.png");
	name_to_sprite["light"] = preload("res://assets/light_idle.png");
	
func calculate_map_size() -> void:
	var tiles = terrainmap.get_used_cells();
	for tile in tiles:
		if tile.x > map_x_max:
			map_x_max = tile.x;
		if tile.y > map_y_max:
			map_y_max = tile.y;
		
func update_targeter() -> void:
	if (heavy_selected and heavy_actor != null):
		targeter.position = terrainmap.map_to_world(heavy_actor.pos);
	elif (light_actor != null):
		targeter.position = terrainmap.map_to_world(light_actor.pos);
		
func prepare_audio() -> void:
	# TODO: I could automate this if I can iterate the folder
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
	if muted:
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
	actor.texture = name_to_sprite[actorname];
	actor.offset = Vector2(cell_size/2, cell_size/2);
	actors.append(actor);
	actorsfolder.add_child(actor);
	move_actor_to(actor, pos, chrono);
	if (chrono < Chrono.META_UNDO):
		print("TODO")
	return actor;
	
func move_actor_relative(actor: Actor, dir: Vector2, chrono: int = Chrono.TIMELESS) -> bool:
	return move_actor_to(actor, actor.pos + dir, chrono);
	
func move_actor_to(actor: Actor, pos: Vector2, chrono: int = Chrono.TIMELESS) -> bool:
	if (try_enter(actor, pos - actor.pos, chrono)):
		if (chrono == Chrono.MOVE):
			add_undo_event(["move", actor, pos - actor.pos]);
		actor.pos = pos;
		actor.position = terrainmap.map_to_world(actor.pos);
		update_targeter();
		return true;
	return false;
		
func actors_in_tile(pos: Vector2) -> Array:
	var result = [];
	for actor in actors:
		if actor.pos == pos:
			result.append(actor);
	return result;
	
func terrain_in_tile(pos: Vector2) -> String:
	return terrainmap.tile_set.tile_get_name(terrainmap.get_cellv(pos));

func terrain_is_solid(pos: Vector2) -> bool:
	var name = terrain_in_tile(pos);
	return name == "Wall" || name == "LockClosed";
	
func try_enter(Actor: Actor, dir: Vector2, chrono: int = Chrono.MOVE) -> bool:
	var dest = Actor.pos + dir;
	if (chrono >= Chrono.META_UNDO):
		# assuming no bugs, if it was overlapping in the meta-past, then it must have been valid to reach then
		return true
	if (terrain_is_solid(dest)):
		return false
	var actors_there = actors_in_tile(dest);
	if (actors_there.size() > 0):
		return false
	return true

func add_undo_event(event: Array, chrono: int = Chrono.MOVE) -> void:
	if (heavy_selected):
		if (heavy_undo_buffer.size() <= heavy_turn):
			heavy_undo_buffer.append([]);
		heavy_undo_buffer[heavy_turn].push_front(event);
	else:
		if (light_undo_buffer.size() <= light_turn):
			light_undo_buffer.append([]);
		light_undo_buffer[light_turn].push_front(event);

func character_undo(is_silent: bool = false) -> bool:
	if (heavy_selected):
		if (heavy_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var events = heavy_undo_buffer.pop_back();
		for event in events:
			character_undo_one_event(event);
		heavy_turn -= 1;
		meta_turn += 1;
		if (!is_silent):
			play_sound("undo");
		return true;
	else:
		if (light_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var events = light_undo_buffer.pop_back();
		for event in events:
			character_undo_one_event(event);
		light_turn -= 1;
		meta_turn += 1;
		if (!is_silent):
			play_sound("undo");
		return true;
	
func character_undo_one_event(event: Array) -> void:
	if (event[0] == "move"):
		move_actor_relative(event[1], -event[2], Chrono.CHAR_UNDO);
	
func meta_undo(is_silent: bool = false) -> bool:
	return false;
	
func meta_undo_one_event(event: Array) -> void:
	pass
	
func character_switch() -> void:
	heavy_selected = !heavy_selected;
	update_targeter();
	play_sound("switch")

func restart() -> void:
	pass
	
func escape() -> void:
	pass
	
func cycle_level(impulse: int) -> void:
	pass

func character_move(dir: Vector2) -> bool:
	var result = false;
	if heavy_selected:
		if (heavy_turn >= heavy_max_moves and heavy_max_moves >= 0):
			play_sound("bump");
			return false;
		result = move_actor_relative(heavy_actor, dir, Chrono.MOVE);
	else:
		if (light_turn >= light_max_moves and light_max_moves >= 0):
			play_sound("bump");
			return false;
		result = move_actor_relative(light_actor, dir, Chrono.MOVE);
	if (result):
		play_sound("step")
		if heavy_selected:
			heavy_turn += 1;
		else:
			light_turn += 1;
	else:
		play_sound("bump")
	return result;
	
func update_info_labels() -> void:
	heavyinfolabel.text = "Heavy";
	if (heavy_selected):
		heavyinfolabel.text += " (Selected)"
	heavyinfolabel.text += ": Turn "
	heavyinfolabel.text += str(heavy_turn);
	if heavy_max_moves >= 0:
		heavyinfolabel.text += "/" + str(heavy_max_moves);
	lightinfolabel.text = "Light";
	if (!heavy_selected):
		lightinfolabel.text += " (Selected)"
	lightinfolabel.text += ": Turn "
	lightinfolabel.text += str(light_turn);
	if light_max_moves >= 0:
		lightinfolabel.text += "/" + str(light_max_moves);

func _process(delta: float) -> void:
	timer += delta;
	if (Input.is_action_just_pressed("mute")):
		toggle_mute();
	
	if (Input.is_action_just_pressed("character_undo")):
		character_undo();
		update_info_labels();
	if (Input.is_action_just_pressed("meta_undo")):
		meta_undo();
		update_info_labels();
	if (Input.is_action_just_pressed("character_switch")):
		character_switch();
		update_info_labels();
	if (Input.is_action_just_pressed("restart")):
		restart();
		update_info_labels();
	if (Input.is_action_just_pressed("escape")):
		escape();
	if (Input.is_action_just_pressed("previous_level")):
		cycle_level(-1);
	if (Input.is_action_just_pressed("next_level")):
		cycle_level(1);
	
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
		character_move(dir);
		update_info_labels();
