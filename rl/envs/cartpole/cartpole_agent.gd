## CartPole agent: owns the cart + pole bodies, exposes obs/action/reward.
##
## Observation (4):
##   0  cart x       (m,    roughly [-2.4, 2.4])
##   1  cart vx      (m/s)
##   2  pole angle   (rad,  0 = upright)
##   3  pole ang vel (rad/s)
##
## Action (1): force on cart in [-1, 1], scaled by FORCE_SCALE.
##
## Reward: +1 per step while upright.
## Done: |angle| > 12 deg, or |x| > 2.4, or step cap reached.
class_name CartPoleAgent
extends RLAgent

const OBS_DIM := 4
const ACTION_DIM := 1
const FORCE_SCALE := 800.0
const ANGLE_LIMIT := deg_to_rad(12.0)
const X_LIMIT_PX := 2.4 * 80.0
const POLE_HALF_LEN_PX := 60.0

@export var cart_path: NodePath = ^"../Cart"
@export var pole_path: NodePath = ^"../Pole"

var cart: RigidBody2D
var pole: RigidBody2D

var _step_reward: float = 0.0
var _done: bool = false
var _initial_cart_pos: Vector2
var _initial_pole_pos: Vector2
var _initial_pole_rot: float


func _setup() -> void:
	cart = get_node(cart_path) as RigidBody2D
	pole = get_node(pole_path) as RigidBody2D
	_initial_cart_pos = cart.position
	_initial_pole_pos = pole.position
	_initial_pole_rot = pole.rotation


func get_observation() -> PackedFloat32Array:
	var obs := PackedFloat32Array()
	obs.resize(OBS_DIM)
	obs[0] = clampf(cart.position.x / X_LIMIT_PX, -1.0, 1.0)
	obs[1] = clampf(cart.linear_velocity.x / 500.0, -1.0, 1.0)
	obs[2] = pole.rotation / ANGLE_LIMIT
	obs[3] = clampf(pole.angular_velocity / 5.0, -1.0, 1.0)
	return obs


func set_action(action: PackedFloat32Array) -> void:
	if action.is_empty():
		return
	var force: float = clampf(action[0], -1.0, 1.0) * FORCE_SCALE
	cart.apply_central_force(Vector2(force, 0.0))


func get_reward() -> float:
	return _step_reward


func is_done() -> bool:
	return _done


func _physics_process(_delta: float) -> void:
	var angle: float = pole.rotation
	var x: float = cart.position.x
	var upright: bool = abs(angle) < ANGLE_LIMIT and abs(x) < X_LIMIT_PX
	_step_reward = 1.0 if upright else 0.0
	_done = not upright


func reset() -> void:
	_step_reward = 0.0
	_done = false
	cart.position = _initial_cart_pos + Vector2(randf_range(-5.0, 5.0), 0)
	cart.linear_velocity = Vector2.ZERO
	cart.angular_velocity = 0.0
	cart.rotation = 0.0
	pole.position = _initial_pole_pos
	pole.rotation = _initial_pole_rot + randf_range(-0.05, 0.05)
	pole.linear_velocity = Vector2.ZERO
	pole.angular_velocity = 0.0


func get_action_dim() -> int:
	return ACTION_DIM


func get_obs_dim() -> int:
	return OBS_DIM
