##不要把此节点跟通用型ObjectPool混淆了，因为根据MfObject个性化了。
##注意此节点在场景树的顺序，避免依赖问题

extends Node

@onready var json_file_operator: Node = $"../JsonFileOperator"
@onready var mf_objects: Node2D = $"../MfObjects"

@export var obj_scene: PackedScene#MfObject
var mf_objects_initial_size:int  = 0
var free_mf_objects: Array[Object] = []##存储空闲对象的数组（池）


func _ready() -> void:
		self.initialize()


func initialize() -> void:
	
	##序列化谱面文件时，该行代码会报错，是因为文件写入时就读取了，先不管
	mf_objects_initial_size = ceil(json_file_operator.chart_data["max_mf_object_count"] * 1.5)##根据max_mf_object_count设置容量
	
	if obj_scene == null:#验证场景资源
		push_error("对象池错误：未设置场景资源！")
		
	for i in range(mf_objects_initial_size):#预创建部分对象
		create_objects()


func create_objects() -> void:##预创建对象
	
	var obj = obj_scene.instantiate()
	if obj:
		#obj.name = "MfObject_" + str(mf_objects.get_child_count())
		#（重要）帧函数脚本禁用ready内已设置
		#obj.set_process(false)#停止 _process()调用
		#obj.set_physics_process(false)#停止 _physics_process()调用
		obj.hide()#隐藏预创建的对象
		#mf_objects.add_child(obj)
		free_mf_objects.append(obj)
	else:
		push_error("无法实例化对象: " + str(obj_scene))
	#print("MfObjectPool :   ", obj)
	

func get_object() -> Object:##（外部调用）取出对象
	if free_mf_objects.size() > 0:
		var obj = free_mf_objects.pop_back()#取出空闲对象
		mf_objects.add_child(obj)
		obj.name = "MfObject"
		#（重要）恢复节点的处理逻辑，在节点脚本的initialize内实现
		
		return obj#返回可用对象
	elif mf_objects_initial_size == -1 or free_mf_objects.size() < mf_objects_initial_size:
		var new_obj = obj_scene.instantiate()
		return new_obj if new_obj else null
	else:
		return null


func return_object(obj: Object) -> void:##（外部调用）回收对象
	if obj and (mf_objects_initial_size == -1 or free_mf_objects.size() < mf_objects_initial_size):
		#obj.is_need_show = true
		obj.hide()
		#（重要）帧函数脚本禁用reset内设置
		#obj.set_process(false)      # 停止 _process 调用
		#obj.set_physics_process(false)  # 停止 _physics_process 调用
		mf_objects.remove_child(obj)
		free_mf_objects.append(obj)
	else:
		push_error("MfObjectPool:  return_object()不对!")
