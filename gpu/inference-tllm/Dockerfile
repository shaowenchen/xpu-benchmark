FROM nvcr.io/nvidia/tensorrt-llm/release:0.20.0

# Set working directory
WORKDIR /workspace

# Create model directory
RUN mkdir -p /data/models

# Set environment variables
ENV TLLM_MODEL_PATH=/data/models
ENV TLLM_SERVER_ARGS="--model /data/models --host 0.0.0.0 --port 8000"

# Expose TLLM server port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

COPY extra-llm-api-config.yml /etc/extra-llm-api-config.yml

# Default command using trtllm-serve
CMD ["trtllm-serve", \
     "/data/models", \
     "--host", "0.0.0.0", \
     "--port", "8000", \
     "--backend", "pytorch", \
     "--max_batch_size", "128", \
     "--max_num_tokens", "16384", \
     "--kv_cache_free_gpu_memory_fraction", "0.95", \
     "--extra_llm_api_options", "/etc/extra-llm-api-config.yml"] 