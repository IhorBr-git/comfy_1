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

# --- Helper: clone or pull a custom node repo ---
install_or_update_node() {
    local REPO_URL="$1"
    local DIR_NAME
    DIR_NAME=$(basename "$REPO_URL" .git)
    local TARGET="/workspace/ComfyUI/custom_nodes/$DIR_NAME"

    if [ -d "$TARGET/.git" ]; then
        echo "Updating $DIR_NAME..."
        git -C "$TARGET" pull --ff-only || echo "Warning: failed to update $DIR_NAME, skipping."
    else
        echo "Cloning $DIR_NAME..."
        git -C /workspace/ComfyUI/custom_nodes clone "$REPO_URL"
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
    # ===== UPDATE =====
    echo "===== Updating existing installation ====="

    # Update ComfyUI itself
    if [ -d "/workspace/ComfyUI/.git" ]; then
        echo "Updating ComfyUI core..."
        git -C /workspace/ComfyUI pull --ff-only || echo "Warning: failed to update ComfyUI core."
    fi

    # Update ComfyUI-Manager
    if [ -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager/.git" ]; then
        echo "Updating ComfyUI-Manager..."
        git -C /workspace/ComfyUI/custom_nodes/ComfyUI-Manager pull --ff-only || echo "Warning: failed to update ComfyUI-Manager."
    fi
fi

# Install or update custom nodes (works for both modes).
install_or_update_node "https://github.com/dsigmabcn/comfyui-model-downloader.git"
install_or_update_node "https://github.com/MadiatorLabs/ComfyUI-RunpodDirect.git"
install_or_update_node "https://github.com/crystian/ComfyUI-Crystools.git"

# Start the main Runpod service and the ComfyUI service in the background.
echo "Starting ComfyUI and Runpod services..."
(/start.sh & /workspace/run_gpu.sh)
