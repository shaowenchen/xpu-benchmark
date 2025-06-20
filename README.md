# XPU Benchmark

一个用于测试 GPU 和 NPU 性能的基准测试工具，支持 NVIDIA GPU 和华为 Ascend NPU。

## 快速开始

### 1. 一键安装
```bash
# 克隆项目
git clone https://github.com/your-repo/xpu-benchmark.git
cd xpu-benchmark

# 一键安装所有依赖
./install.sh
```

### 2. 激活环境
```bash
source activate_env.sh
```

### 3. 运行测试
```bash
# 运行 GPU 测试
./scripts/run_gpu_tests.sh

# 运行 NPU 测试
./scripts/run_npu_tests.sh
```

## 支持的测试

### GPU 测试 (NVIDIA)
- **训练**: ResNet50 PyTorch
- **推理**: BERT TensorFlow Serving
- **压力测试**: 内存带宽测试

### NPU 测试 (华为 Ascend)
- **训练**: ResNet50 MindSpore
- **推理**: BERT MindSpore
- **压力测试**: 内存带宽测试

## 安装选项

### 完整安装
```bash
./scripts/install_dependencies.sh
```

### 选择性安装
```bash
# 只安装 GPU 依赖
./scripts/install_dependencies.sh --gpu

# 只安装 NPU 依赖
./scripts/install_dependencies.sh --npu

# 安装开发依赖
./scripts/install_dependencies.sh --dev
```

### 手动安装
```bash
# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装依赖
pip install -r benchmarks/requirements.txt
```

## 系统要求

- **操作系统**: Linux (Ubuntu 18.04+, CentOS 7+), macOS 10.15+
- **Python**: 3.8+
- **GPU**: NVIDIA GPU (支持 CUDA 11.0+)
- **NPU**: 华为 Ascend NPU (支持 MindSpore 1.8+)
- **内存**: 至少 8GB RAM
- **存储**: 至少 10GB 可用空间

## 项目结构

```
xpu-benchmark/
├── benchmarks/           # 基准测试脚本
│   ├── gpu/             # GPU 测试
│   │   ├── training/    # 训练测试
│   │   ├── inference/   # 推理测试
│   │   └── stress/      # 压力测试
│   ├── npu/             # NPU 测试
│   │   ├── training/    # 训练测试
│   │   ├── inference/   # 推理测试
│   │   └── stress/      # 压力测试
│   └── requirements.txt # Python 依赖
├── config/              # 配置文件
├── scripts/             # 脚本文件
├── reports/             # 测试报告
├── docs/                # 文档
├── install.sh           # 快速安装脚本
└── INSTALL.md           # 详细安装指南
```

## 配置

测试配置位于 `config/` 目录下：

- `config/gpu/nvidia.yaml` - NVIDIA GPU 配置
- `config/npu/ascend.yaml` - 华为 Ascend NPU 配置

## 运行单个测试

```bash
# GPU 训练测试
python benchmarks/gpu/training/resnet50_pytorch.py \
    --config config/gpu/nvidia.yaml \
    --output reports/gpu

# NPU 训练测试
python benchmarks/npu/training/resnet50_mindspore.py \
    --config config/npu/ascend.yaml \
    --output reports/npu
```

## 结果分析

测试结果保存在 `reports/` 目录下，格式为 JSON：

```json
{
  "test_name": "resnet50_pytorch_training",
  "hardware_type": "nvidia_gpu",
  "total_time": 120.5,
  "epochs": 10,
  "batch_size": 32,
  "device": "cuda:0",
  "training_metrics": [...],
  "status": "success",
  "timestamp": "2024-01-01T12:00:00"
}
```

## 故障排除

### 常见问题

1. **CUDA 版本不匹配**
   ```bash
   nvcc --version
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

2. **MindSpore 安装失败**
   ```bash
   # 参考华为官方文档
   # https://www.mindspore.cn/install
   pip install mindspore-cpu  # 测试用
   ```

3. **权限问题**
   ```bash
   chmod +x scripts/*.sh
   sudo ./scripts/install_dependencies.sh
   ```

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 支持

- **文档**: [INSTALL.md](INSTALL.md)
- **问题反馈**: [GitHub Issues](https://github.com/your-repo/xpu-benchmark/issues)

## 运行测试

### 1. 激活环境
```bash
source activate_env.sh
```

### 2. 运行 GPU 测试
```bash
# 运行所有 GPU 测试
./scripts/run_gpu_tests.sh

# 运行单个测试
python benchmarks/gpu/training/resnet50_pytorch.py \
    --config config/gpu/nvidia.yaml \
    --output reports/gpu
```

### 3. 运行 NPU 测试
```bash
# 运行所有 NPU 测试
./scripts/run_npu_tests.sh

# 运行单个测试
python benchmarks/npu/training/resnet50_mindspore.py \
    --config config/npu/ascend.yaml \
    --output reports/npu
```

## Docker 支持

### 快速开始（Docker）
```bash
# 构建所有 Docker 镜像
./scripts/build-docker.sh build

# 运行 GPU 训练测试
./scripts/build-docker.sh run gpu-training

# 运行 NPU 训练测试
./scripts/build-docker.sh run npu-training
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

### 从 Docker Hub 拉取镜像
```bash
# 拉取最新镜像
docker pull shaowenchen/xpu-benchmark:gpu-training-latest
docker pull shaowenchen/xpu-benchmark:npu-training-latest

# 运行镜像
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-training-latest
```

详细说明请查看 [DOCKER.md](DOCKER.md) 