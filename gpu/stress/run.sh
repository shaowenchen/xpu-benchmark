#!/bin/bash

# GPU Stress Test Runner
# 直接运行 Python 脚本

set -e

echo "=== GPU Stress Test Runner ==="
echo "Running memory_bandwidth.py..."

# 检查 Python 环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

# 安装依赖
if [ -f "requirements.txt" ]; then
    echo "📦 Installing dependencies..."
    pip3 install -r requirements.txt
fi

# 运行 Python 脚本
python3 memory_bandwidth.py 