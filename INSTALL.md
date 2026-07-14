# 전체 설치 항목 정리

## ✅ setup.sh가 자동으로 설치하는 것

### 1. 시스템 의존성 (apt-get)
```bash
python3-pip python3-venv    # Python 환경
build-essential cmake git   # 빌드 도구
libgl1 libglib2.0-0        # OpenGL 라이브러리
xvfb                        # 가상 디스플레이 (headless 모드)
ffmpeg                      # 비디오 인코딩
wget                        # 다운로드 도구
```

### 2. CoppeliaSim v4.1.0
- **위치**: `~/CoppeliaSim/`
- 자동 다운로드 & 설치
- 시스템 라이브러리 등록 (`/etc/ld.so.conf.d/`)

### 3. Python 라이브러리

#### PyRep (위치: ~/RLBenchSim/PyRep)
PyRep의 `requirements.txt`:
- numpy
- pillow
- (기타 PyRep 의존성)

#### RLBench (위치: ~/RLBenchSim/RLBench)
RLBench 자체 + `gymnasium`

#### Runner 전용 패키지 (requirements.txt)
```
Pillow>=12.0.0
numpy>=2.0.0
scipy>=1.17.0
gymnasium>=1.3.0
pyquaternion>=0.9.9
cloudpickle>=3.0.0
natsort>=8.4.0
cffi>=2.0.0
pycparser>=3.0
Farama-Notifications>=0.0.6
typing_extensions>=4.15.0
```

## ⚠️ 수동으로 설치해야 하는 것 (선택사항)

### GPU 지원 (NVIDIA만)

```bash
# 1. NVIDIA 드라이버 확인
nvidia-smi

# 2. CUDA Toolkit (RLBench는 CPU로도 동작하지만 GPU가 훨씬 빠름)
# Ubuntu 24.04:
sudo apt install nvidia-cuda-toolkit

# 또는 NVIDIA 공식 설치:
# https://developer.nvidia.com/cuda-downloads
```

### 머신러닝 프레임워크 (RL 에이전트 학습용)

**데모 녹화만 한다면 불필요**, 학습까지 하려면 설치:

```bash
source ~/RLBenchSim/.venv/bin/activate

# PyTorch (CUDA 12.1)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# 또는 TensorFlow
pip install tensorflow

# RL 라이브러리 (선택)
pip install stable-baselines3 tianshou

# 데이터 처리 & 시각화
pip install pandas matplotlib opencv-python wandb tensorboard
```

또는 한 번에:
```bash
pip install -r requirements_ml.txt  # (주석 해제 후 사용)
```

## 🔍 설치 확인

### 1. 기본 RLBench 동작 확인

```bash
source ~/RLBenchSim/.venv/bin/activate

# 라이브러리 import 테스트
python3 -c "import rlbench; print(f'RLBench {rlbench.__version__} OK')"
python3 -c "from pyrep import PyRep; print('PyRep OK')"
python3 -c "import gymnasium; print(f'Gymnasium {gymnasium.__version__} OK')"
```

### 2. 데모 실행 테스트

```bash
cd ~/rlbench  # (레포 위치)
bash run.sh --config configs/config_reach_target.json
```

성공 시 `videos/ReachTarget_v0_demo1.mp4` 생성

### 3. GPU 사용 확인 (선택)

```bash
# CUDA 사용 가능 여부
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# GPU 이름 확인
python3 -c "import torch; print(torch.cuda.get_device_name(0))"
```

## 📊 디스크 사용량

설치 후 예상 디스크 사용량:

```
~/CoppeliaSim/           ~500 MB   (시뮬레이터)
~/RLBenchSim/
  ├── PyRep/             ~50 MB    (Python API)
  ├── RLBench/           ~200 MB   (태스크 & 3D 모델)
  └── .venv/             ~500 MB   (Python 패키지)
─────────────────────────────────
Total:                   ~1.2 GB

# ML 프레임워크 추가 시
+ PyTorch               ~2.5 GB
+ TensorFlow            ~1.5 GB
```

## 🚀 최소 설치 vs 전체 설치

### 최소 설치 (데모 녹화만)
```bash
bash setup.sh
```
→ 1.2 GB, 10분 소요

### 전체 설치 (학습까지)
```bash
bash setup.sh
source ~/RLBenchSim/.venv/bin/activate
pip install -r requirements_ml.txt  # PyTorch/TensorFlow 주석 해제
```
→ 4+ GB, 20분 소요

## ❓ FAQ

**Q: RLBench가 CUDA 없이 동작하나요?**
A: 네! CPU만으로도 데모 생성/녹화가 가능합니다. 단, 속도가 느려질 수 있어요.

**Q: PyTorch와 TensorFlow 둘 다 설치해야 하나요?**
A: 아니요. RL 에이전트를 학습시킬 때만 필요하고, 그 중 하나만 설치하면 됩니다.

**Q: WSL에서 CUDA를 사용할 수 있나요?**
A: 네! Windows 11 + WSL2 + NVIDIA 드라이버가 있으면 WSL 내에서 CUDA 사용 가능합니다.
https://docs.nvidia.com/cuda/wsl-user-guide/index.html

**Q: 설치가 실패하면?**
A:
1. `~/RLBenchSim/` 삭제 후 재실행
2. Python 버전 확인 (3.8 이상 권장)
3. 디스크 여유 공간 확인 (최소 5GB)
4. 인터넷 연결 확인 (CoppeliaSim 다운로드)
