# Docker 使用指南

## 概述

XPU Benchmark 提供了 Docker 镜像来简化环境部署和测试执行。每个测试脚本都有对应的 Docker 镜像，包含所有必要的依赖。

## 镜像列表

### GPU 镜像
- `shaowenchen/xpu-benchmark:gpu-training` - ResNet50 PyTorch 训练测试
- `shaowenchen/xpu-benchmark:gpu-inference` - BERT TensorFlow Serving 推理测试
- `shaowenchen/xpu-benchmark:gpu-stress` - GPU 内存带宽压力测试

### NPU 镜像
- `shaowenchen/xpu-benchmark:npu-training` - ResNet50 MindSpore 训练测试
- `shaowenchen/xpu-benchmark:npu-inference` - BERT MindSpore 推理测试
- `shaowenchen/xpu-benchmark:npu-stress` - NPU 内存带宽压力测试

## 本地构建

### 使用构建脚本（推荐）

```bash
# 构建所有镜像
./scripts/build-docker.sh build

# 构建特定类型的镜像
./scripts/build-docker.sh build gpu          # 构建所有 GPU 镜像
./scripts/build-docker.sh build npu          # 构建所有 NPU 镜像
./scripts/build-docker.sh build gpu-training # 构建 GPU 训练镜像

# 查看已构建的镜像
./scripts/build-docker.sh list

# 运行镜像
./scripts/build-docker.sh run gpu-training
```

### 手动构建

```bash
# GPU 训练镜像
docker build -f benchmarks/gpu/training/Dockerfile -t shaowenchen/xpu-benchmark:gpu-training benchmarks/gpu/training/

# GPU 推理镜像
docker build -f benchmarks/gpu/inference/Dockerfile -t shaowenchen/xpu-benchmark:gpu-inference benchmarks/gpu/inference/

# GPU 压力测试镜像
docker build -f benchmarks/gpu/stress/Dockerfile -t shaowenchen/xpu-benchmark:gpu-stress benchmarks/gpu/stress/

# NPU 训练镜像
docker build -f benchmarks/npu/training/Dockerfile -t shaowenchen/xpu-benchmark:npu-training benchmarks/npu/training/

# NPU 推理镜像
docker build -f benchmarks/npu/inference/Dockerfile -t shaowenchen/xpu-benchmark:npu-inference benchmarks/npu/inference/

# NPU 压力测试镜像
docker build -f benchmarks/npu/stress/Dockerfile -t shaowenchen/xpu-benchmark:npu-stress benchmarks/npu/stress/
```

## 运行容器

### 基本运行

```bash
# 运行 GPU 训练测试
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training

# 运行 NPU 训练测试
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-training
```

### 使用 GPU 支持

```bash
# 运行 GPU 测试（需要 NVIDIA Docker 支持）
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training
```

### 自定义配置

```bash
# 使用自定义配置文件
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training \
  python3 resnet50_pytorch.py \
    --config /app/config/custom.yaml \
    --output /app/reports
```

## GitHub Actions 自动构建

项目配置了 GitHub Actions 来自动构建和发布 Docker 镜像：

### 触发条件
- 推送到 `main` 或 `master` 分支
- 创建 Pull Request
- 手动触发（workflow_dispatch）

### 镜像标签
- `docker.io/shaowenchen/xpu-benchmark:gpu-training-{commit-sha}`
- `docker.io/shaowenchen/xpu-benchmark:npu-training-{commit-sha}`
- 等等...

### 使用 Docker Hub 镜像

```bash
# 拉取镜像
docker pull shaowenchen/xpu-benchmark:gpu-training-latest

# 运行镜像
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-training-latest
```

### 设置 Docker Hub 凭据

在 GitHub 仓库的 Settings > Secrets and variables > Actions 中添加以下密钥：

- `DOCKERHUB_USERNAME`: 您的 Docker Hub 用户名
- `DOCKERHUB_TOKEN`: 您的 Docker Hub 访问令牌

#### 创建 Docker Hub 访问令牌

1. 登录 [Docker Hub](https://hub.docker.com/)
2. 进入 Account Settings > Security
3. 点击 "New Access Token"
4. 输入令牌名称（如 "GitHub Actions"）
5. 选择权限（建议选择 "Read & Write"）
6. 复制生成的令牌并保存到 GitHub Secrets

## 依赖文件结构

每个测试脚本都有独立的依赖文件：

```
benchmarks/
├── gpu/
│   ├── training/
│   │   ├── resnet50_pytorch.py
│   │   ├── requirements.txt      # GPU 训练依赖
│   │   └── Dockerfile
│   ├── inference/
│   │   ├── bert_tf_serving.py
│   │   ├── requirements.txt      # GPU 推理依赖
│   │   └── Dockerfile
│   └── stress/
│       ├── memory_bandwidth.py
│       ├── requirements.txt      # GPU 压力测试依赖
│       └── Dockerfile
└── npu/
    ├── training/
    │   ├── resnet50_mindspore.py
    │   ├── requirements.txt      # NPU 训练依赖
    │   └── Dockerfile
    ├── inference/
    │   ├── bert_mindspore.py
    │   ├── requirements.txt      # NPU 推理依赖
    │   └── Dockerfile
    └── stress/
        ├── memory_bandwidth.py
        ├── requirements.txt      # NPU 压力测试依赖
        └── Dockerfile
```

## 依赖详情

### GPU 训练依赖
```txt
numpy>=1.21.0
psutil>=5.8.0
pyyaml>=6.0
torch>=1.12.0
torchvision>=0.13.0
torchaudio>=0.12.0
nvidia-ml-py3>=7.352.0
```

### GPU 推理依赖
```txt
numpy>=1.21.0
psutil>=5.8.0
pyyaml>=6.0
torch>=1.12.0
torchvision>=0.13.0
torchaudio>=0.12.0
tensorflow>=2.8.0
transformers>=4.20.0
datasets>=2.0.0
nvidia-ml-py3>=7.352.0
```

### NPU 依赖
```txt
numpy>=1.21.0
psutil>=5.8.0
pyyaml>=6.0
mindspore>=1.8.0
mindinsight>=1.8.0
mindarmour>=1.8.0
mindspore-hub>=1.8.0
```

## 故障排除

### 常见问题

1. **GPU 不可用**
   ```bash
   # 检查 NVIDIA Docker 支持
   docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
   
   # 安装 NVIDIA Docker
   # 参考: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
   ```

2. **NPU 不可用**
   ```bash
   # NPU 镜像基于 Ubuntu，需要手动配置 MindSpore 环境
   # 参考: https://www.mindspore.cn/install
   ```

3. **权限问题**
   ```bash
   # 确保 Docker 有足够权限
   sudo usermod -aG docker $USER
   # 重新登录后生效
   ```

4. **存储空间不足**
   ```bash
   # 清理 Docker 缓存
   docker system prune -a
   ```

### 调试模式

```bash
# 进入容器进行调试
docker run -it --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training /bin/bash

# 在容器内运行测试
python3 resnet50_pytorch.py --config config.yaml --output /app/reports
```

## 最佳实践

1. **使用数据卷**：将配置和结果目录挂载到容器中
2. **GPU 支持**：使用 `--gpus all` 参数启用 GPU 支持
3. **资源限制**：根据需要设置内存和 CPU 限制
4. **网络访问**：如果需要下载模型，确保容器有网络访问权限

```bash
# 完整示例
docker run --rm \
  --gpus all \
  --memory=8g \
  --cpus=4 \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  --network=host \
  shaowenchen/xpu-benchmark:gpu-training
``` 