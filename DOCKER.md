# Docker Usage Guide

## Overview

XPU Benchmark provides Docker images to simplify environment deployment and test execution. Each test script has a corresponding Docker image containing all necessary dependencies.

## Image List

### GPU Images
- `shaowenchen/xpu-benchmark:gpu-training` - ResNet50 PyTorch Training Test
- `shaowenchen/xpu-benchmark:gpu-inference` - BERT TensorFlow Serving Inference Test
- `shaowenchen/xpu-benchmark:gpu-stress` - GPU Memory Bandwidth Stress Test

### NPU Images
- `shaowenchen/xpu-benchmark:npu-training` - ResNet50 MindSpore Training Test
- `shaowenchen/xpu-benchmark:npu-inference` - BERT MindSpore Inference Test
- `shaowenchen/xpu-benchmark:npu-stress` - NPU Memory Bandwidth Stress Test

## Local Building

### Using Build Script (Recommended)

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
docker build -f benchmarks/gpu/training/Dockerfile -t shaowenchen/xpu-benchmark:gpu-training benchmarks/gpu/training/

# GPU inference image
docker build -f benchmarks/gpu/inference/Dockerfile -t shaowenchen/xpu-benchmark:gpu-inference benchmarks/gpu/inference/

# GPU stress test image
docker build -f benchmarks/gpu/stress/Dockerfile -t shaowenchen/xpu-benchmark:gpu-stress benchmarks/gpu/stress/

# NPU training image
docker build -f benchmarks/npu/training/Dockerfile -t shaowenchen/xpu-benchmark:npu-training benchmarks/npu/training/

# NPU inference image
docker build -f benchmarks/npu/inference/Dockerfile -t shaowenchen/xpu-benchmark:npu-inference benchmarks/npu/inference/

# NPU stress test image
docker build -f benchmarks/npu/stress/Dockerfile -t shaowenchen/xpu-benchmark:npu-stress benchmarks/npu/stress/
```

## Running Containers

### Basic Running

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

### Custom Configuration

```bash
# Use custom configuration file
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training \
  python3 resnet50_pytorch.py \
    --config /app/config/custom.yaml \
    --output /app/reports
```

## GitHub Actions Automatic Building

The project is configured with GitHub Actions to automatically build and publish Docker images:

### Trigger Conditions
- Push to `main` or `master` branch
- Create Pull Request
- Manual trigger (workflow_dispatch)

### Image Tags
- `docker.io/shaowenchen/xpu-benchmark:gpu-training-{commit-sha}`
- `docker.io/shaowenchen/xpu-benchmark:npu-training-{commit-sha}`
- etc...

### Using Docker Hub Images

```bash
# Pull images
docker pull shaowenchen/xpu-benchmark:gpu-training-latest

# Run images
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-training-latest
```

### Setting Up Docker Hub Credentials

Add the following secrets in your GitHub repository's Settings > Secrets and variables > Actions:

- `DOCKERHUB_USERNAME`: Your Docker Hub username
- `DOCKERHUB_TOKEN`: Your Docker Hub access token

#### Creating Docker Hub Access Token

1. Login to [Docker Hub](https://hub.docker.com/)
2. Go to Account Settings > Security
3. Click "New Access Token"
4. Enter token name (e.g., "GitHub Actions")
5. Select permissions (recommended: "Read & Write")
6. Copy the generated token and save it to GitHub Secrets

## Dependency File Structure

Each test script has independent dependency files:

```
benchmarks/
├── gpu/
│   ├── training/
│   │   ├── resnet50_pytorch.py
│   │   ├── requirements.txt      # GPU training dependencies
│   │   └── Dockerfile
│   ├── inference/
│   │   ├── bert_tf_serving.py
│   │   ├── requirements.txt      # GPU inference dependencies
│   │   └── Dockerfile
│   └── stress/
│       ├── memory_bandwidth.py
│       ├── requirements.txt      # GPU stress test dependencies
│       └── Dockerfile
└── npu/
    ├── training/
    │   ├── resnet50_mindspore.py
    │   ├── requirements.txt      # NPU training dependencies
    │   └── Dockerfile
    ├── inference/
    │   ├── bert_mindspore.py
    │   ├── requirements.txt      # NPU inference dependencies
    │   └── Dockerfile
    └── stress/
        ├── memory_bandwidth.py
        ├── requirements.txt      # NPU stress test dependencies
        └── Dockerfile
```

## Dependency Details

### GPU Training Dependencies
```txt
numpy>=1.21.0
psutil>=5.8.0
pyyaml>=6.0
torch>=1.12.0
torchvision>=0.13.0
torchaudio>=0.12.0
nvidia-ml-py3>=7.352.0
```

### GPU Inference Dependencies
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

### NPU Dependencies
```txt
numpy>=1.21.0
psutil>=5.8.0
pyyaml>=6.0
mindspore>=1.8.0
mindinsight>=1.8.0
mindarmour>=1.8.0
mindspore-hub>=1.8.0
```

## Troubleshooting

### Common Issues

1. **GPU Not Available**
   ```bash
   # Check NVIDIA Docker support
   docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi
   
   # Install NVIDIA Docker
   # Reference: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html
   ```

2. **NPU Not Available**
   ```bash
   # NPU images are based on Ubuntu, need manual MindSpore environment configuration
   # Reference: https://www.mindspore.cn/install
   ```

3. **Permission Issues**
   ```bash
   # Ensure Docker has sufficient permissions
   sudo usermod -aG docker $USER
   # Re-login to take effect
   ```

4. **Insufficient Storage Space**
   ```bash
   # Clean Docker cache
   docker system prune -a
   ```

### Debug Mode

```bash
# Enter container for debugging
docker run -it --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training /bin/bash

# Run tests inside container
python3 resnet50_pytorch.py --config config.yaml --output /app/reports
```

## Best Practices

1. **Use Data Volumes**: Mount configuration and result directories to containers
2. **GPU Support**: Use `--gpus all` parameter to enable GPU support
3. **Resource Limits**: Set memory and CPU limits as needed
4. **Network Access**: Ensure containers have network access if downloading models is required

```bash
# Complete example
docker run --rm \
  --gpus all \
  --memory=8g \
  --cpus=4 \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  --network=host \
  shaowenchen/xpu-benchmark:gpu-training
``` 