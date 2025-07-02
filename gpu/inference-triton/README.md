# GPU Inference with NVIDIA Triton Server

This directory contains scripts for running GPU inference using NVIDIA Triton Server with vLLM backend.

## Overview

This implementation uses NVIDIA Triton Server with the vLLM Python backend to serve large language models for inference. Triton Server provides enterprise-grade serving capabilities with features like:

- Model versioning and management
- Dynamic batching
- Concurrent model execution
- GPU memory optimization
- Metrics and monitoring
- REST and gRPC APIs

## Prerequisites

- NVIDIA GPU with CUDA support
- Docker or nerdctl
- Git LFS
- At least 16GB GPU memory (for 7B models)

## Quick Start

### 1. Build the Docker Image

```bash
cd gpu/inference-triton
./build.sh
```

### 2. Download a Model

```bash
# Download default model (Qwen2.5-7B-Instruct)
./run.sh --model

# Download custom model
./run.sh --model https://huggingface.co/microsoft/DialoGPT-medium

# Download multiple models concurrently
./run.sh --concurrent \
  https://huggingface.co/Qwen/Qwen2.5-7B-Instruct \
  https://huggingface.co/microsoft/DialoGPT-medium
```

### 3. Start Triton Server

```bash
./run.sh --start
```

### 4. Test the Service

```bash
# Quick test
./client.sh quick

# Full test suite
./client.sh all

# Test specific model
./client.sh --model Qwen2.5-7B-Instruct quick
```

### 5. Stop the Service

```bash
./run.sh --stop
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Client.sh     │───▶│  Triton Server   │───▶│  vLLM Backend   │
│   (Test Client) │    │  (Port 8000)     │    │  (GPU Inference)│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌──────────────────┐
                       │ Model Repository │
                       │ (model_repository)│
                       └──────────────────┘
```

## Configuration

### Model Repository Structure

```
model_repository/
├── Qwen2.5-7B-Instruct/
│   ├── config/
│   │   └── config.pbtxt          # Triton model configuration
│   ├── 1/
│   │   └── model.py              # vLLM model files
│   └── ...                       # Model weights and configs
└── DialoGPT-medium/
    ├── config/
    │   └── config.pbtxt
    └── ...
```

### Triton Model Configuration

The `config.pbtxt` file is automatically generated with the following settings:

```protobuf
name: "Qwen2.5-7B-Instruct"
platform: "vllm"
max_batch_size: 8

input [
  {
    name: "prompt"
    data_type: TYPE_STRING
    dims: [ -1 ]
  }
]

output [
  {
    name: "text"
    data_type: TYPE_STRING
    dims: [ -1 ]
  }
]

instance_group [
  {
    count: 1
    kind: KIND_GPU
  }
]

parameters [
  {
    key: "model_path"
    value: {string_value: "/opt/tritonserver/model_repository/Qwen2.5-7B-Instruct"}
  },
  {
    key: "tensor_parallel_size"
    value: {string_value: "1"}
  },
  {
    key: "max_model_len"
    value: {string_value: "2048"}
  },
  {
    key: "gpu_memory_utilization"
    value: {string_value: "0.9"}
  }
]
```

## API Endpoints

### Health Check
```bash
curl http://localhost:8000/v2/health/ready
```

### List Models
```bash
curl http://localhost:8000/v2/models
```

### Model Metadata
```bash
curl http://localhost:8000/v2/models/Qwen2.5-7B-Instruct/config
```

### Inference
```bash
curl -X POST http://localhost:8000/v2/models/Qwen2.5-7B-Instruct/infer \
  -H "Content-Type: application/json" \
  -d '{
    "inputs": [
      {
        "name": "prompt",
        "shape": [1],
        "datatype": "BYTES",
        "data": ["Hello, how are you?"]
      }
    ],
    "outputs": [
      {
        "name": "text",
        "shape": [1],
        "datatype": "BYTES"
      }
    ]
  }'
```

## Client Script Usage

### Basic Commands

```bash
# Health check
./client.sh health

# Model inference
./client.sh inference "Hello, world!" 100

# Model metadata
./client.sh metadata

# List available models
./client.sh models

# Quick test
./client.sh quick

# Full test suite
./client.sh all
```

### Advanced Usage

```bash
# Test specific model
./client.sh --model Qwen2.5-7B-Instruct quick

# Custom server URL
./client.sh --url http://192.168.1.100:8000 health

# Benchmark test
./client.sh --model Qwen2.5-7B-Instruct benchmark 10

# Test scenarios
./client.sh --model Qwen2.5-7B-Instruct scenarios
```

## Performance Tuning

### GPU Memory Optimization

Adjust the `gpu_memory_utilization` parameter in the model configuration:

```protobuf
parameters [
  {
    key: "gpu_memory_utilization"
    value: {string_value: "0.8"}  # Use 80% of GPU memory
  }
]
```

### Batch Size Configuration

Modify `max_batch_size` in the model configuration:

```protobuf
max_batch_size: 16  # Increase for better throughput
```

### Tensor Parallelism

For multi-GPU setups, adjust `tensor_parallel_size`:

```protobuf
parameters [
  {
    key: "tensor_parallel_size"
    value: {string_value: "2"}  # Use 2 GPUs
  }
]
```

## Monitoring

### Metrics Endpoint
```bash
curl http://localhost:8002/metrics
```

### Container Logs
```bash
nerdctl logs xpu-benchmark-gpu-inference-triton
```

### Health Monitoring
```bash
# Check container status
nerdctl ps | grep xpu-benchmark-gpu-inference-triton

# Monitor GPU usage
nvidia-smi
```

## Troubleshooting

### Common Issues

1. **Model Loading Failed**
   - Check GPU memory availability
   - Verify model files are complete
   - Check Triton Server logs

2. **Port Already in Use**
   - Stop existing containers: `./run.sh --stop`
   - Check for other services using port 8000

3. **GPU Memory Issues**
   - Reduce `gpu_memory_utilization` parameter
   - Use smaller models
   - Close other GPU applications

4. **Model Not Found**
   - Verify model is downloaded: `ls model_repository/`
   - Check model configuration: `cat model_repository/*/config/config.pbtxt`

### Debug Mode

Enable verbose logging by modifying the Dockerfile:

```dockerfile
ENV TRITON_SERVER_ARGS="--model-repository=${TRITON_MODEL_REPO} --log-verbose=1 --log-info=1"
```

## Comparison with vLLM-OpenAI

| Feature | vLLM-OpenAI | Triton Server |
|---------|-------------|---------------|
| API Compatibility | OpenAI-compatible | Triton Inference API |
| Model Management | Single model | Multi-model support |
| Batching | Dynamic batching | Advanced batching |
| Monitoring | Basic | Enterprise-grade |
| Scalability | Single instance | Multi-instance |
| Production Ready | Good | Excellent |

## License

This project is licensed under the MIT License. 