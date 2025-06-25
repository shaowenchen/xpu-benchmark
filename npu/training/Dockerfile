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
# Copy benchmark script and config
COPY resnet50_mindspore.py .
COPY config.yaml ./config.yaml

# Create output directory
RUN mkdir -p /app/reports

# Set default command
CMD ["python", "resnet50_mindspore.py", "--config", "config.yaml", "--output", "/app/reports"] 