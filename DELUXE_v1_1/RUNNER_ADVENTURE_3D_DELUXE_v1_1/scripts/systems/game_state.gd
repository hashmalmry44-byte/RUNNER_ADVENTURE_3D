extends Node
## Persistent player profile and shared game state.

const SAVE_PATH := "user://runner_adventure_save.json"
const SAVE_VERSION := 1

var profile: Dictionary = {
	"version": SAVE_VERSION,
	"best_score": 0,
	"total_coins": 0,
	"total_gems": 0,
	"unlocked_characters": ["sahra"],
	"selected_character": "sahra",
	"purchased_items": [],
	"missions": {},
	"achievements": [],
	"settings": {
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"vibration": true,
		"graphics_quality": 1
	}
}

func _ready() -> void:
	load_profile()

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_profile()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("تعذر فتح ملف الحفظ؛ سيتم استخدام ملف جديد.")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		profile = _merge_defaults(profile, parsed)
	else:
		push_warning("ملف الحفظ غير صالح؛ لم يتم استبداله تلقائياً.")

func save_profile() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("تعذر حفظ تقدم اللاعب.")
		return
	file.store_string(JSON.stringify(profile, "\t"))

func _merge_defaults(defaults: Dictionary, loaded: Dictionary) -> Dictionary:
	var merged := defaults.duplicate(true)
	for key in loaded:
		if merged.has(key) and merged[key] is Dictionary and loaded[key] is Dictionary:
			merged[key] = _merge_defaults(merged[key], loaded[key])
		else:
			merged[key] = loaded[key]
	return merged

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	profile["total_coins"] = int(profile.get("total_coins", 0)) + amount
	save_profile()

func add_gems(amount: int) -> void:
	if amount <= 0:
		return
	profile["total_gems"] = int(profile.get("total_gems", 0)) + amount
	save_profile()

func update_best_score(score: int) -> void:
	if score > int(profile.get("best_score", 0)):
		profile["best_score"] = score
		save_profile()

func reset_profile() -> void:
	profile = {
		"version": SAVE_VERSION,
		"best_score": 0,
		"total_coins": 0,
		"total_gems": 0,
		"unlocked_characters": ["sahra"],
		"selected_character": "sahra",
		"purchased_items": [],
		"missions": {},
		"achievements": [],
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"vibration": true,
			"graphics_quality": 1
		}
	}
	save_profile()
