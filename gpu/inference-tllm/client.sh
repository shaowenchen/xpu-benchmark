#!/bin/bash

# TLLM Client Test Script
# Test TLLM API endpoints

set -e

# Default configuration
SERVER_URL="http://localhost:8000"
DEFAULT_PROMPT="Hello, how are you today?"
DEFAULT_MESSAGE="Hello, can you help me with a question?"
DEFAULT_MODEL_NAME="Qwen3-0.6B-Base"

# Parse command line arguments
HEALTH_CHECK=false
CHAT_COMPLETION=false
TEXT_COMPLETION=false
PROMPT=""
MESSAGE=""
MODEL_LIST=false

while [[ $# -gt 0 ]]; do
    case $1 in
    health)
        HEALTH_CHECK=true
        shift
        ;;
    chat)
        CHAT_COMPLETION=true
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            MESSAGE="$2"
            shift 2
        else
            MESSAGE="$DEFAULT_MESSAGE"
            shift
        fi
        ;;
    completion)
        TEXT_COMPLETION=true
        if [ -n "$2" ] && [[ ! "$2" =~ ^- ]]; then
            PROMPT="$2"
            shift 2
        else
            PROMPT="$DEFAULT_PROMPT"
            shift
        fi
        ;;
    models)
        MODEL_LIST=true
        shift
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
        echo "Unknown option: $1"
        echo "Usage: $0 [health|chat [message]|completion [prompt]|models] [--url server_url]"
        echo ""
        echo "Commands:"
        echo "  health                    Check server health"
        echo "  chat [message]            Test chat completion (default: '$DEFAULT_MESSAGE')"
        echo "  completion [prompt]       Test text completion (default: '$DEFAULT_PROMPT')"
        echo "  models                    List available models"
        echo ""
        echo "Options:"
        echo "  --url server_url          Server URL (default: $SERVER_URL)"
        exit 1
        ;;
    esac
done

# Check if server is running
check_server() {
    if ! curl -s "$SERVER_URL/health" > /dev/null 2>&1; then
        echo "❌ Server is not running at $SERVER_URL"
        echo "Please start the server first: ./run.sh start"
        exit 1
    fi
}

# Get model name from server
get_model_name() {
    local model_name=""
    
    # Try to get model name from /v1/models endpoint
    if response=$(curl -s "$SERVER_URL/v1/models" 2>/dev/null); then
        if command -v jq >/dev/null 2>&1; then
            model_name=$(echo "$response" | jq -r ".data[0].id // \"$DEFAULT_MODEL_NAME\"")
        else
            # Fallback: extract model name from response without jq
            model_name=$(echo "$response" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
        fi
    fi
    
    # If we couldn't get the model name, use default
    if [ -z "$model_name" ] || [ "$model_name" = "null" ]; then
        model_name="$DEFAULT_MODEL_NAME"
    fi
    
    echo "$model_name"
}

# Health check
health_check() {
    echo "=== Health Check ==="
    echo "Server URL: $SERVER_URL"
    echo ""
    
    check_server
    
    echo "🔍 Checking server health..."
    response=$(curl -s "$SERVER_URL/health")
    
    if [ $? -eq 0 ]; then
        echo "✅ Server is healthy"
        echo "Response: $response"
    else
        echo "❌ Health check failed"
        exit 1
    fi
}

# List models
list_models() {
    echo "=== Model List ==="
    echo "Server URL: $SERVER_URL"
    echo ""
    
    check_server
    
    echo "📋 Listing available models..."
    response=$(curl -s "$SERVER_URL/v1/models")
    
    if [ $? -eq 0 ]; then
        echo "✅ Models retrieved successfully"
        echo "Response:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
    else
        echo "❌ Failed to retrieve models"
        exit 1
    fi
}

# Chat completion
chat_completion() {
    echo "=== Chat Completion Test ==="
    echo "Server URL: $SERVER_URL"
    echo "Message: $MESSAGE"
    echo ""
    
    check_server
    
    # Get actual model name
    MODEL_NAME=$(get_model_name)
    echo "Using model: $MODEL_NAME"
    echo ""
    
    echo "💬 Testing chat completion..."
    
    # Prepare request payload
    payload=$(cat <<EOF
{
    "model": "$MODEL_NAME",
    "messages": [
        {
            "role": "user",
            "content": "$MESSAGE"
        }
    ],
    "max_tokens": 100,
    "temperature": 0.7
}
EOF
)
    
    echo "Request payload:"
    echo "$payload" | jq '.' 2>/dev/null || echo "$payload"
    echo ""
    
    # Send request
    response=$(curl -s -X POST "$SERVER_URL/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    if [ $? -eq 0 ]; then
        echo "✅ Chat completion successful"
        echo "Response:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        
        # Extract and display the generated text
        if command -v jq >/dev/null 2>&1; then
            generated_text=$(echo "$response" | jq -r '.choices[0].message.content // "No content"')
            echo ""
            echo "Generated text:"
            echo "$generated_text"
        fi
    else
        echo "❌ Chat completion failed"
        exit 1
    fi
}

# Text completion
text_completion() {
    echo "=== Text Completion Test ==="
    echo "Server URL: $SERVER_URL"
    echo "Prompt: $PROMPT"
    echo ""
    
    check_server
    
    # Get actual model name
    MODEL_NAME=$(get_model_name)
    echo "Using model: $MODEL_NAME"
    echo ""
    
    echo "📝 Testing text completion..."
    
    # Prepare request payload
    payload=$(cat <<EOF
{
    "model": "$MODEL_NAME",
    "prompt": "$PROMPT",
    "max_tokens": 100,
    "temperature": 0.7
}
EOF
)
    
    echo "Request payload:"
    echo "$payload" | jq '.' 2>/dev/null || echo "$payload"
    echo ""
    
    # Send request
    response=$(curl -s -X POST "$SERVER_URL/v1/completions" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    if [ $? -eq 0 ]; then
        echo "✅ Text completion successful"
        echo "Response:"
        echo "$response" | jq '.' 2>/dev/null || echo "$response"
        
        # Extract and display the generated text
        if command -v jq >/dev/null 2>&1; then
            generated_text=$(echo "$response" | jq -r '.choices[0].text // "No content"')
            echo ""
            echo "Generated text:"
            echo "$generated_text"
        fi
    else
        echo "❌ Text completion failed"
        exit 1
    fi
}

# Main execution
if [ "$HEALTH_CHECK" = true ]; then
    health_check
elif [ "$CHAT_COMPLETION" = true ]; then
    chat_completion
elif [ "$TEXT_COMPLETION" = true ]; then
    text_completion
elif [ "$MODEL_LIST" = true ]; then
    list_models
else
    echo "=== TLLM Client Test Script ==="
    echo "Please specify a command:"
    echo "  $0 health                    # Check server health"
    echo "  $0 chat [message]            # Test chat completion"
    echo "  $0 completion [prompt]       # Test text completion"
    echo "  $0 models                    # List available models"
    echo ""
    echo "Examples:"
    echo "  $0 health"
    echo "  $0 chat 'What is AI?'"
    echo "  $0 completion 'The future of technology is'"
    echo "  $0 models"
fi 