#!/bin/bash
PROJECT_ROOT=/home/sangwon/RLBenchSim
source $PROJECT_ROOT/.venv/bin/activate
export COPPELIASIM_ROOT=$HOME/CoppeliaSim
export LD_LIBRARY_PATH=$COPPELIASIM_ROOT

# Start virtual display for OpenGL rendering
Xvfb :99 -screen 0 1024x768x24 &>/dev/null &
XVFB_PID=$!
export DISPLAY=:99
sleep 1

cd /mnt/c/Users/user/Desktop/rlbench
python main.py "$@"
EXIT_CODE=$?

kill $XVFB_PID 2>/dev/null
exit $EXIT_CODE
