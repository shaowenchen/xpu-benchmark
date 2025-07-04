# ResNet-50 Training Environment

快速验证训练的 Docker 环境，使用 ResNet-50 在 MNIST 数据集上进行训练。

## 特性

- 基于 PyTorch 的 ResNet-50 训练
- 支持 MNIST 和 CIFAR-10 数据集
- 支持混合精度训练
- 内置 TensorBoard 监控
- 完整的基准测试工具
- 简单的容器管理

## 快速开始

### 1. 构建镜像

```bash
# 构建训练镜像
cd gpu
./build.sh training --build

# 或者构建所有镜像
./build.sh all --build
```

### 2. 启动训练

```bash
cd gpu/training

# 基础训练（10个epoch，MNIST数据集）
./run.sh start

# 自定义训练参数
./run.sh start --epochs 20 --batch-size 64 --mixed-precision --save-model

# 快速训练（使用预训练模型）
./run.sh start --epochs 5 --pretrained --mixed-precision

# 使用 CIFAR-10 数据集训练
./run.sh start --dataset cifar10 --epochs 15
```

### 3. 监控训练

```bash
# 查看训练日志
./client.sh logs

# 实时跟踪日志
./client.sh logs --follow

# 检查训练状态
./client.sh health

# 启动 TensorBoard
./run.sh tensorboard
# 然后访问 http://localhost:6006
```

### 4. 运行基准测试

```bash
# 运行性能基准测试
./run.sh benchmark

# 查看基准测试结果
./client.sh results
```

### 5. 停止训练

```bash
./run.sh stop
```

## 命令参考

### 运行脚本 (run.sh)

```bash
./run.sh [命令] [选项]
```

**命令:**
- `start` - 开始训练
- `stop` - 停止训练
- `status` - 查看状态
- `benchmark` - 运行基准测试
- `tensorboard` - 启动 TensorBoard
- `jupyter` - 启动 Jupyter Notebook

**训练选项:**
- `--epochs N` - 训练轮数 (默认: 10)
- `--batch-size N` - 批次大小 (默认: 128)
- `--lr F` - 学习率 (默认: 0.001)
- `--dataset NAME` - 数据集选择 (mnist, cifar10, 默认: mnist)
- `--mixed-precision` - 启用混合精度训练
- `--pretrained` - 使用预训练模型
- `--save-model` - 保存最佳模型

### 客户端脚本 (client.sh)

```bash
./client.sh [命令] [选项]
```

**命令:**
- `logs` - 查看训练日志
- `results` - 显示训练结果
- `tensorboard` - 打开 TensorBoard
- `health` - 检查训练健康状态

**选项:**
- `--follow` - 实时跟踪日志

## 使用示例

### 基本训练

```bash
# 快速验证训练（MNIST）
./run.sh start --epochs 5 --batch-size 64

# 使用 CIFAR-10 数据集
./run.sh start --epochs 10 --dataset cifar10

# 查看进度
./client.sh logs --follow
```

### 高性能训练

```bash
# 使用混合精度和预训练模型
./run.sh start --epochs 20 --mixed-precision --pretrained --save-model

# 启动 TensorBoard 监控
./run.sh tensorboard
```

### 基准测试

```bash
# 运行性能基准测试
./run.sh benchmark

# 查看结果
./client.sh results
```

## 目录结构

```
gpu/training/
├── Dockerfile              # Docker 镜像定义
├── train_resnet50.py       # ResNet-50 训练脚本
├── benchmark.py            # 基准测试脚本
├── run.sh                  # 运行管理脚本
├── client.sh               # 客户端测试脚本
└── README.md               # 说明文档
```

## 数据目录

训练环境会使用以下目录：

- `/data/datasets/` - 数据集存储（MNIST 会自动下载）
- `/data/logs/` - 日志和 TensorBoard 数据
- `/data/models/` - 保存的模型文件

## 端口映射

- `6006` - TensorBoard 服务
- `8888` - Jupyter Notebook

## 数据集支持

### MNIST（默认）
- **图像尺寸**: 28x28 灰度图像（自动转换为 32x32 RGB）
- **类别数**: 10（数字 0-9）
- **数据量**: 60,000 训练样本，10,000 测试样本
- **优点**: 数据量小，训练快速，适合快速验证

### CIFAR-10
- **图像尺寸**: 32x32 RGB 图像
- **类别数**: 10（飞机、汽车、鸟等）
- **数据量**: 50,000 训练样本，10,000 测试样本
- **优点**: 更复杂的图像，更接近真实场景

使用 `--dataset` 参数选择数据集：
```bash
./run.sh start --dataset mnist    # 使用 MNIST（默认）
./run.sh start --dataset cifar10  # 使用 CIFAR-10
```

## 常见问题

### 1. GPU 不可用

确保：
- 安装了正确的 NVIDIA 驱动
- 安装了 nvidia-container-toolkit
- 使用 `--gpus all` 参数运行容器

### 2. 内存不足

尝试：
- 减少批次大小：`--batch-size 32`
- 启用混合精度：`--mixed-precision`

### 3. 训练速度慢

优化建议：
- 使用混合精度训练
- 使用预训练模型
- 增加批次大小（在内存允许的情况下）

### 4. 查看详细日志

```bash
# 查看容器日志
nerdctl logs -f xpu-benchmark-gpu-training

# 查看训练脚本输出
./client.sh logs --follow
```

## 性能基准

运行基准测试获取您系统的性能指标：

```bash
./run.sh benchmark
```

结果会保存在 `/data/logs/benchmark.json` 中，包含：
- 吞吐量（samples/second）
- 每批次处理时间
- GPU 利用率
- 内存使用情况

基准测试默认使用 MNIST 格式的数据进行性能评估。

## 为什么选择 MNIST？

MNIST 是一个经典的机器学习数据集，特别适合快速验证训练环境：

- **快速下载**: 数据集小（约 50MB），下载速度快
- **训练快速**: 简单的图像，训练收敛快
- **资源占用低**: 对 GPU 内存要求低，适合各种硬件
- **结果可预期**: 容易达到高精度（>95%），便于验证环境正确性

如果需要更具挑战性的测试，可以使用 CIFAR-10 数据集。

## 扩展

您可以通过修改 `train_resnet50.py` 来：

1. 添加其他数据集支持（ImageNet、Fashion-MNIST 等）
2. 使用不同的模型架构（ResNet-18、ResNet-101 等）
3. 添加更多的训练选项（学习率调度、数据增强等）
4. 集成其他深度学习框架

## 故障排除

如果遇到问题：

1. 检查容器状态：`./run.sh status`
2. 查看系统健康：`./client.sh health`
3. 查看错误日志：`./client.sh logs`
4. 重启训练：`./run.sh stop && ./run.sh start` 