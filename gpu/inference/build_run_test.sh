#!/bin/bash

set -e

echo "=== Step 0: 更新代码仓库 ==="
git pull

IMAGE_NAME="xpu-benchmark:gpu-inference"
CONTAINER_NAME="xpu-benchmark-test"
HOST_PORT=8000
CONTAINER_PORT=8000

echo "=== Step 1: 构建 Docker 镜像 ==="
# 添加构建参数和重试机制
MAX_RETRIES=3
for attempt in $(seq 1 $MAX_RETRIES); do
  echo "构建尝试 $attempt/$MAX_RETRIES"
  
  if $CONTAINER_TOOL build \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    -t $IMAGE_NAME .; then
    echo "构建成功！"
    break
  else
    echo "构建失败，尝试 $attempt/$MAX_RETRIES"
    if [ $attempt -eq $MAX_RETRIES ]; then
      echo "所有构建尝试都失败了"
      exit 1
    fi
    echo "等待 10 秒后重试..."
    sleep 10
  fi
done

echo "=== Step 2: 启动容器（后台运行）==="
$CONTAINER_TOOL rm -f $CONTAINER_NAME >/dev/null 2>&1 || true
$CONTAINER_TOOL run --rm -d \
  --gpus all \
  --name $CONTAINER_NAME \
  -p $HOST_PORT:$CONTAINER_PORT \
  -v "$(pwd)/../reports:/app/reports" \
  $IMAGE_NAME

echo "=== Step 3: 等待服务启动... ==="
# 最多等待60秒
for i in {1..30}; do
  sleep 2
  if curl -s http://localhost:$HOST_PORT/health | grep -q '"status"'; then
    echo "服务已启动"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "服务启动超时，退出"
    $CONTAINER_TOOL logs $CONTAINER_NAME
    $CONTAINER_TOOL rm -f $CONTAINER_NAME
    exit 1
  fi
done

echo "=== Step 4: 运行基础功能测试 ==="
chmod +x client.sh
./client.sh health
./client.sh models
./client.sh chat "你好，介绍一下你自己" 50
./client.sh completion "The future of AI is" 50

echo "=== Step 5: 关闭容器 ==="
$CONTAINER_TOOL rm -f $CONTAINER_NAME

echo "=== 所有步骤完成 ===" 