#!/bin/bash

# NPU Test Runner Script
# Supports Huawei Ascend NPU testing

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Default configuration
CONFIG_DIR="config/npu"
REPORTS_DIR="reports"
BENCHMARKS_DIR="benchmarks/npu"
DOCKER_IMAGE="xpu-bench-npu:latest"

# Show help information
show_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help information"
    echo "  -c, --config CONFIG     Specify configuration file (default: auto)"
    echo "  -t, --type TYPE         Specify NPU type (ascend)"
    echo "  -b, --benchmark BENCH   Specify test type (training|inference|stress|all)"
    echo "  -d, --docker            Use Docker to run tests"
    echo "  -v, --verbose           Enable verbose output"
    echo "  -o, --output DIR        Specify output directory"
    echo ""
    echo "Examples:"
    echo "  $0 -t ascend -b training"
    echo "  $0 -c config/npu/ascend.yaml -b all"
    echo "  $0 -t ascend -b inference -d"
}

# Detect NPU type
detect_npu() {
    if lspci | grep -i ascend > /dev/null; then
        echo "ascend"
    else
        echo "unknown"
    fi
}

# Validate environment
validate_environment() {
    log_info "Validating test environment..."
    
    # Check Python environment
    if ! command -v python3 &> /dev/null; then
        log_error "Python3 not installed"
        exit 1
    fi
    
    # Check required Python packages
    python3 -c "import numpy, psutil" 2>/dev/null || {
        log_error "Missing required Python packages, please install: numpy, psutil"
        exit 1
    }
    
    # Check NPU drivers
    NPU_TYPE=$(detect_npu)
    case $NPU_TYPE in
        "ascend")
            if ! command -v npu-smi &> /dev/null; then
                log_error "Huawei Ascend drivers not installed or npu-smi not available"
                exit 1
            fi
            ;;
        *)
            log_error "No supported NPU detected"
            exit 1
            ;;
    esac
    
    log_info "Environment validation passed"
}

# Run training tests
run_training_tests() {
    log_info "Running training tests..."
    
    cd "$BENCHMARKS_DIR/training"
    
    # Run different training tests based on NPU type
    case $NPU_TYPE in
        "ascend")
            if [[ -f "resnet50_mindspore.py" ]]; then
                log_info "Running ResNet50 MindSpore training test..."
                python3 resnet50_mindspore.py --config "../../$CONFIG_FILE" --output "../../$REPORTS_DIR"
            else
                log_warn "ResNet50 MindSpore training test file does not exist"
            fi
            ;;
    esac
    
    cd - > /dev/null
}

# Run inference tests
run_inference_tests() {
    log_info "Running inference tests..."
    
    cd "$BENCHMARKS_DIR/inference"
    
    # Run different inference tests based on NPU type
    case $NPU_TYPE in
        "ascend")
            if [[ -f "bert_mindspore.py" ]]; then
                log_info "Running BERT MindSpore inference test..."
                python3 bert_mindspore.py --config "../../$CONFIG_FILE" --output "../../$REPORTS_DIR"
            else
                log_warn "BERT MindSpore inference test file does not exist"
            fi
            ;;
    esac
    
    cd - > /dev/null
}

# Run stress tests
run_stress_tests() {
    log_info "Running stress tests..."
    
    cd "$BENCHMARKS_DIR/stress"
    
    # Run memory bandwidth test
    if [[ -f "memory_bandwidth.py" ]]; then
        log_info "Running memory bandwidth test..."
        python3 memory_bandwidth.py --config "../../$CONFIG_FILE" --output "../../$REPORTS_DIR"
    else
        log_warn "Memory bandwidth test file does not exist"
    fi
    
    cd - > /dev/null
}

# Run tests using Docker
run_docker_tests() {
    log_info "Running tests using Docker..."
    
    # Build Docker image
    if [[ ! -f "docker/npu.Dockerfile" ]]; then
        log_error "Docker file does not exist: docker/npu.Dockerfile"
        exit 1
    fi
    
    log_info "Building Docker image..."
    docker build -f docker/npu.Dockerfile -t $DOCKER_IMAGE .
    
    # Run Docker container
    log_info "Running Docker container..."
    docker run --rm \
        --privileged \
        -v "$(pwd)/$CONFIG_DIR:/app/config" \
        -v "$(pwd)/$REPORTS_DIR:/app/reports" \
        -v "$(pwd)/$BENCHMARKS_DIR:/app/benchmarks" \
        $DOCKER_IMAGE \
        python3 -m xpu_bench.runner --config "/app/$CONFIG_FILE" --benchmark "$BENCHMARK_TYPE"
}

# Generate report
generate_report() {
    log_info "Generating test report..."
    
    cd "$REPORTS_DIR"
    
    # Generate HTML report
    if command -v python3 &> /dev/null; then
        python3 -c "
import json
import os
from datetime import datetime

# Read test results
results = {}
for file in os.listdir('.'):
    if file.endswith('.json'):
        with open(file, 'r') as f:
            results[file] = json.load(f)

# Generate HTML report
html_content = f'''
<!DOCTYPE html>
<html>
<head>
    <title>XPU NPU Benchmark Report</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .header {{ background-color: #f0f0f0; padding: 10px; border-radius: 5px; }}
        .result {{ margin: 10px 0; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }}
        .success {{ background-color: #d4edda; }}
        .error {{ background-color: #f8d7da; }}
    </style>
</head>
<body>
    <div class=\"header\">
        <h1>XPU NPU Benchmark Report</h1>
        <p>Generated at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
        <p>NPU type: $NPU_TYPE</p>
    </div>
'''

for test_name, result in results.items():
    status_class = 'success' if result.get('status') == 'success' else 'error'
    html_content += f'''
    <div class=\"result {status_class}\">
        <h3>{test_name}</h3>
        <pre>{json.dumps(result, indent=2)}</pre>
    </div>
'''

html_content += '''
</body>
</html>
'''

with open('npu_report.html', 'w') as f:
    f.write(html_content)
"
        log_info "HTML report generated: $REPORTS_DIR/npu_report.html"
    fi
    
    cd - > /dev/null
}

# Main function
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -t|--type)
                NPU_TYPE="$2"
                shift 2
                ;;
            -b|--benchmark)
                BENCHMARK_TYPE="$2"
                shift 2
                ;;
            -d|--docker)
                USE_DOCKER=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -o|--output)
                REPORTS_DIR="$2"
                shift 2
                ;;
            *)
                log_error "Unknown parameter: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set default values
    if [[ -z "$NPU_TYPE" ]]; then
        NPU_TYPE=$(detect_npu)
    fi
    
    if [[ -z "$CONFIG_FILE" ]]; then
        CONFIG_FILE="$CONFIG_DIR/${NPU_TYPE}.yaml"
    fi
    
    if [[ -z "$BENCHMARK_TYPE" ]]; then
        BENCHMARK_TYPE="all"
    fi
    
    # Validate environment
    validate_environment
    
    # Create output directory
    mkdir -p "$REPORTS_DIR"
    
    log_info "Starting NPU tests..."
    log_info "NPU type: $NPU_TYPE"
    log_info "Configuration file: $CONFIG_FILE"
    log_info "Test type: $BENCHMARK_TYPE"
    log_info "Output directory: $REPORTS_DIR"
    
    # Run tests
    if [[ "$USE_DOCKER" == "true" ]]; then
        run_docker_tests
    else
        case $BENCHMARK_TYPE in
            "training")
                run_training_tests
                ;;
            "inference")
                run_inference_tests
                ;;
            "stress")
                run_stress_tests
                ;;
            "all")
                run_training_tests
                run_inference_tests
                run_stress_tests
                ;;
            *)
                log_error "Unsupported test type: $BENCHMARK_TYPE"
                exit 1
                ;;
        esac
    fi
    
    # Generate report
    generate_report
    
    log_info "NPU tests completed!"
    log_info "Report location: $REPORTS_DIR"
}

# Execute main function
main "$@" 