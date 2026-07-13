## Pong test: spawn a single pong env, apply random actions, log state.
extends Node2D

var _env: PongEnv
var _step: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
        RLEnvRegistration.register_all()
        var scene := load("res://rl/envs/pong/pong_env.tscn") as PackedScene
        _env = scene.instantiate() as PongEnv
        add_child(_env)
        _env.reset()
        print("[pong_test] env_name=", _env.env_name)
        print("[pong_test] agent_count=", _env.get_agent_count())
        print("[pong_test] action_dim=", _env.get_action_dim())
        print("[pong_test] obs_dim=", _env.get_obs_dim())
        _rng.randomize()


func _physics_process(delta: float) -> void:
        var actions: Array[PackedFloat32Array] = []
        actions.append(PackedFloat32Array([_rng.randf_range(-1.0, 1.0)]))
        actions.append(PackedFloat32Array([_rng.randf_range(-1.0, 1.0)]))
        _env.apply_actions(actions)
        _env.physics_step(delta)

        _step += 1
        if _step % 30 == 0 or _env.is_done():
                var ball: RigidBody2D = _env.get_node("Ball")
                var left_paddle: RigidBody2D = _env.get_node("LeftPaddle")
                var right_paddle: RigidBody2D = _env.get_node("RightPaddle")
                print("[step %4d] ball=(%.1f,%.1f) v=(%.1f,%.1f) L=(%.1f) R=(%.1f) reward=%.2f done=%s" % [
                        _step, ball.position.x, ball.position.y,
                        ball.linear_velocity.x, ball.linear_velocity.y,
                        left_paddle.position.y, right_paddle.position.y,
                        _env.get_reward(), _env.is_done()
                ])
        if _env.is_done() or _step >= 600:
                print("[pong_test] episode ended after %d steps" % _step)
                _env.reset()
                _step = 0
                if Engine.get_physics_frames() > 1500:
                        set_physics_process(false)
                        print("[pong_test] stopping")
