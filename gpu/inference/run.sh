#!/bin/bash

# GPU Inference Test Runner with vLLM
# Start vLLM server using nerdctl

set -e

# Default configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference"
CONTAINER_NAME="xpu-benchmark-gpu-inference"
HOST_PORT=8000
CONTAINER_PORT=8000
DEFAULT_MODEL="https://huggingface.co/Qwen/Qwen2.5-7B-Instruct"
MODEL_PATH=""
# Parse command line arguments
START_MODE=false
STOP_MODE=false
MODEL_MODE=false
CONCURRENT_MODE=false
MODEL_URLS=()

while [[ $# -gt 0 ]]; do
    case $1 in
    --start)
        START_MODE=true
        shift
        ;;
    --stop)
        STOP_MODE=true
        shift
        ;;
    --model)
        MODEL_MODE=true
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            shift 2
        else
            shift
        fi
        ;;
    --concurrent)
        CONCURRENT_MODE=true
        shift
        while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^- ]]; do
            MODEL_URLS+=("$1")
            shift
        done
        ;;
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--start|--stop|--model [model_path]|--concurrent model1 model2 ...]"
        echo ""
        echo "Options:"
        echo "  --start              Start service"
        echo "  --stop               Stop service"
        echo "  --model [model_path] Download single model (default: $DEFAULT_MODEL)"
        echo "  --concurrent model1 model2 ... Download multiple models in parallel"
        exit 1
        ;;
    esac
done

# Download model using git clone
download_model() {
    local model_path="$1"
    local model_dir="model"

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
        echo "Model location: $(pwd)/$target_dir"
        
        # Pull LFS files
        echo "📥 Pulling LFS files..."
        cd "$target_dir"
        git lfs pull
        cd ..
        
        echo "✅ LFS files downloaded successfully!"
    else
        echo "❌ Model download failed"
        exit 1
    fi
}

# Download multiple models concurrently
download_model_concurrent() {
    local model_urls=("$@")
    
    if [ ${#model_urls[@]} -eq 0 ]; then
        echo "❌ No model URLs provided for concurrent download"
        exit 1
    fi

    echo "=== Downloading ${#model_urls[@]} models concurrently ==="
    
    # Configure git for faster cloning
    echo "🔧 Configuring git for faster cloning..."
    git config --global http.postBuffer 524288000
    git config --global core.compression 9
    git config --global http.lowSpeedLimit 0
    git config --global http.lowSpeedTime 999999

    # Create model directory
    mkdir -p "model"

    # Function to download a single model
    download_single_model() {
        local model_path="$1"
        local model_name=$(basename "$model_path")
        local target_dir="model/$model_name"
        
        echo "🚀 Starting download: $model_name"
        
        if git clone --depth 1 --single-branch "$model_path" "$target_dir"; then
            echo "📥 Pulling LFS files for $model_name..."
            cd "$target_dir"
            git lfs pull
            cd ..
            echo "✅ $model_name downloaded successfully!"
        else
            echo "❌ Failed to download $model_name"
            return 1
        fi
    }

    # Download all models in parallel
    local pids=()
    for model_url in "${model_urls[@]}"; do
        download_single_model "$model_url" &
        pids+=($!)
    done

    # Wait for all downloads to complete
    echo "⏳ Waiting for all downloads to complete..."
    for pid in "${pids[@]}"; do
        wait $pid
    done

    echo "🎉 All downloads completed!"
}

# Start vLLM service
start_service() {
    echo "=== Starting vLLM service ==="
    
    # Determine which model to serve
    local model_to_serve=""
    if [ -n "$MODEL_PATH" ]; then
        # Use the model specified by --model parameter
        model_to_serve=$(basename "$MODEL_PATH")
    else
        # Use the default model
        model_to_serve=$(basename "$DEFAULT_MODEL")
    fi
    
    echo "Using model: $model_to_serve"
    
    # Check if container already exists
    if nerdctl ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Container $CONTAINER_NAME already exists"
        if nerdctl ps | grep -q "$CONTAINER_NAME"; then
            echo "Container is already running"
            echo "Container ID: $(nerdctl ps --format 'table {{.ID}}' | grep $CONTAINER_NAME)"
            echo "Service URL: http://localhost:$HOST_PORT"
            exit 0
        else
            echo "Starting existing container..."
            nerdctl start $CONTAINER_NAME
        fi
    else
        echo "Creating and starting new container..."
        nerdctl run -d \
            --gpus all \
            --name $CONTAINER_NAME \
            --volume $(pwd)/model:/model \
            -p $HOST_PORT:$CONTAINER_PORT \
            $IMAGE_NAME \
            serve /model/$model_to_serve
    fi
    # Show container information
    echo ""
    echo "=== Service Information ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Container ID: $(nerdctl ps --format 'table {{.ID}}' | grep $CONTAINER_NAME)"
    echo "Service URL: http://localhost:$HOST_PORT"
    echo "Health check: http://localhost:$HOST_PORT/health"
    echo ""
    echo "✅ Service started successfully!"
    echo ""
    echo "You can now:"
    echo "  - Test the API: ./client.sh health"
    echo "  - Stop the service: $0 --stop"
    echo "  - View logs: nerdctl logs $CONTAINER_NAME"
}

# Stop vLLM service
stop_service() {
    echo "=== Stopping vLLM service ==="
    if nerdctl ps | grep -q "$CONTAINER_NAME"; then
        echo "Stopping container $CONTAINER_NAME..."
        nerdctl stop $CONTAINER_NAME
        nerdctl rm $CONTAINER_NAME
        echo "✅ Service stopped successfully"
    elif nerdctl ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Removing stopped container $CONTAINER_NAME..."
        nerdctl rm $CONTAINER_NAME
        echo "✅ Container removed successfully"
    else
        echo "ℹ️  No container $CONTAINER_NAME found"
    fi
}

# Main execution
if [ "$MODEL_MODE" = true ]; then
    download_model "$MODEL_PATH"
elif [ "$START_MODE" = true ]; then
    start_service
elif [ "$STOP_MODE" = true ]; then
    stop_service
elif [ "$CONCURRENT_MODE" = true ]; then
    download_model_concurrent "${MODEL_URLS[@]}"
else
    echo "=== GPU Inference Test Runner with vLLM ==="
    echo "Please specify an action:"
    echo "  $0 --start              # Start vLLM service"
    echo "  $0 --stop               # Stop vLLM service"
    echo "  $0 --model <model_path> # Default model: $DEFAULT_MODEL"
    echo "  $0 --concurrent model1 model2 ... Download multiple models in parallel"
fi
