#!/bin/bash

# GPU Inference Test Runner with vLLM
# Start vLLM server using nerdctl

set -e

echo "=== GPU Inference Test Runner with vLLM ==="
echo "Starting vLLM server using nerdctl..."

# Check if nerdctl is available
if ! command -v nerdctl >/dev/null 2>&1; then
    echo "❌ nerdctl not found. Please install nerdctl."
    exit 1
fi

# Check nerdctl connection
if ! nerdctl info >/dev/null 2>&1; then
    echo "❌ nerdctl connection failed. Please check nerdctl setup."
    exit 1
fi

# Configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference-latest"
CONTAINER_NAME="xpu-benchmark-test"
HOST_PORT=8000
CONTAINER_PORT=8000

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
      -p $HOST_PORT:$CONTAINER_PORT \
      -v "$(pwd)/../reports:/app/reports" \
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
echo "  - Stop the service: nerdctl stop $CONTAINER_NAME && nerdctl rm $CONTAINER_NAME"
echo "  - View logs: nerdctl logs $CONTAINER_NAME" 