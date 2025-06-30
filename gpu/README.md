## Quick Start

### prepare

```bash
if command -v nerdctl >/dev/null 2>&1; then
  echo "Found nerdctl, aliasing docker to nerdctl"
  alias docker='nerdctl'
else
  echo "nerdctl not found, using docker as is"
fi
```

### inference (vLLM with Qwen2.5-7B-Instruct)

```bash
docker run --rm -it \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-inference
```

The inference container now uses **vLLM** to serve the **Qwen2.5-7B-Instruct** model from [ModelScope](https://www.modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct/).

**Direct vLLM Command Used**:
```bash
CUDA_VISIBLE_DEVICES=1 \
vllm serve /model/Qwen2.5-7B-Instruct \
    --served-model-name Qwen2.5-7B-Instruct \
    --port 8000 \
    --enable-prefix-caching \
    --gpu-memory-utilization 0.90 \
    --max-model-len 4096 \
    --max-seq-len-to-capture 8192 \
    --max-num-seqs 128 \
    --disable-log-stats \
    --enforce-eager
```

### training

```bash
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-training
```

### stress

```bash
docker run --rm \
  --gpus all \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-stress
```

## vLLM Inference Features

### Model Information
- **Model**: Qwen2.5-7B-Instruct
- **Source**: [ModelScope](https://www.modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct/)
- **Framework**: vLLM (High-performance LLM inference)
- **API**: OpenAI-compatible REST API

### vLLM Parameters
- **GPU**: CUDA_VISIBLE_DEVICES=1
- **Model Path**: /model/Qwen2.5-7B-Instruct
- **Port**: 8000
- **GPU Memory Utilization**: 0.90 (90%)
- **Max Model Length**: 4096 tokens
- **Max Sequence Length to Capture**: 8192 tokens
- **Max Number of Sequences**: 128
- **Prefix Caching**: Enabled
- **Log Stats**: Disabled
- **Enforce Eager**: Enabled

### API Endpoints
Once the container is running, the vLLM server will be available at:
- **Health Check**: `http://localhost:8000/health`
- **Chat Completions**: `http://localhost:8000/v1/chat/completions`
- **Completions**: `http://localhost:8000/v1/completions`
- **Models**: `http://localhost:8000/v1/models`

## Testing with curl

### Using the Test Client Script

A comprehensive test client script is included for testing the vLLM server:

```bash
# Make script executable
chmod +x gpu/inference/client.sh

# Run all tests
./gpu/inference/client.sh

# Test specific functionality
./gpu/inference/client.sh health
./gpu/inference/client.sh chat "Hello! How are you?" 50
./gpu/inference/client.sh completion "The future of AI is" 50
./gpu/inference/client.sh models
./gpu/inference/client.sh benchmark 10 "Write a story about"
./gpu/inference/client.sh scenarios
./gpu/inference/client.sh errors
```

### Test Commands

#### Health Check
```bash
curl http://localhost:8000/health
```

#### Chat Completion
```bash
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen2.5-7B-Instruct",
    "messages": [
      {"role": "user", "content": "Hello! What can you do?"}
    ],
    "max_tokens": 100,
    "temperature": 0.7
  }'
```

#### Completion API
```bash
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen2.5-7B-Instruct",
    "prompt": "The future of artificial intelligence is",
    "max_tokens": 50,
    "temperature": 0.7
  }'
```

#### List Models
```bash
curl http://localhost:8000/v1/models
```

### Example Usage

#### Using OpenAI Client
```python
from openai import OpenAI

client = OpenAI(base_url="http://localhost:8000", api_key="dummy")

response = client.chat.completions.create(
    model="Qwen2.5-7B-Instruct",
    messages=[
        {"role": "user", "content": "Hello! What can you do?"}
    ],
    max_tokens=100,
    temperature=0.7
)

print(response.choices[0].message.content)
```

## Advanced Usage

### Custom GPU Selection

```bash
docker run --rm \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  -e CUDA_VISIBLE_DEVICES=0 \
  shaowenchen/xpu-benchmark:gpu-inference
```

### Custom Model Path

```bash
docker run --rm \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/models:/model \
  shaowenchen/xpu-benchmark:gpu-inference
```

### Custom Port

```bash
docker run --rm \
  --gpus all \
  -p 8001:8000 \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-inference
```

### Resource Limits

```bash
docker run --rm \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  --memory=32g \
  --cpus=8 \
  --shm-size=8g \
  shaowenchen/xpu-benchmark:gpu-inference
```

### Interactive Mode

```bash
docker run -it --rm \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-inference /bin/bash
```

## Performance Monitoring

The vLLM server automatically collects and saves performance metrics:
- GPU utilization and memory usage
- System CPU and memory usage
- Request latency and throughput
- Model loading and inference times

Metrics are saved to `/app/reports/vllm_metrics_*.json` in the container.

## Troubleshooting

### Common Issues

#### Model Loading Issues
```bash
# Check GPU memory
nvidia-smi

# Verify model path
ls -la /model/Qwen2.5-7B-Instruct/
```

#### Port Already in Use
```bash
# Use different port
docker run --rm -it \
  --gpus all \
  -p 8001:8000 \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-inference
```

#### Memory Issues
```bash
# Reduce GPU memory utilization
docker run --rm -it \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  -e CUDA_VISIBLE_DEVICES=1 \
  shaowenchen/xpu-benchmark:gpu-inference
```

#### GPU Selection
```bash
# Use different GPU
docker run --rm -it \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  -e CUDA_VISIBLE_DEVICES=0 \
  shaowenchen/xpu-benchmark:gpu-inference
```

#### Testing Issues
```bash
# Check if server is running
curl http://localhost:8000/health

# Check server logs
docker logs <container_id>

# Run test client with verbose output
./gpu/inference/client.sh health
```

