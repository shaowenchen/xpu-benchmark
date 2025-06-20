# NPU Training Dockerfile
# Based on Huawei Ascend NPU environment
FROM ubuntu:20.04

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
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir -r requirements.txt

# Copy benchmark script and config
COPY resnet50_mindspore.py .
COPY ../../../config/npu/ascend.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Set default command
CMD ["python3", "resnet50_mindspore.py", "--config", "config.yaml", "--output", "/app/reports"] 