#!/bin/bash

set -e

# Parse command line arguments
BUILD_ONLY=false
TEST_ONLY=false
START_MODE=false
STOP_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --start)
            START_MODE=true
            shift
            ;;
        --stop)
            STOP_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--build-only|--test-only|--start|--stop]"
            exit 1
            ;;
    esac
done

# Validate conflicting options
if [ "$BUILD_ONLY" = true ] && [ "$TEST_ONLY" = true ]; then
    echo "[ERROR] Cannot use --build-only and --test-only together"
    exit 1
fi

if [ "$START_MODE" = true ] && [ "$STOP_MODE" = true ]; then
    echo "[ERROR] Cannot use --start and --stop together"
    exit 1
fi

if [ "$START_MODE" = true ] && [ "$BUILD_ONLY" = true ]; then
    echo "[ERROR] Cannot use --start and --build-only together"
    exit 1
fi

if [ "$START_MODE" = true ] && [ "$TEST_ONLY" = true ]; then
    echo "[ERROR] Cannot use --start and --test-only together"
    exit 1
fi

if [ "$STOP_MODE" = true ] && [ "$BUILD_ONLY" = true ]; then
    echo "[ERROR] Cannot use --stop and --build-only together"
    exit 1
fi

if [ "$STOP_MODE" = true ] && [ "$TEST_ONLY" = true ]; then
    echo "[ERROR] Cannot use --stop and --test-only together"
    exit 1
fi

echo "=== Step 0: Update code repository ==="
git pull

IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference-latest"
CONTAINER_NAME="xpu-benchmark-test"
HOST_PORT=8000
CONTAINER_PORT=8000

# Detect container tool: use nerdctl only
if command -v nerdctl >/dev/null 2>&1; then
  echo "Using nerdctl as container tool"
  CONTAINER_RUNTIME="nerdctl"
elif command -v docker >/dev/null 2>&1; then
  echo "Using docker as container tool"
  CONTAINER_RUNTIME="docker"
else
  echo "[ERROR] Neither nerdctl nor docker found, please install one of them"
  exit 1
fi

# Check if container tool is available
check_container_tool() {
  if ! $CONTAINER_RUNTIME info >/dev/null 2>&1; then
    echo "[ERROR] $CONTAINER_RUNTIME connection failed"
    return 1
  fi
  return 0
}

echo "=== Step 1: Check container tool status ==="
if ! check_container_tool; then
  exit 1
fi

# Handle start/stop modes
if [ "$START_MODE" = true ]; then
    echo "=== Starting vLLM service ==="
    
    # Check if image exists
    if ! $CONTAINER_RUNTIME images | grep -q "$IMAGE_NAME"; then
        echo "[ERROR] Image $IMAGE_NAME not found. Please build first with --build-only"
        exit 1
    fi
    
    # Check if container already exists
    if $CONTAINER_RUNTIME ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Container $CONTAINER_NAME already exists"
        if $CONTAINER_RUNTIME ps | grep -q "$CONTAINER_NAME"; then
            echo "Container is already running"
            echo "Container ID: $($CONTAINER_RUNTIME ps --format 'table {{.ID}}' | grep $CONTAINER_NAME)"
            echo "Service URL: http://localhost:$HOST_PORT"
            exit 0
        else
            echo "Starting existing container..."
            $CONTAINER_RUNTIME start $CONTAINER_NAME
        fi
    else
        echo "Creating and starting new container..."
        $CONTAINER_RUNTIME run -d \
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
        $CONTAINER_RUNTIME logs $CONTAINER_NAME
        exit 1
      fi
    done
    
    # Show container information
    echo ""
    echo "=== Service Information ==="
    echo "Container name: $CONTAINER_NAME"
    echo "Container ID: $($CONTAINER_RUNTIME ps --format 'table {{.ID}}' | grep $CONTAINER_NAME)"
    echo "Service URL: http://localhost:$HOST_PORT"
    echo "Health check: http://localhost:$HOST_PORT/health"
    echo ""
    echo "Useful commands:"
    echo "  View logs: $CONTAINER_RUNTIME logs $CONTAINER_NAME"
    echo "  Stop service: $0 --stop"
    echo "  Test API: ./client.sh health"
    echo ""
    echo "Service is running in background"
    exit 0
fi

if [ "$STOP_MODE" = true ]; then
    echo "=== Stopping vLLM service ==="
    
    if $CONTAINER_RUNTIME ps | grep -q "$CONTAINER_NAME"; then
        echo "Stopping container $CONTAINER_NAME..."
        $CONTAINER_RUNTIME stop $CONTAINER_NAME
        $CONTAINER_RUNTIME rm $CONTAINER_NAME
        echo "Service stopped"
    elif $CONTAINER_RUNTIME ps -a | grep -q "$CONTAINER_NAME"; then
        echo "Removing stopped container $CONTAINER_NAME..."
        $CONTAINER_RUNTIME rm $CONTAINER_NAME
        echo "Container removed"
    else
        echo "No container $CONTAINER_NAME found"
    fi
    exit 0
fi

# Build section
if [ "$TEST_ONLY" != true ]; then
    echo "=== Step 2: Build Docker image ==="

    # Check if image already exists
    if $CONTAINER_RUNTIME images | grep -q "$IMAGE_NAME"; then
        echo "Found existing image: $IMAGE_NAME"
        echo "Using existing image as cache..."
        
        # Build with cache from existing image
        $CONTAINER_RUNTIME build \
            --cache-from $IMAGE_NAME \
            --tag $IMAGE_NAME \
            .
    else
        echo "No existing image found, building from scratch..."
        
        # First time build
        $CONTAINER_RUNTIME build --tag $IMAGE_NAME .
    fi
    
    if [ "$BUILD_ONLY" = true ]; then
        echo "=== Build completed ==="
        exit 0
    fi
fi

# Test section
if [ "$BUILD_ONLY" != true ]; then
    echo "=== Step 3: Start container (background) ==="
    $CONTAINER_RUNTIME rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
    $CONTAINER_RUNTIME run -d \
      --gpus all \
      --name $CONTAINER_NAME \
      -p $HOST_PORT:$CONTAINER_PORT \
      -v "$(pwd)/../reports:/app/reports" \
      $IMAGE_NAME

    echo "=== Step 4: Wait for service to start... ==="
    # Wait up to 60 seconds
    for i in {1..30}; do
      sleep 2
      if curl -s http://localhost:$HOST_PORT/health | grep -q '"status"'; then
        echo "Service started"
        break
      fi
      if [ $i -eq 30 ]; then
        echo "Service startup timeout, exiting"
        $CONTAINER_RUNTIME logs $CONTAINER_NAME
        $CONTAINER_RUNTIME rm -f $CONTAINER_NAME
        exit 1
      fi
    done

    echo "=== Step 5: Run basic functionality tests ==="
    chmod +x client.sh

    # Run tests and capture results
    echo "Running health check..."
    ./client.sh health > health_test.log 2>&1
    HEALTH_RESULT=$?

    echo "Running models test..."
    ./client.sh models > models_test.log 2>&1
    MODELS_RESULT=$?

    echo "Running chat completion test..."
    ./client.sh chat "Hello, please introduce yourself" 50 > chat_test.log 2>&1
    CHAT_RESULT=$?

    echo "Running completion API test..."
    ./client.sh completion "The future of AI is" 50 > completion_test.log 2>&1
    COMPLETION_RESULT=$?

    echo "=== Step 6: Generate test report ==="
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    REPORT_FILE="../reports/test_report_${TIMESTAMP}.md"

    mkdir -p ../reports

    cat > "$REPORT_FILE" << EOF
# vLLM Server Test Report

**Test Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Container Tool:** $CONTAINER_RUNTIME
**Image:** $IMAGE_NAME
**Port:** $HOST_PORT

## Test Results

### Health Check
- **Status:** $([ $HEALTH_RESULT -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Log:** \`\`\`
$(cat health_test.log)
\`\`\`

### Models Endpoint
- **Status:** $([ $MODELS_RESULT -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Log:** \`\`\`
$(cat models_test.log)
\`\`\`

### Chat Completion
- **Status:** $([ $CHAT_RESULT -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Log:** \`\`\`
$(cat chat_test.log)
\`\`\`

### Completion API
- **Status:** $([ $COMPLETION_RESULT -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Log:** \`\`\`
$(cat completion_test.log)
\`\`\`

## Overall Status

$([ $HEALTH_RESULT -eq 0 ] && [ $MODELS_RESULT -eq 0 ] && [ $CHAT_RESULT -eq 0 ] && [ $COMPLETION_RESULT -eq 0 ] && echo "✅ **All tests passed successfully!**" || echo "❌ **Some tests failed. Please check the logs above.**")

---
*Report generated by build_run_test.sh*
EOF

    echo "Test report saved to: $REPORT_FILE"

    echo "=== Step 7: Stop container ==="
    $CONTAINER_RUNTIME rm -f $CONTAINER_NAME

    echo "=== All steps completed ==="
fi 