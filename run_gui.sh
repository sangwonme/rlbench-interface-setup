#!/bin/bash
# GUI 모드로 실행 (순수 Ubuntu에서만 사용)
# CoppeliaSim 시뮬레이션을 실제로 볼 수 있습니다

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$HOME/RLBenchSim"

source $PROJECT_ROOT/.venv/bin/activate
export COPPELIASIM_ROOT=$HOME/CoppeliaSim
export LD_LIBRARY_PATH=$COPPELIASIM_ROOT:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT

# GUI 모드는 Xvfb 없이 실제 디스플레이 사용
cd "$SCRIPT_DIR"

echo "Starting in GUI mode..."
echo "Note: Config에서 'headless: false'로 설정해야 창이 뜹니다."
echo ""

python main.py "$@"
