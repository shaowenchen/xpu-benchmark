# vLLM GPU Inference Testing

This directory contains simplified testing scripts for the vLLM server running on GPU.

## Requirements

- `nerdctl` - Container runtime tool
- `curl` - HTTP client (usually pre-installed)
- GPU with CUDA support

## Quick Start

### 1. Build and Test (Default)

```bash
# Build image and run all tests (default behavior)
./build_run_test.sh
```

### 2. Build Only

```bash
# Build only, don't run tests
./build_run_test.sh --build-only
```

### 3. Test Only

```bash
# Test only, skip build (assumes image exists)
./build_run_test.sh --test-only
```

### 4. Service Mode

```bash
# Build, test, and keep service running
./build_run_test.sh --serve
```

This mode will:
- Build the image (if needed)
- Run tests
- Keep the container running
- Show service status and useful commands
- Wait for Ctrl+C to stop the service

### 4. Manual Testing

If you want to test manually:

```bash
# Build the image
nerdctl build -t xpu-benchmark:gpu-inference .

# Run the container
nerdctl run -d \
  --name xpu-benchmark-test \
  --gpus all \
  -p 8000:8000 \
  xpu-benchmark:gpu-inference

# Test the server
./client.sh health
./client.sh chat "Hello, how are you?" 50
./client.sh completion "The future of AI is" 50
./client.sh models

# Stop the container
nerdctl stop xpu-benchmark-test
nerdctl rm xpu-benchmark-test
```

## Client Script Usage

The `client.sh` script supports various test commands:

```bash
# Health check
./client.sh health

# Chat completion
./client.sh chat "Your prompt here" 100

# Text completion
./client.sh completion "Your prompt here" 50

# List available models
./client.sh models

# Run benchmark test
./client.sh benchmark 10 "Generate a story"

# Run all test scenarios
./client.sh scenarios

# Test error handling
./client.sh errors

# Run all tests
./client.sh all
```

## Features

- **Simplified Dependencies**: Only requires `nerdctl` and `curl`
- **No External Tools**: No need for `jq`, `bc`, or other external dependencies
- **Flexible Options**: Control build and test steps separately
- **Service Mode**: Keep service running for manual testing and inspection
- **Comprehensive Testing**: Tests health, models, chat completion, and completion APIs
- **Error Handling**: Tests various error scenarios
- **Benchmarking**: Performance testing with multiple requests
- **Automatic Reports**: Generates test reports in `../reports/` directory

## Troubleshooting

1. **nerdctl not found**: Install nerdctl following the official documentation
2. **GPU not available**: Ensure your system has GPU with CUDA support
3. **Port 8000 in use**: Change the port in the scripts or stop other services using port 8000
4. **Container fails to start**: Check the logs with `nerdctl logs xpu-benchmark-test`

## Test Reports

Test reports are automatically generated in the `../reports/` directory with timestamps. Each report includes:

- Test results for all endpoints
- Success/failure status
- Response logs
- Overall test summary 