FROM nvidia/cuda:12.3.2-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies first (this layer rarely changes)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        cmake \
        git \
        wget \
        curl \
        htop \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean

# Configure pip (this layer rarely changes)
RUN pip3 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# Upgrade pip tools (this layer rarely changes)
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel

# Set working directory
WORKDIR /app

# Copy requirements first to leverage Docker layer caching
# This layer will be cached unless requirements.txt changes
COPY requirements.txt .

# Install Python dependencies (this layer will be cached if requirements.txt doesn't change)
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy application code (this layer changes most frequently)
COPY vllm_server.py .

# Create output directory
RUN mkdir -p /app/reports

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())" || exit 1

CMD ["python3", "vllm_server.py", "--model-path", "/model/Qwen2.5-7B-Instruct", "--cuda-visible-devices", "1", "--port", "8000"] 