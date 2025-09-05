#!/bin/bash

# ResNet-50 Training Runner
# Start training container using nerdctl

set -e

# Default configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-training"
CONTAINER_NAME="xpu-benchmark-gpu-training"
GPU_DEVICE="all"

# Parse command line arguments
START_MODE=false
STOP_MODE=false
STATUS_MODE=false
BENCHMARK_MODE=false
CMD_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case $1 in
    start)
        START_MODE=true
        shift
        ;;
    stop)
        STOP_MODE=true
        shift
        ;;
    status)
        STATUS_MODE=true
        shift
        ;;
    benchmark)
        BENCHMARK_MODE=true
        shift
        ;;
    --gpu)
        GPU_DEVICE="$2"
        shift 2
        ;;
    --cmd)
        CMD_OVERRIDE="$2"
        shift 2
        ;;
    --help | -h)
        echo "Usage: $0 [start|stop|status|benchmark] [options]"
        echo ""
        echo "Commands:"
        echo "  start                Start training container"
        echo "  stop                 Stop training container"
        echo "  status               Check container status"
        echo "  benchmark            Run benchmark test"
        echo ""
        echo "Options:"
        echo "  --gpu DEVICE         GPU device to use (0,1,2,... or 'all', default: all)"
        echo "  --cmd COMMAND        Override container start command"
        echo "  --help, -h           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 start                                 # Start training with default command"
        echo "  $0 start --gpu 0                         # Use GPU 0 only"
        echo "  $0 --cmd 'python train_resnet50.py --epochs 20' start  # Custom command"
        echo "  $0 benchmark                             # Run benchmark"
        echo "  $0 stop                                  # Stop training"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Check if data directory exists
check_data_directory() {
    if [ ! -d "/data" ]; then
        echo "❌ /data directory does not exist"
        echo "Please create /data directory for datasets and logs"
        exit 1
    fi
    
    # Create necessary subdirectories
    mkdir -p /data/datasets
    mkdir -p /data/logs
    mkdir -p /data/models
}

# Start training service
start_service() {
    echo "=== Starting ResNet-50 Training ==="
    
    check_data_directory
    
    # Check if container already exists
    if nerdctl ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Container $CONTAINER_NAME already exists"
        if nerdctl ps | grep -q "$CONTAINER_NAME"; then
            echo "Container is already running"
            echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
            exit 0
        else
            echo "Removing existing container..."
            nerdctl rm $CONTAINER_NAME
        fi
    fi
    
    echo "Creating and starting training container..."
    echo "GPU device: $GPU_DEVICE"

    # Build start command (default or overridden)
    local START_COMMAND
    if [ -n "$CMD_OVERRIDE" ]; then
        START_COMMAND="$CMD_OVERRIDE"
    else
        START_COMMAND="python train_resnet50.py"
    fi
    echo "Start command: $START_COMMAND"
    
    # Set CUDA_VISIBLE_DEVICES based on GPU selection
    local cuda_env=""
    if [ "$GPU_DEVICE" != "all" ]; then
        cuda_env="-e CUDA_VISIBLE_DEVICES=$GPU_DEVICE"
    fi
    
    nerdctl run -d \
        --gpus $GPU_DEVICE \
        --ipc=host \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --name $CONTAINER_NAME \
        --volume /data:/data \
        $cuda_env \
        $IMAGE_NAME \
        bash -lc "$START_COMMAND"
    
    # Show container information
    echo ""
    echo "=== Training Information ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
    echo "GPU device: $GPU_DEVICE"
    echo ""
    echo "✅ Training started successfully!"
    echo ""
    echo "You can:"
    echo "  - View logs: nerdctl logs -f $CONTAINER_NAME"
    echo "  - Stop training: $0 stop"
}

# Stop training service
stop_service() {
    echo "=== Stopping Training Service ==="
    if nerdctl ps | grep -q "$CONTAINER_NAME"; then
        echo "Stopping container $CONTAINER_NAME..."
        nerdctl stop $CONTAINER_NAME
        nerdctl rm $CONTAINER_NAME
        echo "✅ Training stopped successfully"
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
    echo "=== Training Container Status ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Image: $IMAGE_NAME"
    echo ""
    
    if nerdctl ps | grep -q "$CONTAINER_NAME"; then
        echo "Status: ✅ Running"
        echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
        echo ""
        echo "Recent logs:"
        nerdctl logs --tail 10 $CONTAINER_NAME
    elif nerdctl ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Status: ⏸️  Stopped"
        echo "Container ID: $(nerdctl ps -a | grep "$CONTAINER_NAME" | awk '{print $1}')"
    else
        echo "Status: ❌ Not found"
    fi
}

# Run benchmark
run_benchmark() {
    echo "=== Running ResNet-50 Benchmark ==="
    
    check_data_directory
    
    # Check if benchmark container exists
    local benchmark_container="${CONTAINER_NAME}-benchmark"
    if nerdctl ps | grep -q "$benchmark_container"; then
        echo "Benchmark is already running"
        exit 0
    fi
    
    echo "Starting benchmark container..."
    echo "GPU device: $GPU_DEVICE"
    
    # Set CUDA_VISIBLE_DEVICES based on GPU selection
    local cuda_env=""
    if [ "$GPU_DEVICE" != "all" ]; then
        cuda_env="-e CUDA_VISIBLE_DEVICES=$GPU_DEVICE"
    fi
    
    nerdctl run --rm \
        --gpus $GPU_DEVICE \
        --ipc=host \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --name $benchmark_container \
        --volume /data:/data \
        $cuda_env \
        $IMAGE_NAME \
        python benchmark.py
    
    echo "✅ Benchmark completed!"
    echo "Results saved to /data/logs/benchmark.json"
}

# Main execution
if [ "$START_MODE" = true ]; then
    start_service
elif [ "$STOP_MODE" = true ]; then
    stop_service
elif [ "$STATUS_MODE" = true ]; then
    check_status
elif [ "$BENCHMARK_MODE" = true ]; then
    run_benchmark
else
    echo "Please specify a command. Use --help for usage information."
    exit 1
fi
