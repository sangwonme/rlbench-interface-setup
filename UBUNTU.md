# Ubuntu (WSL 아님) 사용 가이드

순수 Ubuntu 환경에서 RLBench를 사용하는 방법입니다.

## 🚀 빠른 시작

```bash
# 1. 레포 가져오기
git clone https://github.com/yourusername/rlbench-runner.git ~/rlbench
cd ~/rlbench

# 2. 설치 (10~15분 소요)
bash setup.sh

# 3. 실행
bash run.sh --config configs/config_reach_target.json

# 결과 확인
ls -lh videos/
```

## 📺 GUI 모드로 보기

순수 Ubuntu에서는 시뮬레이션을 실제로 볼 수 있습니다.

**1. Config 파일 수정**

```bash
# 예: configs/config_reach_target.json 복사
cp configs/config_reach_target.json configs/my_config_gui.json
```

`configs/my_config_gui.json` 에서 `headless`를 `false`로 변경:

```json
{
  "scene": {
    "headless": false,    // true → false로 변경
    "robot": "panda"
  },
  ...
}
```

**2. GUI 모드로 실행**

```bash
bash run_gui.sh --config configs/my_config_gui.json
```

CoppeliaSim 창이 뜨면서 로봇이 움직이는 것을 실시간으로 볼 수 있습니다!

## 🎥 Headless vs GUI 모드

| 모드 | 속도 | 디스플레이 | 용도 |
|------|------|------------|------|
| **Headless** | 빠름 | 화면 안 보임 | 대량 데이터 생성, 자동화 |
| **GUI** | 느림 | 화면 보임 | 디버깅, 시각적 확인 |

## 🖥️ 원격 서버에서 사용

X11 forwarding으로 원격에서도 GUI를 볼 수 있습니다:

```bash
# 로컬 컴퓨터에서 SSH 접속
ssh -X user@remote-server

# 원격 서버에서 GUI 모드 실행
cd ~/rlbench
bash run_gui.sh --config configs/my_config_gui.json
```

또는 headless 모드로 실행 후 생성된 영상만 다운로드:

```bash
# 원격 서버에서
bash run.sh --config configs/config_reach_target.json

# 로컬에서 다운로드
scp user@remote-server:~/rlbench/videos/*.mp4 ./
```

## 💡 성능 팁

### GPU 사용 확인

```bash
# NVIDIA GPU 확인
nvidia-smi

# CUDA 버전 확인
nvcc --version
```

### 병렬 실행

여러 태스크를 동시에 실행하려면:

```bash
# 터미널 1
bash run.sh --config configs/config_reach_target.json &

# 터미널 2
bash run.sh --config configs/config_pick_and_place.json &

# 터미널 3
bash run.sh --config configs/config_open_door.json &

# 모든 작업이 끝날 때까지 대기
wait
```

또는 GNU Parallel 사용:

```bash
sudo apt install parallel

# configs 폴더의 모든 설정을 병렬 실행
ls configs/config_*.json | parallel -j 4 bash run.sh --config {}
```

### 메모리 관리

RLBench는 메모리를 많이 사용합니다:

```bash
# 메모리 사용량 모니터링
watch -n 1 free -h

# 실행 중 메모리 부족 시 스왑 늘리기
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 🔧 문제 해결

### CoppeliaSim이 안 열림

```bash
# 라이브러리 확인
ldd $HOME/CoppeliaSim/coppeliaSim | grep "not found"

# 빠진 라이브러리 설치
sudo apt install libgl1-mesa-glx libglib2.0-0
```

### Python import 에러

```bash
# 가상환경 확인
which python
# 출력: /home/user/RLBenchSim/.venv/bin/python

# 재설치
source ~/RLBenchSim/.venv/bin/activate
pip install -e ~/RLBenchSim/RLBench
```

### Xvfb 에러

```bash
# Xvfb 수동 시작
Xvfb :99 -screen 0 1024x768x24 &
export DISPLAY=:99

# 테스트
python -c "from pyrep import PyRep; print('OK')"
```

## 📊 배치 처리 예시

모든 태스크를 한 번에 실행:

```bash
#!/bin/bash
# run_all.sh

for config in configs/config_*.json; do
    echo "Running $config..."
    bash run.sh --config "$config"
    echo "Completed $config"
    echo "---"
done

echo "All tasks completed!"
echo "Videos saved in: $(pwd)/videos/"
ls -lh videos/
```

실행:

```bash
chmod +x run_all.sh
nohup ./run_all.sh > output.log 2>&1 &
```

## 🎯 WSL과의 차이점 요약

| 작업 | WSL에서 | Ubuntu에서 |
|------|---------|------------|
| 설치 | `bash setup.sh` | `bash setup.sh` ✓ 동일 |
| Headless 실행 | `wsl -d Ubuntu -- bash -c '...'` | `bash run.sh` ✓ 더 간단 |
| GUI 실행 | 불가능 | `bash run_gui.sh` ✓ 가능 |
| 경로 | `/mnt/c/Users/...` | `~/rlbench/` ✓ 직관적 |
| 성능 | 약간 느림 | 빠름 ✓ |

**순수 Ubuntu가 더 좋은 점:**
- ✅ 실행이 더 간단함
- ✅ GUI 모드 지원
- ✅ 성능이 더 좋음
- ✅ 네이티브 환경

**WSL이 필요한 경우:**
- Windows 환경을 유지하면서 RLBench 사용
- Windows 툴과 통합 필요
