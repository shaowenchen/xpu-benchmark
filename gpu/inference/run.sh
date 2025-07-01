#!/bin/bash

# GPU Inference Test Runner with vLLM
# Start vLLM server for Qwen2.5-7B-Instruct

set -e

echo "=== GPU Inference Test Runner with vLLM ==="
echo "Starting vLLM server for Qwen2.5-7B-Instruct..."

# Check Python environment
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

# Check CUDA availability
if ! python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())" 2>/dev/null; then
    echo "❌ CUDA not available. Please check NVIDIA drivers and CUDA installation."
    exit 1
fi

# Install dependencies
if [ -f "requirements.txt" ]; then
    echo "📦 Installing dependencies..."
    pip3 install -r requirements.txt
fi

# Run vLLM server with direct command
echo "🚀 Starting vLLM server..."
python3 vllm_server.py \
    --model-path "/model/Qwen2.5-7B-Instruct" \
    --cuda-visible-devices "1" \
    --port 8000 \
    --output "/app/reports" 