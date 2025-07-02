# GPU Inference Frameworks

This directory contains implementations for three popular GPU inference frameworks:

- **vLLM**: High-performance LLM inference and serving
- **TLLM (TensorRT-LLM)**: NVIDIA's optimized LLM inference framework
- **SGLang**: Structured generation language for LLMs

## Directory Structure

```
gpu/
├── inference-vllm/          # vLLM implementation
│   ├── Dockerfile          # vLLM Docker image
│   ├── run.sh              # vLLM server management script
│   └── client.sh           # vLLM client test script
├── inference-tllm/          # TLLM implementation
│   ├── Dockerfile          # TLLM Docker image
│   ├── server.py           # TLLM server implementation
│   ├── run.sh              # TLLM server management script
│   └── client.sh           # TLLM client test script
├── inference-sglang/        # SGLang implementation
│   ├── Dockerfile          # SGLang Docker image
│   ├── server.py           # SGLang server implementation
│   ├── run.sh              # SGLang server management script
│   └── client.sh           # SGLang client test script
├── build.sh                 # Build script for all frameworks
└── README.md               # This file
```

## Prerequisites

- **nerdctl**: Container runtime (Docker alternative)
- **NVIDIA GPU**: With CUDA support
- **Git LFS**: For downloading large model files
- **jq**: For JSON parsing (optional, for better output formatting)

## Quick Start

### 1. Build Docker Images

Build all frameworks:
```bash
cd gpu
./build.sh --all
```

Or build individual frameworks:
```bash
./build.sh --vllm
./build.sh --tllm
./build.sh --sglang
```

### 2. Download Models

Download a model for testing:
```bash
# For vLLM
cd inference-vllm
./run.sh --model

# For TLLM
cd inference-tllm
./run.sh --model

# For SGLang
cd inference-sglang
./run.sh --model
```

Download multiple models concurrently:
```bash
./run.sh --concurrent \
  https://huggingface.co/Qwen/Qwen2.5-7B-Instruct \
  https://huggingface.co/meta-llama/Llama-2-7b-chat-hf
```

### 3. Start Inference Server

Start the server:
```bash
./run.sh --start
```

### 4. Test the API

Test server health:
```bash
./client.sh health
```

Test chat completion:
```bash
./client.sh chat "Hello, how are you?"
```

Test text completion:
```bash
./client.sh completion "The future of AI is"
```

List available models:
```bash
./client.sh models
```

### 5. Stop the Server

```bash
./run.sh --stop
```

## Framework Details

### vLLM

**Features:**
- High-performance LLM inference
- PagedAttention for efficient memory usage
- Continuous batching
- OpenAI-compatible API

**Default Model:** Qwen2.5-7B-Instruct

**API Endpoints:**
- `GET /health` - Health check
- `GET /v1/models` - List models
- `POST /v1/chat/completions` - Chat completion
- `POST /v1/completions` - Text completion

### TLLM (TensorRT-LLM)

**Features:**
- NVIDIA's optimized inference framework
- TensorRT acceleration
- Multi-GPU support
- Custom server implementation

**Default Model:** Qwen2.5-7B-Instruct

**API Endpoints:**
- `GET /health` - Health check
- `GET /v1/models` - List models
- `POST /v1/chat/completions` - Chat completion
- `POST /v1/completions` - Text completion

### SGLang

**Features:**
- Structured generation language
- Advanced prompting capabilities
- Efficient inference
- Custom server implementation

**Default Model:** Qwen2.5-7B-Instruct

**API Endpoints:**
- `GET /health` - Health check
- `GET /v1/models` - List models
- `POST /v1/chat/completions` - Chat completion
- `POST /v1/completions` - Text completion

## Configuration

### Environment Variables

Each framework supports the following environment variables:

- `MODEL_PATH`: Path to the model directory (default: `/model`)
- `SERVER_HOST`: Server host (default: `0.0.0.0`)
- `SERVER_PORT`: Server port (default: `8000`)

### Model Management

Models are stored in the `model/` directory within each framework directory. The structure is:

```
model/
├── Qwen2.5-7B-Instruct/    # Model files
├── Llama-2-7b-chat-hf/     # Another model
└── ...
```

## Performance Comparison

To compare performance between frameworks:

1. **Start each framework server:**
   ```bash
   # Terminal 1: vLLM
   cd inference-vllm && ./run.sh --start
   
   # Terminal 2: TLLM
   cd inference-tllm && ./run.sh --start
   
   # Terminal 3: SGLang
   cd inference-sglang && ./run.sh --start
   ```

2. **Test with the same model and prompts:**
   ```bash
   # Test vLLM
   ./client.sh chat "Generate a story about AI"
   
   # Test TLLM (on different port)
   ./client.sh --url http://localhost:8001 chat "Generate a story about AI"
   
   # Test SGLang (on different port)
   ./client.sh --url http://localhost:8002 chat "Generate a story about AI"
   ```

## Troubleshooting

### Common Issues

1. **Server won't start:**
   - Check if GPU is available: `nvidia-smi`
   - Verify nerdctl is installed: `nerdctl --version`
   - Check container logs: `nerdctl logs <container_name>`

2. **Model download fails:**
   - Ensure Git LFS is installed: `git lfs version`
   - Check network connectivity
   - Verify model URL is correct

3. **API requests fail:**
   - Check server health: `./client.sh health`
   - Verify server is running: `nerdctl ps`
   - Check server logs: `nerdctl logs <container_name>`

### Port Conflicts

If you want to run multiple frameworks simultaneously, modify the port in the `run.sh` script:

```bash
# In run.sh, change HOST_PORT
HOST_PORT=8001  # For TLLM
HOST_PORT=8002  # For SGLang
```

## Advanced Usage

### Custom Models

To use a custom model:

1. Download the model:
   ```bash
   ./run.sh --model https://huggingface.co/your-model
   ```

2. Start the server:
   ```bash
   ./run.sh --start
   ```

### Batch Testing

Create a batch test script:

```bash
#!/bin/bash
# test_all_frameworks.sh

echo "Testing vLLM..."
./client.sh chat "Test message" > vllm_results.txt

echo "Testing TLLM..."
./client.sh --url http://localhost:8001 chat "Test message" > tllm_results.txt

echo "Testing SGLang..."
./client.sh --url http://localhost:8002 chat "Test message" > sglang_results.txt
```

### Monitoring

Monitor resource usage:

```bash
# GPU usage
watch -n 1 nvidia-smi

# Container resource usage
nerdctl stats

# Server logs
nerdctl logs -f <container_name>
```

## Contributing

To add a new framework:

1. Create a new directory: `inference-<framework-name>/`
2. Add `Dockerfile` for the framework
3. Add `run.sh` for server management
4. Add `client.sh` for API testing
5. Update `build.sh` to include the new framework
6. Update this README with framework details

## License

This project is licensed under the MIT License. 