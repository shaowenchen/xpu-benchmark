# NPU Inference Benchmark

This directory contains the NPU (Neural Processing Unit) inference benchmark for Huawei Ascend NPU using MindSpore framework.

## Features

- **BERT Model Inference**: Benchmark BERT model inference performance on Ascend NPU
- **Model Parameter Support**: Support for custom model paths with `--model` parameter
- **Metrics Collection**: Collect NPU and system metrics during inference
- **Docker Support**: Containerized execution environment

## Quick Start

### Prerequisites

- Python 3.7+
- MindSpore (for Ascend NPU)
- Docker (optional)

### Basic Usage

1. **List available models**:
   ```bash
   ./run.sh --list
   ```

2. **Using custom model**:
   ```bash
   ./run.sh --model /path/to/your/model
   ```

3. **Using default Qwen3-0.6B-Base model**:
   ```bash
   ./run.sh --model /data/models/Qwen3-0.6B-Base
   ```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--model model_path` | Path to the model directory | `/data/models/Qwen3-0.6B-Base` |
| `--list` | List models in /data directory | - |
| `--help`, `-h` | Show help message | - |

### Examples

```bash
# List available models
./run.sh --list

# Use custom model path
./run.sh --model /data/models/custom-model

# Use specific model
./run.sh --model /data/models/Qwen3-0.6B-Base

# Show help
./run.sh --help
```

## Docker Usage

### Build Image

```bash
docker build -t npu-inference .
```

### Run Container

```bash
# Use default model
docker run -it --rm npu-inference

# Use custom model
docker run -it --rm -v /path/to/models:/data/models npu-inference --model /data/models/custom-model
```

## Configuration

The benchmark configuration is defined in `config.yaml`:

```yaml
benchmarks:
  inference:
    bert_mindspore:
      enabled: true
      batch_size: 1
      sequence_length: 512
      model_path: "/data/models/Qwen3-0.6B-Base"  # Default model path
      iterations: 1000
```

## Model Structure

Models should be placed in the `/data/models/` directory:

```
/data/models/
├── Qwen3-0.6B-Base/        # Default model
├── custom-model/           # Custom model
└── ...
```

## Output

The benchmark generates:

- **JSON Results**: Detailed metrics and performance data
- **Console Output**: Real-time progress and summary
- **Logs**: Execution logs and error messages

### Sample Output

```
=== BERT MindSpore Inference Benchmark ===
Model path: /data/models/Qwen3-0.6B-Base
Creating BERT model from: /data/models/Qwen3-0.6B-Base
✅ Model path exists: /data/models/Qwen3-0.6B-Base
Starting inference: 1000 iterations
...
Benchmark completed!
Model used: /data/models/Qwen3-0.6B-Base
Total time: 45.23s
Average inference time: 0.0452s
Average throughput: 22.12 samples/s
```

## Troubleshooting

### Common Issues

1. **Model path not found**:
   ```
   ⚠️  Model path does not exist: /data/models/Qwen3-0.6B-Base
   Creating a simplified BERT-like model for demonstration
   ```
   - Ensure the model directory exists
   - Check file permissions
   - Verify the path is correct

2. **MindSpore not available**:
   ```
   MindSpore not available, creating mock model
   ```
   - Install MindSpore for Ascend NPU
   - Follow Huawei's official installation guide

3. **NPU not detected**:
   ```
   Warning: npu-smi not available, Ascend NPU status unknown
   ```
   - Install NPU drivers
   - Configure Ascend environment

### Testing

Run the test script to verify functionality:

```bash
./test_model_param.sh
```

## Performance Tuning

### Configuration Parameters

- `batch_size`: Adjust based on NPU memory
- `sequence_length`: Modify for different input sizes
- `iterations`: Increase for more accurate measurements

### Model Optimization

- Use quantized models for better performance
- Optimize model architecture for NPU
- Consider mixed precision inference

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License. 