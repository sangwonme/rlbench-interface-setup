# RLBench Interface Setup

**JSON-based configuration interface for RLBench** - Easily run robotic manipulation tasks with automated setup.

Supports **Ubuntu 24.04** (native) and **WSL2** (Windows 11).

## 🚀 Quick Start

### For Ubuntu (Native Linux)

```bash
# 1. Clone repository
git clone https://github.com/sangwonme/rlbench-interface-setup.git ~/rlbench
cd ~/rlbench

# 2. Run automated setup (installs CoppeliaSim, PyRep, RLBench)
bash setup.sh

# 3. Run a demo task
bash run.sh --config configs/config_reach_target.json

# Videos will be saved to videos/
ls videos/
```

### For WSL2 (Windows 11)

```bash
# 1. Clone to Windows directory
cd /mnt/c/Users/YOUR_USERNAME/Desktop
git clone https://github.com/sangwonme/rlbench-interface-setup.git rlbench
cd rlbench

# 2. Run setup from WSL
bash setup.sh

# 3. Run from Windows Terminal
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/YOUR_USERNAME/Desktop/rlbench/run.sh --config configs/config_reach_target.json'
```

That's it! 🎉

---

## 📋 What Gets Installed

The `setup.sh` script automatically installs:

- **CoppeliaSim v4.1.0** - Robot simulation engine (~500 MB)
- **PyRep** - Python interface for CoppeliaSim
- **RLBench** - 100+ robotic manipulation tasks
- **Python dependencies** - numpy, scipy, gymnasium, pillow, etc.

**Total**: ~1.2 GB, takes ~10 minutes on a good connection.

See [INSTALL.md](INSTALL.md) for detailed installation info.

---

## 🎮 Usage

### Basic Usage

```bash
# Run a single task
bash run.sh --config configs/config_pick_and_place.json

# Run all tasks sequentially
bash run.sh --all
```

### GUI Mode (Ubuntu only)

On native Ubuntu, you can watch the simulation in real-time:

```bash
# 1. Modify config to set "headless": false
# 2. Run with GUI script
bash run_gui.sh --config configs/config_reach_target.json
```

See [UBUNTU.md](UBUNTU.md) for Ubuntu-specific features.

### Batch Processing

```bash
# Run multiple tasks in parallel
ls configs/config_*.json | parallel -j 4 bash run.sh --config {}
```

---

## 📁 Configuration Files

Tasks are configured via JSON files in `configs/`. Each config controls:

```json
{
  "task": {
    "name": "PickAndPlace",     // Task name
    "variation": 0              // Task variation (0-N)
  },
  "scene": {
    "robot": "panda",           // Robot: panda, sawyer, ur5, jaco, mico
    "headless": true            // Run without GUI (faster)
  },
  "action": {
    "arm_mode": "JointVelocity",    // Control mode
    "gripper_mode": "Discrete"      // Gripper control
  },
  "observation": {
    "cameras": {
      "front": {
        "enabled": true,
        "rgb": true,
        "image_size": [256, 256]
      }
      // Also: wrist, left_shoulder, right_shoulder, overhead
    }
  },
  "episode": {
    "num_episodes": 3,          // Number of demo episodes to record
    "max_steps": 40
  },
  "recording": {
    "enabled": true,
    "camera": "front",          // Which camera to record
    "fps": 30,
    "output_dir": "videos"
  }
}
```

100+ pre-configured tasks are included in `configs/`:
- `config_reach_target.json` - Simple reaching task
- `config_pick_and_place.json` - Pick and place
- `config_open_door.json` - Door opening
- `config_stack_blocks.json` - Block stacking
- ... and 100+ more

---

## 🤖 Available Robots

| Robot | ID | DoF | Notes |
|-------|-----|-----|-------|
| Franka Panda | `panda` | 7 | Default, recommended |
| Sawyer | `sawyer` | 7 | |
| UR5 | `ur5` | 6 | |
| Jaco | `jaco` | 6 | |
| Mico | `mico` | 6 | |

Change robot in config:
```json
"scene": {
  "robot": "sawyer"
}
```

---

## 🎥 Output

Videos are saved to `videos/` as:
```
videos/
├── ReachTarget_v0_demo1.mp4
├── ReachTarget_v0_demo2.mp4
├── PickAndPlace_v0_demo1.mp4
└── ...
```

Each demo shows the robot successfully completing the task.

---

## 📚 Documentation

- **[DEPLOY.md](DEPLOY.md)** - Deploy to new machines
- **[INSTALL.md](INSTALL.md)** - Detailed installation guide
- **[UBUNTU.md](UBUNTU.md)** - Ubuntu-specific features (GUI mode, performance tips)

---

## 🔧 Advanced: Customizing Tasks

RLBench supports extensive customization. Below is a reference guide.

### Scene Customization

#### Environment (Background)

Use domain randomization to vary scene appearance:

```python
from rlbench import RandomizeEvery, VisualRandomizationConfig

rand_config = VisualRandomizationConfig(
    image_directory='./textures')

env = Environment(
    action_mode=action_mode,
    headless=True,
    randomize_every=RandomizeEvery.EPISODE,
    frequency=1,
    visual_randomization_config=rand_config)
```

`RandomizeEvery` options: `EPISODE`, `VARIATION`, `TRANSITION`

#### Object Placement

Object positions are controlled via `SpawnBoundary` in each task's `init_episode()`:

```python
from rlbench.backend.spawn_boundary import SpawnBoundary

def init_episode(self, index):
    boundary = SpawnBoundary([Shape('boundary')])

    # Random placement within boundary
    boundary.sample(
        self.target_object,
        min_distance=0.2,
        min_rotation=(0, 0, 0),
        max_rotation=(0, 0, 3.14),
        ignore_collisions=False)

    # Fixed placement
    self.target.set_position([0.25, 0.1, 0.8])
    self.target.set_orientation([0.0, 0.0, 1.57])
```

#### Robot Configuration

```python
# Change robot type
env = Environment(..., robot_setup='ur5')

# Adjust speed/acceleration
env = Environment(
    ...,
    arm_max_velocity=1.0,
    arm_max_acceleration=4.0)

# Modify joint positions after launch
env.launch()
robot = env._robot
robot.arm.set_joint_positions([0, -0.3, 0, -2.2, 0, 2.0, 0.78])
```

---

### Task Customization

Each task consists of:
- **Python class** (`rlbench/tasks/*.py`) - Logic
- **TTM file** (`rlbench/task_ttms/*.ttm`) - 3D objects

#### Creating a New Task

**1. Create TTM file in CoppeliaSim**

Open `rlbench/task_design.ttt`:
1. Add objects (shapes, dummies, sensors)
2. Group under a single dummy (task name)
3. Add waypoints (`waypoint0`, `waypoint1`, ...)
4. Add boundary shape for object placement
5. Export as `rlbench/task_ttms/my_task.ttm`

**2. Create Python task file**

`rlbench/tasks/my_task.py`:

```python
from typing import List
import numpy as np
from pyrep.objects.shape import Shape
from pyrep.objects.proximity_sensor import ProximitySensor
from rlbench.backend.task import Task
from rlbench.backend.conditions import DetectedCondition, GraspedCondition
from rlbench.backend.spawn_boundary import SpawnBoundary


class MyTask(Task):

    def init_task(self) -> None:
        """Called once when task loads."""
        self.target = Shape('target_object')
        self.sensor = ProximitySensor('success_sensor')
        self.boundary = SpawnBoundary([Shape('boundary')])

        # Register graspable objects
        self.register_graspable_objects([self.target])

        # Register success conditions
        self.register_success_conditions([
            GraspedCondition(self.robot.gripper, self.target),
            DetectedCondition(self.target, self.sensor),
        ])

    def init_episode(self, index: int) -> List[str]:
        """Called at start of each episode."""
        colors = ['red', 'blue', 'green']
        color_name = colors[index % len(colors)]
        color_rgb = {'red': [1,0,0], 'blue': [0,0,1], 'green': [0,1,0]}

        self.target.set_color(color_rgb[color_name])

        # Random placement
        self.boundary.clear()
        self.boundary.sample(self.target, min_distance=0.1)

        # Natural language task descriptions
        return [
            f'pick up the {color_name} object',
            f'grasp the {color_name} block and place it on the sensor',
        ]

    def variation_count(self) -> int:
        """Number of task variations."""
        return 3

    def base_rotation_bounds(self):
        """Rotation bounds for task placement."""
        return (0, 0, -3.14), (0, 0, 3.14)

    def reward(self) -> float:
        """Optional: custom reward shaping."""
        return -np.linalg.norm(
            self.target.get_position() -
            self.robot.arm.get_tip().get_position())
```

**3. Register and run**

```python
from rlbench.tasks.my_task import MyTask

env.launch()
task = env.get_task(MyTask)
descriptions, obs = task.reset()
```

---

### Success Conditions

Available condition types:

| Condition | Description |
|-----------|-------------|
| `DetectedCondition(obj, sensor)` | Object detected by sensor |
| `DetectedCondition(obj, sensor, negated=True)` | Object NOT detected |
| `GraspedCondition(gripper, obj)` | Object is grasped |
| `NothingGrasped(gripper)` | Gripper is empty |
| `JointCondition(joint, position)` | Joint at position |
| `DetectedSeveralCondition(objs, sensor, n)` | N+ objects detected |
| `ConditionSet(conditions, order_matters)` | Composite conditions |
| `OrConditions(conditions)` | Any condition satisfied |

**Example - Sequential conditions:**

```python
from rlbench.backend.conditions import ConditionSet, GraspedCondition, DetectedCondition

self.register_success_conditions([
    ConditionSet([
        GraspedCondition(self.robot.gripper, self.cup),
        DetectedCondition(self.cup, self.place_sensor),
    ], order_matters=True)
])
```

---

### Waypoint Manipulation

Waypoints define robot motion sequence. Add actions at waypoints:

```python
def init_task(self):
    # Open gripper before waypoint 1
    self.register_waypoint_ability_start(
        1, lambda wp: self.robot.gripper.actuate(1.0, 0.04))

    # Close gripper after waypoint 2
    self.register_waypoint_ability_end(
        2, lambda wp: self.robot.gripper.actuate(0.0, 0.04))

    # Repeat waypoints while items remain
    self.register_waypoints_should_repeat(
        lambda: len(self.remaining_items) > 0)
```

---

### Observation Configuration

```python
from rlbench.observation_config import ObservationConfig, CameraConfig

obs_config = ObservationConfig()

# Camera configuration
obs_config.front_camera = CameraConfig(
    rgb=True,
    depth=True,
    point_cloud=False,
    mask=True,
    image_size=(256, 256))

# Low-dimensional state
obs_config.joint_positions = True
obs_config.gripper_pose = True
obs_config.task_low_dim_state = True

env = Environment(
    action_mode=action_mode,
    obs_config=obs_config,
    headless=True)
```

---

### Action Modes

| Arm Mode | Description |
|----------|-------------|
| `JointVelocity` | Joint velocity control |
| `JointPosition` | Absolute/delta joint position |
| `JointTorque` | Joint torque control |
| `EndEffectorPoseViaPlanning` | End-effector with motion planning |
| `EndEffectorPoseViaIK` | End-effector with IK |

| Gripper Mode | Description |
|--------------|-------------|
| `Discrete` | Open (1.0) / Close (0.0) |
| `GripperJointPosition` | Continuous position |

---

### Generating Demonstration Datasets

```bash
cd ~/RLBenchSim/RLBench
python tools/dataset_generator.py \
    --tasks reach_target pick_and_place \
    --episodes_per_task 100 \
    --variations 5 \
    --processes 4 \
    --save_path ./data/demos
```

---

## 📂 File Structure

```
rlbench-interface-setup/
├── setup.sh              # Automated installation
├── run.sh                # Headless execution
├── run_gui.sh            # GUI execution (Ubuntu only)
├── main.py               # Main runner program
├── requirements.txt      # Python dependencies
├── requirements_ml.txt   # Optional ML libraries
├── configs/              # 100+ task configurations
│   ├── config_reach_target.json
│   ├── config_pick_and_place.json
│   └── ...
├── videos/               # Generated demo videos (gitignored)
├── README.md             # This file
├── DEPLOY.md             # Deployment guide
├── INSTALL.md            # Installation details
└── UBUNTU.md             # Ubuntu-specific guide
```

**RLBench installation** (created by setup.sh):
```
~/RLBenchSim/
├── .venv/                # Python virtual environment
├── PyRep/                # PyRep library
├── RLBench/              # RLBench library
│   ├── rlbench/tasks/    # 100+ task Python files
│   └── rlbench/task_ttms/ # 100+ task 3D models
└── ~/CoppeliaSim/        # Simulation engine
```

---

## 🐛 Troubleshooting

### CoppeliaSim won't start

```bash
# Check missing libraries
ldd $HOME/CoppeliaSim/coppeliaSim | grep "not found"

# Install missing dependencies
sudo apt install libgl1-mesa-glx libglib2.0-0
```

### Python import errors

```bash
# Verify installation
source ~/RLBenchSim/.venv/bin/activate
python3 -c "import rlbench; print('OK')"

# Reinstall if needed
cd ~/RLBenchSim/RLBench
pip install -e .
```

### Out of memory

```bash
# Add swap space
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📝 License

This repository provides a configuration interface for RLBench.

- **RLBench**: MIT License - [stepjam/RLBench](https://github.com/stepjam/RLBench)
- **PyRep**: MIT License - [stepjam/PyRep](https://github.com/stepjam/PyRep)
- **CoppeliaSim**: Educational license

---

## 🙏 Credits

Built on top of:
- [RLBench](https://github.com/stepjam/RLBench) by Stephen James
- [PyRep](https://github.com/stepjam/PyRep) by Stephen James
- [CoppeliaSim](https://www.coppeliarobotics.com/) by Coppelia Robotics

Interface and setup automation by [@sangwonme](https://github.com/sangwonme)
