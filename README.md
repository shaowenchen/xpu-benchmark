# XPU Benchmark

A benchmark tool for testing GPU and NPU performance, supporting NVIDIA GPU and Huawei Ascend NPU.

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/shaowenchen/xpu-benchmark.git
cd xpu-benchmark
```

### 2. Install Dependencies

```bash
# Create virtual environment (recommended)
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r benchmarks/requirements.txt
```

### 3. Run Tests

```bash
# Run GPU tests
./scripts/run_gpu_tests.sh

# Run NPU tests
./scripts/run_npu_tests.sh
```

## Supported Tests

### GPU Tests (NVIDIA)

- **Training**: ResNet50 PyTorch
- **Inference**: BERT TensorFlow Serving
- **Stress Test**: Memory Bandwidth Test

### NPU Tests (Huawei Ascend)

- **Training**: ResNet50 MindSpore
- **Inference**: BERT MindSpore
- **Stress Test**: Memory Bandwidth Test

## Installation Options

### Manual Installation

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r benchmarks/requirements.txt
```

### Selective Installation

```bash
# Install GPU-related dependencies
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install tensorflow transformers datasets

# Install NPU-related dependencies
pip install mindspore mindinsight mindarmour mindspore-hub

# Install common dependencies
pip install numpy psutil pyyaml
```

## System Requirements

- **Operating System**: Linux (Ubuntu 18.04+, CentOS 7+), macOS 10.15+
- **Python**: 3.8+
- **GPU**: NVIDIA GPU (CUDA 11.0+ supported)
- **NPU**: Huawei Ascend NPU (MindSpore 1.8+ supported)
- **Memory**: At least 8GB RAM
- **Storage**: At least 10GB available space

## Project Structure

```
xpu-benchmark/
├── benchmarks/           # Benchmark scripts
│   ├── gpu/             # GPU tests
│   │   ├── training/    # Training tests
│   │   ├── inference/   # Inference tests
│   │   └── stress/      # Stress tests
│   ├── npu/             # NPU tests
│   │   ├── training/    # Training tests
│   │   ├── inference/   # Inference tests
│   │   └── stress/      # Stress tests
│   └── requirements.txt # Python dependencies
├── config/              # Configuration files
├── scripts/             # Script files
├── reports/             # Test reports
├── docs/                # Documentation
├── docker/              # Docker files
├── tests/               # Test files
├── xpu_bench/           # Core modules
└── DOCKER.md            # Docker usage guide
```

## Configuration

Test configurations are located in the `config/` directory:

- `config/gpu/nvidia.yaml` - NVIDIA GPU configuration
- `config/npu/ascend.yaml` - Huawei Ascend NPU configuration

## Running Tests

### 1. Activate Environment

```bash
# If using virtual environment
source venv/bin/activate  # Linux/macOS
# or
venv\Scripts\activate     # Windows
```

### 2. Run GPU Tests

```bash
# Run all GPU tests
./scripts/run_gpu_tests.sh

# Run individual test
python benchmarks/gpu/training/resnet50_pytorch.py \
    --config config/gpu/nvidia.yaml \
    --output reports/gpu
```

### 3. Run NPU Tests

```bash
# Run all NPU tests
./scripts/run_npu_tests.sh

# Run individual test
python benchmarks/npu/training/resnet50_mindspore.py \
    --config config/npu/ascend.yaml \
    --output reports/npu
```

## Result Analysis

Test results are saved in the `reports/` directory in JSON format:

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

## Troubleshooting

### Common Issues

1. **CUDA Version Mismatch**

   ```bash
   nvcc --version
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
   ```

2. **MindSpore Installation Failed**

   ```bash
   # Refer to Huawei official documentation
   # https://www.mindspore.cn/install
   pip install mindspore-cpu  # For testing
   ```

3. **Permission Issues**
   ```bash
   chmod +x scripts/*.sh
   ```

## Contributing

Welcome to submit Issues and Pull Requests!

## License

MIT License

## Support

- **Documentation**: [DOCKER.md](DOCKER.md)
- **Issue Feedback**: [GitHub Issues](https://github.com/shaowenchen/xpu-benchmark/issues)

## Docker Support

### Quick Start (Docker)

```bash
# Build all Docker images
./scripts/build-docker.sh build

# Run GPU training test
./scripts/build-docker.sh run gpu-training

# Run NPU training test
./scripts/build-docker.sh run npu-training
```

### Using GPU Support

```bash
# Run GPU tests (requires NVIDIA Docker support)
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training
```

### Pull Images from Docker Hub

```bash
# Pull latest images
docker pull shaowenchen/xpu-benchmark:gpu-training-latest
docker pull shaowenchen/xpu-benchmark:npu-training-latest

# Run images
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-training-latest
```

For detailed instructions, please refer to [DOCKER.md](DOCKER.md)
