#!/bin/bash

# NPU Inference Test Runner
# 直接运行 Python 脚本

set -e

# Default configuration
MODEL_PATH=""
LIST_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_PATH="$2"
            shift 2
        else
            echo "❌ No model path specified. Please use --model <model_path>"
            exit 1
        fi
        ;;
    --list)
        LIST_MODE=true
        shift
        ;;
    --help|-h)
        echo "Usage: $0 [--model model_path|--list]"
        echo ""
        echo "Options:"
        echo "  --model model_path    Model path"
        echo "  --list                List models in /data directory"
        echo "  --help, -h           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 --model /data/models/Qwen3-0.6B-Base"
        echo "  $0 --model /path/to/custom/model"
        echo "  $0 --list"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# List models in /data directory
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

# 检查 Python 环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python3."
    exit 1
fi

# Main execution
if [ "$LIST_MODE" = true ]; then
    list_models
else
    echo "=== NPU Inference Test Runner ==="
    echo "Running bert_mindspore.py..."

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
        echo "❌ No model specified. Please use --model <model_path>"
        exit 1
    fi

    # 运行 Python 脚本
    echo "Executing: ${CMD_ARGS[*]}"
    "${CMD_ARGS[@]}"
fi 