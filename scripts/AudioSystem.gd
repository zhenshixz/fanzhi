extends Node
class_name AudioSystem

var music_enabled := true

var _music: AudioStreamPlayer
var _sfx := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_load_sfx()
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.stream = load("res://assets/audio/music/southern_gothic.mp3")
	_music.volume_db = -13.0
	add_child(_music)
	_music.finished.connect(_on_music_finished)
	set_music_enabled(true)


func set_music_enabled(value: bool) -> void:
	music_enabled = value
	if not _music:
		return
	if value:
		if not _music.playing:
			_music.play()
	else:
		_music.stop()


func play_sfx(kind: String) -> void:
	if not _sfx.has(kind):
		return
	var player := AudioStreamPlayer.new()
	player.stream = _sfx[kind]
	player.volume_db = _volume_for(kind)
	add_child(player)
	_players.append(player)
	player.finished.connect(_on_sfx_finished.bind(player))
	player.play()


func _load_sfx() -> void:
	for kind in ["ui", "build", "upgrade", "shot", "hit", "death", "leak", "quake"]:
		var path := "res://assets/audio/sfx/%s.ogg" % kind
		if ResourceLoader.exists(path):
			_sfx[kind] = load(path)


func _volume_for(kind: String) -> float:
	match kind:
		"shot":
			return -16.0
		"hit":
			return -13.0
		"ui":
			return -12.0
		"quake":
			return -7.0
		"leak":
			return -8.0
		"build", "upgrade", "death":
			return -10.0
	return -12.0


func _on_music_finished() -> void:
	if music_enabled and _music:
		_music.play()


func _on_sfx_finished(player: AudioStreamPlayer) -> void:
	_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()
