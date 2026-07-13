## RigidBody2D that supports reliable teleport-style reset.
##
## Setting Node2D.position/rotation on a RigidBody2D directly is
## unreliable - the physics server keeps its own transform and the
## two can disagree, especially when the body is constrained by joints.
##
## This class accepts a "pending" transform + velocity and applies
## them inside _integrate_forces, which is the canonical hook for
## mutating dynamic body state mid-step.
class_name RLResettableBody2D
extends RigidBody2D

var _pending_transform: Transform2D = Transform2D.IDENTITY
var _pending_linear_velocity: Vector2 = Vector2.ZERO
var _pending_angular_velocity: float = 0.0
var _has_pending_reset: bool = false


func request_reset(new_transform: Transform2D,
		new_linear_velocity: Vector2 = Vector2.ZERO,
		new_angular_velocity: float = 0.0) -> void:
	_pending_transform = new_transform
	_pending_linear_velocity = new_linear_velocity
	_pending_angular_velocity = new_angular_velocity
	_has_pending_reset = true


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _has_pending_reset:
		state.transform = _pending_transform
		state.linear_velocity = _pending_linear_velocity
		state.angular_velocity = _pending_angular_velocity
		_has_pending_reset = false
		# Don't fall through to default gravity integration this frame
		return
	# Default: let the engine apply gravity and forces normally.
	# (No need to call super; RigidBody2D's default integration runs
	# automatically when _integrate_forces is not overridden... but
	# since we ARE overriding, we need to apply gravity ourselves.)
	# Actually, _integrate_forces in Godot 4 lets us mutate state,
	# but the default forces (gravity, applied forces) are applied
	# by the engine BEFORE calling this hook. We just observe/modify.
