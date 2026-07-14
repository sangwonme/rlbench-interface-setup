import os
import argparse
import json
import subprocess
import shutil
import tempfile
from pathlib import Path
from PIL import Image
from pyrep.const import RenderMode
from rlbench.action_modes.action_mode import MoveArmThenGripper
import rlbench.action_modes.arm_action_modes as arm_modes
import rlbench.action_modes.gripper_action_modes as gripper_modes
from rlbench.environment import Environment
from rlbench.observation_config import ObservationConfig, CameraConfig
import rlbench.tasks


def load_config(path):
    with open(path) as f:
        return json.load(f)


def build_camera_config(cam_cfg):
    if not cam_cfg.get("enabled", False):
        return CameraConfig(rgb=False, depth=False, point_cloud=False, mask=False)
    size = tuple(cam_cfg.get("image_size", [256, 256]))
    return CameraConfig(
        rgb=cam_cfg.get("rgb", True),
        depth=cam_cfg.get("depth", False),
        point_cloud=cam_cfg.get("point_cloud", False),
        mask=cam_cfg.get("mask", False),
        image_size=size,
        render_mode=RenderMode.OPENGL)


def build_obs_config(cfg):
    cams = cfg.get("cameras", {})
    return ObservationConfig(
        front_camera=build_camera_config(cams.get("front", {})),
        left_shoulder_camera=build_camera_config(cams.get("left_shoulder", {})),
        right_shoulder_camera=build_camera_config(cams.get("right_shoulder", {})),
        overhead_camera=build_camera_config(cams.get("overhead", {})),
        wrist_camera=build_camera_config(cams.get("wrist", {})),
        joint_positions=True,
        joint_velocities=True,
        gripper_pose=True,
        gripper_open=True)


def build_action_mode(cfg):
    arm_cls = getattr(arm_modes, cfg.get("arm_mode", "JointVelocity"))
    grip_cls = getattr(gripper_modes, cfg.get("gripper_mode", "Discrete"))
    return MoveArmThenGripper(arm_action_mode=arm_cls(), gripper_action_mode=grip_cls())


def get_task_class(name):
    cls = getattr(rlbench.tasks, name, None)
    if cls is not None:
        return cls
    camel = "".join(word.capitalize() for word in name.split("_"))
    cls = getattr(rlbench.tasks, camel, None)
    if cls is not None:
        return cls
    raise ValueError(f"Task '{name}' not found.")


def save_video(frames, path, fps=30):
    tmpdir = tempfile.mkdtemp()
    for i, frame in enumerate(frames):
        Image.fromarray(frame).save(os.path.join(tmpdir, f"{i:05d}.png"))
    subprocess.run([
        "ffmpeg", "-y", "-framerate", str(fps),
        "-i", os.path.join(tmpdir, "%05d.png"),
        "-c:v", "libx264", "-pix_fmt", "yuv420p", path
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    shutil.rmtree(tmpdir)
    print(f"  Video saved: {path}")


CAMERA_MAP = {
    "front": "front_rgb",
    "left_shoulder": "left_shoulder_rgb",
    "right_shoulder": "right_shoulder_rgb",
    "overhead": "overhead_rgb",
    "wrist": "wrist_rgb",
}


def get_frame(obs, camera_name):
    attr = CAMERA_MAP.get(camera_name, "front_rgb")
    return getattr(obs, attr, None)


def run_demo(task, num_episodes, variation, camera, fps, output_dir, task_name):
    for ep in range(num_episodes):
        task.set_variation(variation)
        try:
            demos = task.get_demos(1, live_demos=True, max_attempts=5)
        except RuntimeError as e:
            print(f"  Failed: {e}")
            continue

        demo = demos[0]
        print(f"\n=== Demo {ep + 1}/{num_episodes} ===")
        print(f"  Steps: {len(demo)}")

        frames = [get_frame(obs, camera) for obs in demo if get_frame(obs, camera) is not None]
        print(f"  Frames: {len(frames)}")

        if frames:
            os.makedirs(output_dir, exist_ok=True)
            video_name = f"{task_name}_v{variation}_demo{ep+1}.mp4"
            save_video(frames, os.path.join(output_dir, video_name), fps=fps)


# ── Main ───────────────────────────────────────────────────────

def run_single_config(config_path):
    """Run a single config file"""
    cfg = load_config(config_path)
    task_cfg = cfg["task"]
    scene_cfg = cfg.get("scene", {})
    episode_cfg = cfg.get("episode", {})
    record_cfg = cfg.get("recording", {})

    task_name = task_cfg["name"]
    variation = task_cfg.get("variation", 0)

    print(f"Config: {config_path}")
    print(f"Task:   {task_name}")
    print(f"Var:    {variation}\n")

    env = Environment(
        action_mode=build_action_mode(cfg.get("action", {})),
        obs_config=build_obs_config(cfg.get("observation", {})),
        headless=scene_cfg.get("headless", True),
        robot_setup=scene_cfg.get("robot", "panda"))

    env.launch()
    task = env.get_task(get_task_class(task_name))

    run_demo(
        task=task,
        num_episodes=episode_cfg.get("num_episodes", 3),
        variation=variation,
        camera=record_cfg.get("camera", "front"),
        fps=record_cfg.get("fps", 30),
        output_dir=record_cfg.get("output_dir", "videos"),
        task_name=task_name
    )

    env.shutdown()


def main():
    parser = argparse.ArgumentParser(description="RLBench demo runner")
    parser.add_argument("--config", "-c", help="Path to config JSON")
    parser.add_argument("--all", action="store_true", help="Run all configs in configs/")
    args = parser.parse_args()

    if args.all:
        config_dir = Path("configs")
        config_files = sorted(config_dir.glob("config_*.json"))
        total = len(config_files)
        print(f"Running {total} config files...\n")
        print("=" * 60)

        for i, config_path in enumerate(config_files, 1):
            print(f"\n[{i}/{total}] {config_path.name}")
            print("=" * 60)
            try:
                run_single_config(str(config_path))
            except Exception as e:
                print(f"Error: {e}")
                continue
            print("=" * 60)

        print(f"\nAll {total} configs completed.")
    elif args.config:
        run_single_config(args.config)
        print("\nDone.")
    else:
        parser.error("Either --config or --all is required")


if __name__ == "__main__":
    main()
