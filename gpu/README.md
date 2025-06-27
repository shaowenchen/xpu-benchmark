## Quick Start

### alias docker to nerdctl

```bash
if command -v nerdctl >/dev/null 2>&1; then
  echo "Found nerdctl, aliasing docker to nerdctl"
  alias docker='nerdctl'
else
  echo "nerdctl not found, using docker as is"
fi
```

### inference

```bash
docker run --rm -it \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \
  shaowenchen/xpu-benchmark:gpu-inference \
  python3 run_benchmark.py \
  --model_name resnet50 \
  --precision fp32 \
  --mode inference \
  --batch_size 128 \
  --data_path /app/data/imagenet
```

### training

```bash
docker run --rm \
  -v $(pwd)/reports:/app/reports \
  -v $(pwd)/config:/app/config \