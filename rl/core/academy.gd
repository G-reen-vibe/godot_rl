## Orchestrates N parallel envs in one Godot process.
##
## Architecture
## ------------
## - Each env lives in its own SubViewport (own World2D / physics space).
## - All envs step in lock-step via the main physics loop.
## - Every `decision_period` physics steps the Academy:
##     1. Asks the ActionSource for a batch of actions
##     2. Applies actions to every env
##     3. Reads back obs / reward / done
##     4. Resets any env that reported done
##     5. Updates per-env stats for the preview UI
##
## No networking, no threads, no Python. The Academy is the only
## entry point the trainer will ever need.
extends Node

class_name RLAcademy


## Emitted after every decision step. Carries a snapshot of all env
## stats. Preview UI listens to this.
signal step_completed(stats: Array)


## Name of the env to spawn. Must be in RLEnvRegistry.
@export var env_name: String = "cartpole"

## Number of parallel envs to run.
@export var num_envs: int = 16

## Physics frames between action decisions.
@export var decision_period: int = 1

## If non-empty, env indices in this set are rendered live. The rest
## run with rendering disabled for throughput.
@export var preview_env_indices: PackedInt32Array = []

## SubViewport size for each env (smaller = more envs fit on screen).
@export var env_viewport_size: Vector2i = Vector2i(192, 192)

## Whether to render the envs at all (false = pure headless mode).
@export var render_envs: bool = true

## Time scale for the simulation. 1.0 = real-time, 4.0 = 4x speed.
@export var time_scale: float = 1.0


var _envs: Array[RLEnvironment] = []
var _viewports: Array[SubViewport] = []
var _stats: Array[RLEnvStats] = []
var _action_source: RLActionSource = null
var _agents_per_env: int = 1
var _action_dim: int = 1
var _decision_step: int = 0


func _ready() -> void:
	Engine.time_scale = time_scale
	_spawn_envs()


func _spawn_envs() -> void:
	# Pre-spawn: figure out agent count + action dim from one env
	var probe := RLEnvRegistry.create(env_name)
	if probe == null:
		push_error("RLAcademy: cannot spawn env '%s'" % env_name)
		return
	_agents_per_env = probe.get_agent_count()
	# Probe action_dim by asking the first agent for an observation,
	# then taking its size. (For these envs action_dim == obs_dim
	# doesn't hold in general, so we use a static method if available.)
	_action_dim = _infer_action_dim(probe)
	probe.queue_free()
	# free in next frame
	await get_tree().process_frame

	# Now spawn the real envs
	for i in range(num_envs):
		var env := RLEnvRegistry.create(env_name)
		env.decision_period = decision_period
		env.env_name = env_name

		var vp := SubViewport.new()
		vp.name = "EnvViewport_%d" % i
		vp.size = env_viewport_size
		vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		vp.disable_3d = true
		vp.world_2d = World2D.new()  # CRITICAL: each env gets its own physics space
		vp.add_child(env)

		add_child(vp)
		_envs.append(env)
		_viewports.append(vp)

		var stats := RLEnvStats.new()
		stats.env_idx = i
		_stats.append(stats)

		# Initialize the env (reset to start first episode)
		env.reset()

	# Only render envs that the preview wants visible
	_apply_render_visibility()


func _apply_render_visibility() -> void:
	if preview_env_indices.is_empty():
		# Render all if no filter set
		for vp in _viewports:
			vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		return
	for i in range(_viewports.size()):
		var vp := _viewports[i]
		if preview_env_indices.has(i):
			vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
		else:
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


## Subclasses (or the trainer) set this before _ready.
func set_action_source(source: RLActionSource) -> void:
	_action_source = source
	if _action_source:
		_action_source.setup(num_envs, _agents_per_env, _action_dim)


func get_stats() -> Array:
	var out: Array = []
	for s in _stats:
		out.append(s.to_dict())
	return out


func _physics_process(delta: float) -> void:
	_decision_step += 1
	if _decision_step % decision_period != 0:
		return

	# 1. Get actions from the source
	var actions: Array[Array] = []
	if _action_source:
		actions = _action_source.get_actions(num_envs, _agents_per_env, _action_dim)
	else:
		# No source: zero actions
		for i in range(num_envs):
			var env_actions: Array[PackedFloat32Array] = []
			for j in range(_agents_per_env):
				env_actions.append(PackedFloat32Array())
				env_actions[j].resize(_action_dim)
				for k in range(_action_dim):
					env_actions[j][k] = 0.0
			actions.append(env_actions)

	# 2. Apply + step + read
	for i in range(num_envs):
		var env := _envs[i]
		var env_actions: Array[PackedFloat32Array] = []
		if i < actions.size():
			env_actions = actions[i]
		env.apply_actions(env_actions)
		env.physics_step(delta)

		var reward := env.get_reward()
		_stats[i].steps = env.get_step_count()
		_stats[i].accumulate(reward)

		# 3. Reset if done
		if env.is_done():
			_stats[i].done = true
			_stats[i].best_reward = maxf(_stats[i].best_reward, _stats[i].episode_reward)
			env.reset()
			_stats[i].reset_for_new_episode()

	step_completed.emit(_stats.map(func(s): return s.to_dict()))


## Pull action_dim from an env instance. We use a static convention:
## subclasses may declare `const ACTION_DIM`, or a method `get_action_dim()`.
func _infer_action_dim(env: RLEnvironment) -> int:
	if env.has_method("get_action_dim"):
		return env.get_action_dim()
	if "ACTION_DIM" in env:
		return env.get("ACTION_DIM")
	push_warning("RLAcademy: env has no ACTION_DIM, defaulting to 1")
	return 1


## Pull obs_dim from an env instance.
func _infer_obs_dim(env: RLEnvironment) -> int:
	if env.has_method("get_obs_dim"):
		return env.get_obs_dim()
	if "OBS_DIM" in env:
		return env.get("OBS_DIM")
	push_warning("RLAcademy: env has no OBS_DIM, defaulting to 1")
	return 1


func get_env(idx: int) -> RLEnvironment:
	if idx < 0 or idx >= _envs.size():
		return null
	return _envs[idx]


func get_viewport_for_env(idx: int) -> SubViewport:
	if idx < 0 or idx >= _viewports.size():
		return null
	return _viewports[idx]


func get_num_envs() -> int:
	return _envs.size()
