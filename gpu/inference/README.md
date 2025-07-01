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

### 4. Start/Stop Service

```bash
# Start service in background (requires image to exist)
./build_run_test.sh --start

# Stop service
./build_run_test.sh --stop
```

Start mode will:
- Check if image exists
- Create or start container
- Wait for service to be ready
- Show container information
- Exit (service runs in background)

Stop mode will:
- Stop and remove the container
- Clean up resources

### 5. Manual Testing

If you want to test manually:

```