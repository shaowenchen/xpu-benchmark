#!/bin/bash

# GPU Inference Test Runner with vLLM
# Stop vLLM server using nerdctl

set -e

echo "=== GPU Inference Test Runner with vLLM ==="
echo "Stopping vLLM server using nerdctl..."

# Check if nerdctl is available
if ! command -v nerdctl >/dev/null 2>&1; then
    echo "❌ nerdctl not found. Please install nerdctl."
    exit 1
fi

# Configuration
CONTAINER_NAME="xpu-benchmark-test"

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