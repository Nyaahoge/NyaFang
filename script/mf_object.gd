##（自拟）喵方对象
##MfObject：note们及box的统一名称，当时没有抽象，现在已经迟了，不管了先。
##因为会导致抖动所以不考虑AudioServer.get_time_since_last_mix()
##（注意）exist_period理应跟opacity_curve分开考虑，不要直接把exist_period作为是否渲染出来这个功能用，应该以opacity_curve为准。这一点也是为了防止渲染出现延迟而闪图像、时刻对不上等情况。

##MfObject详情：
##Hold无尾判



class_name MfObject
extends Node2D

##基本量
#region
enum MfObjectType {##枚举MfObject的子类型
	BOX,##判定框（给玩家对照标志用的，不接受操作，打击特效也是显示在其他可打击的MfObject上的）
	TAP,##点按（手指在屏幕上按下，点击到TAP）
	DRAG,##接按（手指触屏，接触到DRAG即可）
	HOLD##点接长按（手指在屏幕上按下后还要持续接触到HOLD，在尾判前提前结束接触则判定为MISS）
}
enum State {##枚举当前状态，状态处理这里直接状态式编程，没用状态机了
	NOT,##非判定中状态（可以是激活后还未判定过，也可以是判定结束之后）
	TAP_IN,##Tap的判定中状态（判定后立即变为NOT状态（击中或miss））
	DRAG_IN,##Drag的判定中状态（判定后立即变为NOT状态（击中或miss））
	HOLD_IN,##Hold的一阶段判定中状态（判定后立即变为HOLD_AFTER状态（击中或miss））
	HOLD_KEEP,##Hold的长按状态，处于HOLD_IN与HOLD_OUT之间的连续段
	HOLD_IN_MISS,##MISS了的HOLD_IN（判定后立即变为HOLD_AFTER状态（击中或miss））
	HOLD_KEEP_MISS,##MISS了的HOLD_KEEP
	HOLD_OUT,##Hold的二阶段判定中状态（判定后立即变为NOT状态（击中或miss））
}



##@onready节点
#region
@onready var game: Node = $"../../Game"
@onready var hit_judgment: Node = $"../../Game/HitJudgment"


@onready var track_player: AudioStreamPlayer = $"../../TrackPlayer"

@onready var move_curve: Path2D = $MoveCurve
@onready var path_follow_2d: PathFollow2D = $MoveCurve/PathFollow2D
#@onready var touch_area: Area2D = $MoveCurve/PathFollow2D/TouchArea##（触控判定换了思路，不用此了）TouchArea的碰撞体直接用Drag的图形
#@onready var collision_polygon_2d: CollisionPolygon2D = $MoveCurve/PathFollow2D/TouchArea/CollisionPolygon2D##（触控判定换了思路，不用此了）TouchArea的碰撞体直接用Drag的图形




@onready var shape: Node2D = $MoveCurve/PathFollow2D/Shape

@onready var box_shape: Node2D = $MoveCurve/PathFollow2D/Shape/BoxShape
@onready var b_right_0: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BRight0
@onready var b_top_0: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BTop0
@onready var b_left_0: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BLeft0
@onready var b_bottom_0: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BBottom0
@onready var b_right_1: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BRight1
@onready var b_top_1: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BTop1
@onready var b_left_1: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BLeft1
@onready var b_bottom_1: Polygon2D = $MoveCurve/PathFollow2D/Shape/BoxShape/BBottom1

@onready var tap_shape: Node2D = $MoveCurve/PathFollow2D/Shape/TapShape
@onready var t_body: Polygon2D = $MoveCurve/PathFollow2D/Shape/TapShape/TBody
@onready var t_top_right: Polygon2D = $MoveCurve/PathFollow2D/Shape/TapShape/TTopRight
@onready var t_top_left: Polygon2D = $MoveCurve/PathFollow2D/Shape/TapShape/TTopLeft
@onready var t_bottom_left: Polygon2D = $MoveCurve/PathFollow2D/Shape/TapShape/TBottomLeft
@onready var t_bottom_right: Polygon2D = $MoveCurve/PathFollow2D/Shape/TapShape/TBottomRight

@onready var drag_shape: Node2D = $MoveCurve/PathFollow2D/Shape/DragShape
@onready var d_body: Polygon2D = $MoveCurve/PathFollow2D/Shape/DragShape/DBody

@onready var hold_shape: Node2D = $MoveCurve/PathFollow2D/Shape/HoldShape
@onready var h_body: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HBody
@onready var h_right: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HRight
@onready var h_top: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HTop
@onready var h_left: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HLeft
@onready var h_bottom: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HBottom
@onready var h_top_right: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HTopRight
@onready var h_top_left: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HTopLeft
@onready var h_bottom_left: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HBottomLeft
@onready var h_bottom_right: Polygon2D = $MoveCurve/PathFollow2D/Shape/HoldShape/HBottomRight
#endregion


@export var mf_object_type:MfObjectType##此MfObject是什么键型的：BOX、TAP、DRAG、HOLD
@export var exist_period:Dictionary = { "start": 0.0, "over": 0.0 }##存在时间段，以歌曲时间为参照(开始时刻，结束时刻)
@export var judge_timing: Array##判定时机，以歌曲时间为参照
@export var hold_release_timing: Array##hold这种键型的长按释放时机，以歌曲时间为参照
@export var mf_z_index: int = -1##MfObject图层
@export  var thickness: float = 40.0##图形样式的厚度。目前先设为不可变，默认40.0。
#@export var is_rotates: Array[float]##元素为歌曲时刻，表明PathFollow2D的rotates何时开启关闭，默认关闭
#废弃思路：要得到中间断开的Curve，只能用多个Curve实现，这里使用数组；解决思路：直接用多个MfObject对各方面都方便
##MfObject_move_curve:Path2D##MfObject运动的位置Curve2D，用于Path2D类型的MfObject——当前的MoveCurve（此节点是由MfObject的move_curve赋值的）
@export var progress_ratio_curve: Curve = Curve.new()##MfObject在MoveCurve上的路程位置Curve
@export var length_curve: Curve = Curve.new()##MfObject的矩形长Curve
@export var width_curve: Curve = Curve.new()##MfObject的矩形宽Curve
@export var rotation_curve: Curve = Curve.new()##MfObject运动的旋转角度Curve
@export var opacity_curve: Curve = Curve.new()##不透明度Curve
#endregion











func _ready() -> void:
	visible = true
	shape.visible = false
	box_shape.visible = false
	tap_shape.visible = false
	drag_shape.visible = false
	hold_shape.visible = false
	set_process(false)#停止 _process()调用
	set_physics_process(false)#停止 _physics_process()调用

#func _process(_delta: float) -> void:
	#pass

func _physics_process(_delta: float) -> void:
	curve_handling()
	judgment_state_detection()






func initialize(dictionary: Dictionary) -> void:##MfObject根据新值初始化（就是从对象池拿出来复用时的初始化），参数为要导入的MfObject的字典
	
	
	
	##主要值的初始化设置
	mf_object_type = dictionary["mf_object_type"]
	exist_period = dictionary["exist_period"]
	judge_timing = dictionary["judge_timing"]
	hold_release_timing = dictionary["hold_release_timing"]
	mf_z_index = dictionary["mf_z_index"]
	thickness = dictionary["thickness"]
	#"is_rotates": null,
	move_curve.curve = Extension.dictionary_to_curve_2d(dictionary["MfObject_move_curve"])
	progress_ratio_curve = Extension.dictionary_to_curve(dictionary["progress_ratio_curve"])
	length_curve = Extension.dictionary_to_curve(dictionary["length_curve"])
	width_curve = Extension.dictionary_to_curve(dictionary["width_curve"])
	rotation_curve = Extension.dictionary_to_curve(dictionary["rotation_curve"])
	opacity_curve = Extension.dictionary_to_curve(dictionary["opacity_curve"])
	
	
	
	#print("[MfObject]    ", track_player.thread_track_player_position, "   ", shape.visible, shape.position)
	curve_handling()##先运行一帧此函数，先赋值一些值，防止闪一下原图形。
	#print("[MfObject]    ", track_player.thread_track_player_position, "   ", shape.visible, shape.position)
	
	
	
	##其他初始化设置
	match  mf_object_type:
		MfObjectType.BOX:
			box_shape.z_index = 100 if mf_z_index == -1 else mf_z_index##设置不同MfObject对应图层，未设置mf_z_index将启用默认值。
			box_shape.visible = true##mf_object_type分别对应的四种皮肤（性能上Sprite更好）
		MfObjectType.TAP:
			tap_shape.z_index = 200 if mf_z_index == -1 else mf_z_index
			tap_shape.visible = true
		MfObjectType.DRAG:
			drag_shape.z_index = 200 if mf_z_index == -1 else mf_z_index
			drag_shape.visible = true
		MfObjectType.HOLD:
			hold_shape.z_index = 200 if mf_z_index == -1 else mf_z_index
			hold_shape.visible = true
	
	
	#if track_player_latency_position > exist_period["start"] + 5:
		#shape.visible = true
	
	
	
	
	#print("[MfObject]    ", track_player.thread_track_player_position, "   ", shape.visible, shape.position)
	set_process(true)
	set_physics_process(true)
	
	shape.visible = true
	#print("[MfObject]    ", track_player.thread_track_player_position, "   ", shape.visible, shape.position)



func reset():##回收到对象池时重置
	#visible = false
	shape.visible = false
	box_shape.visible = false
	tap_shape.visible = false
	drag_shape.visible = false
	hold_shape.visible = false
	
	
	
	set_process(false)      # 停止 _process 调用
	set_physics_process(false)  # 停止 _physics_process 调用
















##形态、运动、触控区域 模块
#region
var track_player_latency_position##（重要）（赋值） 延时后 的track时刻
#var curve_position: Vector2##曲线插值位置
var curve_size: Vector2##（传出量值）曲线插值长宽
#var curve_rotation: float##曲线插值旋转角度
#var curve_opacity: float##曲线插值不透明度
func curve_handling() -> void:##对curve进行实时线性插值并赋值给对应变量，控制MfObject的形态、运动、触控区域
	track_player_latency_position = track_player.thread_track_player_latency_position##（重要）get_playback_position()更新较快，故赋值给临时变量保持各属性处于同一时刻。下面统一使用track_player_position这个时刻标准。
	if move_curve.curve && progress_ratio_curve:
		if track_player_latency_position > exist_period["start"]:
			path_follow_2d.progress_ratio = progress_ratio_curve.sample(track_player_latency_position)
			#shape.position = move_curve.curve.samplef(lerp(0, move_curve.curve.point_count, progress_ratio_curve.sample(track_player_latency_position)))
		else:
			#shape.position = move_curve.curve.samplef(0.0)
			path_follow_2d.progress_ratio = 0.0
	else:
		print("move_curve 或 progress_ratio_curve为空")
	
	if length_curve && width_curve:##长、宽，注意不是单纯缩放；另外注意，长宽以Box的内外图形间（Drag一样）为标准
		##mf_object皮肤（性能上Sprite更好，应废弃多边形绘制思路）绘制MfObject图形
		#regions
		var a: float = length_curve.sample(track_player_latency_position if track_player_latency_position > exist_period["start"] else exist_period["start"])#（临时变量）长
		var b: float = width_curve.sample(track_player_latency_position if track_player_latency_position > exist_period["start"] else exist_period["start"])#（临时变量）宽
		var t: float = thickness#（重要）（设定）（临时变量）厚度
		
		curve_size = Vector2(a, b)##（重要）用于传出长宽数值，现在判定模块用到了
		
		match  mf_object_type:
			MfObjectType.BOX:
				b_right_0.polygon = [Vector2(a / 2 + t, b / 2 + t), Vector2(a / 2 + t, - b / 2 - t), Vector2(a / 2, - b / 2), Vector2(a / 2, b / 2)]
				b_top_0.polygon = [Vector2(a / 2 + t, - b / 2 - t), Vector2(- a / 2 - t, - b / 2 - t), Vector2(- a / 2, - b / 2), Vector2(a / 2, - b / 2)]
				b_left_0.polygon = [Vector2(- a / 2 - t, - b / 2 - t), Vector2(- a / 2 - t, b / 2 + t), Vector2(- a / 2, b / 2), Vector2(- a / 2, - b / 2)]
				b_bottom_0.polygon = [Vector2(- a / 2 - t, b / 2 + t), Vector2(a / 2 + t, b / 2 + t), Vector2(a / 2, b / 2), Vector2(- a / 2, b / 2)]
				b_right_1.polygon = [Vector2(a / 2, b / 2), Vector2(a / 2, - b / 2), Vector2(a / 2 - t, - b / 2 + t), Vector2(a / 2 - t, b / 2 - t)]
				b_top_1.polygon = [Vector2(a / 2, - b / 2), Vector2(- a / 2, - b / 2), Vector2(- a / 2 + t, - b / 2 + t), Vector2(a / 2 - t, - b / 2 + t)]
				b_left_1.polygon = [Vector2(- a / 2, - b / 2), Vector2(- a / 2, b / 2), Vector2(- a / 2 + t, b / 2 - t), Vector2(- a / 2 + t, - b / 2 + t)]
				b_bottom_1.polygon = [Vector2(- a / 2, b / 2), Vector2(a / 2, b / 2), Vector2(a / 2 - t, b / 2 - t), Vector2(- a / 2 + t, b / 2 - t)]
			MfObjectType.TAP:
				t_body.polygon = [Vector2(a / 2, - b / 4), Vector2(a / 2 - t, - b / 4), Vector2(a / 2 - t, - b / 2 + t), Vector2(a / 4, - b / 2 + t), Vector2(a / 4, - b / 2), 
					Vector2(- a / 4, - b / 2), Vector2(- a / 4, - b / 2 + t), Vector2(- a / 2 + t, - b / 2 + t), Vector2(- a / 2 + t, - b / 4), Vector2(- a / 2, - b / 4), 
					Vector2(- a / 2, b / 4),Vector2(- a / 2 + t, b / 4), Vector2(- a / 2 + t, b / 2 - t), Vector2(- a / 4, b / 2 - t), Vector2(- a / 4, b / 2), 
					Vector2(a / 4, b / 2), Vector2(a / 4, b / 2 - t), Vector2(a / 2 - t, b / 2 - t), Vector2(a / 2 - t, b / 4), Vector2(a / 2, b / 4)]
				t_top_right.polygon = [Vector2(a / 2, - b / 4), Vector2(a / 2, - b / 2), Vector2(a / 4, - b / 2), Vector2(a / 4, - b / 2 + t), Vector2(a / 2 - t, - b / 2 + t), Vector2(a / 2 - t, - b / 4)]
				t_top_left.polygon = [Vector2(- a / 4, - b / 2), Vector2(- a / 2, - b / 2), Vector2(- a / 2, - b / 4), Vector2(- a / 2 + t, - b / 4), Vector2(- a / 2 + t, - b / 2 + t), Vector2(- a / 4, - b / 2 + t)]
				t_bottom_left.polygon = [Vector2(- a / 2, b / 4), Vector2(- a / 2, b / 2), Vector2(- a / 4, b / 2), Vector2(- a / 4, b / 2 - t), Vector2(- a / 2 + t, b / 2 - t), Vector2(- a / 2 + t, b / 4)]
				t_bottom_right.polygon = [Vector2(a / 4, b / 2), Vector2(a / 2, b / 2), Vector2(a / 2, b / 4), Vector2(a / 2 - t, b / 4), Vector2(a / 2 - t, b / 2 - t), Vector2(a / 4, b / 2 - t)]
			MfObjectType.DRAG:##TouchArea的碰撞体直接用此
				d_body.polygon = [Vector2(a / 2, - b / 2), Vector2(- a / 2, - b / 2), Vector2(- a / 2, b / 2), Vector2(a / 2, b / 2)]
			MfObjectType.HOLD:
				h_body.polygon = [Vector2(a / 2 - t, - b / 2 + t), Vector2(- a / 2 + t, - b / 2 + t), Vector2(- a / 2 + t, b / 2 - t), Vector2(a / 2 - t, b / 2 - t)]
				h_right.polygon = [Vector2(a / 2, b / 2 - t), Vector2(a / 2, - b / 2 + t), Vector2(a / 2 - t, - b / 2 + t), Vector2(a / 2 - t, b / 2 - t)]
				h_top.polygon = [Vector2(a / 2 - t, - b / 2), Vector2(- a / 2 + t, - b / 2), Vector2(- a / 2 + t, - b / 2 + t), Vector2(a / 2 - t, - b / 2 + t)]
				h_left.polygon = [Vector2(- a / 2, - b / 2 + t), Vector2(- a / 2, b / 2 - t), Vector2(- a / 2 + t, b / 2 - t), Vector2(- a / 2 + t, - b / 2 + t)]
				h_bottom.polygon = [Vector2(- a / 2 + t, b / 2), Vector2(a / 2 - t, b / 2), Vector2(a / 2 - t, b / 2 - t), Vector2(- a / 2 + t, b / 2 - t)]
				h_top_right.polygon = [Vector2(a / 2, - b / 2), Vector2(a / 2 - t, - b / 2), Vector2(a / 2 - t, - b / 2 + t), Vector2(a / 2, - b / 2 + t)]
				h_top_left.polygon = [Vector2(- a / 2, - b / 2), Vector2(- a / 2, - b / 2 + t), Vector2(- a / 2 + t, - b / 2 + t), Vector2(- a / 2 + t, - b / 2)]
				h_bottom_left.polygon = [Vector2(- a / 2, b / 2), Vector2(- a / 2 + t, b / 2), Vector2(- a / 2 + t, b / 2 - t), Vector2(- a / 2, b / 2 - t)]
				h_bottom_right.polygon = [Vector2(a / 2, b / 2), Vector2(a / 2, b / 2 - t), Vector2(a / 2 - t, b / 2 - t), Vector2(a / 2 - t, b / 2)]
		#endregion
		
		
		
		
		
		
		
		
		
		
		
		
		###（触控判定换了思路，不用此了）TouchArea的碰撞体直接用Drag的图形
		#collision_polygon_2d.polygon = [Vector2(a / 2, - b / 2), Vector2(- a / 2, - b / 2), Vector2(- a / 2, b / 2), Vector2(a / 2, b / 2)]
	else:
		print("length_curve 或 width_curve为空")
		
	if rotation_curve:
		shape.rotation_degrees = rotation_curve.sample(track_player_latency_position if track_player_latency_position > exist_period["start"] else exist_period["start"])
		#collision_polygon_2d.rotation_degrees = shape.rotation_degrees##（触控判定换了思路，不用此了）TouchArea的碰撞体直接用Drag的图形
	else:
		print("rotation_curve为空")
	
	if opacity_curve:
		shape.modulate.a = opacity_curve.sample(track_player_latency_position if track_player_latency_position > exist_period["start"] else exist_period["start"])
	else:
		print("opacity_curve为空")
	
#endregion









##管理判定相关状态主要模块（根据State、被如何打击和判定相关量，管理MfObject的判定过程）
#region
var is_hit_jugement_over: bool = false##所有打击判定点是否已结束

var current_state: State = State.NOT##(当前)当前状态

var judge_timing_index: int = 0##（重要）（标记）接下来要进行或正在进行的判定点。随检测判定更新。
var hold_release_timing_index: int = 0##（重要）（标记）接下来要或正在进行的Hold尾部判定点。随检测判定更新。
#var is_on_hold_in: bool = false##（当前）是否进入hold判定期

var add_to_tap_priority_index: int = 0##（重要）（标记）接下来要to_tap_priority的判定点

var judge_timing_hit_score: Array[HitJudgment.HitScore]##记录每次（Hold是看最终评分）判定的评分。（不要跟表示总分数的score混淆了）
var hold_head_judge_timing_hit_score: Array[HitJudgment.HitScore]##记录每次Hold头部判定的评分。（头部一判定就记录）(此并非最终评分，还得看尾判，再传入hold_release_timing_index)

func judgment_state_detection() -> void:##State检测
	
	
	if not mf_object_type == MfObjectType.BOX and not is_hit_jugement_over:##非Box 且 所有打击判定点未结束，则运行打击判定等相关模块
		
		track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
		#var is_in_judge_timing_bad_window = judge_timing[judge_timing_index] - game.bad_window <= track_player.thread_track_player_latency_position && track_player.thread_track_player_latency_position <= judge_timing[judge_timing_index] + game.bad_window##是否处于judge_timing判定期
		
		
		
		
		#if is_in_judge_timing_bad_window:
			#print(track_player.get_playback_position())
			
		
		
		
		##上传判定点模块
		##（重要）注意在tap_action_mf_objects_priority上的添加与删除
		match mf_object_type:
			
			##MfObjectType.TAP:
			##以下为废弃思路，因为Tap不通过依赖状态能更简单实现，故废弃。
			#1.处于NOT，2.处于NOT变换为TAP_IN瞬间，3.处于TAP_IN，4.处于TAP_IN变换为NOT瞬间（两条路径）
			#从NOT变换为TAP_IN只会由判定点引起；从TAP_IN变换为NOT既可能经过打击到了判定，也有可能是MISS了
			
			
			MfObjectType.TAP:
				##检测判定点上传
				while add_to_tap_priority_index < judge_timing.size() && judge_timing[add_to_tap_priority_index] - game.bad_window <= track_player.thread_track_player_latency_position:##（防越界）有判定点处于判定窗口（注意，当然是按bad_window来算的），则加入tap_action_mf_objects_priority排队。
					#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " hit_judgment.add_to_priority(self)")
					hit_judgment.add_to_priority(self)
					add_to_tap_priority_index += 1
			
			
			
			MfObjectType.DRAG:
				##检测判定点上传
				while add_to_tap_priority_index < judge_timing.size() && judge_timing[add_to_tap_priority_index] - game.bad_window <= track_player.thread_track_player_latency_position:##（防越界）有判定点处于判定窗口（注意，当然是按bad_window来算的），则加入tap_action_mf_objects_priority排队。
					#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " hit_judgment.add_to_touch(self)")
					hit_judgment.add_to_touch(self)
					add_to_tap_priority_index += 1
			
			
			
			MfObjectType.HOLD:
				##检测判定点上传
				while add_to_tap_priority_index < judge_timing.size() && judge_timing[add_to_tap_priority_index] - game.bad_window <= track_player.thread_track_player_latency_position:##（防越界）有判定点处于判定窗口（注意，当然是按bad_window来算的），则加入tap_action_mf_objects_priority排队。
					#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " hit_judgment.add_to_priority(self)")
					hit_judgment.add_to_priority(self)
					add_to_tap_priority_index += 1
					current_state = State.HOLD_IN
			
			
			
			
			
			








##判定评分后执行程序模块


func mf_object_hit(hit_score: HitJudgment.HitScore):##打击判定到了
	match mf_object_type:
		MfObjectType.TAP:
			tap_mf_object_hit(hit_score)
		MfObjectType.DRAG:
			drag_mf_object_hit(hit_score)
		MfObjectType.HOLD:##还要按状态分
			if current_state == State.HOLD_IN:
				hold_mf_object_hold_in_hit(hit_score)
			if current_state == State.HOLD_KEEP:
				hold_mf_object_hold_keep_hit(hit_score)


func mf_object_miss(hit_score: HitJudgment.HitScore):##MISS了（虽然知道判定的MISS，但还是按形式来吧）
	match mf_object_type:
		MfObjectType.TAP:
			tap_mf_object_miss(hit_score)
		MfObjectType.DRAG:
			drag_mf_object_miss(hit_score)
		MfObjectType.HOLD:##还要按状态分
			hold_mf_object_miss(hit_score)







##各类型MfObject执行函数

func tap_mf_object_hit(hit_score: HitJudgment.HitScore):##（被动调用）Tap类型MfObject被打击判定到了,自己要执行的程序（注意：Tap和Hold要分别执行）
	hit_judgment.remove_from_priority(self)
	judge_timing_hit_score.push_back(hit_score)
	judge_timing_index += 1
	##根据打击判定评分执行各自程序
	match hit_score:
		HitJudgment.HitScore.PERFECT:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is PERFECT")
			
		HitJudgment.HitScore.EARLY_GOOD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is EARLY_GOOD")
			
		HitJudgment.HitScore.LATE_GOOD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_GOOD")
			
		HitJudgment.HitScore.EARLY_BAD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is EARLY_BAD")
			
		HitJudgment.HitScore.LATE_BAD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_BAD")
			
		HitJudgment.HitScore.NOT:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_BAD")
			
	
	##根据打击判定评分固定执行的程序
	game.update_game_stats(hit_score)
	
	##检测所有打击判定点是否已结束
	if judge_timing_hit_score.size() == judge_timing.size():
		is_hit_jugement_over = true
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, "    所有判定点已结束")


func tap_mf_object_miss(hit_score: HitJudgment.HitScore):##（被动调用）Tap类型MfObject被判定为MISS,自己要执行的程序（注意：Tap和Hold要分别执行）
	hit_judgment.remove_from_priority(self)
	judge_timing_hit_score.push_back(hit_score)
	judge_timing_index += 1
	##根据打击判定MISS评分执行程序
	print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is MISS")
	
	##根据打击判定评分固定执行的程序
	game.update_game_stats(hit_score)
	
	##检测所有打击判定点是否已结束
	if judge_timing_hit_score.size() == judge_timing.size():
		is_hit_jugement_over = true
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, "    所有判定点已结束")
		








func drag_mf_object_hit(hit_score: HitJudgment.HitScore):##Drag类型MfObject被打击判定到了（虽然Drag打击判定到了肯定是PERFECT，但还是按形式来吧）
	hit_judgment.remove_from_touch(self)
	judge_timing_hit_score.push_back(hit_score)
	judge_timing_index += 1
	##根据打击判定PERFECT评分执行程序
	print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is PERFECT")
	
	##根据打击判定评分固定执行的程序
	game.update_game_stats(hit_score)
	
	##检测所有打击判定点是否已结束
	if judge_timing_hit_score.size() == judge_timing.size():
		is_hit_jugement_over = true
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, "    所有判定点已结束")
		


func drag_mf_object_miss(hit_score: HitJudgment.HitScore):##Drag类型MfObject被判定为MISS
	hit_judgment.remove_from_touch(self)
	judge_timing_hit_score.push_back(hit_score)
	judge_timing_index += 1
	##根据打击判定MISS评分执行程序
	print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is MISS")
	
	##根据打击判定评分固定执行的程序
	game.update_game_stats(hit_score)
	
	##检测所有打击判定点是否已结束
	if judge_timing_hit_score.size() == judge_timing.size():
		is_hit_jugement_over = true
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, "    所有判定点已结束")
		









func hold_mf_object_hold_in_hit(hit_score: HitJudgment.HitScore):##处于HOLD_IN的Hold类型MfObject被打击判定到了
	hit_judgment.remove_from_priority(self)
	hold_head_judge_timing_hit_score.push_back(hit_score)##Hold头部评分
	judge_timing_index += 1
	match hit_score:##根据打击判定评分执行各自程序
		HitJudgment.HitScore.PERFECT:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN PERFECT")
			
		HitJudgment.HitScore.EARLY_GOOD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN EARLY_GOOD")
			
		HitJudgment.HitScore.LATE_GOOD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN LATE_GOOD")
			
		HitJudgment.HitScore.EARLY_BAD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN EARLY_BAD")
			
		HitJudgment.HitScore.LATE_BAD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN LATE_BAD")
			
		HitJudgment.HitScore.NOT:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN LATE_BAD")
			
	
	#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " hit_judgment.add_to_touch(self)")
	hit_judgment.add_to_touch(self)
	current_state = State.HOLD_KEEP


func hold_mf_object_hold_keep_hit(hit_score: HitJudgment.HitScore):##处于HOLD_KEEP的Hold类型MfObject被打击判定到了
	
	if track_player.thread_track_player_latency_position < hold_release_timing[hold_release_timing_index] - game.bad_window:
		##若还处于HOLD_KEEP
		pass
	
	else:
		##HOLD_KEEP结束
		hit_judgment.remove_from_touch(self)
		var hold_head_hit_score = hold_head_judge_timing_hit_score[-1]
		judge_timing_hit_score.push_back(hold_head_hit_score)##（重要）若未MISS，则最终评分按头判的评分算。
		hold_release_timing_index += 1
		current_state = State.NOT
		match hold_head_hit_score:##根据打击判定评分执行各自程序
			HitJudgment.HitScore.PERFECT:
				print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is PERFECT")
				
			HitJudgment.HitScore.EARLY_GOOD:
				print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is EARLY_GOOD")
				
			HitJudgment.HitScore.LATE_GOOD:
				print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_GOOD")
				
			HitJudgment.HitScore.EARLY_BAD:
				print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is EARLY_BAD")
				
			HitJudgment.HitScore.LATE_BAD:
				print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_BAD")
				
			HitJudgment.HitScore.NOT:
				print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is NOT!!!")
				
		
		##根据打击判定评分固定执行的程序
		game.update_game_stats(hit_score)
		
		##检测所有打击判定点是否已结束
		if judge_timing_hit_score.size() == judge_timing.size():
			is_hit_jugement_over = true
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, "    所有判定点已结束")
			


func hold_mf_object_miss(hit_score: HitJudgment.HitScore):##Hold类型MfObject被判定为MISS（注意要考虑两种原因MISS的情况）
	if current_state == State.HOLD_IN:##情况1.未打击Hold头部
		hit_judgment.remove_from_priority(self)
		hold_head_judge_timing_hit_score.push_back(hit_score)##Hold头部评分
		judge_timing_index += 1
		judge_timing_hit_score.push_back(hit_score)##最终评分
		hold_release_timing_index += 1
		current_state = State.HOLD_IN_MISS
		
		##根据HOLD_IN_MISS评分执行程序
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is HOLD_IN MISS")
		
		##根据打击判定评分固定执行的程序
		game.update_game_stats(hit_score)

	if current_state == State.HOLD_KEEP:##情况2.在尾判前释放
		hit_judgment.remove_from_touch(self)
		judge_timing_hit_score.push_back(hit_score)
		hold_release_timing_index += 1
		current_state = State.HOLD_KEEP_MISS
		
		##根据HOLD_KEEP_MISS评分执行程序
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is MISS")
		
		##根据打击判定评分固定执行的程序
		game.update_game_stats(hit_score)
	
	
	##检测所有打击判定点是否已结束
	if judge_timing_hit_score.size() == judge_timing.size():
		is_hit_jugement_over = true
		print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, "    所有判定点已结束")
		




#endregion
