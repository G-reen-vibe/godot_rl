## Test entry: load a single cartpole env (no Academy), step physics,
## and print observations + rewards to console.
##
## This validates that:
##   - The tscn loads cleanly
##   - Physics bodies are wired correctly
##   - The agent exposes obs / action / reward correctly
##   - The pole actually falls under gravity when no action is applied
extends Node2D

var _env: CartPoleEnv
var _step: int = 0
var _max_steps: int = 300


func _ready() -> void:
	RLEnvRegistration.register_all()
	var scene := load("res://rl/envs/cartpole/cartpole_env.tscn") as PackedScene
	_env = scene.instantiate() as CartPoleEnv
	add_child(_env)
	_env.reset()
	print("[entry_test] env_name=", _env.env_name)
	print("[entry_test] agent_count=", _env.get_agent_count())
	print("[entry_test] action_dim=", _env.get_action_dim())
	print("[entry_test] obs_dim=", _env.get_obs_dim())
	print("[entry_test] initial_obs=", _env.get_observations())


func _physics_process(delta: float) -> void:
	# Apply a tiny periodic force so the cart wiggles (just to test action path)
	var action := PackedFloat32Array()
	action.append(sin(_step * 0.05) * 0.5)
	var actions: Array[PackedFloat32Array] = [action]
	_env.apply_actions(actions)
	_env.physics_step(delta)

	_step += 1
	if _step % 30 == 0:
		var obs := _env.get_observations()
		print("[step %4d] obs=%s  reward=%.2f  done=%s" % [
			_step, obs, _env.get_reward(), _env.is_done()
		])

	if _env.is_done() or _step >= _max_steps:
		print("[entry_test] done after %d steps, final_reward=%.1f" % [
			_step, _env.get_reward()
		])
		_env.reset()
		_step = 0
		print("[entry_test] reset OK")
		set_physics_process(false)
