##此为自用工具，在制谱器做出来之前，用来设置MfObject；好像又不太需要了，右键实例化了的MfObject，勾选“子节点可编辑”即可！
extends Node

@onready var mf_object: MfObject = $".."
@onready var move_curve: Path2D = $"../MoveCurve"
@onready var curve_value: CurveValue = $"../MoveCurve/PathFollow2D/CurveValue"




@export var is_work: bool##是否启用
@export var parse_or_save_to_json_file: bool = true##默认为正向解析（读取 JSON）




func parse_json_file(file_path: String) -> Dictionary:
	# 1. 文件读取优化
	if not FileAccess.file_exists(file_path):
		push_error("文件不存在: " + file_path)
		return {}
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开文件: " + file_path + " | 错误码: " + str(FileAccess.get_open_error()))
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	# 2. 解析流程强化
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		# 输出详细错误位置
		var err_msg = "JSON解析失败: %s (行: %d)" % [
			json.get_error_message(), 
			json.get_error_line()
		]
		push_error(err_msg)
		return {}
	
	# 3. 数据类型校验
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("解析成功但根节点非字典类型: " + str(typeof(json.data)))
		return {}
	
	return json.data as Dictionary  # 关键修正点




# 反向生成（写入 JSON）
func save_to_json_file(data: Dictionary, file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("无法打开文件写入: " + file_path)
		return false
		
	# 使用2个空格缩进，并添加换行符
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	
	return true






func _ready() -> void:
	
	if is_work:
		
		if parse_or_save_to_json_file:
			
			# 执行正向解析
			var data1 = parse_json_file("res://jsonfiles/j1.json")
			print(data1)  # 打印解析后的字典数据
			
			
			
			
			mf_object.mf_object_type = data1["mf_objects"][0]["mf_object_type"]
			move_curve.curve = Extension.value_to_curve_2d(data1["mf_objects"][0]["MfObject_move_curve"])
			curve_value.progress_ratio_curve = Extension.value_to_curve(data1["mf_objects"][0]["progress_ratio_curve"])
			curve_value.modulate_curve = Extension.value_to_curve(data1["mf_objects"][0]["modulate_curve"])
			
			
			
			
			
		else:
			
			
			
			# 获取当前节点的所有子节点
			var all_children = get_children()
			for child in all_children:
				print(child.name)  # 输出每个子节点的名称
				
				
				
			# 执行反向生成
			var data2 = {#主花括号
				"mf_objects": [#此数列包含所有mf_object。每个mf_object都以一个字典表示。
					{
						"mf_object_type": 1,
						"is_rotates": null,
						"MfObject_move_curve": Extension.curve_2d_to_value(move_curve.curve),
						"progress_ratio_curve": Extension.curve_to_value(curve_value.progress_ratio_curve),
						"length_curve": Extension.curve_to_value(curve_value.length_curve),
						"width_curve": Extension.curve_to_value(curve_value.width_curve),
						"rotation_curve": Extension.curve_to_value(curve_value.rotation_curve),
						"modulate_curve": Extension.curve_to_value(curve_value.modulate_curve)
					}
				]
			}

			var success = save_to_json_file(data2, "res://jsonfiles/j1.json")
			if success:
				print("JSON文件保存成功")
			else:
				print("JSON文件保存失败")
