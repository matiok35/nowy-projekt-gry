extends Node

var build_sound: AudioStreamPlayer
var error_sound: AudioStreamPlayer
var heal_sound: AudioStreamPlayer
var potions_sound: AudioStreamPlayer
var recruit_sound: AudioStreamPlayer
var temple_sound: AudioStreamPlayer
var tree_sound: AudioStreamPlayer
var bg_music: AudioStreamPlayer
var steps_sound: AudioStreamPlayer
var buy_sound: AudioStreamPlayer

func _ready() -> void:
	build_sound = _create_player("res://assets/sounds/builded.mp3")
	error_sound = _create_player("res://assets/sounds/error.mp3")
	heal_sound = _create_player("res://assets/sounds/heal.mp3")
	potions_sound = _create_player("res://assets/sounds/potions.mp3")
	recruit_sound = _create_player("res://assets/sounds/recrut.mp3")
	temple_sound = _create_player("res://assets/sounds/temple.mp3")
	tree_sound = _create_player("res://assets/sounds/tree.mp3")
	
	steps_sound = _create_player("res://assets/sounds/steps.mp3")
	buy_sound = _create_player("res://assets/sounds/buy.mp3")
	
	bg_music = _create_player("res://assets/sounds/bg3.mp3")
	if bg_music and bg_music.stream:
		if bg_music.stream is AudioStreamMP3:
			bg_music.stream.loop = true
		bg_music.volume_db = -25.0

func _create_player(path: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	var stream = load(path)
	if stream:
		p.stream = stream
		p.volume_db = -25.0
		add_child(p)
	else:
		push_error("AudioManager: Could not load sound from " + path)
	return p

func play_build() -> void: if build_sound: build_sound.play()
func play_error() -> void: if error_sound: error_sound.play()
func play_heal() -> void: if heal_sound: heal_sound.play()
func play_potions() -> void: if potions_sound: potions_sound.play()
func play_recruit() -> void: if recruit_sound: recruit_sound.play()
func play_temple() -> void: if temple_sound: temple_sound.play()
func play_tree() -> void: if tree_sound: tree_sound.play()
func play_steps() -> void: if steps_sound and not steps_sound.playing: steps_sound.play()
func stop_steps() -> void: if steps_sound and steps_sound.playing: steps_sound.stop()
func play_bg_music() -> void: if bg_music and not bg_music.playing: bg_music.play()
func stop_bg_music() -> void: if bg_music and bg_music.playing: bg_music.stop()
func pause_bg_music() -> void: if bg_music: bg_music.stream_paused = true
func resume_bg_music() -> void: if bg_music: bg_music.stream_paused = false
func play_buy() -> void: if buy_sound: buy_sound.play()
