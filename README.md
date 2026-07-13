# godot_rl

Parallel RL training environment frontend in Godot 4.4. Built for
genetic algorithm training (no Python, no ZMQ, no external dependencies).

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    RLAcademy                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │SubViewport│ │SubViewport│ │SubViewport│  ...      │
│  │  ┌─────┐ │ │  ┌─────┐ │ │  ┌─────┐ │            │
│  │  │ Env │ │ │  │ Env │ │ │  │ Env │ │            │
│  │  │┌───┐│ │ │  │┌───┐│ │ │  │┌───┐│ │            │
│  │  ││Agt││ │ │  ││Agt││ │ │  ││Agt││ │            │
│  │  │└───┘│ │ │  │└───┘│ │ │  │└───┘│ │            │
│  │  └─────┘ │ │  └─────┘ │ │  └─────┘ │            │
│  │ World2D  │ │ World2D  │ │ World2D  │            │
│  └──────────┘ └──────────┘ └──────────┘            │
│                                                     │
│  ActionSource: RLRandomActionSource (for now)       │
└─────────────────────────────────────────────────────┘
```

Each env lives in its own SubViewport with its own World2D, so
physics spaces are fully isolated. All envs step in lock-step via
Godot's main physics loop.

## Core Classes (rl/core/)

| File | Purpose |
|------|---------|
| `agent.gd` | Base class for RL agents (obs/action/reward/done interface) |
| `environment.gd` | Base class for RL environments (owns agents + scene) |
| `academy.gd` | Orchestrates N parallel envs, applies actions, collects stats |
| `action_source.gd` | Abstract base for action providers |
| `random_action_source.gd` | Yields uniform random actions (placeholder) |
| `resettable_body_2d.gd` | RigidBody2D with reliable teleport-reset via _integrate_forces |
| `env_registry.gd` | Maps env name -> PackedScene |
| `env_registration.gd` | Registers all built-in envs |
| `env_stats.gd` | Per-env stats (reward, episode count, best reward) |

## Environments (rl/envs/)

| Env | Obs | Action | Notes |
|-----|-----|--------|-------|
| `cartpole` | 4 | 1 | Classic pole balancing, PinJoint2D |
| `pong` | 5 | 1 | Self-play, 2 agents per env |
| `lunar_lander` | 6 | 3 | Thruster control, landing detection |
| `bipedal_walker` | 8 | 4 | 7-body ragdoll with hip/knee/ankle joints |

## Preview (rl/preview/)

| File | Purpose |
|------|---------|
| `preview_scene.gd` | Top-level: Academy + grid + header |
| `preview_grid.gd` | Lays out all env SubViewports in a grid |

## Tests (test/)

All tests are tscn-based (no autoloads). Run with:
```
godot --headless --path . res://test/<name>.tscn
```

| Test | What it validates |
|------|-------------------|
| `entry_test.tscn` | Single cartpole env loads, physics works |
| `vp_test.tscn` | Cartpole env inside SubViewport, reset works |
| `pong_test.tscn` | Pong env: ball bounces, paddles move, scoring works |
| `ll_test.tscn` | Lunar lander: thrusters, crash/land detection |
| `bw_test.tscn` | Bipedal walker: joints, falling detection |
| `preview_test.tscn` | Academy + grid with 9 parallel cartpole envs |
| `e2e_test.tscn` | All 4 envs through Academy, 300 steps each |
| `configurable_preview.tscn` | Editable preview (change env_name in inspector) |

## Running

```bash
# Headless e2e test (validates all envs)
godot --headless --path . res://test/e2e_test.tscn

# With rendering (grid preview)
godot --path . res://test/configurable_preview.tscn
```

## Adding a New Env

1. Create `rl/envs/my_env/my_env_env.gd` (extends RLEnvironment)
2. Create `rl/envs/my_env/my_env_agent.gd` (extends RLAgent)
3. Create `rl/envs/my_env/my_env_env.tscn` (Node2D + bodies + agent)
4. Register in `rl/core/env_registration.gd`
5. Test with a new `test/my_env_test.tscn`

See `rl/envs/cartpole/` for the simplest reference example.

## Key Design Decisions

- **Live state for done/reward**: Agents compute `is_done()` and
  `get_reward()` from current physics state, not cached flags. This
  avoids one-frame lag between physics step and Academy read.

- **RLResettableBody2D**: Setting RigidBody2D.position directly is
  unreliable (physics server keeps its own transform). Reset is done
  via `_integrate_forces` which is the canonical hook.

- **Kinematic mode**: Paddles use high-mass + `set_kinematic_velocity`
  instead of `freeze_mode=KINEMATIC`. The latter doesn't move the body
  reliably in Godot 4.4.

- **No autoloads**: Env registration is explicit via
  `RLEnvRegistration.register_all()` called from each test scene.

- **SubViewport per env**: Each env gets its own World2D automatically.
  No manual `World2D.new()` needed.
