#!/bin/bash
set -e

echo "========================================="
echo "RLBench Environment Setup"
echo "========================================="
echo ""

# 1. Detect installation directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/RLBenchSim"

echo "Installation directory: $INSTALL_DIR"
echo ""

# 2. Install system dependencies
echo "[1/6] Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip python3-venv build-essential cmake git \
    libgl1 libglib2.0-0 xvfb ffmpeg wget

# 3. Install CoppeliaSim v4.1.0
if [ ! -d "$HOME/CoppeliaSim" ]; then
    echo "[2/6] Installing CoppeliaSim v4.1.0..."
    cd /tmp
    wget -q https://downloads.coppeliarobotics.com/V4_1_0/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz
    mkdir -p ~/CoppeliaSim
    tar -xf CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz -C ~/CoppeliaSim --strip-components 1
    rm -f CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz

    # Register shared libraries
    sudo bash -c 'echo "$HOME/CoppeliaSim" > /etc/ld.so.conf.d/coppeliasim.conf'
    sudo ldconfig
else
    echo "[2/6] CoppeliaSim already installed, skipping..."
fi

# 4. Set environment variables
echo "[3/6] Setting environment variables..."
if ! grep -q "COPPELIASIM_ROOT" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# RLBench environment
export COPPELIASIM_ROOT=${HOME}/CoppeliaSim
export LD_LIBRARY_PATH=$COPPELIASIM_ROOT:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT
EOF
    echo "Added to ~/.bashrc"
else
    echo "Already configured in ~/.bashrc"
fi

export COPPELIASIM_ROOT=$HOME/CoppeliaSim
export LD_LIBRARY_PATH=$COPPELIASIM_ROOT:$LD_LIBRARY_PATH
export QT_QPA_PLATFORM_PLUGIN_PATH=$COPPELIASIM_ROOT

# 5. Create Python virtual environment
echo "[4/6] Creating Python virtual environment..."
mkdir -p "$INSTALL_DIR"
python3 -m venv "$INSTALL_DIR/.venv"
source "$INSTALL_DIR/.venv/bin/activate"
pip install --upgrade pip

# 6. Install PyRep
if [ ! -d "$INSTALL_DIR/PyRep" ]; then
    echo "[5/6] Installing PyRep..."
    git clone https://github.com/stepjam/PyRep.git "$INSTALL_DIR/PyRep"
    cd "$INSTALL_DIR/PyRep"
    pip install -r requirements.txt
    pip install -e .
else
    echo "[5/6] PyRep already installed, skipping..."
fi

# 7. Install RLBench
if [ ! -d "$INSTALL_DIR/RLBench" ]; then
    echo "[6/6] Installing RLBench..."
    git clone https://github.com/stepjam/RLBench.git "$INSTALL_DIR/RLBench"
    cd "$INSTALL_DIR/RLBench"
    pip install -e .
    pip install gymnasium
else
    echo "[6/6] RLBench already installed, skipping..."
fi

# 8. Install Python dependencies for this repo
echo "Installing Python dependencies for runner..."
cd "$SCRIPT_DIR"
if [ -f requirements.txt ]; then
    pip install -r requirements.txt
fi

# 9. Update run.sh with correct paths
echo ""
echo "Updating run.sh with installation paths..."
cat > "$SCRIPT_DIR/run.sh" << EOF
#!/bin/bash
PROJECT_ROOT=$INSTALL_DIR
source \$PROJECT_ROOT/.venv/bin/activate
export COPPELIASIM_ROOT=\$HOME/CoppeliaSim
export LD_LIBRARY_PATH=\$COPPELIASIM_ROOT:\$LD_LIBRARY_PATH
export QT_QPA_PLATFORM_PLUGIN_PATH=\$COPPELIASIM_ROOT

# Start virtual display for OpenGL rendering
Xvfb :99 -screen 0 1024x768x24 &>/dev/null &
XVFB_PID=\$!
export DISPLAY=:99
sleep 1

cd "$SCRIPT_DIR"
python main.py "\$@"
EXIT_CODE=\$?

kill \$XVFB_PID 2>/dev/null
exit \$EXIT_CODE
EOF
chmod +x "$SCRIPT_DIR/run.sh"

echo ""
echo "========================================="
echo "✓ Installation complete!"
echo "========================================="
echo ""
echo "To verify installation:"
echo "  source $INSTALL_DIR/.venv/bin/activate"
echo "  python3 -c 'import rlbench; print(f\"RLBench OK\")'"
echo ""
echo "To run a demo:"
echo "  bash $SCRIPT_DIR/run.sh --config configs/config_pick_and_place.json"
echo ""
