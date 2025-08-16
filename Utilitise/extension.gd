##（自拟）拓展功能，针对通用且常用功能自拟
class_name Extension

extends Node

static func curve_to_dictionary(curve: Curve) -> Dictionary:##把curve本体的值打包为字典以便储存文件
	var points : Array
	var point_count = curve.point_count
	for i in range(0, point_count):
		points.push_back({
			"position": { "x": curve.get_point_position(i).x, "y": curve.get_point_position(i).y },
			"left_tangent": curve.get_point_left_tangent(i),
			"left_mode": curve.get_point_left_mode(i),
			"right_tangent": curve.get_point_right_tangent(i),
			"right_mode": curve.get_point_right_mode(i)
		})
	return {#要养成导入量的先后顺序，避免顺序不对导致引擎自动纠错
		"max_domain": curve.max_domain,
		"min_domain": curve.min_domain,
		"max_value": curve.max_value,
		"min_value": curve.min_value,
		"bake_resolution": curve.bake_resolution,
		"points": points#点的数组，每个元素（点）的属性用一个字典表示
	}
static func dictionary_to_curve(dictionary: Dictionary) -> Curve:##把打包为字典的curve的值返回成curve
	var curve = Curve.new()
	curve.max_domain = dictionary["max_domain"]#先给最大值赋值。因为如果要设的最小值比当前的最大值要大就会改错。
	curve.min_domain = dictionary["min_domain"]
	curve.max_value = dictionary["max_value"]
	curve.min_value = dictionary["min_value"]
	curve.bake_resolution = dictionary["bake_resolution"]
	for i in dictionary["points"]:
		curve.add_point(
			Vector2(i["position"]["x"], i["position"]["y"]), 
			i["left_tangent"], 
			i["right_tangent"], 
			i["left_mode"], 
			i["right_mode"]
		)
	return curve

static func curve_2d_to_dictionary(curve_2d: Curve2D) -> Dictionary:##把curve2D本体的值打包为字典以便储存文件
	var points : Array
	var point_count = curve_2d.point_count
	for i in range(0, point_count):
		points.push_back({
			"position": { "x": curve_2d.get_point_position(i).x, "y": curve_2d.get_point_position(i).y },
			"in": { "x": curve_2d.get_point_in(i).x, "y": curve_2d.get_point_in(i).y },
			"out": { "x": curve_2d.get_point_out(i).x, "y": curve_2d.get_point_out(i).y },
		})
	return {
		"bake_interval": curve_2d.bake_interval,
		"points": points#点的数组，每个元素（点）的属性用一个字典表示
	}
static func dictionary_to_curve_2d(dictionary: Dictionary) -> Curve2D:##把打包为字典的curve_2d的值返回成curve_2d
	var curve_2d = Curve2D.new()
	curve_2d.bake_interval = dictionary["bake_interval"]
	for i in dictionary["points"]:
		curve_2d.add_point(
			Vector2(i["position"]["x"], i["position"]["y"]), 
			Vector2(i["in"]["x"], i["in"]["y"]),
			Vector2(i["out"]["x"], i["out"]["y"])
		)
	return curve_2d

static func json_to_dictionary(file_path: String) -> Dictionary:##把json文件解析为字典
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
	
	return json.data as Dictionary
static func dictionary_to_json(data: Dictionary, file_path: String) -> bool:##把字典保存为json文件
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("无法打开文件写入: " + file_path)
		return false
		
	# 使用2个空格缩进，并添加换行符
	file.store_string(JSON.stringify(data, "  "))
	file.close()
	
	return true
