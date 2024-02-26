extends Node2D
class_name Menu

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var yourreplaybutton : Button = get_node("Holder/YourReplayButton");
onready var authorsreplaybutton : Button = get_node("Holder/AuthorsReplayButton");
onready var savereplaybutton : Button = get_node("Holder/SaveReplayButton");
onready var copyreplaybutton : Button = get_node("Holder/CopyReplayButton");
onready var pastereplaybutton : Button = get_node("Holder/PasteReplayButton");
onready var levelselectbutton : Button = get_node("Holder/LevelSelectButton");
onready var insightbutton : Button = get_node("Holder/InsightButton");
onready var controlsbutton : Button = get_node("Holder/ControlsButton");
onready var settingsbutton : Button = get_node("Holder/SettingsButton");
onready var restartbutton : Button = get_node("Holder/RestartButton");
onready var quitgamebutton : Button = get_node("Holder/QuitGameButton");
var is_web = false;

func _ready() -> void:
	var os_name = OS.get_name();
	if (os_name == "HTML5" or os_name == "Android" or os_name == "iOS"):
		is_web = true;
	
	okbutton.connect("pressed", self, "destroy");
	yourreplaybutton.connect("pressed", self, "_yourreplaybutton_pressed");
	authorsreplaybutton.connect("pressed", self, "_authorsreplaybutton_pressed");
	savereplaybutton.connect("pressed", self, "_savereplaybutton_pressed");
	copyreplaybutton.connect("pressed", self, "_copyreplaybutton_pressed");
	pastereplaybutton.connect("pressed", self, "_pastereplaybutton_pressed");
	levelselectbutton.connect("pressed", self, "_levelselectbutton_pressed");
	insightbutton.connect("pressed", self, "_insightbutton_pressed");
	controlsbutton.connect("pressed", self, "_controlsbutton_pressed");
	settingsbutton.connect("pressed", self, "_settingsbutton_pressed");
	restartbutton.connect("pressed", self, "_restartbutton_pressed");
	quitgamebutton.connect("pressed", self, "_quitgamebutton_pressed");
	#IF YOU CHANGE THE NUMBER OF BUTTONS, CHANGE FOCUS NEIGHBOURS IN EDITOR TOO!!
	
	if gamelogic.has_remix.has(gamelogic.level_name) or gamelogic.level_name.find("(Remix)") >= 0:
		if gamelogic.in_insight_level:
			insightbutton.text = "Lose Remix";
		else:
			insightbutton.text = "Gain Remix";
	elif gamelogic.in_insight_level:
		insightbutton.text = "Lose Insight";
	elif !gamelogic.has_insight_level:
		insightbutton.disabled = true;
		
	if gamelogic.doing_replay:
		authorsreplaybutton.text = "End Replay";
		authorsreplaybutton.rect_size.x = yourreplaybutton.rect_size.x;
		
	#check if player has beaten and saved a replay for this puzzle
	var levels_save_data = gamelogic.save_file["levels"];
	if (!levels_save_data.has(gamelogic.level_name)):
		yourreplaybutton.disabled = true;
	else:
		var level_save_data = levels_save_data[gamelogic.level_name];
		if (!level_save_data.has("replay")):
			yourreplaybutton.disabled = true;
	
	if (!gamelogic.won):
		savereplaybutton.disabled = true;
		
	if (gamelogic.user_replay.length() <= 0):
		copyreplaybutton.disabled = true;
	
	# constantly check if we could paste this replay or not
	# (unless it's a web build, silly!
	if (is_web):
		pastereplaybutton.disabled = false;
		pastereplaybutton.text = "Paste Replay/Lvl";
		quitgamebutton.queue_free();
		#then re-do focus
		pastereplaybutton.focus_neighbour_bottom = pastereplaybutton.get_path_to(yourreplaybutton);
		yourreplaybutton.focus_neighbour_top = yourreplaybutton.get_path_to(pastereplaybutton);
	else:
		var clipboard = OS.get_clipboard();
		if (gamelogic.looks_like_level(clipboard)):
			pastereplaybutton.disabled = false;
			pastereplaybutton.text = "Paste Level";
		elif (gamelogic.is_valid_replay(clipboard)):
			pastereplaybutton.disabled = false;
			pastereplaybutton.text = "Paste Replay";
		else:
			pastereplaybutton.disabled = true;
			pastereplaybutton.text = "Paste Replay";
	
	okbutton.grab_focus();

func _yourreplaybutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	# must be kept in sync with GameLogic
	destroy();
	if (gamelogic.doing_replay):
		gamelogic.end_replay();
	gamelogic.start_saved_replay();
	gamelogic.update_info_labels();
	
func _authorsreplaybutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	# must be kept in sync with GameLogic
	destroy();
	gamelogic.authors_replay();
	gamelogic.update_info_labels();
	
func _savereplaybutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	if (gamelogic.won):
		if (!gamelogic.save_file["levels"].has(gamelogic.level_name)):
			gamelogic.save_file["levels"][gamelogic.level_name] = {};
		gamelogic.save_file["levels"][gamelogic.level_name]["replay"] = gamelogic.annotate_replay(gamelogic.user_replay);
		gamelogic.save_game();
		gamelogic.floating_text("Shift+F11: Replay force saved!");
	destroy();
	
func _copyreplaybutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	# must be kept in sync with GameLogic
	destroy();
	if (len(gamelogic.user_replay) > 0):
		OS.set_clipboard(gamelogic.annotate_replay(gamelogic.user_replay));
		gamelogic.floating_text("Ctrl+C: Replay copied");
	else:
		gamelogic.floating_text("Ctrl+C: Make some moves first!");
	
func _pastereplaybutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	# must be kept in sync with GameLogic
	destroy();
	var clipboard = OS.get_clipboard();
	if (gamelogic.looks_like_level(clipboard)):
		gamelogic.paste_level(clipboard);
	else:
		gamelogic.start_specific_replay(clipboard);
	
func _levelselectbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://LevelSelect.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	destroy();
	
func _insightbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	destroy();
	gamelogic.gain_insight();
	
func _controlsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Controls.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	destroy();
	
func _settingsbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	var a = preload("res://Settings.tscn").instance();
	self.get_parent().add_child(a);
	gamelogic.ui_stack.push_back(a);
	destroy();
	
func _restartbutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	destroy();
	# must be kept in sync with GameLogic "restart"
	gamelogic.end_replay();
	gamelogic.restart();
	gamelogic.update_info_labels();
	
func _quitgamebutton_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	get_tree().quit();

func destroy() -> void:
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_pressed("escape")):
		destroy();
	if (Input.is_action_just_pressed("ui_cancel")):
		destroy();
	if (Input.is_action_just_pressed("level_select")):
		_levelselectbutton_pressed();
	if (Input.is_action_just_pressed("gain_insight")):
		_insightbutton_pressed();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		okbutton.grab_focus();
		focus = okbutton;
	
	var focus_middle_x = focus.rect_position.x + focus.rect_size.x / 2;
	pointer.position.y = focus.rect_position.y + focus.rect_size.y / 2;
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = focus.rect_position.x + focus.rect_size.x + 12;
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = focus.rect_position.x - 12;
		
	# constantly check if we could paste this replay or not
	# (unless it's a web build, silly!
	if (is_web):
		pastereplaybutton.disabled = false;
		pastereplaybutton.text = "Paste Replay/Lvl";
	else:
		var clipboard = OS.get_clipboard();
		if (gamelogic.looks_like_level(clipboard)):
			pastereplaybutton.disabled = false;
			pastereplaybutton.text = "Paste Level";
		elif (gamelogic.is_valid_replay(clipboard)):
			pastereplaybutton.disabled = false;
			pastereplaybutton.text = "Paste Replay";
		else:
			pastereplaybutton.disabled = true;
			pastereplaybutton.text = "Paste Replay";

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
