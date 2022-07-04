extends AudioStreamPlayer3D

#class_name ChaoticAudioStreamPlayer3D

export(String) var bus_out = 'Master'
export(bool) var start_timer_on_ready = false
export(bool) var play_on_ready = false
export(Array, AudioStream) var streams
export(bool) var chaos = true
export(float) var max_delay = 0.5
export(float) var min_delay = 0
export(float, 0, 1) var pitch_shift = 0

signal volume_adjusted

# 0 - not playing
# 1 - playing once
# 2 - playing forever
var _mode = 0
var _timer
var _peak0 = -200
var _peak1 = -200
var _bus_index = 0
var _oneshot_is_done = false

func play_once():
	play()
	_mode = 1

func play_forever():
	_setup_timer()
	_mode = 2
	
func stop():
	stop()
	_mode = 0

func _ready():
	_queue()
	set_bus(bus_out)
	
	# Create a timer for looping and chaos
	randomize()
	_timer = Timer.new()
	_timer.connect("timeout", self, "_timeout_handler")
	_timer.set_one_shot(true)
	add_child(_timer)
	
	if !chaos:
		min_delay = 0
		max_delay = 0
	
	# This will play the music before everything else is loaded. Intentional
	# for emoji frog's presentation.
	if play_on_ready:
		play_once()
	
	if start_timer_on_ready:
		play_forever()

func _setup_timer():
	var wait = (randf() * (max_delay - min_delay)) + min_delay + get_stream().get_length()
	_timer.set_wait_time(wait)
	_timer.start()

func _timeout_handler():
	_queue()
	
	if chaos:
		var wait = (randf() * (max_delay - min_delay)) + min_delay + get_stream().get_length()
		_oneshot_is_done = true
	
	_setup_timer()
	play()

func _queue():
	if chaos:
		var scale_to = 1 - (randf() * (pitch_shift * 2)) + pitch_shift
		set_pitch_scale(scale_to)
	
	var index = randi() % len(streams)
	set_stream(streams[index])
