##这里不使用对象池了，直接在场景树里预创建，不使用对象池了，通过启用和禁用节点，这样避免部分场景树操作的错误，减少线程安全问题
##（自拟）对象池(只包含预创建、取出、回收对象功能；初始化对象、添加到场景树等功能自行实现)
##添加此通用节点作为对象使用
##需要在检查器或其他脚本中指明obj_scene，size，initial_size
class_name ObjectPool

extends Node

@onready var mf_chart_scene: Node2D = $".."
@onready var json_file_operator: Node = $"../JsonFileOperator"

@export var obj_scene: PackedScene##要操作的节点
@export var size: int = -1##对象池容量，-1表示不设限
@export var initial_size: int = 0##对象池初始容量

var free_objects: Array[Object] = []##存储空闲对象的数组（池）



func initialize() -> void:##(外部调用)初始化对象池
	if obj_scene == null:#验证场景资源
		push_error("对象池错误：未设置场景资源！")
		
	for i in range(initial_size):#预创建部分对象
		create_and_store_objects()


func create_and_store_objects() -> void:##预创建对象并储存
	var obj = obj_scene.instantiate()
	if obj:
		free_objects.append(obj)
		obj.hide()#隐藏预创建的对象
	else:
		push_error("无法实例化对象: " + str(obj_scene))
	#print("object_pool:", obj)


func get_object() -> Object:##（外部调用）取出对象
	if free_objects.size() > 0:
		var obj = free_objects.pop_back()#取出空闲对象
		
		# 恢复节点的处理逻辑
		obj.set_process(true)
		obj.set_physics_process(true)
		
		return obj#返回可用对象
	elif size == -1 or free_objects.size() < size:
		var new_obj = obj_scene.instantiate()
		return new_obj if new_obj else null
	else:
		return null



func return_object(obj: Object) -> void:##（外部调用）回收对象
	if obj and (size == -1 or free_objects.size() < size):
		#禁用节点
		obj.set_process(false)      # 停止 _process 调用
		obj.set_physics_process(false)  # 停止 _physics_process 调用
		
		#重置对象状态
		obj.hide()
		#添加其他重置逻辑...
		
		free_objects.append(obj)
	else:
		obj.queue_free()#池已满或对象无效，直接销毁
