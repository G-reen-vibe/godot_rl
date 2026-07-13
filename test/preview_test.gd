## Test entry: spawn the Academy with N parallel cartpole envs and a
## preview grid. Used to validate:
##   - Multiple SubViewports each get their own World2D (no physics bleed)
##   - Academy stepping loop works
##   - Stats are tracked and reset properly on episode end
##   - Preview grid renders all envs
extends Node2D

@export var num_envs: int = 9
@export var columns: int = 3

var _preview: RLPreviewScene
var _step: int = 0
var _max_steps: int = 600


func _ready() -> void:
	RLEnvRegistration.register_all()
	_preview = RLPreviewScene.new()
	_preview.env_name = "cartpole"
	_preview.num_envs = num_envs
	_preview.columns = columns
	_preview.time_scale = 1.0
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_preview)
	await get_tree().create_timer(0.5).timeout
	print("[preview_test] academy spawned envs: ", _preview._academy.get_num_envs())


func _physics_process(_delta: float) -> void:
	_step += 1
	if _step % 60 == 0:
		var stats := _preview._academy.get_stats()
		var total_reward := 0.0
		var done_count := 0
		for s in stats:
			total_reward += s.get("episode_reward", 0.0)
			if s.get("done", false):
				done_count += 1
		print("[step %4d] envs=%d  total_reward=%.1f  dones=%d" % [
			_step, stats.size(), total_reward, done_count
		])
	if _step >= _max_steps:
		print("[preview_test] done after %d steps" % _step)
		set_physics_process(false)
