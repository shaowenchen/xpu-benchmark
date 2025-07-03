FROM lmsysorg/sglang:v0.4.8-cu126

# Set working directory
WORKDIR /workspace

# Create model directory
RUN mkdir -p /data/models

# Set environment variables
ENV SGLANG_MODEL_PATH=/data/models
ENV SGLANG_HOST=0.0.0.0
ENV SGLANG_PORT=8000
ENV SGLANG_TP=1
ENV SGLANG_MEM_FRACTION=0.8

# Expose SGLang server port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Default command - directly launch SGLang server
CMD ["python3", "-m", "sglang.launch_server", \
     "--model", "${SGLANG_MODEL_PATH}", \
     "--tp", "${SGLANG_TP}", \
     "--mem-fraction-static", "${SGLANG_MEM_FRACTION}", \
     "--trust-remote-code", \
     "--dtype", "bfloat16", \
     "--host", "${SGLANG_HOST}", \
     "--port", "${SGLANG_PORT}"] 