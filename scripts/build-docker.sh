#!/bin/bash

# XPU Benchmark Docker Build Script
# This script helps build and manage Docker images for GPU and NPU benchmarks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGISTRY="shaowenchen"
IMAGE_NAME="xpu-benchmark"
DEFAULT_TAG="latest"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build a single image
build_image() {
    local context=$1
    local dockerfile=$2
    local tag=$3
    
    print_info "Building image: $tag"
    print_info "Context: $context"
    print_info "Dockerfile: $dockerfile"
    
    if [ ! -d "$context" ]; then
        print_error "Context directory not found: $context"
        return 1
    fi
    
    if [ ! -f "$dockerfile" ]; then
        print_error "Dockerfile not found: $dockerfile"
        return 1
    fi
    
    docker build -f "$dockerfile" -t "$REGISTRY/$IMAGE_NAME:$tag" "$context"
    
    if [ $? -eq 0 ]; then
        print_success "Successfully built: $REGISTRY/$IMAGE_NAME:$tag"
    else
        print_error "Failed to build: $REGISTRY/$IMAGE_NAME:$tag"
        return 1
    fi
}

# Function to build all images
build_all() {
    print_info "Building all Docker images..."
    
    # Build GPU images
    print_info "Building GPU images..."
    build_image "gpu/training" "gpu/training/Dockerfile" "gpu-training"
    build_image "gpu/inference" "gpu/inference/Dockerfile" "gpu-inference"
    build_image "gpu/stress" "gpu/stress/Dockerfile" "gpu-stress"
    
    # Build NPU images
    print_info "Building NPU images..."
    build_image "npu/training" "npu/training/Dockerfile" "npu-training"
    build_image "npu/inference" "npu/inference/Dockerfile" "npu-inference"
    build_image "npu/stress" "npu/stress/Dockerfile" "npu-stress"
    
    print_success "All images built successfully!"
}

# Function to build specific type of images
build_type() {
    local type=$1
    
    case $type in
        "gpu")
            print_info "Building GPU images..."
            build_image "gpu/training" "gpu/training/Dockerfile" "gpu-training"
            build_image "gpu/inference" "gpu/inference/Dockerfile" "gpu-inference"
            build_image "gpu/stress" "gpu/stress/Dockerfile" "gpu-stress"
            ;;
        "npu")
            print_info "Building NPU images..."
            build_image "npu/training" "npu/training/Dockerfile" "npu-training"
            build_image "npu/inference" "npu/inference/Dockerfile" "npu-inference"
            build_image "npu/stress" "npu/stress/Dockerfile" "npu-stress"
            ;;
        "gpu-training")
            build_image "gpu/training" "gpu/training/Dockerfile" "gpu-training"
            ;;
        "gpu-inference")
            build_image "gpu/inference" "gpu/inference/Dockerfile" "gpu-inference"
            ;;
        "gpu-stress")
            build_image "gpu/stress" "gpu/stress/Dockerfile" "gpu-stress"
            ;;
        "npu-training")
            build_image "npu/training" "npu/training/Dockerfile" "npu-training"
            ;;
        "npu-inference")
            build_image "npu/inference" "npu/inference/Dockerfile" "npu-inference"
            ;;
        "npu-stress")
            build_image "npu/stress" "npu/stress/Dockerfile" "npu-stress"
            ;;
        *)
            print_error "Unknown image type: $type"
            print_info "Available types: gpu, npu, gpu-training, gpu-inference, gpu-stress, npu-training, npu-inference, npu-stress"
            exit 1
            ;;
    esac
}

# Function to list built images
list_images() {
    print_info "Listing built images:"
    docker images | grep "$REGISTRY/$IMAGE_NAME" || print_warning "No images found"
}

# Function to run a specific image
run_image() {
    local image_type=$1
    
    case $image_type in
        "gpu-training")
            print_info "Running GPU training image..."
            docker run --rm -it \
                -v "$(pwd)/reports:/app/reports" \
                -v "$(pwd)/config:/app/config" \
                "$REGISTRY/$IMAGE_NAME:gpu-training"
            ;;
        "gpu-inference")
            print_info "Running GPU inference image..."
            docker run --rm -it \
                -v "$(pwd)/reports:/app/reports" \
                -v "$(pwd)/config:/app/config" \
                "$REGISTRY/$IMAGE_NAME:gpu-inference"
            ;;
        "gpu-stress")
            print_info "Running GPU stress image..."
            docker run --rm -it \
                -v "$(pwd)/reports:/app/reports" \
                -v "$(pwd)/config:/app/config" \
                "$REGISTRY/$IMAGE_NAME:gpu-stress"
            ;;
        "npu-training")
            print_info "Running NPU training image..."
            docker run --rm -it \
                -v "$(pwd)/reports:/app/reports" \
                -v "$(pwd)/config:/app/config" \
                "$REGISTRY/$IMAGE_NAME:npu-training"
            ;;
        "npu-inference")
            print_info "Running NPU inference image..."
            docker run --rm -it \
                -v "$(pwd)/reports:/app/reports" \
                -v "$(pwd)/config:/app/config" \
                "$REGISTRY/$IMAGE_NAME:npu-inference"
            ;;
        "npu-stress")
            print_info "Running NPU stress image..."
            docker run --rm -it \
                -v "$(pwd)/reports:/app/reports" \
                -v "$(pwd)/config:/app/config" \
                "$REGISTRY/$IMAGE_NAME:npu-stress"
            ;;
        *)
            print_error "Unknown image type: $image_type"
            print_info "Available types: gpu-training, gpu-inference, gpu-stress, npu-training, npu-inference, npu-stress"
            exit 1
            ;;
    esac
}

# Function to clean images
clean_images() {
    print_info "Cleaning all XPU benchmark images..."
    docker images | grep "$REGISTRY/$IMAGE_NAME" | awk '{print $3}' | xargs -r docker rmi -f
    print_success "Images cleaned successfully!"
}

# Function to show help
show_help() {
    echo "XPU Benchmark Docker Build Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  build [type]     Build Docker images"
    echo "  list             List built images"
    echo "  run <type>       Run a specific image"
    echo "  clean            Clean all images"
    echo "  help             Show this help message"
    echo ""
    echo "Build types:"
    echo "  all              Build all images (default)"
    echo "  gpu              Build all GPU images"
    echo "  npu              Build all NPU images"
    echo "  gpu-training     Build GPU training image"
    echo "  gpu-inference    Build GPU inference image"
    echo "  gpu-stress       Build GPU stress image"
    echo "  npu-training     Build NPU training image"
    echo "  npu-inference    Build NPU inference image"
    echo "  npu-stress       Build NPU stress image"
    echo ""
    echo "Examples:"
    echo "  $0 build                    # Build all images"
    echo "  $0 build gpu                # Build all GPU images"
    echo "  $0 build gpu-training       # Build GPU training image"
    echo "  $0 list                     # List built images"
    echo "  $0 run gpu-training         # Run GPU training image"
    echo "  $0 clean                    # Clean all images"
}

# Main script logic
case "${1:-help}" in
    "build")
        if [ -z "$2" ]; then
            build_all
        else
            build_type "$2"
        fi
        ;;
    "list")
        list_images
        ;;
    "run")
        if [ -z "$2" ]; then
            print_error "Please specify image type to run"
            exit 1
        fi
        run_image "$2"
        ;;
    "clean")
        clean_images
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 