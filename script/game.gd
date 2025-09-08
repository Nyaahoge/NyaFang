##游戏信息（包含 静态 与 动态获取的）
##（记录灵感）分数实时计算：通过每时每刻的 perfect_count、good_count 和 max_combo 直接计算score，而不是按每次的判定来累加分数。有小数应floor()，避免多加发生问题，AP的情况则可直接计为full_score。
extends Node2D

@onready var chart_view: Node2D = $"../ChartView"##可从该节点获取谱面视图相关量
@onready var json_file_operator: Node = $"../JsonFileOperator"
@onready var hud: CanvasLayer = $"../HUD"

enum DifficultyLevel {##枚举 难度层级
	LAUGH,
	SMILE,
	FROWN,
	MAD
}

enum SettleGrade {##枚举 结算评级
	GOLD_NYA,##AP
	PINK_NYA,##FC
	GREEN_NYA,##达到95 0000
	BLUE_NYA,##达到90 0000
	PURPLE_NYA,##达到85 0000
	WHITE_NYA,##未达到85 0000
	NONE_NYA##未评级
}





func _ready() -> void:
	await get_tree().process_frame
	initialize()





func initialize():
	sum_mf_object_count = json_file_operator.chart_data["sum_mf_object_count"]##（读取）
	max_mf_object_count = json_file_operator.chart_data["max_mf_object_count"]##（读取）
	sum_mf_object_judgment_count = json_file_operator.chart_data["sum_mf_object_judgment_count"]##（读取）






##判定时间窗口，单位：正负秒。未得到以下判定则判定为miss。
var perfect_window = 0.080##-80 ~ +80
#var perfect_window = 0.080##（试验）
var good_window = 0.140##-140 ~ +140
#var good_window = 0.140##（试验）
var bad_window = 0.160##-160 ~ +160
#var bad_window = 0.160##（试验）


@export var latency_adjustment: float##(读取设置)（调整延时）谱面延时。要让谱面比track迟一点，就要调正调大


var difficulty_level: DifficultyLevel##（从谱面文件读取）当前曲目的难度层级
var difficulty_rating: int##（读取）当前曲目的难度数













var full_score: int = 1000000##满分，一百万
var max_combo_score_weight: float = 0.15##max_combo在score中的权重。默认15%
var judgment_score_weight: float = 1 - max_combo_score_weight

var sum_mf_object_count: int##（读取）
var max_mf_object_count: int##（读取）
var sum_mf_object_judgment_count: int##（读取）

var full_max_combo_to_score: int = floor(full_score * max_combo_score_weight)
var full_judgment_to_score: int = floor(full_score * judgment_score_weight)

var perfect_count_score_ratio: float = 1.0
var good_count_score_ratio: float = 0.5
var bad_count_score_ratio: float = 0.0##不计入
var miss_count_score_ratio: float = 0.0##不计入

var perfect_count_accuracy_ratio: float = 1.0
var good_count_accuracy_ratio: float = 0.75
var bad_count_accuracy_ratio: float = 0.25
var miss_count_accuracy_ratio: float = 0.0







var player_name: String##（读取）玩家昵称

var combo: int = 0##（实时）连击数
var max_combo: int = 0##（实时）最大连击数

var perfect_count: int = 0##（实时）perfect表现的打击数
var good_count: int = 0##（实时）good表现的打击数
var bad_count: int = 0##（实时）bad表现的打击数
var miss_count: int = 0##（实时）miss表现的“打击”数
var hit_count: int = 0##（实时）总打击数

var max_combo_to_score: int = 0##（实时）
var judgment_to_score: int = 0##（实时）注意跟combo不一样，要看判定评分

var score: int = 0##（实时）分数，满分为full_score，一百万
var accuracy: float = 1.0##（实时）准度


var settle_grade: SettleGrade##（实时）结算评级

func update_game_stats(hit_score: HitJudgment.HitScore):##（更新）
	
	##根据打击判定评分执行各自程序
	match hit_score:
		HitJudgment.HitScore.PERFECT:
			perfect_count += 1;hit_count += 1;combo += 1
		HitJudgment.HitScore.EARLY_GOOD:
			good_count += 1;hit_count += 1;combo += 1
		HitJudgment.HitScore.LATE_GOOD:
			good_count += 1;hit_count += 1;combo += 1
		HitJudgment.HitScore.EARLY_BAD:
			bad_count += 1;hit_count += 1;combo = 0
		HitJudgment.HitScore.LATE_BAD:
			bad_count += 1;hit_count += 1;combo = 0
		HitJudgment.HitScore.MISS:
			miss_count += 1;hit_count += 1;combo = 0
		HitJudgment.HitScore.NOT:
			combo = 0
			
	
	##更新max_combo
	if combo > max_combo:
		max_combo = combo
	
	##计算score；AP的情况则可直接计为full_score
	if perfect_count < sum_mf_object_judgment_count:
		max_combo_to_score = floor(full_max_combo_to_score * (max_combo / sum_mf_object_judgment_count))
		judgment_to_score = floor(full_judgment_to_score * ((perfect_count * perfect_count_score_ratio + good_count * good_count_score_ratio) / sum_mf_object_judgment_count))
		score = max_combo_to_score + judgment_to_score
	else:
		max_combo_to_score = full_max_combo_to_score
		judgment_to_score = full_judgment_to_score
		score = full_score
	
	##计算准度
	if hit_count == 0:
		accuracy = 1.0
	else:
		accuracy = (perfect_count * perfect_count_accuracy_ratio + good_count * good_count_accuracy_ratio + bad_count * bad_count_accuracy_ratio + miss_count * miss_count_accuracy_ratio) / hit_count
	
	##计算结算评级
	if perfect_count == hit_count:
		settle_grade = SettleGrade.GOLD_NYA
	elif miss_count == 0:
		settle_grade = SettleGrade.PINK_NYA
	elif score < 850000:
		settle_grade = SettleGrade.WHITE_NYA
	elif 850000 <= score && score < 900000:
		settle_grade = SettleGrade.PURPLE_NYA
	elif 900000 <= score && score < 950000:
		settle_grade = SettleGrade.BLUE_NYA
	elif 950000 <= score:
		settle_grade = SettleGrade.GREEN_NYA
	
	
	
	
	##判断是否所有MfObject的判定点都已结束
	if hit_count >= sum_mf_object_judgment_count:
		is_all_hit_judgment_over = true
	
	
	hud.update()



var is_all_hit_judgment_over: bool = false##是否所有MfObject的判定点都已结束
