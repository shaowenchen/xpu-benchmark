#!/bin/bash

# XPU Benchmark Docker Build Script
# 本地构建Docker镜像脚本

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to build Docker image
build_image() {
    local context=$1
    local dockerfile=$2
    local tag=$3
    
    print_info "Building $tag from $context"
    
    if [ ! -f "$dockerfile" ]; then
        print_error "Dockerfile not found: $dockerfile"
        return 1
    fi
    
    if [ ! -f "$context/requirements.txt" ]; then
        print_error "requirements.txt not found: $context/requirements.txt"
        return 1
    fi
    
    # Build image
    docker build -f "$dockerfile" -t "xpu-benchmark:$tag" "$context"
    
    if [ $? -eq 0 ]; then
        print_success "Successfully built xpu-benchmark:$tag"
    else
        print_error "Failed to build xpu-benchmark:$tag"
        return 1
    fi
}

# Function to build all images
build_all() {
    print_info "Building all Docker images..."
    
    # GPU images
    build_image "benchmarks/gpu/training" "benchmarks/gpu/training/Dockerfile" "gpu-training"
    build_image "benchmarks/gpu/inference" "benchmarks/gpu/inference/Dockerfile" "gpu-inference"
    build_image "benchmarks/gpu/stress" "benchmarks/gpu/stress/Dockerfile" "gpu-stress"
    
    # NPU images
    build_image "benchmarks/npu/training" "benchmarks/npu/training/Dockerfile" "npu-training"
    build_image "benchmarks/npu/inference" "benchmarks/npu/inference/Dockerfile" "npu-inference"
    build_image "benchmarks/npu/stress" "benchmarks/npu/stress/Dockerfile" "npu-stress"
    
    print_success "All Docker images built successfully!"
}

# Function to build specific image
build_specific() {
    local image_type=$1
    
    case $image_type in
        "gpu-training")
            build_image "benchmarks/gpu/training" "benchmarks/gpu/training/Dockerfile" "gpu-training"
            ;;
        "gpu-inference")
            build_image "benchmarks/gpu/inference" "benchmarks/gpu/inference/Dockerfile" "gpu-inference"
            ;;
        "gpu-stress")
            build_image "benchmarks/gpu/stress" "benchmarks/gpu/stress/Dockerfile" "gpu-stress"
            ;;
        "npu-training")
            build_image "benchmarks/npu/training" "benchmarks/npu/training/Dockerfile" "npu-training"
            ;;
        "npu-inference")
            build_image "benchmarks/npu/inference" "benchmarks/npu/inference/Dockerfile" "npu-inference"
            ;;
        "npu-stress")
            build_image "benchmarks/npu/stress" "benchmarks/npu/stress/Dockerfile" "npu-stress"
            ;;
        "gpu")
            print_info "Building all GPU images..."
            build_image "benchmarks/gpu/training" "benchmarks/gpu/training/Dockerfile" "gpu-training"
            build_image "benchmarks/gpu/inference" "benchmarks/gpu/inference/Dockerfile" "gpu-inference"
            build_image "benchmarks/gpu/stress" "benchmarks/gpu/stress/Dockerfile" "gpu-stress"
            ;;
        "npu")
            print_info "Building all NPU images..."
            build_image "benchmarks/npu/training" "benchmarks/npu/training/Dockerfile" "npu-training"
            build_image "benchmarks/npu/inference" "benchmarks/npu/inference/Dockerfile" "npu-inference"
            build_image "benchmarks/npu/stress" "benchmarks/npu/stress/Dockerfile" "npu-stress"
            ;;
        *)
            print_error "Unknown image type: $image_type"
            print_info "Available types: gpu-training, gpu-inference, gpu-stress, npu-training, npu-inference, npu-stress, gpu, npu, all"
            exit 1
            ;;
    esac
}

# Function to list built images
list_images() {
    print_info "Built Docker images:"
    docker images | grep xpu-benchmark || print_warning "No xpu-benchmark images found"
}

# Function to run image
run_image() {
    local image_type=$1
    local tag="xpu-benchmark:$image_type"
    
    print_info "Running $tag"
    
    # Check if image exists
    if ! docker images | grep -q "xpu-benchmark.*$image_type"; then
        print_error "Image $tag not found. Please build it first."
        exit 1
    fi
    
    # Create output directory
    mkdir -p reports/docker
    
    # Run container
    docker run --rm \
        -v "$(pwd)/reports/docker:/app/reports" \
        -v "$(pwd)/config:/app/config" \
        "$tag"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build [TYPE]     Build Docker image(s)"
    echo "  run [TYPE]       Run Docker image"
    echo "  list             List built images"
    echo "  help             Show this help message"
    echo ""
    echo "Build types:"
    echo "  all              Build all images (default)"
    echo "  gpu              Build all GPU images"
    echo "  npu              Build all NPU images"
    echo "  gpu-training     Build GPU training image"
    echo "  gpu-inference    Build GPU inference image"
    echo "  gpu-stress       Build GPU stress test image"
    echo "  npu-training     Build NPU training image"
    echo "  npu-inference    Build NPU inference image"
    echo "  npu-stress       Build NPU stress test image"
    echo ""
    echo "Examples:"
    echo "  $0 build                    # Build all images"
    echo "  $0 build gpu                # Build all GPU images"
    echo "  $0 build gpu-training       # Build GPU training image"
    echo "  $0 run gpu-training         # Run GPU training image"
    echo "  $0 list                     # List built images"
}

# Main function
main() {
    local command=${1:-build}
    local image_type=${2:-all}
    
    case $command in
        "build")
            if [ "$image_type" = "all" ]; then
                build_all
            else
                build_specific "$image_type"
            fi
            ;;
        "run")
            run_image "$image_type"
            ;;
        "list")
            list_images
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            print_error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 