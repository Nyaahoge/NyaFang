##（自拟）使用子线程，专门用于 高精度时间 的程序
##（错）好像这个脚本本来不需要单独搞子线程的，难改了，出问题再看吧


class_name MfObjectsLifecycle
extends Node



@onready var mf_object_pool: Node = $"../MfObjectPool"
@onready var track_player: AudioStreamPlayer = $"../TrackPlayer"#在 _audio_thread()里使用(track_player.get_playback_position() + AudioServer.get_time_since_last_mix())
@onready var json_file_operator: Node = $"../JsonFileOperator"
@onready var game: Node = $"../Game"
@onready var mf_objects: Node2D = $"../MfObjects"





#const SAMPLE_RATE = 44100#直接使用 _audio_thread()里的(track_player.get_playback_position() + AudioServer.get_time_since_last_mix()) 即可
#const BUFFER_SIZE = 4096  #无用，godot自动配置缓冲区

var thread = Thread.new()
var running = false
var mutex = Mutex.new()  # 线程锁


var thread_track_player_position: float


func _ready() -> void:# 初始化并启动线程
	
	await mf_object_pool.ready#避免mf_chart_scene生成所有MfObject前此节点脚本就开始运行检测
	#print("MfObjectLifecycle :   启动")
	running = true
	thread.start(_audio_thread)







#var thread_track_player_position: float

#var old_mf_objects_index: int#用于确定在主线程里哪些MfObject需要添加
var mf_objects_index: int = -1#用于标记在作为谱面文件的json文件中，通过对象池生成了MfObjects里第几个MfObject，-1表示还未生成下标为0的MfObject
var will_get_objects: Array#记录字典里MfObjects数组下标
var will_return_objects: Array#记录具体哪些对象
var current_mf_objects: Array#当前在谱面上的MfObject

func _audio_thread() -> void:##（重要）子线程
	while running:
		
		OS.delay_msec(0)#（重要）改变检测频率
		
		var a = track_player.get_playback_position()
		mutex.lock()
		if not thread_track_player_position == a:
			thread_track_player_position = a
		#print(thread_track_player_position)
		mutex.unlock()
		
		chack_get_mf_object()
		chack_return_mf_object()
		
		
		






func chack_get_mf_object() -> void:##检查是否要从对象池里获取MfObject并添加到谱面上。场景树操作必须在主线程执行，因此返回要操作的对象在主线程上执行操作。
	mutex.lock()#包围的代码称为临界区，同一时间只能有一个线程进入临界区。通过锁机制，确保对共享资源的修改是串行化的，避免并发冲突。主线程和子线程分别为两个线程都需要在各自操作共享资源部分加锁。
	
	if track_player.playing:
		while mf_objects_index + 1 < json_file_operator.chart_data["sum_mf_object_count"] && (thread_track_player_position - game.latency_adjustment) >= json_file_operator.chart_data["mf_objects"][mf_objects_index + 1]["exist_period"]["start"]:
			will_get_objects.push_back(mf_objects_index + 1)
			mf_objects_index += 1
			#print("[MfObjectLifecycle]    ", (thread_track_player_position), "  要添加", "一个MfObject")
	mutex.unlock()
	call_deferred("_get_mf_object_go_to_main_thread")#线程安全相关节点操作推迟到主线程



func chack_return_mf_object() -> void:##检查是否要把MfObject从谱面上移除并回收进对象池。场景树操作必须在主线程执行，因此返回要操作的对象在主线程上执行操作。
	mutex.lock()
	
	if track_player.playing:
		if current_mf_objects.size() > 0:
			for i in current_mf_objects:
				if i not in will_return_objects && (thread_track_player_position - game.latency_adjustment) >= i.exist_period["over"]:
					will_return_objects.push_back(i)
					#print("[MfObjectLifecycle]    ", (thread_track_player_position), "  要移除", "一个MfObject")
					
			call_deferred("_return_mf_object_go_to_main_thread")#线程安全相关节点操作推迟到主线程
	
	
	mutex.unlock()
	
	
	
	
	
#添加进谱面
func _get_mf_object_go_to_main_thread() -> void:
	while will_get_objects.size() > 0:
		var mf_obj = mf_object_pool.get_object()
		mutex.lock()
		
		mf_obj.initialize(json_file_operator.chart_data["mf_objects"][will_get_objects.pop_front()])#初始化对象
		current_mf_objects.push_back(mf_obj)
		mf_obj.curve_handling()
		mf_obj.show()#显示对象（如果之前被隐藏）
		
		#print("[MfObjectLifecycle]    ", (thread_track_player_position), "  添加成功  ", mf_obj)
		mutex.unlock()
	
#从谱面移除
func _return_mf_object_go_to_main_thread() -> void:
	mutex.lock()
	while will_return_objects.size() > 0:
		var mf_obj = will_return_objects.pop_front()
		
		current_mf_objects.erase(mf_obj)
		mf_object_pool.return_object(mf_obj)#回收
		
		#print("[MfObjectLifecycle]    ", (thread_track_player_position), "  移除成功  ", mf_obj)
	mutex.unlock()
	

func _exit_tree() -> void:# 停止线程（节点释放时自动调用）
	running = false
	thread.wait_to_finish()
