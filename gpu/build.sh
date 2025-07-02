#!/bin/bash

# Build Script for GPU Inference Frameworks
# Build Docker images for vLLM, TLLM, and SGLang

set -e

# Configuration
REGISTRY="shaowenchen"
PROJECT="xpu-benchmark"
PLATFORMS="linux/amd64,linux/arm64"

# Parse command line arguments
BUILD_VLLM=false
BUILD_TLLM=false
BUILD_SGLANG=false
BUILD_ALL=false
PUSH_IMAGES=false
PLATFORM=""

while [[ $# -gt 0 ]]; do
    case $1 in
    --vllm)
        BUILD_VLLM=true
        shift
        ;;
    --tllm)
        BUILD_TLLM=true
        shift
        ;;
    --sglang)
        BUILD_SGLANG=true
        shift
        ;;
    --all)
        BUILD_ALL=true
        shift
        ;;
    --push)
        PUSH_IMAGES=true
        shift
        ;;
    --platform)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            PLATFORM="$2"
            shift 2
        else
            shift
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [--vllm|--tllm|--sglang|--all] [--push] [--platform platform]"
        echo ""
        echo "Options:"
        echo "  --vllm                   Build vLLM image"
        echo "  --tllm                   Build TLLM image"
        echo "  --sglang                 Build SGLang image"
        echo "  --all                    Build all images"
        echo "  --push                   Push images to registry after building"
        echo "  --platform platform      Target platform (default: $PLATFORMS)"
        echo "  --help, -h               Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 --all                 # Build all images"
        echo "  $0 --vllm --push         # Build and push vLLM image"
        echo "  $0 --tllm --platform linux/amd64  # Build TLLM for AMD64 only"
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
    esac
done

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

# Build function
build_image() {
    local framework="$1"
    local context="$2"
    local tag="$3"
    
    log_info "Building $framework image..."
    log_info "Context: $context"
    log_info "Tag: $tag"
    
    # Set platform
    local build_platform=""
    if [ -n "$PLATFORM" ]; then
        build_platform="--platform $PLATFORM"
    else
        build_platform="--platform $PLATFORMS"
    fi
    
    # Build command
    local build_cmd="nerdctl build $build_platform -t $tag $context"
    
    log_info "Build command: $build_cmd"
    
    if eval "$build_cmd"; then
        log_success "$framework image built successfully"
        
        # Push if requested
        if [ "$PUSH_IMAGES" = true ]; then
            log_info "Pushing $framework image..."
            if nerdctl push "$tag"; then
                log_success "$framework image pushed successfully"
            else
                log_error "Failed to push $framework image"
                return 1
            fi
        fi
        
        return 0
    else
        log_error "Failed to build $framework image"
        return 1
    fi
}

# Check if nerdctl is available
check_nerdctl() {
    if ! command -v nerdctl >/dev/null 2>&1; then
        log_error "nerdctl is not installed or not in PATH"
        log_info "Please install nerdctl first: https://github.com/containerd/nerdctl"
        exit 1
    fi
    
    log_info "Using nerdctl: $(nerdctl --version)"
}

# Check if buildx is available
check_buildx() {
    if ! nerdctl buildx ls >/dev/null 2>&1; then
        log_warning "buildx not available, falling back to single platform builds"
        PLATFORM=""
    else
        log_info "buildx is available for multi-platform builds"
    fi
}

# Main execution
main() {
    log_info "=== GPU Inference Framework Build Script ==="
    
    # Check prerequisites
    check_nerdctl
    check_buildx
    
    # Determine what to build
    if [ "$BUILD_ALL" = true ]; then
        BUILD_VLLM=true
        BUILD_TLLM=true
        BUILD_SGLANG=true
    fi
    
    if [ "$BUILD_VLLM" = false ] && [ "$BUILD_TLLM" = false ] && [ "$BUILD_SGLANG" = false ]; then
        log_error "No framework specified for building"
        echo "Use --help for usage information"
        exit 1
    fi
    
    # Build images
    local build_failed=false
    
    if [ "$BUILD_VLLM" = true ]; then
        if ! build_image "vLLM" "gpu/inference-vllm" "$REGISTRY/$PROJECT:gpu-inference-vllm"; then
            build_failed=true
        fi
    fi
    
    if [ "$BUILD_TLLM" = true ]; then
        if ! build_image "TLLM" "gpu/inference-tllm" "$REGISTRY/$PROJECT:gpu-inference-tllm"; then
            build_failed=true
        fi
    fi
    
    if [ "$BUILD_SGLANG" = true ]; then
        if ! build_image "SGLang" "gpu/inference-sglang" "$REGISTRY/$PROJECT:gpu-inference-sglang"; then
            build_failed=true
        fi
    fi
    
    # Summary
    echo ""
    log_info "=== Build Summary ==="
    
    if [ "$build_failed" = true ]; then
        log_error "Some builds failed"
        exit 1
    else
        log_success "All requested builds completed successfully"
        
        if [ "$PUSH_IMAGES" = true ]; then
            log_success "All images pushed to registry"
        fi
        
        echo ""
        log_info "Available images:"
        nerdctl images | grep "$REGISTRY/$PROJECT" || log_warning "No images found"
    fi
}

# Run main function
main 