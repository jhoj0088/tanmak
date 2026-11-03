extends Node
## 소리 (자동 로드 "Snd"). 효과음은 코드로 합성하고, 음악은 assets/music/*.ogg 를 튼다.
## 음악 파일을 같은 이름의 다른 .ogg 로 바꾸면 그대로 교체된다.

var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer
var _music_name := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sfx["blip"] = _tone(620.0, 0.035, 0.12, "square")
	_sfx["move"] = _tone(440.0, 0.04, 0.15, "square")
	_sfx["select"] = _tone(880.0, 0.07, 0.2, "square")
	_sfx["hurt"] = _tone(160.0, 0.25, 0.4, "noise")
	_sfx["hit"] = _tone(320.0, 0.2, 0.3, "square", -900.0)
	_sfx["graze"] = _tone(1500.0, 0.03, 0.08, "sine")
	_sfx["heal"] = _tone(500.0, 0.3, 0.2, "square", 1200.0)
	_sfx["door"] = _tone(260.0, 0.12, 0.2, "square", -600.0)
	_sfx["encounter"] = _tone(900.0, 0.3, 0.25, "square", -1500.0)
	_sfx["bomb"] = _tone(200.0, 0.5, 0.4, "noise", 0.0)
	_sfx["correct"] = _tone(660.0, 0.25, 0.2, "square", 900.0)
	_sfx["wrong"] = _tone(220.0, 0.3, 0.25, "square", -300.0)
	_sfx["save"] = _tone(780.0, 0.4, 0.2, "sine", 600.0)
	_sfx["warn"] = _tone(1100.0, 0.08, 0.15, "square")
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -8.0
	add_child(_music)


func play(n: String) -> void:
	if not _sfx.has(n):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = _sfx[n]
	p.play()


func play_music(n: String) -> void:
	if n == _music_name:
		return
	_music_name = n
	_music.stop()
	if n == "":
		return
	var path := "res://assets/music/%s.ogg" % n
	if not ResourceLoader.exists(path):
		return
	var s = load(path)
	if s is AudioStreamOggVorbis:
		s.loop = true
	_music.stream = s
	_music.play()


func stop_music() -> void:
	play_music("")


func music_name() -> String:
	return _music_name


## 지금 재생 중인 음악의 위치(초). 박자 맞추기에 쓴다. 재생 중이 아니면 -1.
func music_time() -> float:
	if not _music.playing:
		return -1.0
	return maxf(0.0, _music.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())


func _tone(freq: float, dur: float, vol: float, kind: String, slide := 0.0) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n)
	var phase := 0.0
	for i in n:
		var tt := float(i) / rate
		phase += maxf(20.0, freq + slide * tt) / rate
		var v := 0.0
		match kind:
			"square":
				v = 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
			"noise":
				v = randf() * 2.0 - 1.0
			_:
				v = sin(phase * TAU)
		var env := 1.0 - float(i) / n
		data[i] = int(clampf(v * vol * env, -1.0, 1.0) * 127.0) & 0xFF
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = rate
	s.data = data
	return s
