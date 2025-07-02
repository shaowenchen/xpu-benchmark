#!/bin/bash

# NVIDIA Triton Server Client Test Script
# Test various API endpoints using curl with dynamic model support

set -e

# Configuration
SERVER_URL="http://localhost:8000"
DEFAULT_MODEL="Qwen2.5-7B-Instruct"
MODEL_NAME="$DEFAULT_MODEL"
API_KEY="dummy"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    --model)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MODEL_NAME="$2"
            shift 2
        else
            shift
        fi
        ;;
    --url)
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            SERVER_URL="$2"
            shift 2
        else
            shift
        fi
        ;;
    *)
        break
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

# Simple JSON extraction (without jq)
extract_json_value() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":[^,}]*" | cut -d':' -f2- | tr -d '"' | tr -d '}'
}

# Test server health
test_health() {
    log_info "Testing Triton Server health..."
    
    response=$(curl -s -w "%{http_code}" "${SERVER_URL}/v2/health/ready")
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Triton Server health check passed"
        echo "Response: $body"
        return 0
    else
        log_error "Triton Server health check failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test model metadata
test_model_metadata() {
    log_info "Testing model metadata..."
    log_info "Model: $MODEL_NAME"
    
    response=$(curl -s -w "%{http_code}" \
        "${SERVER_URL}/v2/models/${MODEL_NAME}/config")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Model metadata successful"
        echo "Model config: $body"
        return 0
    else
        log_error "Model metadata failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test model inference
test_inference() {
    local prompt="$1"
    local max_tokens="${2:-100}"
    
    log_info "Testing model inference..."
    log_info "Prompt: $prompt"
    log_info "Model: $MODEL_NAME"
    
    # Create inference request JSON
    local request_json="{
        \"inputs\": [
            {
                \"name\": \"prompt\",
                \"shape\": [1],
                \"datatype\": \"BYTES\",
                \"data\": [\"$prompt\"]
            }
        ],
        \"outputs\": [
            {
                \"name\": \"text\",
                \"shape\": [1],
                \"datatype\": \"BYTES\"
            }
        ]
    }"
    
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "$request_json" \
        "${SERVER_URL}/v2/models/${MODEL_NAME}/infer")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Inference successful"
        # Extract output from JSON response
        output=$(extract_json_value "$body" "data")
        if [ -n "$output" ]; then
            echo "Response: $output"
        else
            echo "Response: $body"
        fi
        return 0
    else
        log_error "Inference failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test models endpoint
test_models() {
    log_info "Testing models endpoint..."
    
    response=$(curl -s -w "%{http_code}" \
        "${SERVER_URL}/v2/models")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Models endpoint successful"
        echo "Available models: $body"
        return 0
    else
        log_error "Models endpoint failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Simple timing function (without bc)
get_time() {
    date +%s
}

# Benchmark test
benchmark_test() {
    local num_requests="${1:-5}"
    local prompt="${2:-"Generate a short story about AI."}"
    
    log_info "Running benchmark test with $num_requests requests..."
    log_info "Model: $MODEL_NAME"
    
    start_time=$(get_time)
    successful_requests=0
    
    for i in $(seq 1 $num_requests); do
        log_info "Request $i/$num_requests"
        
        request_start=$(get_time)
        
        # Create inference request JSON
        local request_json="{
            \"inputs\": [
                {
                    \"name\": \"prompt\",
                    \"shape\": [1],
                    \"datatype\": \"BYTES\",
                    \"data\": [\"${prompt} Request number ${i}.\"]
                }
            ],
            \"outputs\": [
                {
                    \"name\": \"text\",
                    \"shape\": [1],
                    \"datatype\": \"BYTES\"
                }
            ]
        }"
        
        response=$(curl -s -w "%{http_code}" \
            -H "Content-Type: application/json" \
            -d "$request_json" \
            "${SERVER_URL}/v2/models/${MODEL_NAME}/infer")
        
        request_end=$(get_time)
        http_code="${response: -3}"
        body="${response%???}"
        
        if [ "$http_code" = "200" ]; then
            successful_requests=$((successful_requests + 1))
            request_time=$((request_end - request_start))
            log_success "Request $i completed in ${request_time}s"
        else
            log_error "Request $i failed: HTTP $http_code"
        fi
    done
    
    end_time=$(get_time)
    total_time=$((end_time - start_time))
    avg_time=$((total_time / num_requests))
    
    # Simple throughput calculation
    if [ $total_time -gt 0 ]; then
        throughput=$((successful_requests / total_time))
    else
        throughput=0
    fi
    
    echo ""
    log_info "📊 Benchmark Results:"
    echo "Model: $MODEL_NAME"
    echo "Total requests: $num_requests"
    echo "Successful requests: $successful_requests"
    echo "Total time: ${total_time}s"
    echo "Average time per request: ${avg_time}s"
    echo "Throughput: ${throughput} requests/second"
}

# Test different scenarios
test_scenarios() {
    log_info "Running various test scenarios..."
    log_info "Model: $MODEL_NAME"
    
    # Test 1: Simple greeting
    echo ""
    log_info "=== Test 1: Simple Greeting ==="
    test_inference "Hello! How are you today?" 50
    
    # Test 2: Technical question
    echo ""
    log_info "=== Test 2: Technical Question ==="
    test_inference "What is the difference between supervised and unsupervised learning?" 150
    
    # Test 3: Creative writing
    echo ""
    log_info "=== Test 3: Creative Writing ==="
    test_inference "Write a short poem about artificial intelligence." 100
    
    # Test 4: Code generation
    echo ""
    log_info "=== Test 4: Code Generation ==="
    test_inference "Write a Python function to calculate the factorial of a number." 200
    
    # Test 5: Translation
    echo ""
    log_info "=== Test 5: Translation ==="
    test_inference "Translate 'Hello, how are you?' to Chinese." 50
    
    # Test 6: Math problem
    echo ""
    log_info "=== Test 6: Math Problem ==="
    test_inference "Solve this math problem: If x + 2y = 10 and 2x + y = 8, what are the values of x and y?" 200
}

# Test error handling
test_error_handling() {
    log_info "Testing error handling..."
    
    # Test 1: Invalid model name
    echo ""
    log_info "=== Test 1: Invalid Model Name ==="
    response=$(curl -s -w "%{http_code}" \
        "${SERVER_URL}/v2/models/invalid-model/infer")
    
    http_code="${response: -3}"
    body="${response%???}"
    log_info "Invalid model response: HTTP $http_code"
    echo "Response: $body"
    
    # Test 2: Invalid JSON
    echo ""
    log_info "=== Test 2: Invalid JSON ==="
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "invalid json" \
        "${SERVER_URL}/v2/models/${MODEL_NAME}/infer")
    
    http_code="${response: -3}"
    body="${response%???}"
    log_info "Invalid JSON response: HTTP $http_code"
    echo "Response: $body"
    
    # Test 3: Missing required fields
    echo ""
    log_info "=== Test 3: Missing Required Fields ==="
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{\"inputs\": []}" \
        "${SERVER_URL}/v2/models/${MODEL_NAME}/infer")
    
    http_code="${response: -3}"
    body="${response%???}"
    log_info "Missing fields response: HTTP $http_code"
    echo "Response: $body"
}

# Quick test function
quick_test() {
    log_info "Running quick test..."
    log_info "Model: $MODEL_NAME"
    
    echo ""
    log_info "=== Quick Inference Test ==="
    test_inference "Hello! Please respond with a short greeting." 30
    
    echo ""
    log_info "=== Model Metadata Test ==="
    test_model_metadata
}

# Main function
main() {
    echo "=== NVIDIA Triton Server Client Test Script ==="
    echo "Server URL: $SERVER_URL"
    echo "Model: $MODEL_NAME"
    echo ""
    
    # Wait for server to be ready
    log_info "Waiting for server to be ready..."
    sleep 5
    
    # Test server health first
    if ! test_health; then
        log_error "Server is not ready. Please check if Triton Server is running."
        exit 1
    fi
    
    # Test models endpoint
    echo ""
    test_models
    
    # Test model metadata
    echo ""
    test_model_metadata
    
    # Run test scenarios
    echo ""
    test_scenarios
    
    # Run benchmark test
    echo ""
    benchmark_test 5 "Generate a creative story about"
    
    # Test error handling
    echo ""
    test_error_handling
    
    echo ""
    log_success "All tests completed!"
}

# Parse command line arguments
case "${1:-all}" in
    "health")
        test_health
        exit $?
        ;;
    "inference")
        test_inference "${2:-"Hello! How are you?"}" "${3:-100}"
        exit $?
        ;;
    "metadata")
        test_model_metadata
        exit $?
        ;;
    "models")
        test_models
        exit $?
        ;;
    "benchmark")
        benchmark_test "${2:-5}" "${3:-"Generate a story about"}"
        ;;
    "scenarios")
        test_scenarios
        ;;
    "errors")
        test_error_handling
        ;;
    "quick")
        quick_test
        ;;
    "all")
        main
        ;;
    *)
        echo "Usage: $0 [--model MODEL_NAME] [--url SERVER_URL] [health|inference|metadata|models|benchmark|scenarios|errors|quick|all]"
        echo ""
        echo "Options:"
        echo "  --model MODEL_NAME    Specify model name (default: $DEFAULT_MODEL)"
        echo "  --url SERVER_URL      Specify server URL (default: $SERVER_URL)"
        echo ""
        echo "Commands:"
        echo "  health                Test server health"
        echo "  inference [prompt] [tokens] Test model inference"
        echo "  metadata              Test model metadata"
        echo "  models                List available models"
        echo "  benchmark [count] [prompt] Run benchmark test"
        echo "  scenarios             Run various test scenarios"
        echo "  errors                Test error handling"
        echo "  quick                 Run quick test"
        echo "  all                   Run all tests"
        echo ""
        echo "Examples:"
        echo "  $0 --model Qwen2.5-7B-Instruct quick"
        echo "  $0 --url http://localhost:8000 inference 'Hello world' 50"
        echo "  $0 --model DialoGPT-medium benchmark 10"
        exit 1
        ;;
esac 