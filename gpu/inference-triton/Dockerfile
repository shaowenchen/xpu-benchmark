FROM nvcr.io/nvidia/tritonserver:25.01-vllm-python-py3

# Set working directory
WORKDIR /workspace

# Install additional dependencies if needed
RUN pip install --no-cache-dir \
    requests \
    numpy \
    pandas \
    tritonclient[all]

# Create model repository directory
RUN mkdir -p /opt/tritonserver/model_repository

# Set environment variables
ENV TRITON_MODEL_REPO=/opt/tritonserver/model_repository
ENV TRITON_SERVER_ARGS="--model-repository=${TRITON_MODEL_REPO} --log-verbose=1 --log-info=1"

# Expose Triton Server ports
# 8000: HTTP/REST API
# 8001: gRPC API  
# 8002: Metrics
EXPOSE 8000 8001 8002

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/v2/health/ready || exit 1

# Default command
CMD ["tritonserver", "--model-repository=/opt/tritonserver/model_repository", "--log-verbose=1"] 