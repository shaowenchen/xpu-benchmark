#!/bin/bash

# NPU Inference Test Runner
# 直接运行 Python 脚本

set -e

# Default configuration
DEFAULT_MODEL="/data/models/Qwen3-0.6B-Base"
MODEL_PATH=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            shift 2
        else
            MODEL_PATH="$DEFAULT_MODEL"
            shift
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [--model model_path]"
        echo ""
        echo "Options:"
        echo "  --model model_path    Model path (default: $DEFAULT_MODEL)"
        echo "  --help, -h           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Use default model"
        echo "  $0 --model /data/models/Qwen3-0.6B-Base"
        echo "  $0 --model /path/to/custom/model"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

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

# 构建命令参数
CMD_ARGS=("python3" "bert_mindspore.py" "--config" "config.yaml" "--output" "/app/reports")

# 添加模型参数
if [ -n "$MODEL_PATH" ]; then
    CMD_ARGS+=("--model" "$MODEL_PATH")
    echo "Using model: $MODEL_PATH"
else
    echo "Using default model: $DEFAULT_MODEL"
fi

# 运行 Python 脚本
echo "Executing: ${CMD_ARGS[*]}"
"${CMD_ARGS[@]}" 