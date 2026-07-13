## Bipedal walker test: single env, random actions, log state.
extends Node2D

var _env: BipedalWalkerEnv
var _step: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	RLEnvRegistration.register_all()
	var scene := load("res://rl/envs/bipedal_walker/bipedal_walker_env.tscn") as PackedScene
	_env = scene.instantiate() as BipedalWalkerEnv
	add_child(_env)
	_env.reset()
	print("[bw_test] env_name=", _env.env_name)
	print("[bw_test] agent_count=", _env.get_agent_count())
	print("[bw_test] action_dim=", _env.get_action_dim())
	print("[bw_test] obs_dim=", _env.get_obs_dim())
	_rng.randomize()


func _physics_process(delta: float) -> void:
	var actions: Array[PackedFloat32Array] = []
	actions.append(PackedFloat32Array([
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
		_rng.randf_range(-1.0, 1.0),
	]))
	_env.apply_actions(actions)
	_env.physics_step(delta)

	_step += 1
	if _step % 30 == 0 or _env.is_done():
		var agent := _env.get_node("BipedalWalkerAgent") as BipedalWalkerAgent
		print("[step %4d] torso=(%.1f,%.1f) rot=%.2f vel=(%.1f,%.1f) contact=%s reward=%.2f done=%s" % [
			_step, agent.torso.position.x, agent.torso.position.y,
			agent.torso.rotation,
			agent.torso.linear_velocity.x, agent.torso.linear_velocity.y,
			agent._has_ground_contact(), _env.get_reward(), _env.is_done()
		])
	if _env.is_done() or _step >= 600:
		print("[bw_test] episode ended after %d steps" % _step)
		_env.reset()
		_step = 0
		if Engine.get_physics_frames() > 1500:
			set_physics_process(false)
			print("[bw_test] stopping")
