## Lunar lander test: single env, random actions, log state.
extends Node2D

var _env: LunarLanderEnv
var _step: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	RLEnvRegistration.register_all()
	var scene := load("res://rl/envs/lunar_lander/lunar_lander_env.tscn") as PackedScene
	_env = scene.instantiate() as LunarLanderEnv
	add_child(_env)
	_env.reset()
	print("[ll_test] env_name=", _env.env_name)
	print("[ll_test] agent_count=", _env.get_agent_count())
	print("[ll_test] action_dim=", _env.get_action_dim())
	print("[ll_test] obs_dim=", _env.get_obs_dim())
	_rng.randomize()


func _physics_process(delta: float) -> void:
	var actions: Array[PackedFloat32Array] = []
	actions.append(PackedFloat32Array([
		_rng.randf_range(0.0, 1.0),  # main
		_rng.randf_range(0.0, 1.0),  # left
		_rng.randf_range(0.0, 1.0),  # right
	]))
	_env.apply_actions(actions)
	_env.physics_step(delta)

	_step += 1
	if _step % 30 == 0 or _env.is_done():
		var agent := _env.get_node("LunarLanderAgent") as LunarLanderAgent
		print("[step %4d] pos=(%.1f,%.1f) vel=(%.1f,%.1f) angle=%.2f reward=%.2f done=%s" % [
			_step, agent.lander.position.x, agent.lander.position.y,
			agent.lander.linear_velocity.x, agent.lander.linear_velocity.y,
			agent.lander.rotation, _env.get_reward(), _env.is_done()
		])
	if _env.is_done() or _step >= 600:
		print("[ll_test] episode ended after %d steps" % _step)
		_env.reset()
		_step = 0
		if Engine.get_physics_frames() > 1500:
			set_physics_process(false)
			print("[ll_test] stopping")
