##（自拟）喵方对象
##MfObject：note们及box的统一名称，当时没有抽象，现在已经迟了。
##因为会导致抖动所以不考虑AudioServer.get_time_since_last_mix()

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
	HOLD_OUT,##Hold的二阶段判定中状态（判定后立即变为NOT状态（击中或miss））
}



##@onready节点
#region
@onready var game: Node = $"../../Game"
@onready var hit_jugdment: Node = $"../../Game/HitJugdment"


@onready var track_player: AudioStreamPlayer = $"../../TrackPlayer"

@onready var move_curve: Path2D = $MoveCurve
@onready var path_follow_2d: PathFollow2D = $MoveCurve/PathFollow2D
@onready var touch_area: Area2D = $MoveCurve/PathFollow2D/TouchArea
@onready var collision_polygon_2d: CollisionPolygon2D = $MoveCurve/PathFollow2D/TouchArea/CollisionPolygon2D




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
@export var jugde_timing: Array##判定时机，以歌曲时间为参照
@export var hold_release_timing: Array##hold这种键型的长按释放时机，以歌曲时间为参照
@export var mf_z_index: int = -1##MfObject图层
@export  var thickness: float = 30.0##图形样式的厚度。目前先设为不可变，默认30.0。
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
	set_process(false)#停止 _process()调用
	set_physics_process(false)#停止 _physics_process()调用

func initialize(dictionary: Dictionary) -> void:##MfObject根据新值初始化（就是从对象池拿出来复用时的初始化），参数为要导入的MfObject的字典
	##主要值的初始化设置
	mf_object_type = dictionary["mf_object_type"]
	exist_period = dictionary["exist_period"]
	jugde_timing = dictionary["jugde_timing"]
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
	
	
	##其他初始化设置
	box_shape.visible = false
	tap_shape.visible = false
	drag_shape.visible = false
	hold_shape.visible = false
	match  mf_object_type:
		MfObjectType.BOX:
			box_shape.z_index = 100 if mf_z_index == -1 else mf_z_index##设置不同MfObject对应图层，未设置mf_z_index将启用默认值。
			box_shape.visible = true##mf_object_type分别对应的四种皮肤（默认为图形绘制降低性能要求）
		MfObjectType.TAP:
			tap_shape.z_index = 200 if mf_z_index == -1 else mf_z_index
			tap_shape.visible = true
		MfObjectType.DRAG:
			drag_shape.z_index = 200 if mf_z_index == -1 else mf_z_index
			drag_shape.visible = true
		MfObjectType.HOLD:
			hold_shape.z_index = 200 if mf_z_index == -1 else mf_z_index
			hold_shape.visible = true



func _process(_delta: float) -> void:
	curve_handling()

func _physics_process(_delta: float) -> void:
	judgment_state_detection()








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
		path_follow_2d.progress_ratio = progress_ratio_curve.sample(track_player_latency_position)
	else:
		print("move_curve 或 progress_ratio_curve为空")
	
	if length_curve && width_curve:##长、宽，注意不是单纯缩放；另外注意，长宽以Box的内外图形间（Drag一样）为标准
		##绘制MfObject图形
		#regions
		var a: float = length_curve.sample(track_player_latency_position)#（临时变量）长
		var b: float = width_curve.sample(track_player_latency_position)#（临时变量）宽
		var t: float = thickness#（重要）（设定）（临时变量）厚度
		
		curve_size = Vector2(a, b)##用于传出长宽数值
		
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
		##TouchArea的碰撞体直接用Drag的图形
		collision_polygon_2d.polygon = [Vector2(a / 2, - b / 2), Vector2(- a / 2, - b / 2), Vector2(- a / 2, b / 2), Vector2(a / 2, b / 2)]
	else:
		print("length_curve 或 width_curve为空")
		
	if rotation_curve:
		shape.rotation_degrees = rotation_curve.sample(track_player_latency_position)
		collision_polygon_2d.rotation_degrees = shape.rotation_degrees
	else:
		print("rotation_curve为空")
	
	if opacity_curve:
		shape.modulate.a = opacity_curve.sample(track_player_latency_position)
	else:
		print("opacity_curve为空")
	
#endregion









##管理判定相关状态主要模块（根据State、被如何打击和判定相关量，管理MfObject的判定过程）
#region
var is_hit_jugement_over: bool = false##所有打击判定点是否已结束

var current_state: State = State.NOT##(当前)当前状态

var jugde_timing_index: int = 0##（重要）（标记）接下来要进行或正在进行的判定点。随检测判定更新。
var hold_release_timing_index: int = 0##（重要）（标记）接下来要或正在进行的Hold尾部判定点。随检测判定更新。
#var is_on_hold_in: bool = false##（当前）是否进入hold判定期

var add_to_tap_priority_index: int = 0##（重要）（标记）接下来要to_tap_priority的判定点

var judge_timing_hit_score: Array##记录每次（Hold是看最终评分）判定的评分。（不要跟表示总分数的score混淆了）
var hold_head_judge_timing_hit_score: Array##记录每次Hold头部判定的评分。（头部一判定就记录）

func judgment_state_detection() -> void:##State检测
	
	
	#print(track_player.get_playback_position())
	if not is_hit_jugement_over:##所有打击判定点未结束，则运行打击判定等相关模块
		
		track_player_latency_position = track_player.thread_track_player_latency_position##（更新值）
		#var is_in_jugde_timing_bad_window = jugde_timing[jugde_timing_index] - game.bad_window <= track_player.thread_track_player_latency_position && track_player.thread_track_player_latency_position <= jugde_timing[jugde_timing_index] + game.bad_window##是否处于jugde_timing判定期
		
		
		
		
		#if is_in_jugde_timing_bad_window:
			#print(track_player.get_playback_position())
			
			
			
		##（重要）注意在tap_in_or_hold_in_mf_objects_priority上的添加与删除
		match mf_object_type:
			
			##MfObjectType.TAP:
			##以下为废弃思路，因为Tap不通过依赖状态能更简单实现，故废弃。
			#1.处于NOT，2.处于NOT变换为TAP_IN瞬间，3.处于TAP_IN，4.处于TAP_IN变换为NOT瞬间（两条路径）
			#从NOT变换为TAP_IN只会由判定点引起；从TAP_IN变换为NOT既可能经过打击到了判定，也有可能是MISS了
			
			
			MfObjectType.TAP:
				
				while add_to_tap_priority_index < jugde_timing.size() && jugde_timing[add_to_tap_priority_index] - game.bad_window <= track_player.thread_track_player_latency_position:##（防越界）有判定点处于判定窗口（注意，当然是按bad_window来算的），则加入tap_in_or_hold_in_mf_objects_priority排队。
					#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " hit_jugdment.add_to_priority(self)")
					hit_jugdment.add_to_priority(self)
					add_to_tap_priority_index += 1
					
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			
			#MfObjectType.TAP:
				###不论状态，只按给出条件执行
				#
				#
				#
				#if is_in_jugde_timing_bad_window and judge_timing_hit_score.size() <= jugde_timing_index:##处于判定期 同时 当前判定点还未被评分
					#if current_state == State.NOT:
					###（状态）处于NOT变换为TAP_IN瞬间
						#mf_objects_priority.add_to_priority(self)
					#
					#
					#
					###（状态）处于TAP_IN
					##if self not in mf_objects_priority.tap_in_or_hold_in_mf_objects_priority:
						##mf_objects_priority.add_to_priority(self)##TAP_IN时保证在优先判定组内，特别是打击判定后接着处于下一个判定点的判定窗口这个情况。
					#if not current_state == State.TAP_IN:
						#current_state = State.TAP_IN
					##to_tap_priority_index
					#
				#else:
					#
					#if current_state == State.TAP_IN and not judge_timing_hit_score.size() <= jugde_timing_index:
						###（状态）处于TAP_IN变换为NOT瞬间  且  由于打击到了判定分数了而转换为State.NOT的
						#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is TAP")
						#mf_objects_priority.remove_from_priority(self)
						#jugde_timing_index += 1
					#
					#
					#if current_state == State.TAP_IN and judge_timing_hit_score.size() <= jugde_timing_index:
						###（状态）处于TAP_IN变换为NOT瞬间  且  是因为 一直到State.TAP_IN结束都没有打击判定 的原因而转换为State.NOT的，则视为HitScore.MISS。
						#mf_objects_priority.remove_from_priority(self)
						#
						#judge_timing_hit_score.push_back(HitScore.MISS)
						#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is MISS")
						#
						#jugde_timing_index += 1
						#if jugde_timing_index >= jugde_timing.size():
							#is_hit_jugement_over = true
							#print("is_hit_jugement_over == true")
					#
					#
					###（状态）处于NOT
					#if not current_state == State.NOT:
						#current_state = State.NOT
			#
			#
			#
			#
			#
			#
			#MfObjectType.DRAG:
				#if is_in_jugde_timing_bad_window and judge_timing_hit_score.size() <= jugde_timing_index:##处于判定期 同时 当前判定点还未被评分
					#if not current_state == State.DRAG_IN:
						#current_state = State.DRAG_IN
				#else:
					#
					#if current_state == State.DRAG_IN and judge_timing_hit_score.size() <= jugde_timing_index:
						#judge_timing_hit_score.push_back(HitScore.MISS)
						#print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is MISS")
						#jugde_timing_index += 1
						#if jugde_timing_index >= jugde_timing.size():
							#is_hit_jugement_over = true
							#print("is_hit_jugement_over == true")
					#
					#if not current_state == State.NOT:
						#current_state = State.NOT
			#
			#
			#
			#
			#
			#
			#
			#MfObjectType.HOLD:
				###Hold专用量
				#var is_in_hold_release_timing_bad_window = hold_release_timing[hold_release_timing_index] - game.bad_window <= track_player_position and track_player_position <= hold_release_timing[hold_release_timing_index]##是否处于jugde_timing判定期。（跟jugde_timing期组成不同，因为无尾判））
				#
				#
				#
				#
				#
				###管理状态
				#
				#if is_in_jugde_timing_bad_window and hold_head_judge_timing_hit_score.size() <= jugde_timing_index:
					###（状态）处于NOT变换为HOLD_IN瞬间
					#if current_state == State.NOT:
						#mf_objects_priority.add_to_priority(self)
					#
					#
					#
					###（状态）处于##（状态）处于HOLD_IN
					#if not current_state == State.HOLD_IN:
						#current_state = State.HOLD_IN
					#
					#
					#
				#elif (not is_in_hold_release_timing_bad_window) and hold_head_judge_timing_hit_score.size() > judge_timing_hit_score.size():##头判后长按状态。头判成功尾部未判且还未到尾部时。
					###（状态）处于HOLD_IN变换为HOLD_KEEP瞬间
					#if current_state == State.HOLD_IN:
						#pass
						##mf_objects_priority.remove_from_priority(self)附加到判定代码里吧
					#
					#
					#
					###（状态）处于##（状态）处于HOLD_KEEP
					#if not current_state == State.HOLD_KEEP:
						#current_state = State.HOLD_KEEP
					#
					#
					#
				#elif is_in_hold_release_timing_bad_window and hold_head_judge_timing_hit_score.size() > judge_timing_hit_score.size():
					###（状态）处于HOLD_KEEP变换为HOLD_OUT瞬间
					#if current_state == State.HOLD_IN:
						#pass
					#
					#
					#
					###（状态）处于##（状态）处于HOLD_OUT
					#if not current_state == State.HOLD_OUT:
						#current_state = State.HOLD_OUT
					#
					#
					#
				#else:
					###（状态）处于因为判定到了分数而从其他状态变换为NOT瞬间
					#if (current_state == State.HOLD_IN or current_state == State.HOLD_KEEP or current_state == State.HOLD_OUT) and judge_timing_hit_score.size() <= jugde_timing_index:
						#pass
					#
					#
					#
					###（状态）处于因为MISS而从其他状态变换为NOT瞬间
					#if (current_state == State.HOLD_IN or current_state == State.HOLD_KEEP or current_state == State.HOLD_OUT) and judge_timing_hit_score.size() <= jugde_timing_index:
						#mf_objects_priority.remove_from_priority(self)
						#judge_timing_hit_score.push_back(HitScore.MISS)
						#print("[MfObject]    ", (track_player.thread_track_player_position), "   ", self, " is MISS")
						#jugde_timing_index += 1
						#if jugde_timing_index >= jugde_timing.size():
							#is_hit_jugement_over = true
							#print("is_hit_jugement_over == true")
					#
					#
					#
					###（状态）处于NOT
					#if not current_state == State.NOT:
						#current_state = State.NOT
			#
			#
			#
			###（这个状态考虑废弃，不提示了）于NOT同时是MISS了的状态，用于提示MISS的效果
	
	
	
	



##判定评分后执行程序模块

##打击判定到了
func mf_object_tap_hit(hitscore: int):##（被动调用）MfObject的tap动作被打击判定到了,自己要执行的程序（注意：Tap和Hold要分别执行）
	hit_jugdment.remove_from_priority(self)
	judge_timing_hit_score.push_back(hitscore)
	jugde_timing_index += 1
	match hitscore:##根据打击判定评分执行各自程序
		HitJugdment.HitScore.PERFECT:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is PERFECT")
		HitJugdment.HitScore.EARLY_GOOD :
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is EARLY_GOOD")
		HitJugdment.HitScore.LATE_GOOD :
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_GOOD")
		HitJugdment.HitScore.EARLY_BAD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is EARLY_BAD")
		HitJugdment.HitScore.LATE_BAD:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_BAD")
		HitJugdment.HitScore.NOT:
			print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is LATE_BAD")
	if add_to_tap_priority_index >= jugde_timing.size():##检测所有打击判定点是否已结束
		is_hit_jugement_over = true
		print("1")

##MISS了
func mf_object_tap_miss():##（被动调用）MfObject的tap动作被判定为MISS,自己要执行的程序（注意：Tap和Hold要分别执行）
	hit_jugdment.remove_from_priority(self)
	judge_timing_hit_score.push_back(hit_jugdment.HitScore.MISS)
	jugde_timing_index += 1
	print("[MfObject]    ", track_player.thread_track_player_position, "   ", self, " is MISS")
	if add_to_tap_priority_index >= jugde_timing.size():##检测所有打击判定点是否已结束
		is_hit_jugement_over = true
		print("1")




#endregion
