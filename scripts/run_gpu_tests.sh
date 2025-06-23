#!/bin/bash

# GPU Test Runner Script
# This script runs GPU benchmark tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"
REPORTS_DIR="$PROJECT_ROOT/reports"
BENCHMARKS_DIR="gpu"

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

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    
    # Check CUDA
    if ! command -v nvidia-smi &> /dev/null; then
        print_warning "NVIDIA GPU not detected or drivers not installed"
    fi
    
    # Check PyTorch
    if ! python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())" 2>/dev/null; then
        print_warning "PyTorch not installed or CUDA not available"
    fi
    
    # Check directories
    if [ ! -d "$BENCHMARKS_DIR" ]; then
        print_error "Benchmarks directory not found: $BENCHMARKS_DIR"
        exit 1
    fi
    
    if [ ! -d "$CONFIG_DIR" ]; then
        print_error "Config directory not found: $CONFIG_DIR"
        exit 1
    fi
    
    # Create reports directory
    mkdir -p "$REPORTS_DIR"
    
    print_success "Prerequisites check completed"
}

# Function to run training test
run_training_test() {
    print_info "Running GPU training test..."
    
    cd "$BENCHMARKS_DIR/training"
    
    if [ ! -f "resnet50_pytorch.py" ]; then
        print_error "Training test script not found"
        return 1
    fi
    
    python3 resnet50_pytorch.py \
        --config "$CONFIG_DIR/gpu/nvidia.yaml" \
        --output "$REPORTS_DIR/gpu_training_results.json"
    
    if [ $? -eq 0 ]; then
        print_success "GPU training test completed"
    else
        print_error "GPU training test failed"
        return 1
    fi
}

# Function to run inference test
run_inference_test() {
    print_info "Running GPU inference test..."
    
    cd "$BENCHMARKS_DIR/inference"
    
    if [ ! -f "bert_tf_serving.py" ]; then
        print_error "Inference test script not found"
        return 1
    fi
    
    python3 bert_tf_serving.py \
        --config "$CONFIG_DIR/gpu/nvidia.yaml" \
        --output "$REPORTS_DIR/gpu_inference_results.json"
    
    if [ $? -eq 0 ]; then
        print_success "GPU inference test completed"
    else
        print_error "GPU inference test failed"
        return 1
    fi
}

# Function to run stress test
run_stress_test() {
    print_info "Running GPU stress test..."
    
    cd "$BENCHMARKS_DIR/stress"
    
    if [ ! -f "memory_bandwidth.py" ]; then
        print_error "Stress test script not found"
        return 1
    fi
    
    python3 memory_bandwidth.py \
        --config "$CONFIG_DIR/gpu/nvidia.yaml" \
        --output "$REPORTS_DIR/gpu_stress_results.json"
    
    if [ $? -eq 0 ]; then
        print_success "GPU stress test completed"
    else
        print_error "GPU stress test failed"
        return 1
    fi
}

# Function to run all tests
run_all_tests() {
    print_info "Running all GPU tests..."
    
    local failed_tests=0
    
    # Run training test
    if run_training_test; then
        print_success "Training test passed"
    else
        print_error "Training test failed"
        ((failed_tests++))
    fi
    
    # Run inference test
    if run_inference_test; then
        print_success "Inference test passed"
    else
        print_error "Inference test failed"
        ((failed_tests++))
    fi
    
    # Run stress test
    if run_stress_test; then
        print_success "Stress test passed"
    else
        print_error "Stress test failed"
        ((failed_tests++))
    fi
    
    # Summary
    if [ $failed_tests -eq 0 ]; then
        print_success "All GPU tests completed successfully!"
    else
        print_error "$failed_tests test(s) failed"
        exit 1
    fi
}

# Function to run tests in Docker
run_docker_tests() {
    print_info "Running GPU tests in Docker..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Run training test in Docker
    print_info "Running GPU training test in Docker..."
    docker run --rm \
        --gpus all \
        -v "$(pwd)/reports:/app/reports" \
        -v "$(pwd)/config:/app/config" \
        -v "$(pwd)/$BENCHMARKS_DIR:/app/benchmarks" \
        shaowenchen/xpu-benchmark:gpu-training
    
    # Run inference test in Docker
    print_info "Running GPU inference test in Docker..."
    docker run --rm \
        --gpus all \
        -v "$(pwd)/reports:/app/reports" \
        -v "$(pwd)/config:/app/config" \
        -v "$(pwd)/$BENCHMARKS_DIR:/app/benchmarks" \
        shaowenchen/xpu-benchmark:gpu-inference
    
    # Run stress test in Docker
    print_info "Running GPU stress test in Docker..."
    docker run --rm \
        --gpus all \
        -v "$(pwd)/reports:/app/reports" \
        -v "$(pwd)/config:/app/config" \
        -v "$(pwd)/$BENCHMARKS_DIR:/app/benchmarks" \
        shaowenchen/xpu-benchmark:gpu-stress
    
    print_success "All Docker tests completed"
}

# Function to show help
show_help() {
    echo "GPU Test Runner Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  all              Run all GPU tests (default)"
    echo "  training         Run GPU training test only"
    echo "  inference        Run GPU inference test only"
    echo "  stress           Run GPU stress test only"
    echo "  docker           Run all tests in Docker containers"
    echo "  help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0               # Run all tests"
    echo "  $0 training      # Run training test only"
    echo "  $0 docker        # Run tests in Docker"
}

# Main script logic
case "${1:-all}" in
    "all")
        check_prerequisites
        run_all_tests
        ;;
    "training")
        check_prerequisites
        run_training_test
        ;;
    "inference")
        check_prerequisites
        run_inference_test
        ;;
    "stress")
        check_prerequisites
        run_stress_test
        ;;
    "docker")
        run_docker_tests
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