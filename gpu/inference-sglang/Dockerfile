FROM nvcr.io/nvidia/pytorch:24.01-py3

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install SGLang and dependencies
RUN pip install --no-cache-dir \
    sglang \
    transformers \
    accelerate \
    requests \
    numpy \
    pandas \
    flask \
    flask-cors \
    fastapi \
    uvicorn

# Create model directory
RUN mkdir -p /model

# Set environment variables
ENV SGLANG_MODEL_PATH=/model
ENV SGLANG_SERVER_ARGS="--model /model --host 0.0.0.0 --port 8000"

# Expose SGLang server port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Copy server script
COPY server.py /workspace/server.py

# Default command
CMD ["python", "/workspace/server.py"] 