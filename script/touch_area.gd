##检测触控并附带时刻：  1.按着  2.按下  3.抬起
extends Area2D

@onready var track_player: AudioStreamPlayer = $"../../../../../TrackPlayer"
#@onready var game: Node = $"../../../../../Game"
@onready var fingers_tracker: Node = $"../../../../../Game/FingersTracker"

@onready var mf_object: MfObject = $"../../.."








#func _ready() -> void:
	#touch_detection_initialize()

#func _physics_process(delta: float) -> void:









##检测触控模块（将鼠标、触控点操作识别成音游操作，发送到hit_jugement）
var is_mouse_inside: bool = false
var is_left_mouse_pressed: bool = false
#func touch_detection_initialize() -> void:
	
	
#func touch_detection(event) -> void:
	#
	###PC端
	#match mf_object.current_state:
		#MfObject.State.TAP_IN:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
		#
		#
		#
		#MfObject.State.DRAG_IN:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
		#
		#
		#
		#MfObject.State.HOLD_IN:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
		#
		#MfObject.State.HOLD_KEEP:
			#if Input.is_action_pressed("mouse_hold"):
				#mf_object.hit_jugement(track_player.thread_track_player_position)
				#print("1111111")
		#
		#MfObject.State.HOLD_OUT:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
#
#
	###移动端
	#match mf_object.current_state:
		#MfObject.State.TAP_IN:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
		#
		#
		#
		#MfObject.State.DRAG_IN:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
		#
		#
		#
		#MfObject.State.HOLD_IN:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
		#
		#MfObject.State.HOLD_KEEP:
			#if Input.is_action_pressed("mouse_hold"):
				#mf_object.hit_jugement(track_player.thread_track_player_position)
				#print("1111111")
		#
		#MfObject.State.HOLD_OUT:
			#if event is InputEventMouseButton:
				#if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					#mf_object.hit_jugement(track_player.thread_track_player_position)
