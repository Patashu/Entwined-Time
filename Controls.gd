extends Node2D
class_name Controls

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var swapbutton : Button = get_node("Holder/SwapButton");
onready var resetbutton : Button = get_node("Holder/ResetButton");
onready var rebindingstuff : Node2D = get_node("Holder/RebindingStuff");

var keyboard_mode = true;

var actions = ["ui_accept", "ui_cancel", "escape", "ui_left", "ui_right", "ui_up", "ui_down",
"character_undo", "meta_undo", "character_switch", "restart",
"next_level", "previous_level", "mute", "start_replay", "speedup_replay",
"slowdown_replay", "start_saved_replay", "gain_insight", "level_select", #zero-index 19, 20 total
"Ctrl+C: Copy Replay", "Ctrl+V: Paste Replay", "Shift+speedup_replay: Max Replay Speed",
"Shift+slowdown_replay: Default Replay Speed", "Shift+start_saved_replay: Save Replay"
]

var hrn_actions = ["Accept", "Cancel", "Menu", "Left", "Right", "Up", "Down",
"Undo", "Meta-Undo", "Swap", "Restart",
"Next Lev/Chap", "Prev Lev/Chap", "Mute", "Author's Replay", "Replay Speed+",
"Replay Speed-", "Your Replay", "Gain Insight", "Level Select"]

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	swapbutton.connect("pressed", self, "_swapbutton_pressed");
	resetbutton.connect("pressed", self, "_resetbutton_pressed");
	okbutton.grab_focus();
	keyboard_mode = !gamelogic.using_controller;
	
	setup_rebinding_stuff();
	
func _swapbutton_pressed() -> void:
	keyboard_mode = !keyboard_mode;
	setup_rebinding_stuff();

func _resetbutton_pressed() -> void:
	pass #TODO
	
func setup_rebinding_stuff() -> void:
	if !keyboard_mode:
		holder.text = "Controller Controls:"
		swapbutton.text = "Keyboard Controls";
	else:
		holder.text = "Keyboard Controls:"
		swapbutton.text = "Controller Controls";
		
	var children = rebindingstuff.get_children();
	for child in children:
		child.queue_free();
		rebindingstuff.remove_child(child);
	
	var half_way = int(ceil(actions.size() / 2));
	var yy = 12;
	var yyy = 16;
	var xx = 4;
	var xxx = int(floor(holder.rect_size.x / 8))-2;
	var xxx2 = xxx-7;
	var xxx3 = xxx+21;
	
	for i in range(actions.size()):
		var x = 0;
		var y = i;
		if i >= half_way:
			x += 4;
			y -= half_way;
		var action = actions[i];
		var action_is_special = action.find(":") > -1;
		var label = Label.new();
		rebindingstuff.add_child(label);
		label.rect_position.x = round(xx + xxx*x);
		label.rect_position.y = round(yy + yyy*y + 2);
		if (action_is_special):
			label.text = action;
		else:
			label.text = hrn_actions[i] + ":";
			for j in range(3):
				var button = Button.new();
				rebindingstuff.add_child(button);
				button.rect_position.x = round(xx + xxx*x + xxx3 + xxx2*j);
				button.rect_position.y = round(yy + yyy*y);
				button.rect_size.x = xxx2-2;
				button.text = get_binding(action, j);
				button.theme = holder.theme;
				button.clip_text = true;
		label.theme = holder.theme;

func get_binding(action: String, i: int) -> String:
	var events = InputMap.get_action_list(action);
	var found = 0;
	for event in events:
		if (keyboard_mode and event is InputEventKey) or (!keyboard_mode and event is InputEventJoypadButton):
			if (found == i):
				if (keyboard_mode):
					return event.as_text();
				else:
					return str(event.button_index);
			else:
				found += 1;
	return "";

func destroy() -> void:
	gamelogic.save_game();
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	# TODO: but don't do this while rebinding keys
	if (Input.is_action_just_released("escape")):
		destroy();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		okbutton.grab_focus();
		focus = okbutton;
	
	var focus_middle_x = round(focus.rect_position.x + focus.rect_size.x / 2);
	pointer.position.y = round(focus.rect_position.y + focus.rect_size.y / 2);
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = round(focus.rect_position.x + focus.rect_size.x + 12);
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = round(focus.rect_position.x - 12);

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
