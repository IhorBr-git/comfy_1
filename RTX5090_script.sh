#!/bin/bash

# -- Installation & Update Script ---
# This script handles the full installation and updates of ComfyUI,
# and comfyui-model-downloader
#
# Usage:
#   ./RTX5090_script.sh           - Fresh install (default)
#   ./RTX5090_script.sh --update  - Update existing installation

set -e

MODE="install"
if [ "$1" = "--update" ]; then
    MODE="update"
fi

# Change to the /workspace directory to ensure all files are downloaded correctly.
cd /workspace

# --- Helper: clone a custom node if not installed, always install deps ---
install_node_if_missing() {
    local REPO_URL="$1"
    local DIR_NAME
    DIR_NAME=$(basename "$REPO_URL" .git)
    local TARGET="/workspace/ComfyUI/custom_nodes/$DIR_NAME"

    if [ -d "$TARGET" ]; then
        echo "$DIR_NAME already installed, skipping."
    else
        echo "Cloning $DIR_NAME..."
        git -C /workspace/ComfyUI/custom_nodes clone "$REPO_URL"

        # Install Python dependencies if requirements.txt exists
        if [ -f "$TARGET/requirements.txt" ]; then
            echo "Installing dependencies for $DIR_NAME..."
            cd "$TARGET"
            pip install -r requirements.txt
            cd /workspace
        fi
    fi
}

if [ "$MODE" = "install" ]; then
    # ===== FRESH INSTALL =====
    echo "===== Fresh Install ====="

    # Download and install ComfyUI using the ComfyUI-Manager script.
    echo "Installing ComfyUI and ComfyUI Manager..."
    wget https://github.com/ltdrdata/ComfyUI-Manager/raw/main/scripts/install-comfyui-venv-linux.sh -O install-comfyui-venv-linux.sh
    chmod +x install-comfyui-venv-linux.sh
    ./install-comfyui-venv-linux.sh

    # Add the --listen flag to the run_gpu.sh script for network access.
    echo "Configuring ComfyUI for network access..."
    sed -i "$ s/$/ --listen /" /workspace/run_gpu.sh
    chmod +x /workspace/run_gpu.sh

    # Clean up the installation scripts.
    echo "Cleaning up..."
    rm -f install_script.sh run_cpu.sh install-comfyui-venv-linux.sh

else
    # ===== SCRIPT UPDATED =====
    echo "===== Script updated, checking for new custom nodes ====="
fi

# Install custom nodes if missing, always install deps (works for both modes).
install_node_if_missing "https://github.com/dsigmabcn/comfyui-model-downloader.git"
install_node_if_missing "https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git"
install_node_if_missing "https://github.com/crystian/comfyui-crystools.git"

# Start the main Runpod service and the ComfyUI service in the background.
echo "Starting ComfyUI and Runpod services..."
(/start.sh & /workspace/run_gpu.sh)
