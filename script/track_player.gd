extends AudioStreamPlayer
##（自拟）使用子线程，专门用于 高精度时间 的程序。用于调用高精度get_playback_position()。（有些 地方不精确也没事，比如：是否在判定窗口，只要进入和出去的时刻对就算行）

const await_time = 3##谱面开始前等待时间

func _ready() -> void:
	
	#（未启用）调整音频缓冲区等操作，由于问题无效
	#region
	#ProjectSettings.set_setting("audio/driver/output_latency", 0.05)

	#match OS.get_name():
		#"Windows":
			##启用Windows独占音频模式（降低延迟）
			#ProjectSettings.set_setting("audio/driver/windows/use_exclusive_audio", true)
		#
		#"Android":
			##Android
			#ProjectSettings.set_setting("audio/driver/android/use_aaudio_exclusive", true)
		#
		#"iOS":
			##iOS
			#ProjectSettings.set_setting("audio/driver/coreaudio/exclusive", true)
	#endregion
	
	##子线程
	running = true
	thread.start(_audio_thread)

	await get_tree().create_timer(await_time).timeout#谱面开始前等待，而不是一加载完毕就突然开始
	play()



##子线程调用get_playback_position()
var thread_track_player_position: float##（重要）（全局引用同步）统一引用一个get_playback_position()

var thread = Thread.new()
var running = false
var mutex = Mutex.new()
func _audio_thread() -> void:##（重要）子线程
	while running:
		
		OS.delay_msec(0)#（重要）改变检测频率
		var a = get_playback_position()
		mutex.lock()
		if not thread_track_player_position == a:
			thread_track_player_position = a
		#print(thread_track_player_position)
		mutex.unlock()


func _exit_tree() -> void:# 停止线程（节点释放时自动调用）
	running = false
	thread.wait_to_finish()
