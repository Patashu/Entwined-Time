extends Node2D
class_name Controls

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Label = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var swapbutton : Button = get_node("Holder/SwapButton");
onready var resetbutton : Button = get_node("Holder/ResetButton");
onready var rebindingstuff : Node2D = get_node("Holder/RebindingStuff");
onready var deadzoneslider: HSlider = get_node("Holder/DeadzoneSlider");
onready var deadzonelabel: Label = get_node("Holder/DeadzoneLabel");
onready var debounceslider: HSlider = get_node("Holder/DebounceSlider");
onready var debouncelabel: Label = get_node("Holder/DebounceLabel");

var keyboard_mode = true;
var rebinding_button = null;
var buttons_by_action = {};
var just_danced = false;

# Must keep in sync with GameLogic serialize_bindings/deserialize_bindings
var actions = ["ui_accept", "ui_cancel", "escape", "ui_left", "ui_right", "ui_up", "ui_down",
"character_undo", "meta_undo", "character_switch", "restart",
"next_level", "previous_level", "mute", "start_replay", "speedup_replay",
"slowdown_replay", "start_saved_replay", 
"replay_back1", "replay_fwd1", "replay_pause", "gain_insight", "level_select", #zero-index 21, 22 total
"Ctrl+C: Copy Replay", "Ctrl+V: Paste Replay", "Shift+Replay Speed+: Max Replay Speed",
"Shift+Replay Speed-: Default Replay Speed", "Shift+Your Replay: Save Replay"
]

var hrn_actions = ["Accept", "Cancel", "Menu", "Left", "Right", "Up", "Down",
"Undo", "Meta-Undo", "Swap", "Restart",
"Next Lev/Chap", "Prev Lev/Chap", "Mute", "Author's Replay", "Replay Speed+",
"Replay Speed-", "Your Replay", "Replay Turn-", "Replay Turn+", "Replay Pause",
"Gain Insight", "Level Select"]

var blacklist_1 = ["ui_accept", "ui_cancel", "escape", "ui_left", "ui_right", "ui_up", "ui_down"];
var blacklist_2 = ["escape", "ui_left", "ui_right", "ui_up", "ui_down",
"character_undo", "meta_undo", "character_switch", "restart",
"next_level", "previous_level", "mute", "start_replay", "speedup_replay",
"slowdown_replay", "start_saved_replay", "gain_insight", "level_select",
"replay_back1", "replay_fwd1", "replay_pause"];
var whitelist_1 = ["speedup_replay", "slowdown_replay", "replay_back1", "replay_fwd1", "replay_pause"];
var whitelist_2 = ["previous_level", "next_level"];

var controller_images = [
	preload("res://controller_prompts/Positional_Prompts_Down.png"),
	preload("res://controller_prompts/Positional_Prompts_Right.png"),
	preload("res://controller_prompts/Positional_Prompts_Left.png"),
	preload("res://controller_prompts/Positional_Prompts_Up.png"),
	preload("res://controller_prompts/XboxSeriesX_LB.png"),
	preload("res://controller_prompts/XboxSeriesX_RB.png"),
	preload("res://controller_prompts/XboxSeriesX_LT.png"),
	preload("res://controller_prompts/XboxSeriesX_RT.png"),
	"L3",
	"R3",
	preload("res://controller_prompts/XboxSeriesX_View.png"),
	preload("res://controller_prompts/XboxSeriesX_Menu.png"),
	preload("res://controller_prompts/XboxSeriesX_Dpad_Up.png"),
	preload("res://controller_prompts/XboxSeriesX_Dpad_Down.png"),
	preload("res://controller_prompts/XboxSeriesX_Dpad_Left.png"),
	preload("res://controller_prompts/XboxSeriesX_Dpad_Right.png"),
	"Home",
	preload("res://controller_prompts/XboxSeriesX_Share.png"),
	"Paddle 1",
	"Paddle 2",
	"Paddle 3",
	"Paddle 4",
	"Touchpad",
];

var controller_labels = [
	"",
	"",
	"",
	"",
	"LB",
	"RB",
	"LT",
	"RT",
	"",
	"",
	"Select",
	"Start",
	"",
	"",
	"",
	"",
	"Share",
];

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	swapbutton.connect("pressed", self, "_swapbutton_pressed");
	resetbutton.connect("pressed", self, "_resetbutton_pressed");
	okbutton.grab_focus();
	keyboard_mode = !gamelogic.using_controller;
	
	if (gamelogic.save_file.has("deadzone")):
		deadzoneslider.value = gamelogic.save_file["deadzone"];
		updatelabeldeadzone(deadzoneslider.value);
	if (gamelogic.save_file.has("debounce")):
		debounceslider.value = gamelogic.save_file["debounce"];
		updatelabeldebounce(debounceslider.value);
	
	debounceslider.connect("value_changed", self, "_debounceslider_value_changed");
	
	setup_rebinding_stuff();

func _deadzoneslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["deadzone"] = value;
	gamelogic.setup_deadzone();
	updatelabeldeadzone(value);
	
func updatelabeldeadzone(value: float) -> void:
	deadzonelabel.text = "Deadzone: " + str(value);
	
func _debounceslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["debounce"] = value;
	updatelabeldebounce(value);
	
func updatelabeldebounce(value: float) -> void:
	debouncelabel.text = "Debounce: " + str(value) + "ms";
	
func _swapbutton_pressed() -> void:
	keyboard_mode = !keyboard_mode;
	setup_rebinding_stuff();

func _resetbutton_pressed() -> void:
	#seems OK to reset both keyboard and controller simultaneously
	InputMap.load_from_globals();
	setup_rebinding_stuff();
	
func remap_dance(button: BindingButton, new_event: InputEvent) -> void:
	just_danced = true;
	# if we WERE an event, erase it.
	if (button.event != null):
		InputMap.action_erase_event(button.action, button.event);
	# Now map the new one.
	if (new_event != null):
		InputMap.action_add_event(button.action, new_event);
		# The dance can contain itself...
		remap_dance_core(button.action, new_event);
	
	# Now refresh the bindings page to get everything back in canonical form.
	var refocus_action = button.action;
	var refocus_index = button.i;
	setup_rebinding_stuff();
	buttons_by_action[refocus_action][refocus_index].grab_focus();
	
func whitelisted(a: String, b: String) -> bool:
	if a == b:
		return true;
	if (keyboard_mode):
		return false;
	if whitelist_1.has(a) and whitelist_2.has(b):
		return true;
	if whitelist_2.has(a) and whitelist_1.has(b):
		return true;
	return false;
	
func remap_dance_core(action: String, new_event: InputEvent) -> void:
	pass
	# Now check blacklists and whitelists.
	# If something else shares a blacklist with us and doesn't share a white list with us,
	# erase the new input from it.
	for blacklist in [blacklist_1, blacklist_2]:
		if blacklist.has(action):
			for other_action in blacklist:
				if !whitelisted(action, other_action):
					if InputMap.action_has_event(other_action, new_event):
						InputMap.action_erase_event(other_action, new_event);
	
	# Now check that everything in blacklist 1 has an input still. If something doesn't, give it
	# event 1 (of the same keyboard/controller type) from the defaults. Loop until stable.
	for bully_action in blacklist_1:
		if get_event(bully_action, 0, keyboard_mode) == null:
			var bully_event = get_default_event(bully_action, 0, keyboard_mode);
			InputMap.action_add_event(bully_action, bully_event);
			remap_dance_core(bully_action, bully_event);
	
func setup_rebinding_stuff() -> void:
	if !keyboard_mode:
		holder.text = "Controller Controls:"
		swapbutton.text = "Keyboard Controls";
		deadzoneslider.visible = true;
		deadzonelabel.visible = true;
		debounceslider.visible = true;
		debouncelabel.visible = true;
	else:
		holder.text = "Keyboard Controls:"
		swapbutton.text = "Controller Controls";
		deadzoneslider.visible = false;
		deadzonelabel.visible = false;
		debounceslider.visible = false;
		debouncelabel.visible = false;
		
	var children = rebindingstuff.get_children();
	for child in children:
		child.queue_free();
		rebindingstuff.remove_child(child);
	rebinding_button = null;
	buttons_by_action.clear();
	
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
		if (action_is_special and !keyboard_mode):
			continue
		var label = Label.new();
		rebindingstuff.add_child(label);
		label.rect_position.x = round(xx + xxx*x);
		label.rect_position.y = round(yy + yyy*y + 2);
		if (action_is_special):
			label.text = action;
		else:
			label.text = hrn_actions[i] + ":";
			buttons_by_action[action] = [];
			for j in range(3):
				var button = Button.new();
				buttons_by_action[action].append(button);
				button.set_script(preload("res://BindingButton.gd"));
				button.parent = self;
				button.i = j;
				button.action = action;
				button.keyboard_mode = keyboard_mode;
				button.toggle_mode = true;
				button.event = get_event(button.action, button.i, button.keyboard_mode);
				rebindingstuff.add_child(button);
				button.rect_position.x = round(xx + xxx*x + xxx3 + xxx2*j);
				button.rect_position.y = round(yy + yyy*y);
				button.rect_size.x = xxx2-2;
				button.theme = holder.theme;
				button.clip_text = true;
				setup_button(button); #must happen after button.rect_size and button.clip_text
		label.theme = holder.theme;

func setup_button(button: Button) -> void:
	button.image = null;
	for child in button.get_children():
		child.queue_free();
	button.text = get_text(button.event);
	if (!keyboard_mode and button.text != ""):
		setup_controller_button(button);

func setup_controller_button(button: Button) -> void:
	var index = int(button.text);
	if index < controller_images.size():
		var image = controller_images[index];
		if image is Texture:
			var sprite = Sprite.new();
			sprite.scale = Vector2(1.0/7.0, 1.0/7.0);
			button.add_child(sprite);
			button.image = sprite;
			sprite.position = button.rect_size / 2;
			sprite.texture = image;
			if (index < controller_labels.size() and controller_labels[index] != ""):
				button.text = "    " + controller_labels[index];
				sprite.position.x = 10;
			else:
				button.text = "";
		else:
			button.text = image;
			return;

func get_event(action: String, i: int, keyboard_mode: bool) -> InputEvent:
	var events = InputMap.get_action_list(action);
	return get_event_core(events, i, keyboard_mode);
	
func get_default_event(action: String, i: int, keyboard_mode: bool) -> InputEvent:
	var events = ProjectSettings.get_setting("input/" + action)["events"];
	return get_event_core(events, i, keyboard_mode);

func get_event_core(events: Array, i: int, keyboard_mode: bool) -> InputEvent:
	var found = 0;
	for event in events:
		if (keyboard_mode and event is InputEventKey) or (!keyboard_mode and event is InputEventJoypadButton):
			if (found == i):
				return event;
			else:
				found += 1;
	return null;

func get_text(event: InputEvent) -> String:
	if (event != null):
		if (keyboard_mode):
			return event.as_text();
		else:
			return str(event.button_index);
	return "";

func destroy() -> void:
	gamelogic.serialize_bindings();
	gamelogic.save_game();
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
		
	if (!just_danced and rebinding_button == null and Input.is_action_just_pressed("escape")):
		destroy();
		return;
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		if rebinding_button == null:
			okbutton.grab_focus();
			focus = okbutton;
		else:
			focus = rebinding_button;
	
	if (!just_danced and rebinding_button == null and focus is BindingButton and Input.is_action_just_pressed("ui_cancel")):
		remap_dance(focus, null);
	
	if (focus != null):
		var focus_middle_x = round(focus.rect_position.x + focus.rect_size.x / 2);
		pointer.position.y = round(focus.rect_position.y + focus.rect_size.y / 2);
		if (focus_middle_x > holder.rect_size.x / 2):
			pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
			pointer.position.x = round(focus.rect_position.x + focus.rect_size.x + 12);
		else:
			pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
			pointer.position.x = round(focus.rect_position.x - 12);
			
	just_danced = false;

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);
