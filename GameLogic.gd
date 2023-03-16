extends Node
class_name GameLogic

var debug_prints = false;

onready var levelscene : Node2D = get_node("/root/LevelScene");
onready var actorsfolder : Node2D = levelscene.get_node("ActorsFolder");
onready var levelfolder : Node2D = levelscene.get_node("LevelFolder");
onready var terrainmap : TileMap = levelfolder.get_node("TerrainMap");
onready var controlslabel : Label = levelscene.get_node("ControlsLabel");
onready var levellabel : Label = levelscene.get_node("LevelLabel");
onready var winlabel : Label = levelscene.get_node("WinLabel");
onready var heavyinfolabel : Label = levelscene.get_node("HeavyInfoLabel");
onready var lightinfolabel : Label = levelscene.get_node("LightInfoLabel");
onready var metainfolabel : Label = levelscene.get_node("MetaInfoLabel");
onready var targeter : Sprite = levelscene.get_node("Targeter")

# distinguish between temporal layers when a move or state change happens
enum Chrono {
	MOVE
	CHAR_UNDO
	META_UNDO
	TIMELESS
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

# Light becomes airborne_state 2 when it becomes airborne for any reason.
# Heavy only becomes airborne_state 2 on an upward movement.
# Light things with airborne_state 0+ can still try to move in any direction.
# Heavy things can't move up under their own power, but still can if pushed.
# When gravity effects things, Light things only move down once.
# Heavy things move down each iteration until settled.
enum Floatiness {
	HEAVY,
	LIGHT
}

# yes means 'do the thing you intended'. no means 'cancel it and this won't cause time to pass'.
# surprise means 'cancel it but there was a side effect so time passes'.
enum Success {
	Yes,
	No,
	Surprise,
}

# information about the level
var level_number = 0
var level_name = "Blah Blah Blah";
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

# names to sprites, I'll think of a better way another time
var name_to_sprite = {};

# song-and-dance state
var timer = 0;
var sounds = {}
var speakers = [];
var muted = false;
var won = false;
var cell_size = 24;

# list of levels in the game
var level_list = [];

func _ready() -> void:
	# Call once when the game is booted up.
	initialize_level_list();
	initialize_name_to_sprites();
	prepare_audio();
	
	# Load the first map.
	load_level(0);
	
func initialize_level_list() -> void:
	level_list.push_back(preload("res://levels/Orientation.tscn"));
	level_list.push_back(preload("res://levels/TheFirstPit.tscn"));
	level_list.push_back(preload("res://levels/Acrobatics.tscn"));

func ready_map() -> void:
	for actor in actors:
		actor.queue_free();
	actors.clear();
	heavy_turn = 0;
	heavy_undo_buffer.clear();
	light_turn = 0;
	light_undo_buffer.clear();
	meta_turn = 0;
	meta_undo_buffer.clear();
	heavy_selected = true;
	
	level_name = terrainmap.get_child(0).level_name;
	heavy_max_moves = terrainmap.get_child(0).heavy_max_moves;
	light_max_moves = terrainmap.get_child(0).light_max_moves;
	calculate_map_size();
	
	# find heavy and light and turn them into actors
	var heavy_id = terrainmap.tile_set.find_tile_by_name("HeavyIdle");
	var heavy_tile = terrainmap.get_used_cells_by_id(heavy_id)[0];
	terrainmap.set_cellv(heavy_tile, -1);
	heavy_actor = make_actor("heavy", heavy_tile);
	heavy_actor.heaviness = Heaviness.STEEL;
	heavy_actor.strength = Strength.HEAVY;
	heavy_actor.durability = Durability.FIRE;
	heavy_actor.floatiness = Floatiness.HEAVY;
	var light_id = terrainmap.tile_set.find_tile_by_name("LightIdle");
	var light_tile = terrainmap.get_used_cells_by_id(light_id)[0];
	terrainmap.set_cellv(light_tile, -1);
	light_actor = make_actor("light", light_tile);
	light_actor.heaviness = Heaviness.IRON;
	light_actor.strength = Strength.LIGHT;
	light_actor.durability = Durability.SPIKES;
	light_actor.floatiness = Floatiness.LIGHT;
	update_info_labels();
	check_won();

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
	
func move_actor_relative(actor: Actor, dir: Vector2, chrono: int = Chrono.TIMELESS, hypothetical: bool = false) -> int:
	return move_actor_to(actor, actor.pos + dir, chrono, hypothetical);
	
func move_actor_to(actor: Actor, pos: Vector2, chrono: int = Chrono.TIMELESS, hypothetical: bool = false) -> int:
	var success = try_enter(actor, pos - actor.pos, chrono, true, hypothetical);
	if (success == Success.Yes and !hypothetical):
		add_undo_event(["move", actor, pos - actor.pos], chrono);
		actor.pos = pos;
		actor.position = terrainmap.map_to_world(actor.pos);
		update_targeter();
		return success;
	return success;
		
func adjust_turn(is_heavy: bool, amount: int, chrono : int) -> void:
	if (is_heavy):
		add_undo_event(["heavy_turn", amount], chrono);
		heavy_turn += amount;
	else:
		add_undo_event(["light_turn", amount], chrono);
		light_turn += amount;
		
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
	
func try_enter(actor: Actor, dir: Vector2, chrono: int, can_push: bool, hypothetical: bool = false) -> int:
	var dest = actor.pos + dir;
	if (chrono >= Chrono.META_UNDO):
		# assuming no bugs, if it was overlapping in the meta-past, then it must have been valid to reach then
		return Success.Yes;
	if (terrain_is_solid(dest)):
		return Success.No;
	var actors_there = actors_in_tile(dest);
	if (actors_there.size() > 0):
		if (!can_push):
			return Success.No;
		# check if the current actor COULD push the next actor, then give them a push and return the result
		# TODO: once crates are in we need to handle various multipush scenarios
		for actor_there in actors_there:
			if !strength_check(actor.strength, actor_there.heaviness):
				return Success.No;
		var result = Success.Yes;
		for actor_there in actors_there:
			# surprise takes precedent over no takes precedent over yes
			result = max(result, move_actor_relative(actor_there, dir, chrono, hypothetical));
		return result;
	return Success.Yes;

func set_actor_var(actor: Actor, prop: String, value, chrono: int) -> void:
	var old_value = actor.get(prop);
	add_undo_event(["set_actor_var", actor, prop, old_value], chrono);
	actor.set(prop, value);

func add_undo_event(event: Array, chrono: int = Chrono.MOVE) -> void:
	if (debug_prints and chrono < Chrono.META_UNDO):
		print("add_undo_event", " ", event, " ", chrono);
	if chrono == Chrono.MOVE:
		if (heavy_selected):
			if (heavy_undo_buffer.size() <= heavy_turn):
				heavy_undo_buffer.append([]);
			heavy_undo_buffer[heavy_turn].push_front(event);
			add_undo_event(["heavy_undo_event_add", heavy_turn], Chrono.CHAR_UNDO);
		else:
			if (light_undo_buffer.size() <= light_turn):
				light_undo_buffer.append([]);
			light_undo_buffer[light_turn].push_front(event);
			add_undo_event(["light_undo_event_add", light_turn], Chrono.CHAR_UNDO);
	
	if (chrono == Chrono.MOVE || chrono == Chrono.CHAR_UNDO):
		if (meta_undo_buffer.size() <= meta_turn):
			meta_undo_buffer.append([]);
		meta_undo_buffer[meta_turn].push_front(event);

func character_undo(is_silent: bool = false) -> bool:
	if (won): return false;
	if (heavy_selected):
		if (heavy_turn <= 0):
			if !is_silent:
				play_sound("bump");
			return false;
		var events = heavy_undo_buffer.pop_back();
		for event in events:
			undo_one_event(event, Chrono.CHAR_UNDO);
			add_undo_event(["heavy_undo_event_remove", heavy_turn, event], Chrono.CHAR_UNDO);
		time_passes(Chrono.CHAR_UNDO);
		adjust_meta_turn(1);
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
			undo_one_event(event, Chrono.CHAR_UNDO);
			add_undo_event(["light_undo_event_remove", light_turn, event], Chrono.CHAR_UNDO);
		time_passes(Chrono.CHAR_UNDO);
		adjust_meta_turn(1);
		if (!is_silent):
			play_sound("undo");
		return true;
	
func adjust_meta_turn(amount: int) -> void:
	meta_turn += amount;
	check_won();
	
func check_won() -> void:
	if (terrain_in_tile(heavy_actor.pos) == "HeavyGoal" and terrain_in_tile(light_actor.pos) == "LightGoal"):
		won = true;
	else:
		won = false;
	winlabel.visible = won;
	
func undo_one_event(event: Array, chrono : int) -> void:
	if (debug_prints):
		print("undo_one_event", " ", event, " ", chrono);
	if (event[0] == "move"):
		move_actor_relative(event[1], -event[2], chrono);
	elif (event[0] == "set_actor_var"):
		set_actor_var(event[1], event[2], event[3], chrono);
	elif (event[0] == "heavy_turn"):
		adjust_turn(true, -event[1], chrono);
	elif (event[0] == "light_turn"):
		adjust_turn(false, -event[1], chrono);
	elif (event[0] == "heavy_undo_event_add"):
		heavy_undo_buffer[event[1]].pop_front();
	elif (event[0] == "light_undo_event_add"):
		light_undo_buffer[event[1]].pop_front();
	elif (event[0] == "heavy_undo_event_remove"):
		# meta undo an undo creates a char undo event but not a meta undo event, it's special!
		if (heavy_undo_buffer.size() <= event[1]):
			heavy_undo_buffer.append([]);
		heavy_undo_buffer[event[1]].push_front(event[2]);
	elif (event[0] == "light_undo_event_remove"):
		if (light_undo_buffer.size() <= event[1]):
			light_undo_buffer.append([]);
		light_undo_buffer[event[1]].push_front(event[2]);
	
func meta_undo(is_silent: bool = false) -> bool:
	if (meta_turn <= 0):
		if !is_silent:
			play_sound("bump");
		return false;
	var events = meta_undo_buffer.pop_back();
	for event in events:
		undo_one_event(event, Chrono.META_UNDO);
	time_passes(Chrono.META_UNDO);
	adjust_meta_turn(-1);
	if (!is_silent):
		play_sound("undo");
	return true;
	
func character_switch() -> void:
	if (won): return;
	heavy_selected = !heavy_selected;
	update_targeter();
	play_sound("switch")

func restart() -> void:
	load_level(0)
	
func escape() -> void:
	pass
	
func load_level(impulse: int) -> void:
	level_number += impulse;
	level_number = posmod(int(level_number), level_list.size());
	var level = level_list[level_number].instance();
	levelfolder.remove_child(terrainmap);
	terrainmap.queue_free();
	levelfolder.add_child(level);
	terrainmap = level;
	ready_map();

func character_move(dir: Vector2) -> bool:
	if (won): return false;
	var result = false;
	if heavy_selected:
		if (heavy_turn >= heavy_max_moves and heavy_max_moves >= 0):
			play_sound("bump");
			return false;
		# airborne == -1 characters can move up and set airborne to 2. airborne >= 0 characters can't move up but it does pass a turn ('Surprise')
		if (dir == Vector2.UP and heavy_actor.airborne >= 0):
			result = Success.Surprise;
		else:
			result = move_actor_relative(heavy_actor, dir, Chrono.MOVE);
	else:
		if (light_turn >= light_max_moves and light_max_moves >= 0):
			play_sound("bump");
			return false;
		# AD01: decided that Heavy and Light have the same 'airborne up' rule
		if (dir == Vector2.UP and light_actor.airborne >= 0):
			result = Success.Surprise;
		else:
			result = move_actor_relative(light_actor, dir, Chrono.MOVE);
	if (result == Success.Yes):
		play_sound("step")
		if (dir == Vector2.UP):
			if heavy_selected:
				set_actor_var(heavy_actor, "airborne", 2, Chrono.MOVE);
			else:
				set_actor_var(light_actor, "airborne", 2, Chrono.MOVE);
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
		# CHAR_UNDO: time passes for everyone but the undoing char
		if (chrono == Chrono.MOVE):
			time_actors.push_back(actor);
		else:
			if (heavy_selected && actor != heavy_actor) || (!heavy_selected && actor != light_actor):
				time_actors.push_back(actor);
	
	# Decrement airborne by one (min zero).
	# AD02: Maybe this should be a +1/-1 instead of a set. Haven't decided yet.
	for actor in time_actors:
		if actor.airborne > 0:
			set_actor_var(actor, "airborne", actor.airborne - 1, chrono);
			
	# GRAVITY
	# For each actor in the list, in order of lowest down to highest up, repeat the following loop until nothing happens:
	# * If airborne is -1 and it COULD push-move down, set airborne to (1 for light, 0 for heavy).
	# * If airborne is 0, push-move down (unless this actor is light and already has this loop). If the push-move fails, set airborne to -1.
	time_actors.sort_custom(self, "bottom_up");
	var has_fallen = {};
	var something_happened = true;
	var tries = 99;
	while (something_happened and tries > 0):
		--tries;
		something_happened = false;
		for actor in time_actors:
			if (actor.floatiness == Floatiness.LIGHT and has_fallen.has(actor)):
				continue;
			if actor.airborne == -1:
				var could_fall = try_enter(actor, Vector2.DOWN, chrono, true, true);
				# we'll say that falling due to gravity onto spikes/a pressure plate makes you airborne so we try to do it, but only once
				if (could_fall != Success.No and (could_fall == Success.Yes or !has_fallen.has(actor))):
					if actor.floatiness == Floatiness.LIGHT:
						set_actor_var(actor, "airborne", 1, chrono);
					else:
						set_actor_var(actor, "airborne", 0, chrono);
					something_happened = true;
			if actor.airborne == 0:
				var did_fall = move_actor_relative(actor, Vector2.DOWN, chrono);
				if (did_fall != Success.No):
					something_happened = true;
					has_fallen[actor] = true;
				if (did_fall != Success.Yes):
					set_actor_var(actor, "airborne", -1, chrono);
	
func bottom_up(a, b) -> bool:
	return a.pos.y > b.pos.y;
	
func update_info_labels() -> void:
	levellabel.text = str(level_number) + " - " + level_name;
	heavyinfolabel.text = "Heavy";
	if (heavy_selected):
		heavyinfolabel.text += " (Selected)"
	if (heavy_actor.airborne > -1):
		heavyinfolabel.text += " (Airborne " + str(heavy_actor.airborne) + ")";
	heavyinfolabel.text += ": Turn "
	heavyinfolabel.text += str(heavy_turn);
	if heavy_max_moves >= 0:
		heavyinfolabel.text += "/" + str(heavy_max_moves);
	lightinfolabel.text = "Light";
	if (!heavy_selected):
		lightinfolabel.text += " (Selected)"
	if (light_actor.airborne > -1):
		lightinfolabel.text += " (Airborne " + str(light_actor.airborne) + ")";
	lightinfolabel.text += ": Turn "
	lightinfolabel.text += str(light_turn);
	if light_max_moves >= 0:
		lightinfolabel.text += "/" + str(light_max_moves);
	metainfolabel.text = "(Meta-Turn: " + str(meta_turn) + ")"

func _process(delta: float) -> void:
	timer += delta;
	
	if (won and Input.is_action_just_pressed("ui_accept")):
		load_level(1);
	
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
		load_level(-1);
	if (Input.is_action_just_pressed("next_level")):
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
		character_move(dir);
		update_info_labels();
