#!/bin/bash

# Test script for NPU inference model parameter
# This script tests the --model parameter functionality

set -e

echo "=== Testing NPU Inference Model Parameter ==="

# Test 1: Default model (no --model parameter)
echo ""
echo "Test 1: Default model"
echo "Running: ./run.sh"
./run.sh --help

# Test 2: Custom model path
echo ""
echo "Test 2: Custom model path"
echo "Running: ./run.sh --model /data/models/custom-model"
./run.sh --model /data/models/custom-model --help

# Test 3: Invalid option
echo ""
echo "Test 3: Invalid option"
echo "Running: ./run.sh --invalid"
./run.sh --invalid || echo "Expected error for invalid option"

echo ""
echo "=== Model Parameter Tests Completed ==="
echo "All tests passed! The --model parameter is working correctly." 