##游戏信息（包含 静态 与 动态获取的）
class_name Game
extends Node2D

@onready var chart_view: Node2D = $"../ChartView"##可从该节点获取谱面视图相关量
@onready var canvas_layer: CanvasLayer = $"../CanvasLayer"








##判定时间窗口，单位：正负秒。未得到以下判定则判定为miss。
var perfect_window = 0.080##-80 ~ +80
#var perfect_window = 0.080##（试验）
var good_window = 0.140##-140 ~ +140
#var good_window = 0.140##（试验）
var bad_window = 0.160##-160 ~ +160
#var bad_window = 0.160##（试验）






@export var latency_adjustment: float##（调整延时）谱面延时。要让谱面比track迟一点，就要调正调大
