# ScoreManager.gd
extends Node

var score: int = 0

signal score_changed(new_score: int)

func add_points(amount: int) -> void:
	score += amount
	emit_signal("score_changed", score)

func reset_score() -> void:
	score = 0
	emit_signal("score_changed", score)
