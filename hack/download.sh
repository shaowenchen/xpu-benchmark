#!/bin/bash

# XPU Benchmark - Download Utility
# Download models from HuggingFace for inference testing and datasets for training

set -e

# Default configuration
DEFAULT_MODEL="https://huggingface.co/Qwen/Qwen3-0.6B-Base"
DEFAULT_DATASET="https://huggingface.co/datasets/ylecun/mnist"
MODEL_DIR="/data/models"
DATASET_DIR="/data/datasets"

# Parse command line arguments
MODEL_PATH=""
DOWNLOAD_TYPE=""
DATASET_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            DOWNLOAD_TYPE="model"
            shift 2
        else
            echo "❌ No model URL specified. Please use --model <model_url>"
            echo ""
            echo "Examples:"
            echo "  $0 --model $DEFAULT_MODEL"
            echo "  $0 --model https://huggingface.co/microsoft/DialoGPT-medium"
            echo "  $0 --model https://huggingface.co/google/gemma-2b"
            echo ""
            echo "ℹ️  Use --help for more information"
            exit 1
        fi
        ;;
    --dataset)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            DATASET_NAME="$2"
            DOWNLOAD_TYPE="dataset"
            shift 2
        else
            echo "❌ No dataset URL specified. Please use --dataset <dataset_url>"
            echo ""
            echo "Examples:"
            echo "  $0 --dataset $DEFAULT_DATASET"
            echo "  $0 --dataset https://huggingface.co/datasets/imdb"
            echo "  $0 --dataset https://huggingface.co/datasets/squad"
            echo "  $0 --dataset https://huggingface.co/datasets/wikitext"
            echo ""
            echo "ℹ️  Use --help for more information"
            exit 1
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [--model model_url] [--dataset dataset_url]"
        echo ""
        echo "Options:"
        echo "  --model model_url      Download model from HuggingFace"
        echo "  --dataset dataset_url  Download dataset from HuggingFace"
        echo "  --help, -h            Show this help message"
        echo ""
        echo "Model Examples:"
        echo "  $0 --model $DEFAULT_MODEL"
        echo "  $0 --model https://huggingface.co/microsoft/DialoGPT-medium"
        echo "  $0 --model https://huggingface.co/google/gemma-2b"
        echo "  $0 --model https://huggingface.co/meta-llama/Llama-2-7b-hf"
        echo ""
        echo "Dataset Examples:"
        echo "  $0 --dataset $DEFAULT_DATASET"
        echo "  $0 --dataset https://huggingface.co/datasets/imdb"
        echo "  $0 --dataset https://huggingface.co/datasets/squad"
        echo "  $0 --dataset https://huggingface.co/datasets/wikitext"
        echo ""
        echo "Notes:"
        echo "  • Both models and datasets are downloaded using git clone with LFS support"
        echo "  • Files are saved to $MODEL_DIR and $DATASET_DIR respectively"
        echo "  • The script will skip downloading if the repository already exists"
        echo "  • Use 'git lfs' commands if you need to manage LFS files manually"
        exit 0
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Unified download function for both models and datasets
download_repo() {
    local repo_url="$1"
    local download_type="$2"
    
    if [ "$download_type" = "model" ]; then
        local target_dir="$MODEL_DIR"
        local display_name="Model"
    else
        local target_dir="$DATASET_DIR"
        local display_name="Dataset"
    fi
    
    # Use default if no URL provided
    if [ -z "$repo_url" ]; then
        if [ "$download_type" = "model" ]; then
            repo_url="$DEFAULT_MODEL"
        else
            repo_url="$DEFAULT_DATASET"
        fi
    fi
    
    # Extract name from URL for subdirectory
    local repo_name=$(basename "$repo_url")
    local target_path="$target_dir/$repo_name"
    
    echo "=== Downloading $display_name ==="
    echo "$display_name: $repo_url"
    echo "Target: $target_path"
    
    # Check if already exists
    if [ -d "$target_path" ]; then
        echo "⚠️ $repo_name already exists at $target_path"
        local size=$(du -sh "$target_path" 2>/dev/null | cut -f1)
        echo "📦 Size: $size"
        return 0
    fi
    
    # Create directory
    if [ ! -d "$target_dir" ]; then
        echo "📁 Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
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
    
    # Download using git clone with LFS
    echo "🚀 Downloading $display_name..."
    echo "📥 Cloning repository (this may take a while)..."
    
    # Use shallow clone for faster initial download
    if git clone --depth 1 "$repo_url" "$target_path"; then
        echo "📦 Downloading LFS files..."
        cd "$target_path"
        
        # Configure LFS for parallel downloads
        git config lfs.concurrenttransfers 8
        git config lfs.transfer.maxretries 3
        git config lfs.transfer.maxverifies 3
        
        # Pull LFS files
        if git lfs pull; then
            echo "✅ $display_name downloaded successfully!"
            local size=$(du -sh "$target_path" 2>/dev/null | cut -f1)
            echo "📍 $display_name saved to: $target_path"
            echo "📦 Size: $size"
        else
            echo "❌ Failed to download LFS files"
            return 1
        fi
    else
        echo "❌ Failed to clone repository"
        return 1
    fi
}

# Show summary
show_summary() {
    local download_type="$1"
    
    if [ "$download_type" = "model" ]; then
        local target_dir="$MODEL_DIR"
        local display_name="Model"
    else
        local target_dir="$DATASET_DIR"
        local display_name="Dataset"
    fi
    
    echo ""
    echo "=== Download Summary ==="
    echo "$display_name directory: $target_dir"
    
    if [ -d "$target_dir" ]; then
        echo "Available ${display_name,,}s:"
        for item in "$target_dir"/*; do
            if [ -d "$item" ]; then
                local item_name=$(basename "$item")
                local size=$(du -sh "$item" 2>/dev/null | cut -f1)
                echo "  ✓ $item_name ($size)"
            fi
        done
    else
        echo "⚠️ No ${display_name,,}s found"
    fi
}

# Main execution
if [ "$DOWNLOAD_TYPE" = "model" ]; then
    download_repo "$MODEL_PATH" "$DOWNLOAD_TYPE"
    show_summary "$DOWNLOAD_TYPE"
elif [ "$DOWNLOAD_TYPE" = "dataset" ]; then
    download_repo "$DATASET_NAME" "$DOWNLOAD_TYPE"
    show_summary "$DOWNLOAD_TYPE"
else
    echo "=== XPU Benchmark - Download Utility ==="
    echo "Download models and datasets from HuggingFace using git clone with LFS support"
    echo ""
    echo "Usage:"
    echo "  $0 --model <model_url>       # Download model"
    echo "  $0 --dataset <dataset_url>   # Download dataset"
    echo "  $0 --help                    # Show detailed help"
    echo ""
    echo "Quick Examples:"
    echo "  $0 --model $DEFAULT_MODEL"
    echo "  $0 --dataset $DEFAULT_DATASET"
    echo ""
    echo "💡 Tip: Use --help for more examples and detailed information"
fi 