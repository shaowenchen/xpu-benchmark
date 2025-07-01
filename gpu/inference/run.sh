#!/bin/bash

# GPU Inference Test Runner with vLLM
# Start vLLM server using nerdctl

set -e

# Parse command line arguments
START_MODE=false
STOP_MODE=false
MODEL_MODE=false
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
        --model)
            MODEL_MODE=true
            MODEL_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--start|--stop|--model <model_path>]"
            echo ""
            echo "Options:"
            echo "  --start              Start vLLM service"
            echo "  --stop               Stop vLLM service"
            echo "  --model <model_path> Download model from ModelScope"
            echo ""
            echo "Examples:"
            echo "  $0 --start"
            echo "  $0 --stop"
            echo "  $0 --model Qwen/Qwen2.5-7B-Instruct"
            exit 1
            ;;
    esac
done

# Validate conflicting options
if [ "$START_MODE" = true ] && [ "$STOP_MODE" = true ]; then
    echo "[ERROR] Cannot use --start and --stop together"
    exit 1
fi

if [ "$START_MODE" = true ] && [ "$MODEL_MODE" = true ]; then
    echo "[ERROR] Cannot use --start and --model together"
    exit 1
fi

if [ "$STOP_MODE" = true ] && [ "$MODEL_MODE" = true ]; then
    echo "[ERROR] Cannot use --stop and --model together"
    exit 1
fi

# Configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference"
CONTAINER_NAME="xpu-benchmark-test"
HOST_PORT=8000
CONTAINER_PORT=8000

# Check if nerdctl is available
check_nerdctl() {
    if ! command -v nerdctl >/dev/null 2>&1; then
        echo "❌ nerdctl not found. Please install nerdctl."
        return 1
    fi
    
    if ! nerdctl info >/dev/null 2>&1; then
        echo "❌ nerdctl connection failed. Please check nerdctl setup."
        return 1
    fi
    
    return 0
}

# Download model from ModelScope
download_model() {
    local model_path="$1"
    local model_dir="model"
    
    echo "=== Downloading model from ModelScope ==="
    echo "Model: $model_path"
    echo "Target directory: $model_dir"
    
    # Create model directory
    mkdir -p "$model_dir"
    
    # Check if modelscope is available
    if ! command -v modelscope-cli >/dev/null 2>&1; then
        echo "📦 Installing modelscope-cli..."
        pip install modelscope-cli
    fi
    
    # Download model
    echo "🚀 Downloading model..."
    modelscope-cli download --model-id "$model_path" --target-dir "$model_dir"
    
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
    if [ -z "$MODEL_PATH" ]; then
        echo "[ERROR] Model path is required with --model option"
        exit 1
    fi
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
    echo "  $0 --model <model_path> # Download model from ModelScope"
    echo ""
    echo "Example:"
    echo "  $0 --model Qwen/Qwen2.5-7B-Instruct"
fi
