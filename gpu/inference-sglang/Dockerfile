FROM lmsysorg/sglang:latest

# Set working directory
WORKDIR /workspace

# Create model directory
RUN mkdir -p /data/models

# Expose SGLang server port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command - directly launch SGLang server
CMD ["python3", "-m", "sglang.launch_server", \
     "--model", "/data/models", \
     "--tp", "1", \
     "--mem-fraction-static", "0.8", \
     "--trust-remote-code", \
     "--dtype", "bfloat16", \
     "--host", "0.0.0.0", \
     "--port", "8000"] 