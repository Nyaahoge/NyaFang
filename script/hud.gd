extends CanvasLayer

@onready var game: Node2D = $"../Game"

@onready var accuracy: Label = $Accuracy
@onready var combo_and_menu: Label = $ComboAndMenu
@onready var score: Label = $Score

func _ready() -> void:
	await get_tree().process_frame
	update()



func update():
	accuracy.text = str("%.4f%%" % [game.accuracy * 100])
	combo_and_menu.text = str(game.combo)
	score.text = str("%07d" % [game.score])
