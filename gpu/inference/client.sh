#!/bin/bash

# vLLM Client Test Script for Qwen2.5-7B-Instruct
# Test various API endpoints using curl

set -e

# Configuration
SERVER_URL="http://localhost:8000"
MODEL_NAME="Qwen2.5-7B-Instruct"
API_KEY="dummy"

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
    log_info "Testing server health..."
    
    response=$(curl -s -w "%{http_code}" "${SERVER_URL}/health")
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Server health check passed"
        echo "Response: $body"
        return 0
    else
        log_error "Server health check failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test chat completion
test_chat_completion() {
    local prompt="$1"
    local max_tokens="${2:-100}"
    
    log_info "Testing chat completion..."
    log_info "Prompt: $prompt"
    
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${MODEL_NAME}\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"${prompt}\"}
            ],
            \"max_tokens\": ${max_tokens},
            \"temperature\": 0.7
        }" \
        "${SERVER_URL}/v1/chat/completions")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Chat completion successful"
        # Extract content from JSON response
        content=$(extract_json_value "$body" "content")
        if [ -n "$content" ]; then
            echo "Response: $content"
        else
            echo "Response: $body"
        fi
        return 0
    else
        log_error "Chat completion failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test completion API
test_completion() {
    local prompt="$1"
    local max_tokens="${2:-50}"
    
    log_info "Testing completion API..."
    log_info "Prompt: $prompt"
    
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${MODEL_NAME}\",
            \"prompt\": \"${prompt}\",
            \"max_tokens\": ${max_tokens},
            \"temperature\": 0.7
        }" \
        "${SERVER_URL}/v1/completions")
    
    http_code="${response: -3}"
    body="${response%???}"
    
    if [ "$http_code" = "200" ]; then
        log_success "Completion successful"
        # Extract text from JSON response
        text=$(extract_json_value "$body" "text")
        if [ -n "$text" ]; then
            echo "Response: $text"
        else
            echo "Response: $body"
        fi
        return 0
    else
        log_error "Completion failed: HTTP $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test models endpoint
test_models() {
    log_info "Testing models endpoint..."
    
    response=$(curl -s -w "%{http_code}" \
        "${SERVER_URL}/v1/models")
    
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
    
    start_time=$(get_time)
    successful_requests=0
    
    for i in $(seq 1 $num_requests); do
        log_info "Request $i/$num_requests"
        
        request_start=$(get_time)
        
        response=$(curl -s -w "%{http_code}" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"${MODEL_NAME}\",
                \"messages\": [
                    {\"role\": \"user\", \"content\": \"${prompt} Request number ${i}.\"}
                ],
                \"max_tokens\": 50,
                \"temperature\": 0.7
            }" \
            "${SERVER_URL}/v1/chat/completions")
        
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
    echo "Total requests: $num_requests"
    echo "Successful requests: $successful_requests"
    echo "Total time: ${total_time}s"
    echo "Average time per request: ${avg_time}s"
    echo "Throughput: ${throughput} requests/second"
}

# Test different scenarios
test_scenarios() {
    log_info "Running various test scenarios..."
    
    # Test 1: Simple greeting
    echo ""
    log_info "=== Test 1: Simple Greeting ==="
    test_chat_completion "Hello! How are you today?" 50
    
    # Test 2: Technical question
    echo ""
    log_info "=== Test 2: Technical Question ==="
    test_chat_completion "What is the difference between supervised and unsupervised learning?" 150
    
    # Test 3: Creative writing
    echo ""
    log_info "=== Test 3: Creative Writing ==="
    test_chat_completion "Write a short poem about artificial intelligence." 100
    
    # Test 4: Code generation
    echo ""
    log_info "=== Test 4: Code Generation ==="
    test_chat_completion "Write a Python function to calculate the factorial of a number." 200
    
    # Test 5: Translation
    echo ""
    log_info "=== Test 5: Translation ==="
    test_chat_completion "Translate 'Hello, how are you?' to Chinese." 50
    
    # Test 6: Math problem
    echo ""
    log_info "=== Test 6: Math Problem ==="
    test_chat_completion "Solve this math problem: If x + 2y = 10 and 2x + y = 8, what are the values of x and y?" 200
    
    # Test 7: Completion API
    echo ""
    log_info "=== Test 7: Completion API ==="
    test_completion "The future of artificial intelligence is" 50
}

# Test error handling
test_error_handling() {
    log_info "Testing error handling..."
    
    # Test 1: Invalid model name
    echo ""
    log_info "=== Test 1: Invalid Model Name ==="
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"invalid-model\",
            \"messages\": [
                {\"role\": \"user\", \"content\": \"Hello\"}
            ],
            \"max_tokens\": 50
        }" \
        "${SERVER_URL}/v1/chat/completions")
    
    http_code="${response: -3}"
    body="${response%???}"
    log_info "Invalid model response: HTTP $http_code"
    echo "Response: $body"
    
    # Test 2: Missing required fields
    echo ""
    log_info "=== Test 2: Missing Required Fields ==="
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"${MODEL_NAME}\"
        }" \
        "${SERVER_URL}/v1/chat/completions")
    
    http_code="${response: -3}"
    body="${response%???}"
    log_info "Missing fields response: HTTP $http_code"
    echo "Response: $body"
    
    # Test 3: Invalid JSON
    echo ""
    log_info "=== Test 3: Invalid JSON ==="
    response=$(curl -s -w "%{http_code}" \
        -H "Content-Type: application/json" \
        -d "invalid json" \
        "${SERVER_URL}/v1/chat/completions")
    
    http_code="${response: -3}"
    body="${response%???}"
    log_info "Invalid JSON response: HTTP $http_code"
    echo "Response: $body"
}

# Main function
main() {
    echo "=== vLLM Client Test Script for Qwen2.5-7B-Instruct ==="
    echo "Server URL: $SERVER_URL"
    echo "Model: $MODEL_NAME"
    echo ""
    
    # Wait for server to be ready
    log_info "Waiting for server to be ready..."
    sleep 5
    
    # Test server health first
    if ! test_health; then
        log_error "Server is not ready. Please check if vLLM server is running."
        exit 1
    fi
    
    # Test models endpoint
    echo ""
    test_models
    
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
    "chat")
        test_chat_completion "${2:-"Hello! How are you?"}" "${3:-100}"
        exit $?
        ;;
    "completion")
        test_completion "${2:-"The future of AI is"}" "${3:-50}"
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
    "all")
        main
        ;;
    *)
        echo "Usage: $0 [health|chat|completion|models|benchmark|scenarios|errors|all]"
        exit 1
        ;;
esac
