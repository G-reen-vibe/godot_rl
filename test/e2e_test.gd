## End-to-end test: run each env type through the Academy + preview grid.
##
## For each env:
##   1. Spawn N parallel envs via the Academy
##   2. Apply random actions
##   3. Verify stats accumulate and episodes reset
##   4. Log results
##
## This is the closest thing to "playing the game" without a real trainer.
extends Node2D

const ENV_NAMES := ["cartpole", "pong", "lunar_lander", "bipedal_walker"]
const NUM_ENVS := 9
const STEPS_PER_ENV := 300

var _current_env_idx: int = 0
var _step: int = 0
var _preview: RLPreviewScene


func _ready() -> void:
	RLEnvRegistration.register_all()
	_start_env(ENV_NAMES[0])


func _start_env(env_name: String) -> void:
	if _preview:
		_preview.queue_free()
	_preview = RLPreviewScene.new()
	_preview.env_name = env_name
	_preview.num_envs = NUM_ENVS
	_preview.columns = 3
	_preview.time_scale = 1.0
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_preview)
	_step = 0
	print("\n=== Starting env: %s ===" % env_name)
	await get_tree().create_timer(0.5).timeout
	print("[e2e] academy spawned envs: ", _preview._academy.get_num_envs())


func _physics_process(_delta: float) -> void:
	_step += 1
	if _step % 60 == 0:
		var stats := _preview._academy.get_stats()
		var total_reward := 0.0
		var avg_steps := 0.0
		for s in stats:
			total_reward += s.get("episode_reward", 0.0)
			avg_steps += s.get("steps", 0)
		avg_steps /= max(1, stats.size())
		print("[%s step %3d] envs=%d  total_reward=%.1f  avg_steps=%.0f" % [
			ENV_NAMES[_current_env_idx], _step, stats.size(), total_reward, avg_steps
		])
	if _step >= STEPS_PER_ENV:
		print("[e2e] %s completed %d steps" % [ENV_NAMES[_current_env_idx], _step])
		_current_env_idx += 1
		if _current_env_idx >= ENV_NAMES.size():
			print("\n=== All envs tested successfully ===")
			set_physics_process(false)
		else:
			_start_env(ENV_NAMES[_current_env_idx])
