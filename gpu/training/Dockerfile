# GPU Training Dockerfile
# Use official Python image with CUDA support
FROM python:3.11-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Install system dependencies and CUDA toolkit
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    htop \
    nvtop \
    nvidia-cuda-toolkit \
    nvidia-cuda-dev \
    libcudnn8 \
    libcudnn8-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies with specific versions for better compatibility
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Install additional useful packages
RUN pip3 install --no-cache-dir \
    jupyter \
    matplotlib \
    seaborn \
    pandas \
    scikit-learn \
    tensorboard \
    wandb

# Copy benchmark script and config
COPY resnet50_pytorch.py .
COPY config.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())" || exit 1

# Set default command
CMD ["python3", "resnet50_pytorch.py", "--config", "config.yaml", "--output", "/app/reports"] 