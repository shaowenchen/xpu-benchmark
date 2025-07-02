#!/bin/bash

# GPU Inference Test Runner with vLLM
# Start vLLM server using nerdctl

set -e

# Default configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference"
CONTAINER_NAME="xpu-benchmark-test"
HOST_PORT=8000
CONTAINER_PORT=8000
DEFAULT_MODEL="https://www.modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct"
MODEL_PATH=""
# Parse command line arguments
START_MODE=false
STOP_MODE=false
MODEL_MODE=false

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
    *)
        echo "Unknown option: $1"
        echo "Usage: $0 [--start|--stop|--model [model_path]]"
        echo ""
        echo "Options:"
        echo "  --start              Start service"
        echo "  --stop               Stop service"
        echo "  --model [model_path] Default model: $DEFAULT_MODEL"
        exit 1
        ;;
    esac
done

# Check if nerdctl is available
check_nerdctl() {
    if ! command -v nerdctl &> /dev/null; then
        echo "❌ nerdctl is not installed or not in PATH"
        echo "Please install nerdctl first"
        return 1
    fi
    return 0
}

# Download model from ModelScope
download_model() {
    local model_path="$1"
    local model_dir="model"

    # Use default model if no model path provided
    if [ -z "$model_path" ]; then
        model_path="$DEFAULT_MODEL"
    fi

    echo "=== Downloading model from ModelScope ==="
    echo "Model: $model_path"
    echo "Target directory: $model_dir"

    # Create model directory
    mkdir -p "$model_dir"

    # Check if modelscope is available
    if ! python3 -c "import modelscope" 2>/dev/null; then
        echo "📦 Installing modelscope..."
        pip install modelscope
    fi

    # Download model using Python script
    echo "🚀 Downloading model..."
    python3 -c "
import os
from modelscope import snapshot_download

model_dir = '$model_dir'
model_path = '$model_path'

try:
    snapshot_download(model_path, cache_dir=model_dir)
    print('Model downloaded successfully')
except Exception as e:
    print(f'Error downloading model: {e}')
    exit(1)
"

    if [ $? -eq 0 ]; then
        echo "✅ Model downloaded successfully!"
        echo "Model location: $(pwd)/$model_dir"
    else
        echo "❌ Model download failed"
        exit 1
    fi
}

# Start vLLM service
start_service() {
    echo "=== Starting vLLM service ==="

    if ! check_nerdctl; then
        exit 1
    fi

    echo "🚀 Starting vLLM service with nerdctl..."

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
            --volume $(pwd)/reports:/app/reports \
            -p $HOST_PORT:$CONTAINER_PORT \
            $IMAGE_NAME
    fi

    # Wait for service to start
    echo "Waiting for service to start..."
    for i in {1..30}; do
        sleep 2
        if curl -s http://localhost:$HOST_PORT/health | grep -q '"status"'; then
            echo "Service started successfully"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "Service startup timeout"
            nerdctl logs $CONTAINER_NAME
            exit 1
        fi
    done

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

    if ! check_nerdctl; then
        exit 1
    fi

    echo "🛑 Stopping vLLM service with nerdctl..."

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
else
    echo "=== GPU Inference Test Runner with vLLM ==="
    echo "Please specify an action:"
    echo "  $0 --start              # Start vLLM service"
    echo "  $0 --stop               # Stop vLLM service"
    echo "  $0 --model <model_path> # Default model: $DEFAULT_MODEL"
fi
