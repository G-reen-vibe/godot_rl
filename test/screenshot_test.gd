## Renders a screenshot of the preview UI after a few seconds of running.
## Used to verify the layout looks good without needing a display.
extends Node2D

var _ui: RLPreviewUI
var _time: float = 0.0


func _ready() -> void:
	_ui = RLPreviewUI.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)


func _process(delta: float) -> void:
	_time += delta
	if _time > 3.0:
		var img := get_viewport().get_texture().get_image()
		var path := "res://screenshot.png"
		img.save_png("user://screenshot.png")
		print("[screenshot] saved to user://screenshot.png")
		# Also try res://
		var err := img.save_png(path)
		print("[screenshot] save to res://: ", err)
		get_tree().quit()
