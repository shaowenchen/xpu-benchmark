#!/bin/bash

# SGLang Inference Test Runner
# Start SGLang server using nerdctl

set -e

# Default configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference-sglang"
CONTAINER_NAME="xpu-benchmark-gpu-inference-sglang"
HOST_PORT=8000
CONTAINER_PORT=8000
DEFAULT_MODEL="https://huggingface.co/Qwen/Qwen3-0.6B-Base"
MODEL_PATH=""

# Parse command line arguments
START_MODE=false
STOP_MODE=false
MODEL_MODE=false
STATUS_MODE=false
MODEL_PATH=""

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
    --status)
        STATUS_MODE=true
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
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--start|--stop|--status|--model [model_path]]"
        echo ""
        echo "Options:"
        echo "  --start              Start SGLang server"
        echo "  --stop               Stop SGLang server"
        echo "  --status             Check container status"
        echo "  --model [model_path] Download single model (default: $DEFAULT_MODEL)"
        exit 1
        ;;
    esac
done

# Download model using git clone
download_model() {
    local model_path="$1"
    local model_dir="/data/models"

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

# Start SGLang service
start_service() {
    echo "=== Starting SGLang service ==="
    
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
            echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
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
            --volume /data/models:/data/models \
            -p $HOST_PORT:$CONTAINER_PORT \
            $IMAGE_NAME \
            --model /data/models/$model_to_serve
    fi
    
    # Show container information
    echo ""
    echo "=== Service Information ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
    echo "SGLang Server URL: http://localhost:$HOST_PORT"
    echo "Health check: http://localhost:$HOST_PORT/health"
    echo ""
    echo "✅ SGLang service started successfully!"
    echo ""
    echo "You can now:"
    echo "  - Test the API: ./client.sh health"
    echo "  - Stop the service: $0 --stop"
    echo "  - View logs: nerdctl logs $CONTAINER_NAME"
}

# Stop SGLang service
stop_service() {
    echo "=== Stopping SGLang service ==="
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

# Check container status
check_status() {
    echo "=== Container Status ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Image: $IMAGE_NAME"
    echo "Port mapping: $HOST_PORT:$CONTAINER_PORT"
    echo ""
    
    # Check if container is running
    if nerdctl ps | grep -q "$CONTAINER_NAME"; then
        echo "✅ Status: RUNNING"
        # Get container ID using awk
        local container_id=$(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')
        if [ -n "$container_id" ]; then
            echo "Container ID: $container_id"
        fi
        echo "Service URL: http://localhost:$HOST_PORT"
        echo "Health check: http://localhost:$HOST_PORT/health"
        echo ""
        echo "Container details:"
        nerdctl ps | grep "$CONTAINER_NAME" || echo "No details available"
    elif nerdctl ps -a | grep -q "$CONTAINER_NAME"; then
        echo "⏸️  Status: STOPPED"
        echo "Container exists but is not running"
        echo ""
        echo "Container details:"
        nerdctl ps -a | grep "$CONTAINER_NAME" || echo "No details available"
    else
        echo "❌ Status: NOT FOUND"
        echo "Container $CONTAINER_NAME does not exist"
    fi
}

# Main execution
if [ "$MODEL_MODE" = true ]; then
    download_model "$MODEL_PATH"
elif [ "$START_MODE" = true ]; then
    start_service
elif [ "$STOP_MODE" = true ]; then
    stop_service
elif [ "$STATUS_MODE" = true ]; then
    check_status
else
    echo "=== SGLang Inference Test Runner ==="
    echo "Please specify an action:"
    echo "  $0 --start              # Start SGLang server"
    echo "  $0 --stop               # Stop SGLang server"
    echo "  $0 --status             # Check container status"
    echo "  $0 --model <model_path> # Default model: $DEFAULT_MODEL"
fi 