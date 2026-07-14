# RLBench Deployment Guide

새 컴퓨터에 RLBench를 배포하는 방법입니다.

## 📦 방법 1: 자동 설치 (추천)

### 준비물
- Windows 11 + WSL2 (Ubuntu 24.04)
- NVIDIA GPU + CUDA 지원

### 설치 절차

**1. 레포 복사**

새 컴퓨터에서:

```bash
# Windows에서 USB나 네트워크로 레포 폴더 복사
# 예: C:\Users\user\Desktop\rlbench

# WSL로 진입
wsl -d Ubuntu
```

**2. 자동 설치 실행**

```bash
# WSL 내에서
cd /mnt/c/Users/user/Desktop/rlbench
chmod +x setup.sh
bash setup.sh
```

설치가 완료되면 `~/RLBenchSim/` 에 다음이 설치됩니다:
- `.venv/` - Python 가상환경
- `PyRep/` - PyRep 라이브러리
- `RLBench/` - RLBench 라이브러리

`~/CoppeliaSim/` 에 CoppeliaSim이 설치됩니다.

**3. 테스트**

```bash
# Windows 터미널에서
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/user/Desktop/rlbench/run.sh --config configs/config_reach_target.json'
```

성공하면 `videos/` 폴더에 영상이 생성됩니다.

---

## 📦 방법 2: 환경 전체 압축 (빠른 복사)

**기존 컴퓨터에서:**

```bash
wsl -d Ubuntu

# 전체 환경 압축
cd ~
tar -czf rlbench_env.tar.gz \
    RLBenchSim/ \
    CoppeliaSim/ \
    .bashrc

# Windows로 복사
cp rlbench_env.tar.gz /mnt/c/Users/user/Desktop/
```

**새 컴퓨터에서:**

```bash
wsl -d Ubuntu

# 압축 해제
cd ~
tar -xzf /mnt/c/Users/user/Desktop/rlbench_env.tar.gz

# 시스템 라이브러리만 설치
sudo apt-get update
sudo apt-get install -y libgl1 libglib2.0-0 xvfb ffmpeg

# ldconfig 재설정
sudo bash -c 'echo "$HOME/CoppeliaSim" > /etc/ld.so.conf.d/coppeliasim.conf'
sudo ldconfig

source ~/.bashrc
```

**장점:** 빠름 (다운로드 없음)
**단점:** Ubuntu 버전이 달라지면 안 될 수 있음

---

## 📦 방법 3: Docker 컨테이너 (고급)

WSL + Docker + GPU 패스스루가 필요하며, 설정이 복잡합니다.

**Dockerfile 예시:**

```dockerfile
FROM ubuntu:24.04

# System dependencies
RUN apt-get update && apt-get install -y \
    python3-pip python3-venv git wget \
    libgl1 libglib2.0-0 xvfb ffmpeg

# CoppeliaSim
RUN wget https://downloads.coppeliarobotics.com/V4_1_0/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz && \
    mkdir -p /opt/CoppeliaSim && \
    tar -xf CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz -C /opt/CoppeliaSim --strip-components 1 && \
    rm CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz

ENV COPPELIASIM_ROOT=/opt/CoppeliaSim
ENV LD_LIBRARY_PATH=$COPPELIASIM_ROOT:$LD_LIBRARY_PATH
ENV QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT

# RLBench installation
WORKDIR /app
RUN git clone https://github.com/stepjam/PyRep.git && \
    cd PyRep && pip install -r requirements.txt && pip install -e . && \
    cd .. && \
    git clone https://github.com/stepjam/RLBench.git && \
    cd RLBench && pip install -e . && pip install gymnasium

COPY . /app/runner
WORKDIR /app/runner

CMD ["bash"]
```

**실행:**

```bash
docker build -t rlbench .
docker run --gpus all -v $(pwd)/videos:/app/runner/videos rlbench \
    bash run.sh --config configs/config_reach_target.json
```

**장점:** 완벽한 격리, 이식성 최고
**단점:** 설정 복잡, OpenGL/GPU 패스스루 필요

---

## 🔧 배포 체크리스트

새 컴퓨터에 배포할 때:

- [ ] Windows 11 + WSL2 설치 확인
- [ ] NVIDIA 드라이버 + CUDA 설치 확인 (WSL용)
- [ ] 레포 폴더 복사 완료
- [ ] `setup.sh` 실행 완료
- [ ] 테스트 실행 성공 (`config_reach_target.json`)
- [ ] `videos/` 폴더에 영상 생성 확인

---

## 📂 배포 패키지 구성

레포를 배포할 때 포함해야 할 파일:

```
rlbench/
├── setup.sh          ✓ 자동 설치 스크립트
├── run.sh            ✓ 실행 스크립트
├── main.py           ✓ 메인 프로그램
├── requirements.txt  ✓ Python 의존성
├── configs/          ✓ 태스크 설정 파일들
├── README.md         ✓ 사용 가이드
└── DEPLOY.md         ✓ 배포 가이드 (이 파일)
```

**불필요:**
- `videos/` - 생성될 폴더이므로 제외
- `.venv/`, `__pycache__/` - 재생성되므로 제외

---

## 🚀 빠른 시작 (새 컴퓨터)

```bash
# 1. WSL 진입
wsl -d Ubuntu

# 2. 레포로 이동
cd /mnt/c/Users/user/Desktop/rlbench

# 3. 설치
bash setup.sh

# 4. 실행 (Windows 터미널에서)
wsl -d Ubuntu -- bash -c 'bash /mnt/c/Users/user/Desktop/rlbench/run.sh --config configs/config_reach_target.json'
```

완료!
