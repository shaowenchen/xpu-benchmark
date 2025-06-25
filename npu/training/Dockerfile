# NPU Training Dockerfile
# Use Python 3.11 slim base image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install additional useful packages for NPU training
RUN pip install --no-cache-dir \
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
    CMD python -c "import torch; print('PyTorch version:', torch.__version__)" || exit 1

# Set default command
CMD ["python", "resnet50_mindspore.py", "--config", "config.yaml", "--output", "/app/reports"] 