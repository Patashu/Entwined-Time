extends Node

var STEAM_VERSION := true
var initialized := false
var steam_app_id: int = 3147300
var steam_id = 0
var steam_username := "You"
var steam_api: Object = null

func _ready() -> void:
	steam_api = Engine.get_singleton("Steam")
	initialize_steam()

func _process(_delta: float) -> void:
	steam_api.run_callbacks()

func initialize_steam() -> void:
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))
	
	var initialize_response: Dictionary = steam_api.steamInitEx(false, steam_app_id, true)
	print("Did Steam initialize?: %s" % initialize_response)

	if initialize_response['status'] > 0:
		initialized = false
		print("Failed to initialize Steam. %s" % initialize_response)
	else:
		initialized = true
		steam_id = steam_api.getSteamID()
		steam_username = steam_api.getPersonaName()
		steam_api.requestCurrentStats()

func check_achievement(ach_name):
	if not initialized: return false
	
	var ach = steam_api.getAchievement(ach_name)
	# Achievement exists
	if ach['ret']:
		if ach['achieved']:
			return true
		else:
			return false
	else:
		return false


func set_achievement(ach_name):
	if not initialized: return
	
	if not check_achievement(ach_name):
		steam_api.setAchievement(ach_name)
		steam_api.storeStats()


func clear_achievement(ach_name):
	if not initialized: return
	
	steam_api.clearAchievement(ach_name)
	steam_api.storeStats()
