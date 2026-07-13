## Configurable preview entry: edit the exports in the inspector to
## pick which env to run and how many parallel envs to spawn.
##
## This is the "default" way to use the framework: pick an env, set
## num_envs, hit Play. The Academy spawns N parallel envs, the grid
## shows them all, and random actions drive the agents.
extends Node2D

@export var env_name: String = "cartpole"
@export var num_envs: int = 16
@export var columns: int = 4
@export var time_scale: float = 1.0

var _preview: RLPreviewScene


func _ready() -> void:
	RLEnvRegistration.register_all()
	_preview = RLPreviewScene.new()
	_preview.env_name = env_name
	_preview.num_envs = num_envs
	_preview.columns = columns
	_preview.time_scale = time_scale
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_preview)
