#!/bin/bash

# ResNet-50 Training Runner
# Start training container using nerdctl

set -e

# Default configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-training"
CONTAINER_NAME="xpu-benchmark-gpu-training"
HOST_TENSORBOARD_PORT=6006
CONTAINER_TENSORBOARD_PORT=6006
HOST_JUPYTER_PORT=8888
CONTAINER_JUPYTER_PORT=8888

# Parse command line arguments
START_MODE=false
STOP_MODE=false
STATUS_MODE=false
BENCHMARK_MODE=false
TENSORBOARD_MODE=false
JUPYTER_MODE=false
TRAIN_ARGS=""

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
    tensorboard)
        TENSORBOARD_MODE=true
        shift
        ;;
    jupyter)
        JUPYTER_MODE=true
        shift
        ;;
    --epochs)
        TRAIN_ARGS="$TRAIN_ARGS --epochs $2"
        shift 2
        ;;
    --batch-size)
        TRAIN_ARGS="$TRAIN_ARGS --batch-size $2"
        shift 2
        ;;
    --lr)
        TRAIN_ARGS="$TRAIN_ARGS --lr $2"
        shift 2
        ;;
    --mixed-precision)
        TRAIN_ARGS="$TRAIN_ARGS --mixed-precision"
        shift
        ;;
    --pretrained)
        TRAIN_ARGS="$TRAIN_ARGS --pretrained"
        shift
        ;;
    --save-model)
        TRAIN_ARGS="$TRAIN_ARGS --save-model"
        shift
        ;;
    --dataset)
        TRAIN_ARGS="$TRAIN_ARGS --dataset $2"
        shift 2
        ;;
    --help | -h)
        echo "Usage: $0 [start|stop|status|benchmark|tensorboard|jupyter] [options]"
        echo ""
        echo "Commands:"
        echo "  start                Start training container"
        echo "  stop                 Stop training container"
        echo "  status               Check container status"
        echo "  benchmark            Run benchmark test"
        echo "  tensorboard          Start TensorBoard"
        echo "  jupyter              Start Jupyter notebook"
        echo ""
        echo "Training Options:"
        echo "  --epochs N           Number of training epochs (default: 10)"
        echo "  --batch-size N       Batch size (default: 128)"
        echo "  --lr F               Learning rate (default: 0.001)"
        echo "  --dataset NAME       Dataset to use (mnist, cifar10, default: mnist)"
        echo "  --mixed-precision    Enable mixed precision training"
        echo "  --pretrained         Use pretrained model"
        echo "  --save-model         Save trained model"
        echo ""
        echo "Examples:"
        echo "  $0 start                                    # Start basic training (MNIST)"
        echo "  $0 start --epochs 20 --batch-size 64       # Custom training"
        echo "  $0 start --dataset cifar10                 # Train on CIFAR-10"
        echo "  $0 start --mixed-precision --pretrained    # Fast training"
        echo "  $0 benchmark                               # Run benchmark"
        echo "  $0 tensorboard                             # Start TensorBoard"
        echo "  $0 stop                                    # Stop training"
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
            echo "TensorBoard URL: http://localhost:$HOST_TENSORBOARD_PORT"
            echo "Jupyter URL: http://localhost:$HOST_JUPYTER_PORT"
            exit 0
        else
            echo "Removing existing container..."
            nerdctl rm $CONTAINER_NAME
        fi
    fi
    
    echo "Creating and starting training container..."
    echo "Training arguments: $TRAIN_ARGS"
    
    # Build command
    local cmd="python train_resnet50.py $TRAIN_ARGS"
    
    nerdctl run -d \
        --gpus all \
        --ipc=host \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --name $CONTAINER_NAME \
        --volume /data:/data \
        -p $HOST_TENSORBOARD_PORT:$CONTAINER_TENSORBOARD_PORT \
        -p $HOST_JUPYTER_PORT:$CONTAINER_JUPYTER_PORT \
        $IMAGE_NAME \
        bash -c "$cmd"
    
    # Show container information
    echo ""
    echo "=== Training Information ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
    echo "TensorBoard URL: http://localhost:$HOST_TENSORBOARD_PORT"
    echo "Jupyter URL: http://localhost:$HOST_JUPYTER_PORT"
    echo ""
    echo "✅ Training started successfully!"
    echo ""
    echo "You can:"
    echo "  - View logs: nerdctl logs -f $CONTAINER_NAME"
    echo "  - Start TensorBoard: $0 tensorboard"
    echo "  - Start Jupyter: $0 jupyter"
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
    echo "Port mappings:"
    echo "  TensorBoard: $HOST_TENSORBOARD_PORT:$CONTAINER_TENSORBOARD_PORT"
    echo "  Jupyter: $HOST_JUPYTER_PORT:$CONTAINER_JUPYTER_PORT"
    echo ""
    
    if nerdctl ps | grep -q "$CONTAINER_NAME"; then
        echo "Status: ✅ Running"
        echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
        echo "TensorBoard: http://localhost:$HOST_TENSORBOARD_PORT"
        echo "Jupyter: http://localhost:$HOST_JUPYTER_PORT"
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
    nerdctl run --rm \
        --gpus all \
        --ipc=host \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --name $benchmark_container \
        --volume /data:/data \
        $IMAGE_NAME \
        python benchmark.py
    
    echo "✅ Benchmark completed!"
    echo "Results saved to /data/logs/benchmark.json"
}

# Start TensorBoard
start_tensorboard() {
    echo "=== Starting TensorBoard ==="
    
    check_data_directory
    
    local tensorboard_container="${CONTAINER_NAME}-tensorboard"
    if nerdctl ps | grep -q "$tensorboard_container"; then
        echo "TensorBoard is already running"
        echo "URL: http://localhost:$HOST_TENSORBOARD_PORT"
        exit 0
    fi
    
    echo "Starting TensorBoard container..."
    nerdctl run -d \
        --name $tensorboard_container \
        --volume /data:/data \
        -p $HOST_TENSORBOARD_PORT:$CONTAINER_TENSORBOARD_PORT \
        $IMAGE_NAME \
        tensorboard --logdir /data/logs --host 0.0.0.0 --port $CONTAINER_TENSORBOARD_PORT
    
    echo "✅ TensorBoard started!"
    echo "URL: http://localhost:$HOST_TENSORBOARD_PORT"
}

# Start Jupyter
start_jupyter() {
    echo "=== Starting Jupyter Notebook ==="
    
    check_data_directory
    
    local jupyter_container="${CONTAINER_NAME}-jupyter"
    if nerdctl ps | grep -q "$jupyter_container"; then
        echo "Jupyter is already running"
        echo "URL: http://localhost:$HOST_JUPYTER_PORT"
        exit 0
    fi
    
    echo "Starting Jupyter container..."
    nerdctl run -d \
        --gpus all \
        --name $jupyter_container \
        --volume /data:/data \
        -p $HOST_JUPYTER_PORT:$CONTAINER_JUPYTER_PORT \
        $IMAGE_NAME \
        jupyter notebook --ip=0.0.0.0 --port=$CONTAINER_JUPYTER_PORT --no-browser --allow-root --NotebookApp.token=''
    
    echo "✅ Jupyter started!"
    echo "URL: http://localhost:$HOST_JUPYTER_PORT"
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
elif [ "$TENSORBOARD_MODE" = true ]; then
    start_tensorboard
elif [ "$JUPYTER_MODE" = true ]; then
    start_jupyter
else
    echo "Please specify a command. Use --help for usage information."
    exit 1
fi
