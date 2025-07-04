#!/bin/bash

# TLLM Inference Test Runner
# Start TLLM server using nerdctl

set -e

# Default configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference-tllm"
CONTAINER_NAME="xpu-benchmark-gpu-inference-tllm"
HOST_PORT=8000
CONTAINER_PORT=8000
MODEL_PATH=""

# Parse command line arguments
START_MODE=false
STOP_MODE=false
STATUS_MODE=false
MODEL_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
    start)
        START_MODE=true
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            shift 2
        else
            shift
        fi
        ;;
    stop)
        STOP_MODE=true
        shift
        ;;
    status)
        STATUS_MODE=true
        shift
        ;;
    --help | -h)
        echo "Usage: $0 [start [model_dir]|stop|status]"
        echo ""
        echo "Options:"
        echo "  start [model_dir]     Start TLLM server with local model dir"
        echo "                        If no model_dir specified, lists available models"
        echo "  stop                  Stop TLLM server"
        echo "  status                Check container status"
        echo "  --help, -h            Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 start                      # List available models"
        echo "  $0 start Qwen2.5-7B-Instruct # Start with specific model"
        echo "  $0 stop                       # Stop the service"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# List available models
list_models() {
    echo "=== Models in /data directory ==="

    if [ ! -d "/data" ]; then
        echo "❌ /data directory does not exist"
        exit 1
    fi

    echo "Scanning /data/models directory for models..."
    echo ""

    # Check /data/models specifically
    if [ -d "/data/models" ]; then
        echo "📁 /data/models:"
        if [ -z "$(ls -A "/data/models" 2>/dev/null)" ]; then
            echo "  (empty)"
        else
            for model in "/data/models"/*; do
                if [ -d "$model" ]; then
                    local model_name=$(basename "$model")
                    local size=$(du -sh "$model" 2>/dev/null | cut -f1)
                    echo "  📁 $model_name ($size)"
                fi
            done
        fi
        echo ""
    else
        echo "❌ /data/models directory does not exist"
        echo "Please create /data/models directory and download models to it"
    fi
}

# Start TLLM service
start_service() {
    echo "=== Starting TLLM service ==="

    # Determine which model to serve
    local model_to_serve=""
    if [ -n "$MODEL_PATH" ]; then
        local model_dir="/data/models/$MODEL_PATH"
        if [ ! -d "$model_dir" ]; then
            echo "❌ Model directory $model_dir does not exist. Available models:"
            echo ""
            list_models
            echo "Usage: $0 start <model_dir>"
            echo "Example: $0 start Qwen2.5-7B-Instruct"
            exit 1
        fi
        model_to_serve="$MODEL_PATH"
    else
        echo "❌ No model specified. Available models:"
        echo ""
        list_models
        echo "Usage: $0 start <model_dir>"
        echo "Example: $0 start Qwen2.5-7B-Instruct"
        exit 1
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
            --volume "$(pwd)/extra-llm-api-config.yml:/etc/extra-llm-api-config.yml" \
            -p $HOST_PORT:$CONTAINER_PORT \
            $IMAGE_NAME \
            trtllm-serve \
            /data/models/$model_to_serve \
            --host 0.0.0.0 \
            --port $CONTAINER_PORT \
            --backend pytorch \
            --max_batch_size 128 \
            --max_num_tokens 16384 \
            --kv_cache_free_gpu_memory_fraction 0.95 \
            --extra_llm_api_options /etc/extra-llm-api-config.yml
    fi

    # Show container information
    echo ""
    echo "=== Service Information ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
    echo "TLLM Server URL: http://localhost:$HOST_PORT"
    echo "Health check: http://localhost:$HOST_PORT/health"
    echo ""
    echo "✅ TLLM service started successfully!"
    echo ""
    echo "You can now:"
    echo "  - Test the API: ./client.sh health"
    echo "  - Stop the service: $0 stop"
    echo "  - View logs: nerdctl logs -f $CONTAINER_NAME"
}

# Stop TLLM service
stop_service() {
    echo "=== Stopping TLLM service ==="
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
if [ "$START_MODE" = true ]; then
    start_service
elif [ "$STOP_MODE" = true ]; then
    stop_service
elif [ "$STATUS_MODE" = true ]; then
    check_status
else
    echo "=== TLLM Inference Test Runner ==="
    echo "Please specify an action:"
    echo "  $0 start [model_dir]     # Start TLLM server with local model dir"
    echo "  $0 stop                  # Stop TLLM server"
    echo "  $0 status                # Check container status"
    echo "  $0 --help                # Show help"
    echo ""
    echo "Examples:"
    echo "  $0 start                      # List available models"
    echo "  $0 start Qwen2.5-7B-Instruct # Start with specific model"
fi
