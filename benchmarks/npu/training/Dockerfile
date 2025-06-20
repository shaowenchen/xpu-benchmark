# NPU Training Dockerfile
# Based on Huawei Ascend NPU environment
FROM python:3.11-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV ASCEND_HOME=/usr/local/Ascend
ENV PATH=${ASCEND_HOME}/ascend-toolkit/latest/compiler/ccec_compiler/bin:${ASCEND_HOME}/ascend-toolkit/latest/compiler/bin:${ASCEND_HOME}/ascend-toolkit/latest/fwkacllib/bin:${PATH}
ENV LD_LIBRARY_PATH=${ASCEND_HOME}/ascend-toolkit/latest/fwkacllib/lib64:${ASCEND_HOME}/ascend-toolkit/latest/opp/op_impl/built-in/ai_core/tbe/op_tiling/lib/linux/aarch64:${LD_LIBRARY_PATH}

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    curl \
    htop \
    libblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    gfortran \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies with specific versions for better compatibility
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Install additional useful packages for NPU training
RUN pip3 install --no-cache-dir \
    jupyter \
    matplotlib \
    seaborn \
    pandas \
    scikit-learn \
    tensorboard \
    wandb \
    opencv-python

# Copy benchmark script and config
COPY resnet50_mindspore.py .
COPY config.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import mindspore; print('MindSpore version:', mindspore.__version__)" || exit 1

# Set default command
CMD ["python3", "resnet50_mindspore.py", "--config", "config.yaml", "--output", "/app/reports"] 