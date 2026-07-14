# RLBench Setup & Customization Guide

RLBench environment running on WSL2 (Ubuntu 24.04) with CoppeliaSim v4.1.0.

## Prerequisites

- Windows 11 with WSL2 (Ubuntu)
- NVIDIA GPU with CUDA support
- Python 3.8+

## Installation

### 1. Install system dependencies

```bash
# Enter WSL
wsl -d Ubuntu

# Install packages (as root or with sudo)
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv build-essential cmake git libgl1 libglib2.0-0 xvfb
```

### 2. Install CoppeliaSim v4.1.0

```bash
cd /tmp
wget https://downloads.coppeliarobotics.com/V4_1_0/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz
mkdir -p ~/CoppeliaSim
tar -xf CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz -C ~/CoppeliaSim --strip-components 1
rm -f CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz
```

Register the shared libraries system-wide:

```bash
sudo bash -c 'echo "$HOME/CoppeliaSim" > /etc/ld.so.conf.d/coppeliasim.conf'
sudo ldconfig
```

### 3. Set environment variables

Add to `~/.bashrc`:

```bash
cat >> ~/.bashrc << 'EOF'

# RLBench environment
export COPPELIASIM_ROOT=${HOME}/CoppeliaSim
export LD_LIBRARY_PATH=$COPPELIASIM_ROOT:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT
EOF

source ~/.bashrc
```

### 4. Create Python virtual environment

```bash
python3 -m venv ~/rlbench_venv
source ~/rlbench_venv/bin/activate
pip install --upgrade pip
```

### 5. Install PyRep

```bash
git clone https://github.com/stepjam/PyRep.git ~/PyRep
cd ~/PyRep
pip install -r requirements.txt
pip install -e .
```

### 6. Install RLBench

```bash
git clone https://github.com/stepjam/RLBench.git ~/RLBench
cd ~/RLBench
pip install -e .
pip install gymnasium  # required dependency
```

### 7. Verify installation

```bash
source ~/rlbench_venv/bin/activate
python3 -c "import rlbench; print(f'RLBench {rlbench.__version__} OK')"
```

## Running RLBench

### Quick start

Windows 터미널에서 한 줄로 실행:

```bash
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/user/Desktop/rlbench/run.sh'
```

기본 설정(`configs/default.json`)으로 ReachTarget 태스크가 실행되고, `videos/` 폴더에 에피소드 영상이 저장됩니다.

### JSON config로 실행

```bash
# 기본 config
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/user/Desktop/rlbench/run.sh --config configs/default.json'

# 다른 config
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/user/Desktop/rlbench/run.sh --config configs/multi_task_example.json'

# 사용 가능한 task 목록 확인
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/user/Desktop/rlbench/run.sh --list-tasks'
```

### JSON config 구조

`configs/` 폴더에 JSON 파일을 만들어 task, scene, action, observation, recording을 관리합니다:

```json
{
  "task": {
    "name": "ReachTarget",      // task 클래스명 또는 snake_case
    "variation": 0              // task variation index
  },
  "scene": {
    "robot": "panda",           // panda, sawyer, ur5, jaco, mico
    "arm_max_velocity": 1.0,
    "arm_max_acceleration": 4.0,
    "static_positions": false,
    "headless": true
  },
  "action": {
    "arm_mode": "JointVelocity",    // JointVelocity, JointPosition, JointTorque,
                                    // EndEffectorPoseViaPlanning, EndEffectorPoseViaIK
    "gripper_mode": "Discrete"      // Discrete, GripperJointPosition
  },
  "observation": {
    "cameras": {
      "front":           { "enabled": true, "rgb": true, "depth": false, "mask": false, "image_size": [256, 256] },
      "wrist":           { "enabled": false },
      "left_shoulder":   { "enabled": false },
      "right_shoulder":  { "enabled": false },
      "overhead":        { "enabled": false }
    },
    "low_dim": {
      "joint_positions": true,
      "joint_velocities": true,
      "gripper_pose": true,
      "gripper_open": true,
      "task_low_dim_state": true
    }
  },
  "episode": {
    "num_episodes": 3,
    "max_steps": 40
  },
  "recording": {
    "enabled": true,
    "camera": "front",          // 어떤 카메라로 녹화할지
    "fps": 30,
    "output_dir": "videos"
  }
}
```

### Generate demonstration dataset

```bash
cd ~/RLBench
python tools/dataset_generator.py \
    --tasks reach_target \
    --episodes_per_task 10 \
    --save_path ./data
```

### Available robots

| Robot | `robot_setup` | DoF |
|-------|---------------|-----|
| Franka Panda | `'panda'` (default) | 7 |
| Sawyer | `'sawyer'` | 7 |
| UR5 | `'ur5'` | 6 |
| Jaco | `'jaco'` | 6 |
| Mico | `'mico'` | 6 |

로봇 변경:

```python
env = Environment(..., robot_setup='sawyer')
```

### Available action modes

| Arm Action Mode | Description |
|-----------------|-------------|
| `JointVelocity` | Joint velocity control |
| `JointPosition` | Absolute/delta joint position control |
| `JointTorque` | Joint torque control |
| `EndEffectorPoseViaPlanning` | End-effector pose with motion planning |
| `EndEffectorPoseViaIK` | End-effector pose with inverse kinematics |

| Gripper Action Mode | Description |
|---------------------|-------------|
| `Discrete` | Open (1.0) / Close (0.0) |
| `GripperJointPosition` | Continuous joint position |

---

## Customizing Scenes

Scene은 시뮬레이션 환경의 시각적/물리적 구성을 의미하며, environment(배경/테이블), object placement(물체 배치), robot placement(로봇 위치)로 구성됩니다.

### Scene architecture

```
Scene (.ttt file in CoppeliaSim)
├── workspace         — 테이블/작업 공간 (Shape object)
├── Robot             — 로봇 arm + gripper (.ttm in rlbench/robot_ttms/)
├── Cameras           — 5개 카메라 (left/right shoulder, overhead, wrist, front)
└── Task objects      — 태스크별 물체들 (.ttm in rlbench/task_ttms/)
```

### Environment (배경) 커스터마이징

기본 scene 파일은 `~/RLBench/rlbench/task_design.ttt`입니다. CoppeliaSim GUI에서 직접 편집하거나 PyRep API로 프로그래밍적으로 수정할 수 있습니다.

**Domain Randomization으로 배경 변경:**

```python
from rlbench import RandomizeEvery, VisualRandomizationConfig

rand_config = VisualRandomizationConfig(
    image_directory='./textures')  # 텍스처 이미지 폴더

env = Environment(
    action_mode=action_mode,
    headless=True,
    randomize_every=RandomizeEvery.EPISODE,  # 매 에피소드마다 랜덤화
    frequency=1,
    visual_randomization_config=rand_config)
```

`RandomizeEvery` 옵션: `EPISODE`, `VARIATION`, `TRANSITION`

### Object placement 커스터마이징

물체 배치는 `SpawnBoundary`를 통해 task의 `init_episode()` 안에서 제어됩니다:

```python
from rlbench.backend.spawn_boundary import SpawnBoundary

def init_episode(self, index):
    boundary = SpawnBoundary([Shape('boundary')])

    # 물체를 boundary 내에서 랜덤 배치
    boundary.sample(
        self.target_object,
        min_distance=0.2,                      # 다른 물체와의 최소 거리
        min_rotation=(0, 0, 0),                # 최소 회전 (x, y, z) radians
        max_rotation=(0, 0, 3.14),             # 최대 회전
        ignore_collisions=False                # 충돌 체크 활성화
    )

    # 여러 물체를 순차적으로 배치 (충돌 방지 자동 적용)
    for obj in [self.obj_a, self.obj_b, self.obj_c]:
        boundary.sample(obj, min_distance=0.1)

    boundary.clear()  # 내부 추적 리스트 초기화
```

**고정 위치로 배치:**

```python
def init_episode(self, index):
    self.target.set_position([0.25, 0.1, 0.8])           # 절대 좌표
    self.target.set_orientation([0.0, 0.0, 1.57])         # 오일러 각도 (radians)
    self.target.set_position([0.1, 0.0, 0.0], relative_to=self.get_base())  # 태스크 기준 상대 좌표
```

**Boundary shape**는 CoppeliaSim에서 만든 Box/Plane Shape이며, `.ttm` 파일 안에 `boundary`라는 이름으로 포함됩니다. Boundary의 크기와 위치를 변경하면 물체 배치 범위가 달라집니다.

### Robot placement 커스터마이징

로봇 위치는 `Scene` 클래스에서 관리됩니다. 기본적으로 로봇은 workspace 앞에 고정되어 있습니다.

**로봇 종류 변경:**

```python
# 지원 로봇: 'panda', 'sawyer', 'ur5', 'jaco', 'mico'
env = Environment(..., robot_setup='ur5')
```

**로봇 속도/가속도 조절:**

```python
env = Environment(
    ...,
    arm_max_velocity=1.0,       # default 1.0
    arm_max_acceleration=4.0    # default 4.0
)
```

**로봇 초기 자세를 코드에서 변경:**

```python
# Environment launch 후 scene의 robot에 직접 접근
env.launch()
robot = env._robot
robot.arm.set_joint_positions([0, -0.3, 0, -2.2, 0, 2.0, 0.78])
```

**새 로봇을 추가하려면:**

1. CoppeliaSim에서 로봇 모델 (`.ttm`)을 만들어 `rlbench/robot_ttms/`에 저장
2. PyRep에 해당 arm/gripper 클래스 추가
3. `rlbench/const.py`의 `SUPPORTED_ROBOTS`에 등록:

```python
SUPPORTED_ROBOTS = {
    'panda': (Panda, PandaGripper, 7),
    'my_robot': (MyRobotArm, MyGripper, 6),  # 추가
}
```

---

## Customizing Tasks

Task는 로봇이 수행할 목표와 평가 방법을 정의합니다. 각 task는 **Python 파일** (로직)과 **TTM 파일** (3D 물체)로 구성됩니다.

### Task architecture

```
Task = Python class (rlbench/tasks/)  +  TTM file (rlbench/task_ttms/)
  │
  ├── Goal            — 태스크의 성공/실패 조건
  ├── Manipulation    — waypoint 기반 조작 순서
  ├── Actuation       — 로봇이 수행할 동작 리스트
  └── Evaluation      — 에피소드 변형(variation) 및 평가 데이터셋
```

### Creating a new task

#### Step 1: TTM 파일 생성

CoppeliaSim에서 `rlbench/task_design.ttt`를 열고:

1. 필요한 물체(Shape, Dummy, Sensor 등)를 scene에 추가
2. 모든 물체를 하나의 Dummy 아래에 그룹화 (이 Dummy의 이름이 task 이름)
3. **waypoint** Dummy를 추가 (`waypoint0`, `waypoint1`, ...)
   - waypoint의 위치와 orientation이 로봇 end-effector의 목표 pose
4. **ProximitySensor**를 추가하여 성공 조건 감지에 사용
5. **boundary** Shape를 추가하여 물체 배치 범위 정의
6. Model로 export → `rlbench/task_ttms/my_task.ttm`

#### Step 2: Task Python 파일 생성

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
        """태스크 로드 시 1회 호출. 물체 참조 및 조건 등록."""
        # TTM 안의 물체를 이름으로 참조
        self.target = Shape('target_object')
        self.sensor = ProximitySensor('success_sensor')
        self.boundary = SpawnBoundary([Shape('boundary')])

        # 잡을 수 있는 물체 등록
        self.register_graspable_objects([self.target])

        # 성공 조건 등록
        self.register_success_conditions([
            GraspedCondition(self.robot.gripper, self.target),
            DetectedCondition(self.target, self.sensor),
        ])

    def init_episode(self, index: int) -> List[str]:
        """에피소드 시작마다 호출. variation에 따라 scene 변경."""
        # index에 따라 물체 색상, 위치 등 변경
        colors = ['red', 'blue', 'green']
        color_name = colors[index % len(colors)]
        color_rgb = {'red': [1,0,0], 'blue': [0,0,1], 'green': [0,1,0]}

        self.target.set_color(color_rgb[color_name])

        # 물체 랜덤 배치
        self.boundary.clear()
        self.boundary.sample(self.target, min_distance=0.1)

        # 자연어 task description 반환
        return [
            f'pick up the {color_name} object',
            f'grasp the {color_name} block and place it on the sensor',
        ]

    def variation_count(self) -> int:
        """이 태스크의 총 variation 수."""
        return 3

    def base_rotation_bounds(self):
        """태스크 전체가 workspace에 배치될 때 허용되는 회전 범위."""
        return (0, 0, -3.14), (0, 0, 3.14)

    def reward(self) -> float:
        """(선택) 커스텀 reward shaping."""
        return -np.linalg.norm(
            self.target.get_position() - self.robot.arm.get_tip().get_position())
```

#### Step 3: 등록 및 실행

```python
from rlbench.tasks.my_task import MyTask

env.launch()
task = env.get_task(MyTask)
descriptions, obs = task.reset()
```

### Goal 커스터마이징

태스크의 성공/실패 조건은 `Condition` 클래스로 정의합니다.

**사용 가능한 조건들:**

| Condition | Description |
|-----------|-------------|
| `DetectedCondition(obj, sensor)` | 물체가 proximity sensor에 감지될 때 |
| `DetectedCondition(obj, sensor, negated=True)` | 물체가 sensor에서 벗어날 때 |
| `GraspedCondition(gripper, obj)` | 그리퍼가 물체를 잡고 있을 때 |
| `NothingGrasped(gripper)` | 그리퍼가 아무것도 잡고 있지 않을 때 |
| `JointCondition(joint, position)` | 조인트가 특정 위치만큼 이동했을 때 |
| `DetectedSeveralCondition(objs, sensor, n)` | n개 이상의 물체가 감지될 때 |
| `ConditionSet(conditions, order_matters)` | 여러 조건의 조합 (순서 옵션) |
| `OrConditions(conditions)` | 조건 중 하나라도 만족하면 성공 |
| `EmptyCondition(container)` | 리스트가 비었을 때 |

**예시 — 순서가 있는 복합 조건:**

```python
from rlbench.backend.conditions import ConditionSet, GraspedCondition, DetectedCondition

self.register_success_conditions([
    ConditionSet([
        GraspedCondition(self.robot.gripper, self.cup),      # 먼저 잡고
        DetectedCondition(self.cup, self.place_sensor),       # 그 다음 센서에 놓기
    ], order_matters=True)
])
```

**실패 조건 등록 (선택):**

```python
self.register_fail_conditions([
    DetectedCondition(self.fragile_obj, self.floor_sensor)  # 떨어지면 실패
])
```

### Manipulation & actuation 커스터마이징

로봇의 조작 순서는 **waypoint**로 정의됩니다. TTM 파일에서 `waypoint0`, `waypoint1`, ... Dummy 오브젝트의 위치가 로봇 end-effector의 목표 pose가 됩니다.

**Waypoint 동작 원리:**
1. 로봇이 `waypoint0` → `waypoint1` → ... 순서로 이동
2. 각 waypoint에 도착하면 등록된 ability 함수 실행 (e.g. 그리퍼 열기/닫기)
3. 모든 waypoint를 완료하면 에피소드 종료

**Waypoint에 동작 추가:**

```python
def init_task(self):
    # waypoint1에 도착 전에 그리퍼 열기
    self.register_waypoint_ability_start(1, lambda wp: self.robot.gripper.actuate(1.0, 0.04))

    # waypoint2에 도착 후 그리퍼 닫기
    self.register_waypoint_ability_end(2, lambda wp: self.robot.gripper.actuate(0.0, 0.04))
```

**반복 조작 등록 (e.g. 컨테이너 비우기):**

```python
def init_task(self):
    self.register_waypoints_should_repeat(lambda: len(self.remaining_items) > 0)
```

**특정 waypoint에서 데모 중단:**

```python
self.register_stop_at_waypoint(3)  # waypoint3까지만 데모
```

### Evaluation 커스터마이징

#### Variation (scene 변형)

`variation_count()`와 `init_episode(index)`로 같은 task의 다양한 변형을 정의합니다:

```python
def variation_count(self) -> int:
    return 20  # 20가지 색상의 variation

def init_episode(self, index: int) -> List[str]:
    # index (0~19)에 따라 다른 설정
    color_name, color_rgb = colors[index]
    self.target.set_color(color_rgb)
    return [f'reach the {color_name} target']
```

#### Demonstration dataset 생성

```bash
python ~/RLBench/tools/dataset_generator.py \
    --tasks my_task \
    --episodes_per_task 100 \
    --variations 5 \
    --processes 4 \
    --save_path ./data/my_task_demos
```

#### Evaluation 스크립트 구성

```python
from rlbench.environment import Environment
from rlbench.tasks.my_task import MyTask

env = Environment(action_mode=action_mode, headless=True)
env.launch()
task = env.get_task(MyTask)

success_count = 0
total_episodes = 100

for variation in range(task._task.variation_count()):
    descriptions, obs = task.reset_to_demo(variation)
    for step in range(max_steps):
        action = agent.act(obs)
        obs, reward, terminate = task.step(action)
        if terminate:
            success, _ = task._task.success()
            if success:
                success_count += 1
            break

print(f'Success rate: {success_count / total_episodes:.2%}')
env.shutdown()
```

#### Observation 설정

평가 시 필요한 관측치를 선택할 수 있습니다:

```python
from rlbench.observation_config import ObservationConfig, CameraConfig

obs_config = ObservationConfig()

# 카메라별 개별 설정
obs_config.front_camera = CameraConfig(
    rgb=True,
    depth=True,
    point_cloud=False,
    mask=True,
    image_size=(256, 256))

# 또는 전체 켜기/끄기
obs_config.set_all(True)

# Low-dim 상태
obs_config.joint_positions = True
obs_config.gripper_pose = True
obs_config.task_low_dim_state = True

env = Environment(action_mode=action_mode, obs_config=obs_config, headless=True)
```

## File structure reference

```
~/RLBench/rlbench/
├── environment.py              # Environment 클래스 (진입점)
├── task_environment.py         # TaskEnvironment (env.get_task()의 반환값)
├── observation_config.py       # 카메라/센서 설정
├── const.py                    # 지원 로봇 목록, 색상 상수
├── task_design.ttt             # CoppeliaSim 기본 scene 파일
├── action_modes/
│   ├── action_mode.py          # MoveArmThenGripper 등
│   ├── arm_action_modes.py     # JointVelocity, EndEffectorPose 등
│   └── gripper_action_modes.py # Discrete, GripperJointPosition
├── backend/
│   ├── scene.py                # Scene 관리 (workspace, camera, robot)
│   ├── task.py                 # Task 베이스 클래스
│   ├── conditions.py           # 성공/실패 조건 클래스들
│   ├── robot.py                # Robot wrapper
│   ├── spawn_boundary.py       # 물체 배치 경계
│   └── observation.py          # Observation 데이터 클래스
├── tasks/                      # 107개 task Python 파일
│   ├── reach_target.py
│   ├── pick_up_cup.py
│   └── ...
├── task_ttms/                  # 107개 task 3D 모델
│   ├── reach_target.ttm
│   ├── pick_up_cup.ttm
│   └── ...
└── robot_ttms/                 # 로봇 3D 모델
    ├── panda.ttm
    ├── sawyer.ttm
    ├── ur5.ttm
    ├── jaco.ttm
    └── mico.ttm
```
