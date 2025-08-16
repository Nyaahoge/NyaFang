extends Node2D

@onready var button_tap: Button = $ButtonTap
@onready var button_drag: Button = $ButtonDrag
@onready var audio_stream_player_tap: AudioStreamPlayer = $AudioStreamPlayerTap
@onready var audio_stream_player_drag: AudioStreamPlayer = $AudioStreamPlayerDrag


func _ready() -> void:
	button_tap.button_down.connect(_button_tap_button_down)
	button_drag.button_down.connect(_button_drag_button_down)

func _button_tap_button_down() -> void:
	audio_stream_player_tap.play()

func _button_drag_button_down() -> void:
	audio_stream_player_drag.play()
