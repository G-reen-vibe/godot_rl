## Diagnostic test: spawn a single env inside a SubViewport and verify
## that physics actually runs inside the SubViewport. Print the pole
## angle every step.
extends Node2D

var _env: CartPoleEnv
var _vp: SubViewport
var _step: int = 0
var _episode: int = 0


func _ready() -> void:
	RLEnvRegistration.register_all()
	var scene := load("res://rl/envs/cartpole/cartpole_env.tscn") as PackedScene
	_env = scene.instantiate() as CartPoleEnv

	_vp = SubViewport.new()
	_vp.size = Vector2i(320, 320)
	_vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_vp.disable_3d = true
	_vp.world_2d = World2D.new()
	_vp.add_child(_env)
	add_child(_vp)

	_env.reset()
	print("[vp_test] env_name=", _env.env_name)
	print("[vp_test] world_2d set? ", _vp.world_2d != null)
	print("[vp_test] env inside viewport? ", _env.get_parent() == _vp)


func _physics_process(delta: float) -> void:
	var action := PackedFloat32Array()
	action.append(0.0)
	var actions: Array[PackedFloat32Array] = [action]
	_env.apply_actions(actions)
	_env.physics_step(delta)

	_step += 1
	var agent := _env.get_node("CartPoleAgent") as CartPoleAgent
	if _step <= 10 or _step % 30 == 0:
		print("[ep=%d step=%4d] pole_angle=%.4f rad (%.2f deg)  cart_x=%.2f  reward=%.2f  done=%s" % [
			_episode, _step, agent.pole.rotation, rad_to_deg(agent.pole.rotation),
			agent.cart.position.x, _env.get_reward(), _env.is_done()
		])
	if _env.is_done() or _step >= 300:
		_episode += 1
		if _episode >= 3:
			set_physics_process(false)
			print("[vp_test] stopping after 3 episodes")
		else:
			_env.reset()
			_step = 0
			print("[vp_test] reset for episode %d" % _episode)
