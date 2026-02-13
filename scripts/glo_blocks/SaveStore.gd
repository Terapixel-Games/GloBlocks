extends Node

const SAVE_PATH := "user://globlocks_save.json"

var data: Dictionary = {}

func _ready() -> void:
	load_save()

func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		data = {}
		save()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		data = parsed.duplicate(true)

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

func get_int(key: String, fallback: int = 0) -> int:
	if not data.has(key):
		return fallback
	return int(data[key])

func set_int(key: String, value: int) -> void:
	data[key] = value
	save()

func get_float(key: String, fallback: float = 0.0) -> float:
	if not data.has(key):
		return fallback
	return float(data[key])

func set_float(key: String, value: float) -> void:
	data[key] = value
	save()
