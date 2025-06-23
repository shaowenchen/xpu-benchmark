# NPU Stress Test Dockerfile
# Use Huawei MindSpore official image
FROM mindspore/mindspore-cpu:2.2.0

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    htop \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies with specific versions for better compatibility
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Install additional useful packages for NPU stress testing
RUN pip3 install --no-cache-dir \
    psutil \
    matplotlib \
    seaborn \
    pandas \
    numpy \
    scipy

# Copy benchmark script and config
COPY memory_bandwidth.py .
COPY config.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import mindspore; print('MindSpore version:', mindspore.__version__)" || exit 1

# Set default command
CMD ["python3", "memory_bandwidth.py", "--config", "config.yaml", "--output", "/app/reports"] 