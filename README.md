# Quick Start

## GPU

[README](./gpu/README.md)

## NPU

[README](./npu/README.md)

## CPU

[README](./cpu/README.md)

## Recent Updates

### GPU Inference - vLLM with Qwen2.5-7B-Instruct (Latest)

**Major Update**: GPU inference has been completely redesigned to use **vLLM** for high-performance LLM inference with the **Qwen2.5-7B-Instruct** model from [ModelScope](https://www.modelscope.cn/models/Qwen/Qwen2.5-7B-Instruct/).

**Key Changes**:
- ✅ Replaced BERT inference with vLLM server
- ✅ Added Qwen2.5-7B-Instruct model support
- ✅ OpenAI-compatible REST API
- ✅ High-performance inference with PagedAttention
- ✅ Automatic performance monitoring
- ✅ Multi-GPU support
- ✅ Real-time metrics collection
- ✅ **Direct vLLM command execution** (no config files)

**New Features**:
- **Model**: Qwen2.5-7B-Instruct (7B parameters)
- **Framework**: vLLM (High-performance LLM inference)
- **API**: OpenAI-compatible endpoints
- **Performance**: PagedAttention for efficient memory usage
- **Monitoring**: Real-time GPU and system metrics
- **Command**: Direct vLLM serve command with optimized parameters

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

**Usage**:
```bash
docker run --rm -it \
  --gpus all \
  -p 8000:8000 \
  -v $(pwd)/reports:/app/reports \
  shaowenchen/xpu-benchmark:gpu-inference
```

### Configuration Structure Fix

Fixed the configuration file structure mismatch that was causing `KeyError: 'benchmarks'`:

**Problem**: Python scripts expected config structure:
```yaml
benchmarks:
  inference:
    bert_tf_serving:
      # config...
```

**But actual config files had**:
```yaml
inference:
  bert_tf_serving:
    # config...
```

**Solution**: Updated all config files to include the `benchmarks` wrapper level:
- `gpu/inference/config.yaml` (now replaced with direct vLLM command)
- `gpu/training/config.yaml` 
- `gpu/stress/config.yaml`
- `npu/inference/config.yaml`
- `npu/training/config.yaml`
- `npu/stress/config.yaml`

### Docker Command Fixes

- Fixed GPU Docker commands to remove incorrect parameters
- Added `--gpus all` flag for proper GPU access
- Ensured commands match Dockerfile CMD entries
- Added advanced usage examples
