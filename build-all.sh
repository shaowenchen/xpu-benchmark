#!/bin/bash

# Universal build script for GPU Inference Images
# Builds both vLLM-OpenAI and Triton Server versions

set -e

# Configuration
VLLM_IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference"
TRITON_IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference-triton"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
BUILD_VLLM=true
BUILD_TRITON=true
PUSH_IMAGE=false
NO_CACHE=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --vllm-only)
        BUILD_VLLM=true
        BUILD_TRITON=false
        shift
        ;;
    --triton-only)
        BUILD_VLLM=false
        BUILD_TRITON=true
        shift
        ;;
    --push)
        PUSH_IMAGE=true
        shift
        ;;
    --no-cache)
        NO_CACHE=true
        shift
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --vllm-only          Build only vLLM-OpenAI version"
        echo "  --triton-only        Build only Triton Server version"
        echo "  --push               Push images to registry after building"
        echo "  --no-cache           Build without using cache"
        echo "  --help, -h           Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Build both versions"
        echo "  $0 --vllm-only        # Build only vLLM-OpenAI"
        echo "  $0 --triton-only      # Build only Triton Server"
        echo "  $0 --no-cache --push  # Build both without cache and push"
        exit 0
        ;;
    *)
        log_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if nerdctl is available
    if ! command -v nerdctl &> /dev/null; then
        log_error "nerdctl is not installed or not in PATH"
        exit 1
    fi
    
    # Check if directories exist
    if [ "$BUILD_VLLM" = true ] && [ ! -d "gpu/inference" ]; then
        log_error "vLLM-OpenAI directory not found: gpu/inference"
        exit 1
    fi
    
    if [ "$BUILD_TRITON" = true ] && [ ! -d "gpu/inference-triton" ]; then
        log_error "Triton Server directory not found: gpu/inference-triton"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Build vLLM-OpenAI image
build_vllm() {
    if [ "$BUILD_VLLM" = true ]; then
        echo ""
        log_info "=== Building vLLM-OpenAI Image ==="
        
        cd gpu/inference
        
        local build_cmd="./build.sh"
        
        if [ "$NO_CACHE" = true ]; then
            build_cmd="$build_cmd --no-cache"
        fi
        
        if [ "$PUSH_IMAGE" = true ]; then
            build_cmd="$build_cmd --push"
        fi
        
        if eval "$build_cmd"; then
            log_success "vLLM-OpenAI image built successfully!"
        else
            log_error "vLLM-OpenAI image build failed"
            exit 1
        fi
        
        cd ../..
    fi
}

# Build Triton Server image
build_triton() {
    if [ "$BUILD_TRITON" = true ]; then
        echo ""
        log_info "=== Building Triton Server Image ==="
        
        cd gpu/inference-triton
        
        local build_cmd="./build.sh"
        
        if [ "$NO_CACHE" = true ]; then
            build_cmd="$build_cmd --no-cache"
        fi
        
        if [ "$PUSH_IMAGE" = true ]; then
            build_cmd="$build_cmd --push"
        fi
        
        if eval "$build_cmd"; then
            log_success "Triton Server image built successfully!"
        else
            log_error "Triton Server image build failed"
            exit 1
        fi
        
        cd ../..
    fi
}

# Show build summary
show_summary() {
    echo ""
    log_info "📋 Build Summary:"
    echo "vLLM-OpenAI build: $BUILD_VLLM"
    echo "Triton Server build: $BUILD_TRITON"
    echo "No cache: $NO_CACHE"
    echo "Push to registry: $PUSH_IMAGE"
    
    if [ "$BUILD_VLLM" = true ]; then
        echo ""
        log_info "🔧 vLLM-OpenAI Image:"
        echo "Image: $VLLM_IMAGE_NAME"
        echo "Usage: cd gpu/inference && ./run.sh --start"
    fi
    
    if [ "$BUILD_TRITON" = true ]; then
        echo ""
        log_info "🔧 Triton Server Image:"
        echo "Image: $TRITON_IMAGE_NAME"
        echo "Usage: cd gpu/inference-triton && ./run.sh --start"
    fi
    
    echo ""
    log_info "🚀 Quick Start Guide:"
    echo ""
    echo "vLLM-OpenAI (OpenAI-compatible API):"
    echo "  cd gpu/inference"
    echo "  ./run.sh --model"
    echo "  ./run.sh --start"
    echo "  ./client.sh quick"
    echo ""
    echo "Triton Server (Enterprise-grade):"
    echo "  cd gpu/inference-triton"
    echo "  ./run.sh --model"
    echo "  ./run.sh --start"
    echo "  ./client.sh quick"
}

# Main execution
main() {
    echo "=== Universal GPU Inference Image Builder ==="
    echo ""
    
    check_prerequisites
    build_vllm
    build_triton
    show_summary
    
    echo ""
    log_success "All builds completed successfully!"
}

# Run main function
main 