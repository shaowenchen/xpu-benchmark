# GPU Training Dockerfile
FROM nvidia/cuda:11.8-devel-ubuntu20.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    htop \
    nvtop \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.txt

# Copy benchmark script and config
COPY resnet50_pytorch.py .
COPY ../../../config/gpu/nvidia.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Set default command
CMD ["python3", "resnet50_pytorch.py", "--config", "config.yaml", "--output", "/app/reports"] 