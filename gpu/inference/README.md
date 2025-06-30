# vLLM Testing Guide

This directory contains testing tools for the vLLM server with Qwen2.5-7B-Instruct model.

## Files

- `client.sh` - Main test client script using curl (no external dependencies)
- `vllm_server.py` - vLLM server wrapper script
- `run.sh` - Server startup script

## Quick Start

### 1. Start the vLLM Server

```bash
# Start the Docker container
docker run --rm -it \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-inference
```

### 2. Test the Server

In a new terminal, run the test client:

```bash
# Make script executable
chmod +x client.sh

# Run all tests
./client.sh
```

## Test Commands

### Basic Tests

```bash
# Health check
./client.sh health

# List available models
./client.sh models

# Simple chat completion
./client.sh chat "Hello! How are you?" 50

# Completion API
./client.sh completion "The future of AI is" 50
```

### Advanced Tests

```bash
# Run various test scenarios
./client.sh scenarios

# Performance benchmark
./client.sh benchmark 10 "Write a story about"

# Error handling tests
./client.sh errors
```

### Custom Tests

```bash
# Custom chat with specific prompt and token limit
./client.sh chat "Explain quantum computing in simple terms" 200

# Custom completion
./client.sh completion "The best way to learn programming is" 100

# Custom benchmark
./client.sh benchmark 20 "Generate a creative story about"
```

## Test Scenarios

The `scenarios` command tests various use cases:

1. **Simple Greeting** - Basic conversation
2. **Technical Question** - Complex topic explanation
3. **Creative Writing** - Poetry generation
4. **Code Generation** - Python function writing
5. **Translation** - Language translation
6. **Math Problem** - Mathematical problem solving
7. **Completion API** - Text completion

## Benchmark Testing

The benchmark test measures:

- **Total requests**: Number of requests sent
- **Successful requests**: Number of successful responses
- **Total time**: Time taken for all requests
- **Average time per request**: Mean response time
- **Throughput**: Requests per second

Example output:
```
📊 Benchmark Results:
Total requests: 5
Successful requests: 5
Total time: 12.34s
Average time per request: 2.47s
Throughput: 0.41 requests/second
```

## Error Handling

The `errors` command tests:

1. **Invalid Model Name** - Tests server response to unknown model
2. **Missing Required Fields** - Tests validation of required parameters
3. **Invalid JSON** - Tests malformed request handling

## Manual curl Commands

You can also test manually with curl:

### Health Check
```bash
curl http://localhost:8000/health
```

### Chat Completion
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

### Completion API
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

### List Models
```bash
curl http://localhost:8000/v1/models
```

## Troubleshooting

### Common Issues

1. **Server not responding**
   ```bash
   # Check if server is running
   curl http://localhost:8000/health
   
   # Check Docker container logs
   docker logs <container_id>
   ```

2. **Permission denied**
   ```bash
   # Make script executable
   chmod +x client.sh
   ```

3. **Script not working**
   ```bash
   # Check if curl is available
   which curl
   
   # Run with verbose output
   ./client.sh health
   ```

### Expected Responses

- **Health Check**: Should return HTTP 200 with server status
- **Chat Completion**: Should return HTTP 200 with generated text
- **Models**: Should return HTTP 200 with available models list
- **Invalid Requests**: Should return appropriate HTTP error codes (400, 404, etc.)

## Performance Tips

1. **Warm up the model**: Run a few requests before benchmarking
2. **Monitor GPU usage**: Use `nvidia-smi` to monitor GPU utilization
3. **Adjust batch size**: Modify `--max-num-seqs` in vLLM parameters
4. **Memory optimization**: Adjust `--gpu-memory-utilization` based on your GPU

## API Reference

The vLLM server provides OpenAI-compatible endpoints:

- `GET /health` - Server health check
- `GET /v1/models` - List available models
- `POST /v1/chat/completions` - Chat completion API
- `POST /v1/completions` - Text completion API

For detailed API documentation, see the [OpenAI API reference](https://platform.openai.com/docs/api-reference). 