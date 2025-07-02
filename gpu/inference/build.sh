#!/bin/bash

# Build script for vLLM-OpenAI GPU Inference Image

set -e

# Configuration
IMAGE_NAME="shaowenchen/xpu-benchmark:gpu-inference"
DOCKERFILE="Dockerfile"
BUILD_CONTEXT="."

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
BUILD_ARGS=""
PUSH_IMAGE=false
NO_CACHE=false

while [[ $# -gt 0 ]]; do
    case $1 in
    --push)
        PUSH_IMAGE=true
        shift
        ;;
    --no-cache)
        NO_CACHE=true
        shift
        ;;
    --tag)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            IMAGE_NAME="$2"
            shift 2
        else
            shift
        fi
        ;;
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --push              Push image to registry after building"
        echo "  --no-cache          Build without using cache"
        echo "  --tag IMAGE_NAME    Specify image name (default: $IMAGE_NAME)"
        echo "  --help, -h          Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Build image"
        echo "  $0 --no-cache         # Build without cache"
        echo "  $0 --push             # Build and push image"
        echo "  $0 --tag my-image:latest --push"
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
    
    # Check if Dockerfile exists
    if [ ! -f "$DOCKERFILE" ]; then
        log_error "Dockerfile not found: $DOCKERFILE"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "run.sh" ] || [ ! -f "client.sh" ]; then
        log_warning "run.sh or client.sh not found. Make sure you're in the correct directory."
    fi
    
    log_success "Prerequisites check passed"
}

# Build the image
build_image() {
    log_info "Building vLLM-OpenAI image: $IMAGE_NAME"
    
    # Prepare build arguments
    local build_cmd="nerdctl build"
    
    if [ "$NO_CACHE" = true ]; then
        build_cmd="$build_cmd --no-cache"
        log_info "Building without cache"
    fi
    
    build_cmd="$build_cmd --tag $IMAGE_NAME $BUILD_CONTEXT"
    
    log_info "Build command: $build_cmd"
    echo ""
    
    # Execute build
    if eval "$build_cmd"; then
        log_success "Image built successfully!"
        echo "Image: $IMAGE_NAME"
        
        # Show image info
        log_info "Image details:"
        nerdctl images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    else
        log_error "Image build failed"
        exit 1
    fi
}

# Push the image
push_image() {
    if [ "$PUSH_IMAGE" = true ]; then
        log_info "Pushing image to registry..."
        
        if nerdctl push "$IMAGE_NAME"; then
            log_success "Image pushed successfully!"
        else
            log_error "Image push failed"
            exit 1
        fi
    fi
}

# Show build summary
show_summary() {
    echo ""
    log_info "📋 Build Summary:"
    echo "Image: $IMAGE_NAME"
    echo "Dockerfile: $DOCKERFILE"
    echo "Build context: $BUILD_CONTEXT"
    echo "No cache: $NO_CACHE"
    echo "Push to registry: $PUSH_IMAGE"
    
    echo ""
    log_info "🚀 Next steps:"
    echo "1. Download a model: ./run.sh --model"
    echo "2. Start the service: ./run.sh --start"
    echo "3. Test the service: ./client.sh quick"
    echo "4. Stop the service: ./run.sh --stop"
}

# Main execution
main() {
    echo "=== vLLM-OpenAI GPU Inference Image Builder ==="
    echo ""
    
    check_prerequisites
    build_image
    push_image
    show_summary
    
    echo ""
    log_success "Build process completed successfully!"
}

# Run main function
main