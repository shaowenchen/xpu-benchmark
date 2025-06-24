# NPU Training Dockerfile
# Use multi-arch Ubuntu base image
FROM --platform=$TARGETPLATFORM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    cmake \
    git \
    wget \
    curl \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies with specific versions for better compatibility
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Install PyTorch (CPU version for compatibility)
RUN pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Install additional useful packages for NPU training
RUN pip3 install --no-cache-dir \
    tensorboard \
    matplotlib \
    seaborn \
    pandas \
    scikit-learn \
    jupyter \
    ipykernel

# Copy benchmark script and config
COPY resnet50_mindspore.py .
COPY config.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import torch; print('PyTorch version:', torch.__version__)" || exit 1

# Set default command
CMD ["python3", "resnet50_mindspore.py", "--config", "config.yaml", "--output", "/app/reports"] 