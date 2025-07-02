FROM nvcr.io/nvidia/tritonserver:25.01-vllm-python-py3

# Set working directory
WORKDIR /workspace

# Install additional dependencies if needed
RUN pip install --no-cache-dir \
    requests \
    numpy \
    pandas

# Copy model configuration and scripts
COPY model_repository/ /opt/tritonserver/model_repository/
COPY scripts/ /workspace/scripts/

# Set environment variables
ENV TRITON_MODEL_REPO=/opt/tritonserver/model_repository
ENV TRITON_SERVER_ARGS="--model-repository=${TRITON_MODEL_REPO} --log-verbose=1"

# Expose Triton Server ports
EXPOSE 8000 8001 8002

# Default command
CMD ["tritonserver", "--model-repository=/opt/tritonserver/model_repository"] 