FROM pytorch/pytorch:2.7.1-cuda12.6-cudnn9-runtime

# Set working directory
WORKDIR /workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python packages
RUN pip install --no-cache-dir \
    torchvision \
    numpy \
    tqdm \
    Pillow

# Create directories
RUN mkdir -p /data/datasets /data/models /data/logs

# Copy training scripts
COPY train_resnet50.py /workspace/
COPY benchmark.py /workspace/

# Set environment variables
ENV PYTHONPATH=/workspace:$PYTHONPATH
ENV TORCH_HOME=/data/models
ENV CUDA_VISIBLE_DEVICES=0

# Expose ports for tensorboard and jupyter
EXPOSE 6006 8888

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA available:', torch.cuda.is_available())" || exit 1

# Default command
CMD ["python", "train_resnet50.py"]