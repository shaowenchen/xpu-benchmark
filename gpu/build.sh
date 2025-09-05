#!/bin/bash

# Build Script for GPU Inference Frameworks
# Build Docker images for vLLM, TLLM, and SGLang

set -e

# Configuration
REGISTRY="shaowenchen"
PROJECT="xpu-benchmark"

# Parse command line arguments
BUILD_VLLM=false
BUILD_TLLM=false
BUILD_SGLANG=false
BUILD_TRAINING=false
BUILD_ALL=false
BUILD_IMAGES=false
PUSH_IMAGES=false

while [[ $# -gt 0 ]]; do
    case $1 in
    vllm)
        BUILD_VLLM=true
        shift
        ;;
    tllm)
        BUILD_TLLM=true
        shift
        ;;
    sglang)
        BUILD_SGLANG=true
        shift
        ;;
    training)
        BUILD_TRAINING=true
        shift
        ;;
    all)
        BUILD_ALL=true
        shift
        ;;
    --build)
        BUILD_IMAGES=true
        shift
        ;;
    --push)
        PUSH_IMAGES=true
        shift
        ;;
    --help|-h)
        echo "Usage: $0 [vllm|tllm|sglang|training|all] [--build] [--push]"
        echo ""
        echo "Options:"
        echo "  vllm                     Select vLLM framework"
        echo "  tllm                     Select TLLM framework"
        echo "  sglang                   Select SGLang framework"
        echo "  training                 Select training framework"
        echo "  all                      Select all frameworks"
        echo "  --build                  Build the selected images"
        echo "  --push                   Push images to registry"
        echo "  --help, -h               Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 all --build           # Build all images"
        echo "  $0 training --build      # Build training image"
        echo "  $0 vllm --build --push   # Build and push vLLM image"
        echo "  $0 all --push            # Push all existing images"
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

# Detect container tool
detect_container_tool() {
    if command -v nerdctl &> /dev/null; then
        echo "nerdctl"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        log_error "Neither nerdctl nor docker found. Please install one of them."
        exit 1
    fi
}

# Build function
build_image() {
    local framework="$1"
    local context="$2"
    local tag="$3"
    
    log_info "Building $framework image..."
    log_info "Context: $context"
    log_info "Tag: $tag"
    
    # Build command
    local build_cmd="$CONTAINER_TOOL build -f $context/Dockerfile -t $tag $context"
    
    log_info "Build command: $build_cmd"
    
    if eval "$build_cmd"; then
        log_success "$framework image built successfully"
        
        # Push if requested and building
        if [ "$PUSH_IMAGES" = true ] && [ "$BUILD_IMAGES" = true ]; then
            log_info "Pushing $framework image..."
            if $CONTAINER_TOOL push "$tag"; then
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

# Main execution
main() {
    log_info "=== GPU Build Script ==="
    
    # Detect container tool
    CONTAINER_TOOL=$(detect_container_tool)
    log_info "Using container tool: $CONTAINER_TOOL"
    
    # Determine what to build
    if [ "$BUILD_ALL" = true ]; then
        BUILD_VLLM=true
        BUILD_TLLM=true
        BUILD_SGLANG=true
        BUILD_TRAINING=true
    fi
    
    if [ "$BUILD_VLLM" = false ] && [ "$BUILD_TLLM" = false ] && [ "$BUILD_SGLANG" = false ] && [ "$BUILD_TRAINING" = false ]; then
        log_error "No framework specified"
        echo "Use --help for usage information"
        exit 1
    fi
    
    if [ "$BUILD_IMAGES" = false ] && [ "$PUSH_IMAGES" = false ]; then
        log_error "No action specified (use --build or --push)"
        echo "Use --help for usage information"
        exit 1
    fi
    
    # Build images
    local build_failed=false
    
    if [ "$BUILD_VLLM" = true ]; then
        if [ "$BUILD_IMAGES" = true ]; then
            if ! build_image "vLLM" "inference-vllm" "$REGISTRY/$PROJECT:gpu-inference-vllm"; then
                build_failed=true
            fi
        elif [ "$PUSH_IMAGES" = true ]; then
            log_info "Pushing vLLM image..."
            if ! $CONTAINER_TOOL image inspect "$REGISTRY/$PROJECT:gpu-inference-vllm" >/dev/null 2>&1; then
                log_error "Local image not found: $REGISTRY/$PROJECT:gpu-inference-vllm"
                log_info "Tip: build and push in one step: $0 vllm --build --push"
                build_failed=true
            elif $CONTAINER_TOOL push "$REGISTRY/$PROJECT:gpu-inference-vllm"; then
                log_success "vLLM image pushed successfully"
            else
                log_error "Failed to push vLLM image"
                build_failed=true
            fi
        fi
    fi
    
    if [ "$BUILD_TLLM" = true ]; then
        if [ "$BUILD_IMAGES" = true ]; then
            if ! build_image "TLLM" "inference-tllm" "$REGISTRY/$PROJECT:gpu-inference-tllm"; then
                build_failed=true
            fi
        elif [ "$PUSH_IMAGES" = true ]; then
            log_info "Pushing TLLM image..."
            if ! $CONTAINER_TOOL image inspect "$REGISTRY/$PROJECT:gpu-inference-tllm" >/dev/null 2>&1; then
                log_error "Local image not found: $REGISTRY/$PROJECT:gpu-inference-tllm"
                log_info "Tip: build and push in one step: $0 tllm --build --push"
                build_failed=true
            elif $CONTAINER_TOOL push "$REGISTRY/$PROJECT:gpu-inference-tllm"; then
                log_success "TLLM image pushed successfully"
            else
                log_error "Failed to push TLLM image"
                build_failed=true
            fi
        fi
    fi
    
    if [ "$BUILD_SGLANG" = true ]; then
        if [ "$BUILD_IMAGES" = true ]; then
            if ! build_image "SGLang" "inference-sglang" "$REGISTRY/$PROJECT:gpu-inference-sglang"; then
                build_failed=true
            fi
        elif [ "$PUSH_IMAGES" = true ]; then
            log_info "Pushing SGLang image..."
            if ! $CONTAINER_TOOL image inspect "$REGISTRY/$PROJECT:gpu-inference-sglang" >/dev/null 2>&1; then
                log_error "Local image not found: $REGISTRY/$PROJECT:gpu-inference-sglang"
                log_info "Tip: build and push in one step: $0 sglang --build --push"
                build_failed=true
            elif $CONTAINER_TOOL push "$REGISTRY/$PROJECT:gpu-inference-sglang"; then
                log_success "SGLang image pushed successfully"
            else
                log_error "Failed to push SGLang image"
                build_failed=true
            fi
        fi
    fi
    
    if [ "$BUILD_TRAINING" = true ]; then
        if [ "$BUILD_IMAGES" = true ]; then
            if ! build_image "Training" "training" "$REGISTRY/$PROJECT:gpu-training"; then
                build_failed=true
            fi
        elif [ "$PUSH_IMAGES" = true ]; then
            log_info "Pushing Training image..."
            if ! $CONTAINER_TOOL image inspect "$REGISTRY/$PROJECT:gpu-training" >/dev/null 2>&1; then
                log_error "Local image not found: $REGISTRY/$PROJECT:gpu-training"
                log_info "Tip: build and push in one step: $0 training --build --push"
                build_failed=true
            elif $CONTAINER_TOOL push "$REGISTRY/$PROJECT:gpu-training"; then
                log_success "Training image pushed successfully"
            else
                log_error "Failed to push Training image"
                build_failed=true
            fi
        fi
    fi
    
    # Summary
    echo ""
    log_info "=== Build Summary ==="
    
    if [ "$build_failed" = true ]; then
        log_error "Some operations failed"
        exit 1
    else
        if [ "$BUILD_IMAGES" = true ]; then
            log_success "All requested builds completed successfully"
        fi
        
        if [ "$PUSH_IMAGES" = true ]; then
            log_success "All images pushed to registry"
        fi
        
        echo ""
        log_info "Available images:"
        $CONTAINER_TOOL images | grep "$REGISTRY/$PROJECT" || log_warning "No images found"
    fi
}

# Run main function
main 