##此节点平常用于解析谱面文件。
##在没有制谱器时可用于暂时制谱：parse_or_save_to_json_file关闭启用，在MfObjects下挂MfObject子场景，运行项目之后成功保存。
##注：场景树中，此节点放在MfObjects的后面，是因为如果要用保存json文件功能就需要在MfObjects以及它的节点都加载完毕之后才运行这个脚本

extends Node

@onready var mf_objects: Node2D = $"../MfObjects"##这是MfObjects的引用，其下子节点为存在的MfObject

@export_file var file: String = ""  ##初始值为空，选择文件后会自动填充路径
@export var is_work: bool##是否启用
@export var parse_or_save_to_json_file: bool = true##默认为正向解析（读取 JSON）



func _ready() -> void:
	
	if is_work:
		
		if parse_or_save_to_json_file:
			parse()
			
			
		else:
			save_to_json_file()
			
			
			



var chart_data: Dictionary##谱面数据。存放返回的字典数据。
func parse():
	if is_work:
		# 执行正向解析
		var data = Extension.json_to_dictionary(file)
		#print(data1)  # 打印解析后的字典数据
		
		chart_data = data
		
	else:
		return {}






func save_to_json_file() -> void:##保存为json文件。必须保持MfObject在数组里按时间顺序排列,即 start 或 start相等的同时over 从小到大排列。
	
	var data = {#主花括号
		"mf_objects": []#此数组包含所有mf_object。MfObject在数组里按时间顺序排列，值为用字典表示的MfObject的内容。
	}
	
	
	
	var node_mf_objects = mf_objects.get_children()#获取当前节点的所有子节点
	var array_mf_objects = []#暂时存放MfObject用于排序
	for i in node_mf_objects:
		var dictionary_mf_object = {
			"mf_object_type": i.mf_object_type,
			"exist_period": i.exist_period,
			"judge_timing": i.judge_timing,
			"hold_release_timing": i.hold_release_timing,
			"mf_z_index": i.mf_z_index,
			"thickness": i.thickness,
			#"is_rotates": null,
			"MfObject_move_curve": Extension.curve_2d_to_dictionary(i.move_curve.curve),
			"progress_ratio_curve": Extension.curve_to_dictionary(i.progress_ratio_curve),
			"length_curve": Extension.curve_to_dictionary(i.length_curve),
			"width_curve": Extension.curve_to_dictionary(i.width_curve),
			"rotation_curve": Extension.curve_to_dictionary(i.rotation_curve),
			"opacity_curve": Extension.curve_to_dictionary(i.opacity_curve)
		}
		array_mf_objects.push_back(dictionary_mf_object)
		
		
	
	
	
	#如果乱序则排序（这里不用检测，必排序，之后制谱器才可能需要；ps：不检测了，直接排序吧）
	#if !(array_mf_objects.size() <= 1) || (func(): 
		#for j in range(array_mf_objects.size() - 1):
			#if !(array_mf_objects[i]["exist_period"]["start"] < array_mf_objects[i + 1]["exist_period"]["start"]) || (array_mf_objects[i]["exist_period"]["start"] == array_mf_objects[i + 1]["exist_period"]["start"] && array_mf_objects[i]["exist_period"]["over"] < array_mf_objects[i + 1]["exist_period"]["over"]):
				#return false
		#return true
			#):
		#pass
	array_mf_objects.sort_custom(func(a, b): return a["exist_period"]["start"] < b["exist_period"]["start"] if a["exist_period"]["start"] != b["exist_period"]["start"] else a["exist_period"]["over"] < b["exist_period"]["over"])#排序
	
	#print(array_mf_objects.size())
	#for k in array_mf_objects:
		#print(k["exist_period"])
	
	
	
	
	var max_mf_object_count: int = 0#分析出同时存在MfObject最大数，保存为json文件时附带进去
	var s: int = 0#（临时变量）MfObject在start上的下标
	var o: int = 0#（临时变量）MfObject在over上的下标
	var c: int = 0#（临时变量）分析过程中当前同时存在MfObject数
	for i in range(array_mf_objects.size() * 2):
		if s < array_mf_objects.size() && o < array_mf_objects.size():
			if array_mf_objects[s]["exist_period"]["start"] <= array_mf_objects[o]["exist_period"]["over"]:
				c += 1
				s += 1
			else:
				c -= 1
				o += 1
		elif s < array_mf_objects.size():
			c += 1
			s += 1
		else:
			c -= 1
			o += 1
		if max_mf_object_count < c:
			max_mf_object_count = c
	#print("%d" % [max_mf_object_count])
	
	
	
	
	
	var sum_mf_object_count = array_mf_objects.size()
	
	
	
	var sum_mf_object_judgment_count: int = 0#谱面物量，MfObject判定次数总数，保存为json文件时附带进去
	for i in node_mf_objects:
		sum_mf_object_judgment_count += i.judge_timing.size()
	
	
	
	
	
	
	data["sum_mf_object_count"] = sum_mf_object_count##总MfObject数
	data["max_mf_object_count"] = max_mf_object_count##同时出现MfObject最大数
	data["sum_mf_object_judgment_count"] = sum_mf_object_judgment_count##总MfObject判定次数（不计Hold的尾部）
	data["mf_objects"] = array_mf_objects
	
	
	
	
	
	var success = Extension.dictionary_to_json(data, file)
	if success:
		print("JSON文件保存成功")
	else:
		print("JSON文件保存失败")
