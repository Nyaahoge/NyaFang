extends Node

@onready var camera_2d: Camera2D = $"../../Camera2D"

@onready var hit_judgment: HitJudgment = $"../HitJudgment"
@onready var track_player: AudioStreamPlayer = $"../../TrackPlayer"
@onready var chart_view: Node2D = $"../../ChartView"





#func _ready() -> void:
	#fingers_tracking_initialize()

func _input(event: InputEvent) -> void:
	tap_action_fingers_states(event)
	fingers_tracking(event)
	
func _physics_process(delta: float) -> void:
	touch_action_fingers_states()
	#print(hit_judgment.tap_action_mf_objects_priority)
	#print("[FingersTracker]    ", fingers)








##触屏手指实时追踪模块（用于支持逻辑判断手指的音游打击操作，用于Drag和Hold的判定，具体思路可直接让激活检测接按操作的MfObject在fingers里遍历坐标确定是否被接按即可。是因为引擎不支持检测手指按着进出Area2D）
#region
var fingers: Array##（重要）所有触屏手指屏幕位置。下标对应引擎触控点事件的index，若某index无手指则为null。
#func fingers_tracking_initialize() -> void:
	#pass
func fingers_tracking(event) -> void:##触屏就检测（检测到后手指坐标记录由 屏幕视图坐标 变换成的 世界坐标）
	
	##移动端
	if OS.get_name() == "Android":
		if event is InputEventScreenTouch and event.pressed:##添加新触控点。godot虽然说数组会自动扩展保证fingers空间足够，但声明时还是要初始化要填的位置为null，是因为有bug会自动判断类型。
			while fingers.size() <= event.index:##保证fingers空间足够
				fingers.push_back(null)
		
		if event is InputEventScreenTouch or event is InputEventScreenDrag:##更新触控点坐标
			var finger_position = view_to_chart_pos(event.position)
			fingers[event.index] = finger_position
		
		if event is InputEventScreenTouch and not event.pressed:##删除抬起的触控点
			fingers[event.index] = null
	
	
	
	
	
	##PC端（调试）
	if OS.get_name() == "Windows":
		if Input.is_action_pressed("mouse_hold"):##更新触控点坐标
			var finger_position = view_to_chart_pos(event.position)
			fingers = [finger_position]
		else:
			fingers = []
	
	
	
#endregion









##tap动作手指触控MfObject判断模块（实时判断手指对MfObject的触控情况）（tap动作触控点在该函数内直接检测调用判定函数）
func tap_action_fingers_states(event: InputEvent):
	
	###移动端
	#if event is InputEventScreenTouch:
		#if event.pressed:
			#print("手指按下")
			#var i: int = 0#（临时）
			#while i < hit_judgment.tap_action_mf_objects_priority.size():
				#var mf_obj = hit_judgment.tap_action_mf_objects_priority[i]
				#if is_in_mf_object(event.position, mf_obj):
					#print("in")
					#hit_judgment.remove_from_priority(mf_obj)
					#mf_obj.hit_jugement(track_player.thread_track_player_position)
					#break
				#i += 1
	
	##移动端
	if OS.get_name() == "Android":
		if event is InputEventScreenTouch:
			if event.pressed:
				#print("[FingersTracker]    ", track_player.thread_track_player_latency_position, "    手指按下")
				var finger_position = view_to_chart_pos(event.position)
				hit_judgment.tap_action_hit_judgment(finger_position)
	
	
	
	##PC端（调试）
	if OS.get_name() == "Windows":
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#print("[FingersTracker]    ", track_player.thread_track_player_latency_position, "    鼠标左键按下")
				var finger_position = view_to_chart_pos(event.position)
				hit_judgment.tap_action_hit_judgment(finger_position)
	
	###PC端（调试）
	#if OS.get_name() == "Windows":
		#if event is InputEventMouseButton:
			#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				#print("鼠标左键按下")
				#var finger_position = (event.position - Vector2(chart_view.viewport_size) / 2) / chart_view.viewport_chart_ratio
				#var i: int = 0#（临时）
				#while i < hit_judgment.tap_action_mf_objects_priority.size():
					#var mf_obj = hit_judgment.tap_action_mf_objects_priority[i]
					#if is_in_mf_object(finger_position, mf_obj):##注意把事件位置变换成世界坐标
						#print("in")
						#hit_judgment.remove_from_priority(mf_obj)
						#mf_obj.hit_jugement(track_player.thread_track_player_position)
						#break
					#i += 1
	
	
	
	
	#is_in_mf_object()
	
	
##touch动作手指触控MfObject判断模块（实时判断手指对MfObject的触控情况）（toush动作触控点把它碰到的键添加进数组后续访问）
func touch_action_fingers_states():
	hit_judgment.touch_action_hit_judgment()








func view_to_chart_pos(pos: Vector2) -> Vector2:##（工具）由（事件）视图位置变换为（世界）谱面位置（1获取事件坐标event.position为窗口屏幕坐标（左上角为(0，0)），2平移成中心为(0,0)的窗口屏幕坐标，3通过比例放缩为世界坐标）
	if chart_view.is_expand_screen_aspect_ratio_more_than_view_aspect_ratio:
		return (pos - chart_view.expand_viewport_size / 2) / chart_view.expand_screen_chart_ratio
	else:
		return (pos - chart_view.expand_viewport_size / 2) / chart_view.expand_screen_chart_ratio
