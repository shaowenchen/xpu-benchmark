#!/bin/bash

set -e

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
$CONTAINER_TOOL build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  -t $IMAGE_NAME .

echo "=== Step 3: Start container (background) ==="
$CONTAINER_TOOL rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
$CONTAINER_TOOL run --rm -d \
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
./client.sh health
./client.sh models
./client.sh chat "Hello, please introduce yourself" 50
./client.sh completion "The future of AI is" 50

echo "=== Step 6: Stop container ==="
$CONTAINER_TOOL rm -f $CONTAINER_NAME

echo "=== All steps completed ===" 