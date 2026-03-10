extends Node

var _sfx_players: Dictionary = {}
var _bgm_player: AudioStreamPlayer

const SFX_PATHS := {
	"match": "res://assets/audio/sfx/match.wav",
	"swap": "res://assets/audio/sfx/swap.wav",
	"cascade": "res://assets/audio/sfx/cascade.wav",
	"booster": "res://assets/audio/sfx/booster.wav",
	"complete": "res://assets/audio/sfx/complete.wav",
	"fail": "res://assets/audio/sfx/fail.wav",
}

const BGM_PATHS := {
	"menu": "res://assets/audio/bgm/menu.ogg",
	"game": "res://assets/audio/bgm/game.ogg",
	"nightmare": "res://assets/audio/bgm/nightmare.ogg",
}

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Music"
	add_child(_bgm_player)
	GameEvents.gems_matched.connect(func(_c, _t): play_sfx("match"))
	GameEvents.cascade_started.connect(func(): play_sfx("cascade"))
	GameEvents.level_completed.connect(func(_s): play_sfx("complete"))
	GameEvents.level_failed.connect(func(): play_sfx("fail"))

func play_sfx(sfx_name: String) -> void:
	if not SFX_PATHS.has(sfx_name):
		return
	var path: String = SFX_PATHS[sfx_name]
	if not ResourceLoader.exists(path):
		return
	var player: AudioStreamPlayer
	if _sfx_players.has(sfx_name):
		player = _sfx_players[sfx_name]
	else:
		player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players[sfx_name] = player
	player.stream = load(path)
	player.play()

func play_bgm(bgm_name: String) -> void:
	if not BGM_PATHS.has(bgm_name):
		return
	var path: String = BGM_PATHS[bgm_name]
	if not ResourceLoader.exists(path):
		return
	_bgm_player.stream = load(path)
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()
