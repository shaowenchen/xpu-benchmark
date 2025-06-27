# NPU Benchmark Containers

This directory contains NPU benchmark containers for training, inference, and stress testing using Huawei Ascend NPUs.

## Available NPU Images

- **npu-training**: ResNet50 training benchmark using MindSpore
- **npu-inference**: Model inference benchmark using MindSpore
- **npu-stress**: NPU stress testing and performance validation

## Prerequisites

- Docker 20.10+
- Huawei Ascend NPU with CANN support
- Ascend Driver and Runtime installed on host
- At least 8GB RAM

## Quick Start

### 1. Build NPU Images

```bash
# Build all NPU images
docker build -f npu/training/Dockerfile -t shaowenchen/xpu-benchmark:npu-training npu/training/
docker build -f npu/inference/Dockerfile -t shaowenchen/xpu-benchmark:npu-inference npu/inference/
docker build -f npu/stress/Dockerfile -t shaowenchen/xpu-benchmark:npu-stress npu/stress/
```

### 2. Verify NPU Support

```bash
# Test Ascend NPU availability
npu-smi info

# Check MindSpore NPU support in training image
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  shaowenchen/xpu-benchmark:npu-training python -c "import mindspore; print('NPU available:', mindspore.get_context('device_target') == 'Ascend')"
```

## Testing Commands

### NPU Training Container

#### Basic Training Test
```bash
# Run ResNet50 training benchmark
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-training
```

#### Training with Custom Configuration
```bash
# Run with custom batch size and epochs
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e BATCH_SIZE=64 \
  -e EPOCHS=20 \
  shaowenchen/xpu-benchmark:npu-training
```

#### Multi-NPU Training
```bash
# Use multiple NPU devices
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci1 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e ASCEND_VISIBLE_DEVICES=0,1 \
  shaowenchen/xpu-benchmark:npu-training
```

#### Training with Resource Limits
```bash
# Run with memory and CPU constraints
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  --memory=16g \
  --cpus=8 \
  --shm-size=8g \
  shaowenchen/xpu-benchmark:npu-training
```

### NPU Inference Container

#### Basic Inference Test
```bash
# Run model inference benchmark
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-inference
```

#### Inference with Model Loading
```bash
# Run with pre-trained model
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/models:/app/models \
  shaowenchen/xpu-benchmark:npu-inference
```

#### Batch Inference Testing
```bash
# Test different batch sizes
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e BATCH_SIZE=1,4,8,16,32 \
  shaowenchen/xpu-benchmark:npu-inference
```

### NPU Stress Container

#### Basic Stress Test
```bash
# Run NPU stress testing
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-stress
```

#### Extended Stress Test
```bash
# Run extended stress test with monitoring
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e STRESS_DURATION=3600 \
  -e MONITOR_INTERVAL=10 \
  shaowenchen/xpu-benchmark:npu-stress
```

#### Memory Stress Test
```bash
# Test NPU memory allocation
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e MEMORY_TEST=true \
  -e MAX_MEMORY_UTILIZATION=0.95 \
  shaowenchen/xpu-benchmark:npu-stress
```

## Advanced Testing Scenarios

### Interactive Debugging
```bash
# Run container in interactive mode
docker run -it --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-training /bin/bash
```

### Performance Profiling
```bash
# Run with performance profiling
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e ENABLE_PROFILING=true \
  -e PROFILE_OUTPUT=/app/reports/profile.json \
  shaowenchen/xpu-benchmark:npu-training
```

### Mixed Precision Testing
```bash
# Test with mixed precision training
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e MIXED_PRECISION=true \
  -e FP16_TRAINING=true \
  shaowenchen/xpu-benchmark:npu-training
```

### Distributed Training Test
```bash
# Test distributed training setup
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  --network=host \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e DISTRIBUTED_TRAINING=true \
  -e WORLD_SIZE=2 \
  -e RANK=0 \
  shaowenchen/xpu-benchmark:npu-training
```

## Monitoring and Validation

### Real-time Monitoring
```bash
# Monitor NPU usage during test
npu-smi info -t board -i 0 -c 1 &
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:npu-training
```

### Container Health Check
```bash
# Check container health status
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  --health-cmd="python -c 'import mindspore; print(mindspore.get_context(\"device_target\") == \"Ascend\")'" \
  --health-interval=30s \
  --health-timeout=10s \
  --health-retries=3 \
  shaowenchen/xpu-benchmark:npu-training
```

### Log Analysis
```bash
# Run with detailed logging
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  -e LOG_LEVEL=DEBUG \
  -e LOG_FILE=/app/reports/npu_training.log \
  shaowenchen/xpu-benchmark:npu-training
```

## Troubleshooting

### Common Issues

#### NPU Not Detected
```bash
# Verify Ascend NPU installation
npu-smi info

# Check device permissions
ls -la /dev/davinci*

# Verify driver installation
ls -la /usr/local/Ascend/driver/
```

#### CANN Version Mismatch
```bash
# Check CANN version compatibility
cat /usr/local/Ascend/ascend-toolkit/version.info

# Verify runtime installation
ls -la /usr/local/Ascend/runtime/
```

#### Memory Issues
```bash
# Run with increased shared memory
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  --shm-size=16g \
  shaowenchen/xpu-benchmark:npu-training
```

### Performance Optimization

#### Optimize for Specific NPU
```bash
# Set NPU compute capability
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -e ASCEND_DEVICE_ID=0 \
  -e ASCEND_VISIBLE_DEVICES=0 \
  shaowenchen/xpu-benchmark:npu-training
```

#### Enable AICore Optimization
```bash
# Enable AICore optimizations
docker run --rm \
  --device=/dev/davinci0 \
  --device=/dev/davinci_manager \
  --device=/dev/hisi_hdc \
  -v /usr/local/Ascend/driver:/usr/local/Ascend/driver \
  -v /usr/local/Ascend/runtime:/usr/local/Ascend/runtime \
  -v $(pwd)/reports:/app/reports \
  -e AICORE_NUM=2 \
  -e AICPU_NUM=2 \
  shaowenchen/xpu-benchmark:npu-training
```

## Configuration Files

Each NPU container uses configuration files located in the respective directories:

- `npu/training/config.yaml` - Training benchmark configuration
- `npu/inference/config.yaml` - Inference benchmark configuration  
- `npu/stress/config.yaml` - Stress test configuration

## Output and Results

Test results are saved to the mounted `reports` directory:

- **JSON Results**: Machine-readable benchmark data
- **Log Files**: Detailed execution logs
- **Performance Metrics**: Throughput, latency, and accuracy measurements
- **Resource Usage**: NPU utilization and memory consumption data

## Support

For NPU-specific issues and questions:
- Check the troubleshooting section above
- Review container logs for error messages
- Verify Ascend driver and runtime installation
- Ensure CANN toolkit is properly configured
- Check NPU device permissions and status 