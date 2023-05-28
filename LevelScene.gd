extends Node2D
class_name LevelScene

onready var gamelogic : GameLogic = self.get_node("GameLogic");
var last_delta = 0;

func _process(delta: float) -> void:
	last_delta = delta;
	update();

func _draw():
	if (gamelogic.undo_effect_strength > 0):
		var color = Color(gamelogic.undo_effect_color);
		color.a = gamelogic.undo_effect_strength;
		draw_rect(Rect2(0, 0, gamelogic.pixel_width, gamelogic.pixel_height), color, true);
	gamelogic.undo_effect_strength -= gamelogic.undo_effect_per_second*last_delta;
	
	# draw background gradients based on character turns elapsed
	var light_intensity = 0.0;
	var heavy_intensity = 0.0;
	
	if (gamelogic.heavy_max_moves == 0):
		heavy_intensity = 1.0;
	elif (gamelogic.heavy_max_moves < 0):
		heavy_intensity = 0.0;
	else:
		heavy_intensity = float(gamelogic.heavy_turn) / float(gamelogic.heavy_max_moves);
	
	if (gamelogic.light_max_moves == 0):
		light_intensity = 1.0;
	elif (gamelogic.light_max_moves < 0):
		light_intensity = 0.0;
	else:
		light_intensity = float(gamelogic.light_turn) / float(gamelogic.light_max_moves);
		
	var intensity_modifier = 0.5;
	light_intensity *= intensity_modifier;
	heavy_intensity *= intensity_modifier;
		
	var true_y = gamelogic.pixel_height;
	
	for i in range(10):
		var color = Color(gamelogic.heavy_color);
		color.a = heavy_intensity*((10.0-i)/10.0);
		var band = true_y/30;
		draw_rect(Rect2(0, i*band, gamelogic.pixel_width, band), color, true);
		
	for i in range(10):
		var color = Color(gamelogic.light_color);
		color.a = light_intensity*((10.0-i)/10.0);
		var band = true_y/30;
		draw_rect(Rect2(0, true_y-(i*band), gamelogic.pixel_width, band), color, true);
