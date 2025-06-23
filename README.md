# XPU Benchmark

A comprehensive benchmarking suite for GPU and NPU performance testing.

## Quick Start

### Prerequisites

- Python 3.8+
- CUDA 11.0+ (for GPU tests)
- MindSpore 1.8+ (for NPU tests)

### Installation

```bash
# Clone repository
git clone https://github.com/shaowenchen/xpu-benchmark.git
cd xpu-benchmark

# Install base dependencies
pip install -r requirements.txt

# Install GPU dependencies
pip install -r gpu/training/requirements.txt
pip install -r gpu/inference/requirements.txt
pip install -r gpu/stress/requirements.txt

# Install NPU dependencies
pip install -r npu/training/requirements.txt
pip install -r npu/inference/requirements.txt
pip install -r npu/stress/requirements.txt
```

### Running Tests

#### GPU Tests

```bash
# Run all GPU tests
python -m xpu_bench.runner --config config/gpu/nvidia.yaml

# Run specific GPU test
python gpu/training/resnet50_pytorch.py --config config/gpu/nvidia.yaml
```

#### NPU Tests

```bash
# Run all NPU tests
python -m xpu_bench.runner --config config/npu/ascend.yaml

# Run specific NPU test
python npu/training/resnet50_mindspore.py --config config/npu/ascend.yaml
```

## Docker Usage

### Building Images

```bash
# Build all images
./scripts/build-docker.sh build

# Build specific type of images
./scripts/build-docker.sh build gpu          # Build all GPU images
./scripts/build-docker.sh build npu          # Build all NPU images
./scripts/build-docker.sh build gpu-training # Build GPU training image

# List built images
./scripts/build-docker.sh list

# Run image
./scripts/build-docker.sh run gpu-training
```

### Manual Building

```bash
# GPU training image
docker build -f gpu/training/Dockerfile -t shaowenchen/xpu-benchmark:gpu-training gpu/training/

# GPU inference image
docker build -f gpu/inference/Dockerfile -t shaowenchen/xpu-benchmark:gpu-inference gpu/inference/

# GPU stress test image
docker build -f gpu/stress/Dockerfile -t shaowenchen/xpu-benchmark:gpu-stress gpu/stress/

# NPU training image
docker build -f npu/training/Dockerfile -t shaowenchen/xpu-benchmark:npu-training npu/training/

# NPU inference image
docker build -f npu/inference/Dockerfile -t shaowenchen/xpu-benchmark:npu-inference npu/inference/

# NPU stress test image
docker build -f npu/stress/Dockerfile -t shaowenchen/xpu-benchmark:npu-stress npu/stress/
```

### Running Containers

```bash
# Run GPU training test
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training

# Run NPU training test
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-training
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

## Project Structure

```
xpu-benchmark/
├── config/              # Configuration files
│   ├── gpu/            # GPU configurations
│   └── npu/            # NPU configurations
├── gpu/                # GPU benchmark scripts
│   ├── training/       # Training benchmarks
│   ├── inference/      # Inference benchmarks
│   └── stress/         # Stress tests
├── npu/                # NPU benchmark scripts
│   ├── training/       # Training benchmarks
│   ├── inference/      # Inference benchmarks
│   └── stress/         # Stress tests
├── xpu_bench/          # Core framework
├── scripts/            # Utility scripts
├── reports/            # Test results
└── tests/              # Unit tests
```

## Configuration

### GPU Configuration (config/gpu/nvidia.yaml)

```yaml
hardware:
  type: "nvidia"
  driver_version: "auto"
  cuda_version: "auto"

benchmarks:
  training:
    resnet50_pytorch:
      enabled: true
      batch_size: 32
      epochs: 10
      learning_rate: 0.001
      optimizer: "adam"
      dataset: "imagenet"
      mixed_precision: true
```

### NPU Configuration (config/npu/ascend.yaml)

```yaml
hardware:
  type: "ascend"
  driver_version: "auto"
  cann_version: "auto"

benchmarks:
  training:
    resnet50_mindspore:
      enabled: true
      batch_size: 32
      epochs: 10
      learning_rate: 0.001
      optimizer: "adam"
      dataset: "imagenet"
      mixed_precision: true
```

## Running Individual Tests

### GPU Training Test

```bash
python gpu/training/resnet50_pytorch.py \
  --config config/gpu/nvidia.yaml \
  --output reports/gpu_training_results.json
```

### NPU Training Test

```bash
python npu/training/resnet50_mindspore.py \
  --config config/npu/ascend.yaml \
  --output reports/npu_training_results.json
```

## Test Results

Test results are saved in the `reports/` directory in multiple formats:

- **JSON**: Machine-readable format for further processing
- **CSV**: Spreadsheet-compatible format
- **HTML**: Human-readable reports with charts

### Example Output

```json
{
  "test_name": "resnet50_pytorch",
  "hardware": "nvidia",
  "timestamp": "2024-01-15T10:30:00Z",
  "metrics": {
    "throughput": 156.7,
    "latency": 6.38,
    "accuracy": 0.945,
    "power_consumption": 245.3
  },
  "configuration": {
    "batch_size": 32,
    "epochs": 10,
    "learning_rate": 0.001
  }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support, please open an issue on GitHub or contact the maintainers.