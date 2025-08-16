extends Node





#func _physics_process(delta: float) -> void:
	#print("[MfObjectsPriority]    ", tap_in_or_hold_in_mf_objects_priority)






var tap_in_or_hold_in_mf_objects_priority: Array##MfObject判定点按的优先级排序数组（注意：包括Hold开头的点按，只会有Tap和Hold）

func add_to_priority(mf_object: MfObject):##MfObject进入点按判定时期，需要通过此函数排序进入mf_objects_tap_priority。
	tap_in_or_hold_in_mf_objects_priority.push_back(mf_object)##一般 最后加的都是最后结束判定窗口的，即它们的判定期都比自己早。废弃思路：所以这里按逆序遍历。


func remove_from_priority(mf_object: MfObject):
	tap_in_or_hold_in_mf_objects_priority.erase(mf_object)
