class_name HitJugdment##用于访问枚举
extends Node

@onready var track_player: AudioStreamPlayer = $"../../TrackPlayer"
@onready var game: Node2D = $".."
@onready var fingers_tracker: Node2D = $"../FingersTracker"

enum HitScore {##枚举打击评分（包括miss）
	PERFECT,
	EARLY_GOOD,
	LATE_GOOD,
	EARLY_BAD,
	LATE_BAD,
	MISS,
	NOT
}

#func _process(delta: float) -> void:

func _physics_process(delta: float) -> void:
	print("[HitJugdment]    ", tap_action_mf_objects_priority, "    ", touch_action_mf_objects)
	#print("[HitJugdment]    ", tap_action_mf_objects_priority)
	check_priority_miss()
	check_touch_miss()





##动作判定模块

var track_player_latency_position: float##考虑了谱面延迟的track时刻
##tap动作判定模块(tap动作：手指在屏幕上按下，是个瞬间性动作)
#region
##tap动作的判定流程：
##（1）每个MfObject自检测到判定点，把判定点上传到HitJugdment
##（2）（注意是瞬间性动作）FingersTracker的触控函数调用HitJugdment的判定函数对判定点进行判定评分  或者  HitJugdment判定MISS函数检测出MISS判定点
##（3）判定点评分调用MfObject的函数执行评分相应程序

##MfObject判定点排队模块（用于管理要判定的MfObject，进行排队）
var tap_action_mf_objects_priority: Array##MfObject判定点按的优先级排序数组（注意：包括Hold开头的点按，只会有Tap和Hold）
func add_to_priority(mf_object: MfObject):##MfObject进入点按判定时期，需要通过此函数排序进入mf_objects_tap_priority。
	tap_action_mf_objects_priority.push_back(mf_object)##一般 最后加的都是最后结束判定窗口的，即它们的判定期都比自己早。废弃思路：所以这里按逆序遍历。
func remove_from_priority(mf_object: MfObject):##移除
	tap_action_mf_objects_priority.erase(mf_object)

##MfObject判定评分模块（被动调用，接收FingersTracker的点击触控信息，据此对MfObject进行判定）
func tap_action_hit_jugdment(finger_position: Vector2):##tap动作的判定
	track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
	var i: int = 0##（临时）
	while i < tap_action_mf_objects_priority.size():##遍历检查待判定MfObject（注意：tap动作对最早判定点起作用后就消耗了不会再次判定其他判定点）
		var mf_obj = tap_action_mf_objects_priority[i]
		if is_in_mf_object(finger_position, mf_obj):##若位置上点击到了MfObject，则时间上进行判定分数
			mf_obj.mf_object_hit(judge_hit_score(mf_obj))
			pass#hold_in
			return
		i += 1

func check_priority_miss():##每帧主动检测tap_action_mf_objects_priority内所有MfObject，哪些MISS了。
	track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
	var i: int = 0##（临时）
	while i < tap_action_mf_objects_priority.size():##遍历检查待判定MfObject
		var mf_obj = tap_action_mf_objects_priority[i]
		var jugde_timing = mf_obj.jugde_timing[mf_obj.jugde_timing_index]##此判定点的时刻,注意：此时后面同一MfObject的判定点仍跟前面这个时刻一样，不过按顺序来不会判定到。
		if jugde_timing + game.bad_window < track_player_latency_position:##判定为MISS
			mf_obj.mf_object_miss(HitScore.MISS)
			pass#hold_in
		i += 1
#endregion








##touch动作判定模块(touch动作：手指碰到屏幕就算，是个可持续性的动作)

#var under_finger_mf_objects: Array##触屏手指按到的mf_object

var touch_action_mf_objects: Array##添加了需要判定touch动作的MfObject的数组（Drag 和 处于HOLD_IN的Hold）
func add_to_touch(mf_object: MfObject):##添加
	touch_action_mf_objects.push_back(mf_object)
func remove_from_touch(mf_object: MfObject):##移除
	touch_action_mf_objects.erase(mf_object)

func touch_action_hit_jugdment():
	track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
	var i: int = 0##（临时）
	while i < touch_action_mf_objects.size():##遍历检查待判定MfObject（注意：touch动作会同时对所有被判定的判定点起作用）
		var mf_obj = touch_action_mf_objects[i]
		var is_hold_touch_action_hit: bool = false
		for pos in fingers_tracker.fingers:
			if not pos is Vector2:##如果是null则跳过
				continue
			if is_in_mf_object(pos, mf_obj):##若位置上点击到了MfObject，则时间上进行判定分数
				mf_obj.mf_object_hit(HitScore.PERFECT)##Drag型MfObject受touch动作直接判定为PERFECT
				is_hold_touch_action_hit = true
				break
		if mf_obj.mf_object_type == MfObject.MfObjectType.HOLD and not is_hold_touch_action_hit:##Hold机制需要每帧判断是否按着
			mf_obj.mf_object_miss(HitScore.MISS)
		i += 1

func check_touch_miss():##每帧主动检测touch_action_mf_objects内所有 非Hold MfObject，哪些MISS了。
	track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
	var i: int = 0##（临时）
	while i < touch_action_mf_objects.size():##遍历检查待判定MfObject
		var mf_obj = touch_action_mf_objects[i]
		if mf_obj.mf_object_type == MfObject.MfObjectType.HOLD:##此判定函数需要非Hold，Hold需要专门函数
			i += 1
			continue
		var jugde_timing = mf_obj.jugde_timing[mf_obj.jugde_timing_index]##此判定点的时刻,注意：此时后面同一MfObject的判定点仍跟前面这个时刻一样，不过按顺序来不会判定到。
		if jugde_timing + game.bad_window < track_player_latency_position:##判定为MISS
			mf_obj.mf_object_miss(HitScore.MISS)
		i += 1

#func hold_touch_action_hit_jugdment(mf_obj: MfObject):##每帧主动检测touch_action_mf_objects内所有 Hold ，哪些MISS了，每帧判断是否按着
	#var hold_release_timing = mf_obj.hold_release_timing[mf_obj.hold_release_timing_index]







##工具类函数模块

func is_in_mf_object(pos: Vector2, mf_obj: MfObject) -> bool:##（工具）（重要）判断一个 世界坐标 是否在一个 MfObject 里。用于检测手指是否碰到MfObject。
	var mf_obj_pos = (pos - mf_obj.path_follow_2d.position).rotated(deg_to_rad(- mf_obj.shape.rotation_degrees))
	return - mf_obj.curve_size.x / 2 <= mf_obj_pos.x  && mf_obj_pos.x <= mf_obj.curve_size.x / 2 && - mf_obj.curve_size.y / 2 <= mf_obj_pos.y && mf_obj_pos.y <= mf_obj.curve_size.y / 2


func judge_hit_score(mf_object: MfObject) -> int:##（工具）判定打击评分。TouchArea检测到触控可通过   数组 或 参数  转递信息（动作时刻）到此集中处理，根据不同State自动条件判断为不同动作。
	track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
	var jugde_timing = mf_object.jugde_timing[mf_object.jugde_timing_index]##此判定点的时刻
	
	if jugde_timing - game.perfect_window <= track_player_latency_position && track_player_latency_position <= jugde_timing + game.perfect_window:
		return HitScore.PERFECT
		
	if jugde_timing - game.good_window <= track_player_latency_position && track_player_latency_position < jugde_timing - game.perfect_window:
		return HitScore.EARLY_GOOD
	
	if jugde_timing + game.perfect_window < track_player_latency_position && track_player_latency_position <= jugde_timing + game.good_window:
		return HitScore.LATE_GOOD
	
	if track_player_latency_position < jugde_timing - game.good_window:
		return HitScore.EARLY_BAD
	
	if jugde_timing + game.good_window < track_player_latency_position:
		return HitScore.LATE_BAD
	print("[HitJugdment]    ", "NOT")
	return HitScore.NOT##意外值
