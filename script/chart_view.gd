extends Node2D

@onready var camera_2d: Camera2D = $"../Camera2D"



var standard_chart_in_viewport_size_y: float = 2000##（重要）预设谱面视图矩形在程序中统一的y尺寸
var view_aspect_ratio: float = 1.777777777777777777777777777777##谱面视图宽高比（要从谱面文件获取）
var chart_size: Vector2 = Vector2(standard_chart_in_viewport_size_y * view_aspect_ratio, standard_chart_in_viewport_size_y)##高为standard_chart_in_viewport_size_y的谱面视图尺寸

var viewport_size: Vector2##此程序窗口的尺寸
var viewport_aspect_ratio: float##此程序窗口的宽高比


func _ready() -> void:
	chart_view_initialize()




##视图适配调整模块
func chart_view_initialize() -> void:
	viewport_size = get_viewport().size
	viewport_aspect_ratio = viewport_size.x / viewport_size.y
	if view_aspect_ratio <= viewport_aspect_ratio:
		camera_2d.zoom = Vector2(viewport_size.y / chart_size.y, viewport_size.y / chart_size.y)
		
	else:
		camera_2d.zoom = Vector2(viewport_size.x / chart_size.x, viewport_size.x / chart_size.x)
		
	#print(chart_size)
	
	
	
	queue_redraw()


func on_viewport_resized():##视图改变时进行适配调整操作；不需要此功能？
	viewport_size = get_viewport().size
	viewport_aspect_ratio = viewport_size.x / viewport_size.y
	if view_aspect_ratio <= viewport_aspect_ratio:
		camera_2d.zoom = Vector2(viewport_size.y / chart_size.y, viewport_size.y / chart_size.y)
		
	else:
		camera_2d.zoom = Vector2(viewport_size.x / chart_size.x, viewport_size.x / chart_size.x)
		
	print(chart_size)
	
	
	
	queue_redraw()


func _draw():
	draw_rect(Rect2(- Vector2(chart_size.x, chart_size.y) / 2, Vector2(chart_size.x, chart_size.y)), Color.WHITE, false, 5, false)
