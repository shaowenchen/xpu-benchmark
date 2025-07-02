FROM vllm/vllm-openai:v0.9.1

# Set working directory
WORKDIR /workspace

# Install additional dependencies
RUN pip install --no-cache-dir \
    requests \
    numpy \
    pandas \
    openai

# Create model directory
RUN mkdir -p /data/models

# Set environment variables
ENV VLLM_MODEL_PATH=/data/models
ENV VLLM_SERVER_ARGS="--model /data/models --host 0.0.0.0 --port 8000"

# Expose vLLM server port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command
CMD ["python", "-m", "vllm.entrypoints.openai.api_server", "--model", "/data/models", "--host", "0.0.0.0", "--port", "8000"]