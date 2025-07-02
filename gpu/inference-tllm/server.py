#!/usr/bin/env python3
"""
TLLM Inference Server
Provides OpenAI-compatible API for TensorRT-LLM models
"""

import os
import json
import time
from typing import List, Dict, Any
from flask import Flask, request, jsonify
from flask_cors import CORS
import tensorrt_llm
from tensorrt_llm.runtime import ModelConfig, SamplingParams
from transformers import AutoTokenizer

app = Flask(__name__)
CORS(app)

# Global variables
model = None
tokenizer = None
model_path = os.getenv("TLLM_MODEL_PATH", "/model")

def load_model():
    """Load TLLM model and tokenizer"""
    global model, tokenizer
    
    try:
        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token
            
        # Load TLLM model
        config = ModelConfig(model_path)
        model = tensorrt_llm.runtime.GenerationSession(config)
        
        print(f"✅ Model loaded successfully from {model_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        return False

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    if model is not None and tokenizer is not None:
        return jsonify({"status": "healthy", "model": "loaded"}), 200
    else:
        return jsonify({"status": "unhealthy", "model": "not_loaded"}), 503

@app.route('/v1/models', methods=['GET'])
def list_models():
    """List available models"""
    model_name = os.path.basename(model_path)
    return jsonify({
        "object": "list",
        "data": [{
            "id": model_name,
            "object": "model",
            "created": int(time.time()),
            "owned_by": "tllm"
        }]
    })

@app.route('/v1/chat/completions', methods=['POST'])
def chat_completions():
    """Chat completions endpoint"""
    try:
        data = request.get_json()
        messages = data.get('messages', [])
        max_tokens = data.get('max_tokens', 100)
        temperature = data.get('temperature', 0.7)
        
        # Extract prompt from messages
        prompt = ""
        for message in messages:
            if message['role'] == 'user':
                prompt += message['content'] + "\n"
        
        # Tokenize input
        input_ids = tokenizer.encode(prompt, return_tensors="pt")
        
        # Set sampling parameters
        sampling_params = SamplingParams(
            max_new_tokens=max_tokens,
            temperature=temperature,
            top_p=0.9,
            top_k=50
        )
        
        # Generate response
        start_time = time.time()
        output_ids = model.generate(input_ids, sampling_params)
        generation_time = time.time() - start_time
        
        # Decode response
        response_text = tokenizer.decode(output_ids[0][input_ids.shape[1]:], skip_special_tokens=True)
        
        return jsonify({
            "id": f"chatcmpl-{int(time.time())}",
            "object": "chat.completion",
            "created": int(time.time()),
            "model": os.path.basename(model_path),
            "choices": [{
                "index": 0,
                "message": {
                    "role": "assistant",
                    "content": response_text
                },
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(input_ids[0]),
                "completion_tokens": len(output_ids[0]) - len(input_ids[0]),
                "total_tokens": len(output_ids[0])
            }
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/v1/completions', methods=['POST'])
def completions():
    """Completions endpoint"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        max_tokens = data.get('max_tokens', 100)
        temperature = data.get('temperature', 0.7)
        
        # Tokenize input
        input_ids = tokenizer.encode(prompt, return_tensors="pt")
        
        # Set sampling parameters
        sampling_params = SamplingParams(
            max_new_tokens=max_tokens,
            temperature=temperature,
            top_p=0.9,
            top_k=50
        )
        
        # Generate response
        start_time = time.time()
        output_ids = model.generate(input_ids, sampling_params)
        generation_time = time.time() - start_time
        
        # Decode response
        response_text = tokenizer.decode(output_ids[0][input_ids.shape[1]:], skip_special_tokens=True)
        
        return jsonify({
            "id": f"cmpl-{int(time.time())}",
            "object": "text_completion",
            "created": int(time.time()),
            "model": os.path.basename(model_path),
            "choices": [{
                "index": 0,
                "text": response_text,
                "finish_reason": "stop"
            }],
            "usage": {
                "prompt_tokens": len(input_ids[0]),
                "completion_tokens": len(output_ids[0]) - len(input_ids[0]),
                "total_tokens": len(output_ids[0])
            }
        })
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    print("🚀 Starting TLLM Inference Server...")
    
    # Load model
    if not load_model():
        print("❌ Failed to load model. Exiting...")
        exit(1)
    
    # Start server
    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("PORT", "8000"))
    
    print(f"✅ Server starting on {host}:{port}")
    app.run(host=host, port=port, debug=False) 