extends Node2D

@onready var camera_2d: Camera2D = $"../Camera2D"



var standard_chart_in_viewport_size_y: float = 2000.0##（重要）预设谱面视图矩形在程序中统一的y尺寸
var view_aspect_ratio: float = 1.777777777777777777777777777777##谱面视图宽高比（要从谱面文件获取）
var chart_size: Vector2 = Vector2(standard_chart_in_viewport_size_y * view_aspect_ratio, standard_chart_in_viewport_size_y)##高为standard_chart_in_viewport_size_y的谱面视图尺寸

var viewport_size: Vector2##视图可见世界坐标的尺寸
var viewport_aspect_ratio: float##此程序窗口的宽高比
var viewport_chart_ratio##此程序窗口的尺寸 与 谱面视图尺寸 之比。用于变换视图比例。

var screen_size: Vector2##屏幕尺寸
var screen_aspect_ratio: float
var screen_chart_ratio

var expand_viewport_size: Vector2##（重要）考虑了expand拉伸模式后视图可见世界坐标的尺寸
var expand_screen_aspect_ratio: float
var expand_screen_chart_ratio

func _ready() -> void:
	chart_view_initialize()




##视图适配调整模块
#var is_view_aspect_ratio_less_than_viewport_aspect_ratio: bool
#var is_view_aspect_ratio_less_than_screen_aspect_ratio: bool
var is_screen_aspect_ratio_more_than_viewport_aspect_ratio: bool
var is_expand_screen_aspect_ratio_more_than_view_aspect_ratio:bool
var is_screen_aspect_ratio_more_than_view_aspect_ratio:bool
func chart_view_initialize() -> void:
	#viewport_size = get_viewport().size
	
	viewport_size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	screen_size = DisplayServer.screen_get_size()
	
	
	viewport_aspect_ratio = viewport_size.x / viewport_size.y
	screen_aspect_ratio = screen_size.x / screen_size.y
	
	

	
	
	if screen_aspect_ratio >= viewport_aspect_ratio:
		is_screen_aspect_ratio_more_than_viewport_aspect_ratio = true
	else:
		is_screen_aspect_ratio_more_than_viewport_aspect_ratio = false
	
	
	
	#if view_aspect_ratio <= screen_aspect_ratio:
		#is_view_aspect_ratio_less_than_screen_aspect_ratio = true
	#else:
		#is_view_aspect_ratio_less_than_screen_aspect_ratio = false
		
	
	if is_screen_aspect_ratio_more_than_viewport_aspect_ratio:
		expand_viewport_size = Vector2(viewport_size.y * screen_aspect_ratio, viewport_size.y)
		#viewport_chart_ratio = viewport_size.y / chart_size.y
		#screen_chart_ratio = screen_size.y / chart_size.y
		#camera_2d.zoom = Vector2(viewport_chart_ratio, viewport_chart_ratio)
		
	else:
		expand_viewport_size = Vector2(viewport_size.x, viewport_size.x / screen_aspect_ratio)
		#viewport_chart_ratio = viewport_size.x / chart_size.x
		#screen_chart_ratio = screen_size.x / chart_size.x
		#camera_2d.zoom = Vector2(viewport_chart_ratio, viewport_chart_ratio)
	expand_screen_aspect_ratio = expand_viewport_size.x / expand_viewport_size.y
	
	
	if screen_aspect_ratio >= view_aspect_ratio:
		#is_expand_screen_aspect_ratio_more_than_view_aspect_ratio = true
		is_screen_aspect_ratio_more_than_view_aspect_ratio = true
		expand_screen_chart_ratio = expand_viewport_size.y / chart_size.y
	else:
		#is_expand_screen_aspect_ratio_more_than_view_aspect_ratio = false
		is_screen_aspect_ratio_more_than_view_aspect_ratio = false
		expand_screen_chart_ratio = expand_viewport_size.x / chart_size.x
	
	camera_2d.zoom = Vector2(expand_screen_chart_ratio, expand_screen_chart_ratio)
	
	
	queue_redraw()


#func on_viewport_resized():##视图改变时进行适配调整操作；不需要此功能？
	#viewport_size = get_viewport().size
	#if view_aspect_ratio <= screen_aspect_ratio:
		#is_view_aspect_ratio_less_than_screen_aspect_ratio = true
		#viewport_chart_ratio = viewport_size.y / chart_size.y
		#screen_chart_ratio = screen_size.y / chart_size.y
		#camera_2d.zoom = Vector2(viewport_chart_ratio, viewport_chart_ratio)
		#
	#else:
		#is_view_aspect_ratio_less_than_screen_aspect_ratio = false
		#viewport_chart_ratio = viewport_size.x / chart_size.x
		#screen_chart_ratio = screen_size.x / chart_size.x
		#camera_2d.zoom = Vector2(viewport_chart_ratio, viewport_chart_ratio)
		
	#print(chart_size)
	
	
	queue_redraw()


func _draw():
	draw_rect(Rect2(- Vector2(chart_size.x, chart_size.y) / 2, Vector2(chart_size.x, chart_size.y)), Color.WHITE, false, 5, false)
