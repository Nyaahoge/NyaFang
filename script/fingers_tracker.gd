extends Node2D


@onready var mf_objects_priority: Node = $"../MfObjectsPriority"
@onready var track_player: AudioStreamPlayer = $"../../TrackPlayer"


#func _ready() -> void:
	#fingers_tracking_initialize()

func _input(event: InputEvent) -> void:
	tap_action_fingers_states(event)
	fingers_tracking(event)
	
func _physics_process(delta: float) -> void:
	hold_action_fingers_states()
	print(mf_objects_priority.tap_in_or_hold_in_mf_objects_priority)






##触屏手指实时追踪模块（返回到under_finger_mf_objects）（用于支持逻辑判断手指的音游打击操作，用于Drag和Hold的判定，具体思路可直接让激活检测接按操作的MfObject在fingers里遍历坐标确定是否被接按即可。是因为引擎不支持检测手指按着进出Area2D）
#region
var fingers: Array##（重要）所有触屏手指屏幕位置。下标对应引擎触控点事件的index，若某index无手指则为null。
var under_finger_mf_objects: Array##触屏手指按到的mf_object
#func fingers_tracking_initialize() -> void:
	#pass

func fingers_tracking(event) -> void:
	
	var finger_position = event.position - Vector2(get_viewport().size) / 2##触控点的世界坐标
	
	
	##触屏就检测型触控点
	if event is InputEventScreenTouch and event.pressed:##添加新触控点
			while fingers.size() <= event.index:##保证fingers空间足够
				fingers.push_back(null)
	
	if event is InputEventScreenTouch or event is InputEventScreenDrag:##更新触控点坐标
		fingers[event.index] = finger_position
		
	if event is InputEventScreenTouch and not event.pressed:##删除抬起的触控点
			fingers[event.index] = null
	
	
	
	
	##点击检测型触控点
	if event is InputEventScreenTouch and event.pressed:
		var tap_in_or_hold_in_mf_objects
#endregion

##tap动作手指触控MfObject判断模块（实时判断手指对MfObject的触控情况）（tap动作（按下）触控点在该函数内直接检测回调判定函数；hold动作（接触到屏幕）触控点把它碰到的键添加进数组后续访问）
func tap_action_fingers_states(event: InputEvent):
	
	##移动端
	if event is InputEventScreenTouch:
		if event.pressed:
			print("手指按下")
			var i: int = 0#（临时）
			while i < mf_objects_priority.tap_in_or_hold_in_mf_objects_priority.size():
				var mf_obj = mf_objects_priority.tap_in_or_hold_in_mf_objects_priority[i]
				if is_in_mf_object(event.position, mf_obj):
					print("in")
					mf_objects_priority.remove_from_priority(mf_obj)
					mf_obj.hit_jugement(track_player.thread_track_player_position)
					break
				i += 1
	
	
	
	##PC端（调试）
	if OS.get_name() == "Windows":
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				print("鼠标左键按下")
				var i: int = 0#（临时）
				while i < mf_objects_priority.tap_in_or_hold_in_mf_objects_priority.size():
					var mf_obj = mf_objects_priority.tap_in_or_hold_in_mf_objects_priority[i]
					if is_in_mf_object(event.position, mf_obj):
						print("in")
						mf_objects_priority.remove_from_priority(mf_obj)
						mf_obj.hit_jugement(track_player.thread_track_player_position)
						break
					i += 1
	
	
	
	
	
	#is_in_mf_object()
	pass
	
##hold动作手指触控MfObject判断模块（实时判断手指对MfObject的触控情况）（tap动作触控点在该函数内直接检测回调判定函数；hold动作触控点把它碰到的键添加进数组后续访问）
func hold_action_fingers_states():
	
	
	
	
	
	
	#is_in_mf_object()
	pass

func is_in_mf_object(pos: Vector2, mf_obj: MfObject) -> bool:##（重要）判断一个 世界坐标 是否在一个 MfObject 里。用于检测手指是否碰到MfObject。
	var mf_obj_pos = (pos - mf_obj.path_follow_2d.position).rotated(deg_to_rad(- mf_obj.shape.rotation_degrees))
	return - mf_obj.curve_size.x / 2 <= mf_obj_pos.x  && mf_obj_pos.x <= mf_obj.curve_size.x / 2 && - mf_obj.curve_size.y / 2 <= mf_obj_pos.y && mf_obj_pos.y <= mf_obj.curve_size.y / 2
