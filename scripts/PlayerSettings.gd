extends RefCounted
class_name PlayerSettings

const SAVE_PATH := "user://xixi_castle_settings.cfg"
const TOWER_ORDER := ["maw", "spore", "sigil", "rainbow", "mascot", "moon", "love"]
const DEFAULT_TOWER_NAMES := {
	"maw": "星光",
	"spore": "冰晶",
	"sigil": "爱心",
	"rainbow": "彩虹",
	"mascot": "萌兔",
	"moon": "月亮",
	"love": "信标"
}
const GAME_VALUE_ORDER := ["coins", "life", "star_power", "start_wave"]
const DEFAULT_GAME_VALUES := {
	"coins": 999,
	"life": 12,
	"star_power": 0,
	"start_wave": 1
}
const GAME_VALUE_LIMITS := {
	"coins": Vector2i(0, 99999),
	"life": Vector2i(1, 999),
	"star_power": Vector2i(0, 100),
	"start_wave": Vector2i(1, 99)
}


static func load_tower_names() -> Dictionary:
	var names := DEFAULT_TOWER_NAMES.duplicate(true)
	var config := _load_config()
	for type in TOWER_ORDER:
		var value := str(config.get_value("tower_names", type, names[type])).strip_edges()
		if value != "":
			names[type] = value.substr(0, 6)
	return names


static func save_tower_names(names: Dictionary) -> void:
	var config := _load_config()
	for type in TOWER_ORDER:
		var value := str(names.get(type, DEFAULT_TOWER_NAMES[type])).strip_edges()
		if value == "":
			value = DEFAULT_TOWER_NAMES[type]
		config.set_value("tower_names", type, value.substr(0, 6))
	config.save(SAVE_PATH)


static func reset_tower_names() -> void:
	save_tower_names(DEFAULT_TOWER_NAMES)


static func load_game_values() -> Dictionary:
	var values := DEFAULT_GAME_VALUES.duplicate(true)
	var config := _load_config()
	for key in GAME_VALUE_ORDER:
		values[key] = _clamp_game_value(key, int(config.get_value("game_values", key, values[key])))
	return values


static func save_game_values(values: Dictionary) -> void:
	var config := _load_config()
	for key in GAME_VALUE_ORDER:
		config.set_value("game_values", key, _clamp_game_value(key, int(values.get(key, DEFAULT_GAME_VALUES[key]))))
	config.save(SAVE_PATH)


static func reset_all_settings() -> void:
	var config := ConfigFile.new()
	for type in TOWER_ORDER:
		config.set_value("tower_names", type, DEFAULT_TOWER_NAMES[type])
	for key in GAME_VALUE_ORDER:
		config.set_value("game_values", key, DEFAULT_GAME_VALUES[key])
	config.save(SAVE_PATH)


static func _load_config() -> ConfigFile:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	return config


static func _clamp_game_value(key: String, value: int) -> int:
	var limits: Vector2i = GAME_VALUE_LIMITS.get(key, Vector2i(0, 99999))
	return clampi(value, limits.x, limits.y)
