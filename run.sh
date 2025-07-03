#!/bin/bash

# XPU Benchmark - Model Download Utility
# Common model download functions for all inference scripts

set -e

# Default configuration
DEFAULT_MODEL="https://huggingface.co/Qwen/Qwen3-0.6B-Base"
MODEL_DIR="/data/models"

# Parse command line arguments
MODEL_MODE=false
MODEL_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        MODEL_MODE=true
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            shift 2
        else
            shift
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [--model [model_path]]"
        echo ""
        echo "Options:"
        echo "  --model [model_path] Download single model (default: $DEFAULT_MODEL)"
        echo "  --help, -h           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 --model https://huggingface.co/Qwen/Qwen3-0.6B-Base"
        echo "  $0 --model                           # Use default model"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Download model using git clone
download_model() {
    local model_path="$1"
    local model_dir="${2:-$MODEL_DIR}"

    # Use default model if no model path provided
    if [ -z "$model_path" ]; then
        model_path="$DEFAULT_MODEL"
    fi

    # Extract model name from URL for subdirectory
    local model_name=$(basename "$model_path")
    local target_dir="$model_dir/$model_name"

    echo "=== Downloading model using git clone ==="
    echo "Model: $model_path"
    echo "Target directory: $target_dir"

    # Create model directory
    mkdir -p "$model_dir"

    # Configure git for faster cloning
    echo "🔧 Configuring git for faster cloning..."
    git config --global http.postBuffer 524288000
    git config --global core.compression 9
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999
    git config --global lfs.concurrenttransfers 10

    # Download model using git clone with LFS
    echo "🚀 Downloading model with git clone (LFS enabled)..."
    
    if git clone --depth 1 --single-branch "$model_path" "$target_dir"; then
        echo "✅ Model downloaded successfully!"
        echo "Model location: $target_dir"
        
        # Pull LFS files
        echo "📥 Pulling LFS files..."
        cd "$target_dir"
        git lfs pull
        cd - > /dev/null
        
        echo "✅ LFS files downloaded successfully!"
    else
        echo "❌ Model download failed"
        exit 1
    fi
}

# Main execution
if [ "$MODEL_MODE" = true ]; then
    download_model "$MODEL_PATH"
else
    echo "=== XPU Benchmark - Model Download Utility ==="
    echo "Please specify an action:"
    echo "  $0 --model <model_path> # Download single model (default: $DEFAULT_MODEL)"
    echo "  $0 --help               # Show detailed help"
fi 