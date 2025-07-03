#!/bin/bash

# XPU Benchmark - Model Download Utility
# Download models from HuggingFace for inference testing

set -e

# Default configuration
DEFAULT_MODEL="https://huggingface.co/Qwen/Qwen3-0.6B-Base"
MODEL_DIR="/data/models"

# Parse command line arguments
MODEL_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            shift 2
        else
            echo "❌ No model path specified. Please use --model <model_path>"
            exit 1
        fi
        ;;
    --help|-h)
        echo "Usage: $0 --model model_path"
        echo ""
        echo "Options:"
        echo "  --model model_path     Download model from HuggingFace"
        echo "  --help, -h            Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 --model $DEFAULT_MODEL"
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

    echo "=== Downloading model ==="
    echo "Model: $model_path"
    echo "Target: $target_dir"

    # Create model directory
    mkdir -p "$model_dir"

    # Configure git for faster cloning
    echo "🔧 Configuring git..."
    git config --global http.postBuffer 524288000
    git config --global core.compression 9
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999
    
    # Additional speed optimizations
    git config --global core.preloadindex true
    git config --global core.fscache true
    git config --global gc.auto 256
    git config --global pack.threads 0
    git config --global pack.windowMemory 256m
    git config --global pack.packSizeLimit 2g

    # Download model using git clone with LFS
    echo "🚀 Downloading model..."
    echo "📥 Cloning repository (this may take a while)..."
    
    # Use shallow clone for faster initial download
    git clone --depth 1 "$model_path" "$target_dir"
    
    echo "📦 Downloading LFS files..."
    cd "$target_dir"
    
    # Configure LFS for parallel downloads
    git config lfs.concurrenttransfers 8
    git config lfs.transfer.maxretries 3
    git config lfs.transfer.maxverifies 3
    
    # Pull LFS files
    git lfs pull
    
    echo "✅ Download completed successfully!"
    echo "📍 Model saved to: $target_dir"
}

# Main execution
if [ -n "$MODEL_PATH" ]; then
    download_model "$MODEL_PATH"
else
    echo "=== XPU Benchmark - Model Download Utility ==="
    echo "Please specify a model to download:"
    echo "  $0 --model <model_path>"
    echo "  $0 --help"
fi 