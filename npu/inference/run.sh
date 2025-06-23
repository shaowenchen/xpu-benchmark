#!/bin/bash

# NPU Inference Test Runner
# 直接运行 Python 脚本

set -e

echo "=== NPU Inference Test Runner ==="
echo "Running bert_mindspore.py..."

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
python3 bert_mindspore.py 