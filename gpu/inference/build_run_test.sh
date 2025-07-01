#!/bin/bash

set -e

# Parse command line arguments
SKIP_BUILD=false
CLEAN_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --clean-build)
            CLEAN_BUILD=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-build    Skip building image, use existing one"
            echo "  --clean-build   Remove existing image and build from scratch"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Normal build with cache"
            echo "  $0 --skip-build # Skip build, use existing image"
            echo "  $0 --clean-build # Clean build from scratch"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "=== Step 0: Update code repository ==="
git pull

IMAGE_NAME="xpu-benchmark:gpu-inference"
CONTAINER_NAME="xpu-benchmark-test"
HOST_PORT=8000
CONTAINER_PORT=8000

# Detect container tool: prioritize nerdctl, then docker, finally podman
if command -v nerdctl >/dev/null 2>&1; then
  echo "Using nerdctl as container tool"
  CONTAINER_TOOL=nerdctl
elif command -v docker >/dev/null 2>&1; then
  echo "Using docker as container tool"
  CONTAINER_TOOL=docker
elif command -v podman >/dev/null 2>&1; then
  echo "Using podman as container tool"
  CONTAINER_TOOL=podman
else
  echo "[ERROR] No available container tool found (docker, nerdctl, or podman)"
  exit 1
fi

# Check if container tool is available
check_container_tool() {
  local tool=$1
  case $tool in
    "docker")
      if ! docker info >/dev/null 2>&1; then
        echo "[ERROR] Docker daemon is not running, please start Docker Desktop"
        return 1
      fi
      ;;
    "podman")
      if ! podman machine list | grep -q "Running"; then
        echo "[ERROR] Podman machine is not running, please run: podman machine init && podman machine start"
        return 1
      fi
      ;;
    "nerdctl")
      if ! nerdctl info >/dev/null 2>&1; then
        echo "[ERROR] nerdctl connection failed"
        return 1
      fi
      ;;
  esac
  return 0
}

echo "=== Step 1: Check container tool status ==="
if ! check_container_tool $CONTAINER_TOOL; then
  exit 1
fi

echo "=== Step 2: Build Docker image ==="

if [ "$SKIP_BUILD" = true ]; then
    echo "Skipping build as requested..."
    
    # Check if image exists
    if ! $CONTAINER_TOOL images | grep -q "$IMAGE_NAME"; then
        echo "[ERROR] Image $IMAGE_NAME not found. Please build first or remove --skip-build flag."
        exit 1
    fi
    
    echo "Using existing image: $IMAGE_NAME"
elif [ "$CLEAN_BUILD" = true ]; then
    echo "Clean build requested, removing existing image..."
    
    # Remove existing image
    $CONTAINER_TOOL rmi -f $IMAGE_NAME >/dev/null 2>&1 || true
    
    echo "Building from scratch..."
    $CONTAINER_TOOL build \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --build-arg DOCKER_BUILDKIT=1 \
        --tag $IMAGE_NAME .
else
    # Check if image already exists
    if $CONTAINER_TOOL images | grep -q "$IMAGE_NAME"; then
        echo "Found existing image: $IMAGE_NAME"
        echo "Using existing image as cache..."
        
        # Build with cache from existing image
        $CONTAINER_TOOL build \
            --build-arg BUILDKIT_INLINE_CACHE=1 \
            --build-arg DOCKER_BUILDKIT=1 \
            --cache-from $IMAGE_NAME \
            --tag $IMAGE_NAME .
    else
        echo "No existing image found, building from scratch..."
        
        # First time build
        $CONTAINER_TOOL build \
            --build-arg BUILDKIT_INLINE_CACHE=1 \
            --build-arg DOCKER_BUILDKIT=1 \
            --tag $IMAGE_NAME .
    fi
fi

echo "=== Step 3: Start container (background) ==="
$CONTAINER_TOOL rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
$CONTAINER_TOOL run -d \
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
    $CONTAINER_TOOL logs $CONTAINER_NAME
    $CONTAINER_TOOL rm -f $CONTAINER_NAME
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
**Container Tool:** $CONTAINER_TOOL
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
$CONTAINER_TOOL rm -f $CONTAINER_NAME

echo "=== All steps completed ===" 