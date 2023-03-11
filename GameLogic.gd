extends Node
class_name GameLogic

onready var levelscene : Node2D = get_node("/root/LevelScene");
onready var actormap : TileMap = levelscene.get_node("ActorMap");
onready var terrainmap : TileMap = levelscene.get_node("TerrainMap");
onready var controlslabel : Label = levelscene.get_node("ControlsLabel");
onready var levellabel : Label = levelscene.get_node("LevelLabel");
onready var heavyinfolabel : Label = levelscene.get_node("HeavyInfoLabel");
onready var lightinfolabel : Label = levelscene.get_node("LightInfoLabel");
onready var targeter : Sprite = levelscene.get_node("Targeter")

# information about the level and actors
var heavy_loc : Vector2 = Vector2.ZERO;
var light_loc : Vector2 = Vector2.ZERO;
var heavy_coyote_time = -1;
var light_coyote_time = -1;
var heavy_undo_buffer : Array = [];
var light_undo_buffer : Array = [];
var meta_undo_buffer : Array = [];
var heavy_max_moves = -1;
var light_max_moves = -1;
var map_x_max : int = 0; # 21
var map_y_max : int = 0; # 10, kind of cramped, if it is then I can just add screen scrolling
var heavy_selected = true;

# song-and-dance state
var timer = 0;
var sounds = {}
var speakers = [];
var muted = false;
var won = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# find heavy and light
	var heavy_id = actormap.tile_set.find_tile_by_name("HeavyIdle");
	var heavy_tile = actormap.get_used_cells_by_id(heavy_id)[0];
	heavy_loc = heavy_tile;
	var light_id = actormap.tile_set.find_tile_by_name("LightIdle");
	var light_tile = actormap.get_used_cells_by_id(light_id)[0];
	light_loc = light_tile;
	calculate_map_size();
	prepare_audio();
	update_targeter();
	
func calculate_map_size() -> void:
	var tiles = terrainmap.get_used_cells();
	for tile in tiles:
		if tile.x > map_x_max:
			map_x_max = tile.x;
		if tile.y > map_y_max:
			map_y_max = tile.y;
		
func update_targeter() -> void:
	if (heavy_selected):
		targeter.position = terrainmap.map_to_world(heavy_loc);
	else:
		targeter.position = terrainmap.map_to_world(light_loc);
		
func prepare_audio() -> void:
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

func character_undo() -> void:
	pass
	
func meta_undo() -> void:
	pass
	
func character_switch() -> void:
	pass

func restart() -> void:
	pass
	
func escape() -> void:
	pass
	
func cycle_level(impulse: int) -> void:
	pass

func character_move(dir: Vector2) -> void:
	pass

func _process(delta: float) -> void:
	timer += delta;
	if (Input.is_action_just_pressed("mute")):
		toggle_mute();
	# character_undo, meta_undo, character_switch, restart, escape, next_level, previous_level
	if (Input.is_action_just_pressed("character_undo")):
		character_undo();
	if (Input.is_action_just_pressed("meta_undo")):
		meta_undo();
	if (Input.is_action_just_pressed("character_switch")):
		character_switch();
	if (Input.is_action_just_pressed("restart")):
		restart();
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
