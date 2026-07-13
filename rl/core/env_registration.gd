## Static helper: registers all built-in envs with RLEnvRegistry.
##
## Call `RLEnvRegistration.register_all()` from a test/preview scene's
## _ready() before instantiating the Academy. We can't use an autoload
## for this because the user explicitly said no autoloads.
extends RefCounted
class_name RLEnvRegistration


static func register_all() -> void:
	if not RLEnvRegistry.has("cartpole"):
		var cartpole_scene := load("res://rl/envs/cartpole/cartpole_env.tscn") as PackedScene
		RLEnvRegistry.register("cartpole", cartpole_scene)
