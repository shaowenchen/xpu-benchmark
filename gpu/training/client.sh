#!/bin/bash

# Training Client Script
# Test training functionality

set -e

# Configuration
CONTAINER_NAME="xpu-benchmark-gpu-training"
LOGS_DIR="/data/logs"

# Parse command line arguments
ACTION=""
FOLLOW_LOGS=false

while [[ $# -gt 0 ]]; do
    case $1 in
    logs)
        ACTION="logs"
        shift
        ;;
    results)
        ACTION="results"
        shift
        ;;
    health)
        ACTION="health"
        shift
        ;;
    --follow|-f)
        FOLLOW_LOGS=true
        shift
        ;;
    --help|-h)
        echo "Usage: $0 [logs|results|health] [--follow]"
        echo ""
        echo "Commands:"
        echo "  logs                     View training logs"
        echo "  results                  Show training results"
        echo "  health                   Check training health"
        echo ""
        echo "Options:"
        echo "  --follow, -f             Follow logs in real-time"
        echo "  --help, -h               Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 logs                  # View recent logs"
        echo "  $0 logs --follow         # Follow logs in real-time"
        echo "  $0 results               # Show training results"
        echo "  $0 health                # Check training health"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Check if training container is running
check_container() {
    if ! nerdctl ps | grep -q "$CONTAINER_NAME"; then
        echo "❌ Training container is not running"
        echo "Start training with: ./run.sh start"
        return 1
    fi
    return 0
}

# View training logs
view_logs() {
    echo "=== Training Logs ==="
    
    if ! check_container; then
        return 1
    fi
    
    if [ "$FOLLOW_LOGS" = true ]; then
        echo "Following logs (Press Ctrl+C to stop)..."
        nerdctl logs -f "$CONTAINER_NAME"
    else
        echo "Recent logs:"
        nerdctl logs --tail 50 "$CONTAINER_NAME"
    fi
}

# Show training results
show_results() {
    echo "=== Training Results ==="
    
    if [ -d "$LOGS_DIR" ]; then
        echo "📁 Log directory: $LOGS_DIR"
        echo ""
        
        # Show training logs
        if [ -d "$LOGS_DIR/runs" ]; then
            echo "📊 Training logs:"
            find "$LOGS_DIR/runs" -name "*.log" -o -name "events.out.tfevents.*" | head -10
            echo ""
        fi
        
        # Show saved models
        if [ -f "$LOGS_DIR/best_model.pth" ]; then
            echo "🏆 Best model saved:"
            ls -lh "$LOGS_DIR/best_model.pth"
            echo ""
        fi
        
        # Show benchmark results
        if [ -f "$LOGS_DIR/benchmark_results.json" ]; then
            echo "📈 Benchmark results:"
            cat "$LOGS_DIR/benchmark_results.json"
            echo ""
        fi
        
        # Show all log files
        echo "📄 All log files:"
        find "$LOGS_DIR" -name "*.log" -o -name "*.json" -o -name "*.pth" | sort
    else
        echo "❌ No logs directory found"
        echo "Make sure training has been started and /data/logs exists"
    fi
}

# Check training health
check_health() {
    echo "=== Training Health Check ==="
    
    if check_container; then
        echo "✅ Training container is running"
        echo "Container ID: $(nerdctl ps | grep "$CONTAINER_NAME" | awk '{print $1}')"
        echo ""
        
        # Check GPU usage
        if nerdctl exec "$CONTAINER_NAME" nvidia-smi 2>/dev/null; then
            echo "✅ GPU is accessible"
        else
            echo "❌ GPU is not accessible or nvidia-smi not available"
        fi
        
        # Check logs for errors
        if nerdctl logs --tail 20 "$CONTAINER_NAME" | grep -i "error\|exception\|failed" >/dev/null 2>&1; then
            echo "⚠️  Errors found in recent logs:"
            nerdctl logs --tail 20 "$CONTAINER_NAME" | grep -i "error\|exception\|failed"
        else
            echo "✅ No errors in recent logs"
        fi
        
        # Check if training is progressing
        if nerdctl logs --tail 20 "$CONTAINER_NAME" | grep -E "Epoch|Loss|Acc" >/dev/null 2>&1; then
            echo "✅ Training is progressing"
            echo "Recent progress:"
            nerdctl logs --tail 5 "$CONTAINER_NAME" | grep -E "Epoch|Loss|Acc"
        else
            echo "⚠️  No training progress found in recent logs"
        fi
    else
        echo "❌ Training container is not running"
        return 1
    fi
}

# Main execution
if [ -z "$ACTION" ]; then
    echo "Please specify an action. Use --help for usage information."
    exit 1
fi

case $ACTION in
    logs)
        view_logs
        ;;
    results)
        show_results
        ;;
    health)
        check_health
        ;;
    *)
        echo "Unknown action: $ACTION"
        echo "Use --help for usage information"
        exit 1
        ;;
esac 